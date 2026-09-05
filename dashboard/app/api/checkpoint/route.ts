import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { generateSessionToken, issueCheckpointKey } from "@/lib/keys";
import crypto from "crypto";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: CORS_HEADERS });
}

// GET /api/checkpoint?token=...
export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get("token");
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || null;

  if (!token) {
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
  if (!session) return NextResponse.json({ error: "Session expired or invalid" }, { status: 404, headers: CORS_HEADERS });

  return NextResponse.json({
    token: session.token,
    step: session.step,
    completed: !!session.completedAt,
    key: session.keyIssued,
  }, { headers: CORS_HEADERS });
}

// POST /api/checkpoint
// Body: { token, passCode }
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}));
  const { token, passCode } = body;

  if (!token) return NextResponse.json({ error: "Token required" }, { status: 400, headers: CORS_HEADERS });

  const session = await prisma.keySession.findUnique({ where: { token } });
  if (!session) return NextResponse.json({ error: "Session expired or invalid" }, { status: 404, headers: CORS_HEADERS });

  if (session.keyIssued) {
    return NextResponse.json({ ok: true, key: session.keyIssued }, { headers: CORS_HEADERS });
  }

  // Validate Linkvertise target secret passcode
  // The user only receives this passcode once they reach Linkvertise's destination
  // Expected passCode: sha256 of session token + salt or direct validation
  const expectedCode = crypto
    .createHash("sha256")
    .update(`speedy_${session.token}_target_2026`)
    .digest("hex")
    .substring(0, 10)
    .toUpperCase();

  if (!passCode || passCode.trim().toUpperCase() !== expectedCode) {
    return NextResponse.json(
      { error: "Invalid completion pass! You must complete the Linkvertise checkpoint to receive your access code." },
      { status: 403, headers: CORS_HEADERS }
    );
  }

  // Issue 24h key
  const newKey = await issueCheckpointKey(`Linkvertise Checkpoint -> ${session.ip || "User"}`);
  await prisma.keySession.update({
    where: { id: session.id },
    data: {
      step: 2,
      completedAt: new Date(),
      keyIssued: newKey,
    },
  });

  return NextResponse.json({ ok: true, key: newKey }, { headers: CORS_HEADERS });
}
