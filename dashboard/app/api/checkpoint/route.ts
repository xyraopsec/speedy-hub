import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { generateSessionToken, issueCheckpointKey } from "@/lib/keys";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: CORS_HEADERS });
}

// GET /api/checkpoint?token=...
// Starts session or gets status
export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get("token");
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || null;

  if (!token) {
    // Generate new session token
    const newToken = generateSessionToken();
    const session = await prisma.keySession.create({
      data: {
        token: newToken,
        ip,
        step: 1,
      },
    });
    return NextResponse.json({ token: session.token, step: session.step }, { headers: CORS_HEADERS });
  }

  const session = await prisma.keySession.findUnique({ where: { token } });
  if (!session) return NextResponse.json({ error: "Invalid session" }, { status: 404, headers: CORS_HEADERS });

  return NextResponse.json({
    token: session.token,
    step: session.step,
    completed: !!session.completedAt,
    key: session.keyIssued,
  }, { headers: CORS_HEADERS });
}

// POST /api/checkpoint { token, stepCompleted }
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}));
  const { token, stepCompleted } = body;

  if (!token) return NextResponse.json({ error: "Token required" }, { status: 400, headers: CORS_HEADERS });

  const session = await prisma.keySession.findUnique({ where: { token } });
  if (!session) return NextResponse.json({ error: "Session expired or invalid" }, { status: 404, headers: CORS_HEADERS });

  // Anti-bypass minimum cooldown: user cannot skip steps within 3 seconds
  const now = Date.now();
  const elapsed = now - session.updatedAt.getTime();
  if (elapsed < 3000 && stepCompleted > session.step) {
    return NextResponse.json({ error: "Please wait before proceeding." }, { status: 429, headers: CORS_HEADERS });
  }

  // Checkpoints: 2 steps by default (Step 1 -> Step 2 -> Vend Key)
  if (stepCompleted === 1 && session.step === 1) {
    const updated = await prisma.keySession.update({
      where: { id: session.id },
      data: { step: 2 },
    });
    return NextResponse.json({ ok: true, step: updated.step }, { headers: CORS_HEADERS });
  }

  if (stepCompleted === 2 && session.step === 2) {
    // Already issued?
    if (session.keyIssued) {
      return NextResponse.json({ ok: true, step: 3, key: session.keyIssued }, { headers: CORS_HEADERS });
    }

    const newKey = await issueCheckpointKey(`Auto-issued via Checkpoints to ${session.ip || "User"}`);
    await prisma.keySession.update({
      where: { id: session.id },
      data: {
        step: 3,
        completedAt: new Date(),
        keyIssued: newKey,
      },
    });

    return NextResponse.json({ ok: true, step: 3, key: newKey }, { headers: CORS_HEADERS });
  }

  return NextResponse.json({ error: "Invalid step progression" }, { status: 400, headers: CORS_HEADERS });
}
