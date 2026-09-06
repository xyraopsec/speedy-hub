import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: CORS_HEADERS });
}

// GET /api/checkpoint?hwid=...
// Starts or resumes session, returns status or generates Linkvertise dynamic link
export async function GET(req: NextRequest) {
  const hwid = req.nextUrl.searchParams.get("hwid") || null;
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "127.0.0.1";

  // Check if this IP or HWID already has an active session from today
  let session = await prisma.keySession.findFirst({
    where: {
      OR: [
        { ip },
        ...(hwid ? [{ token: hwid }] : []),
      ],
    },
    orderBy: { createdAt: "desc" },
  });

  if (!session) {
    const rawToken = crypto.randomBytes(16).toString("hex");
    session = await prisma.keySession.create({
      data: {
        token: rawToken,
        ip,
        step: 1,
      },
    });
  }

  // If already unlocked and key valid
  if (session.completedAt && session.keyIssued) {
    return NextResponse.json(
      {
        token: session.token,
        completed: true,
        key: session.keyIssued,
      },
      { headers: CORS_HEADERS }
    );
  }

  // Create HMAC tamper-proof signature for the callback
  const secret = process.env.NEXTAUTH_SECRET || "speedy_secret_salt_2026";
  const sig = crypto.createHmac("sha256", secret).update(`${session.token}:${session.id}`).digest("hex").slice(0, 16);

  // Redirect to our checkpoint page which embeds Linkvertise Full Script API
  const checkpointPageUrl = `https://dashboard-ten-peach-19.vercel.app/checkpoint?token=${session.token}&sig=${sig}`;

  return NextResponse.json(
    {
      token: session.token,
      completed: false,
      checkpointUrl: checkpointPageUrl,
    },
    { headers: CORS_HEADERS }
  );
}
