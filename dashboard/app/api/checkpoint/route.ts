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

  // Linkvertise dynamic link — target is our callback endpoint
  const callbackUrl = `https://dashboard-ten-peach-19.vercel.app/api/checkpoint/callback?token=${session.token}&sig=${sig}`;
  // Working format: https://link-to.net/{userId}/{random}/dynamic?r={base64url(encodeURI(targetUrl))}
  const encodedDestination = Buffer.from(encodeURI(callbackUrl)).toString('base64url');
  const linkvertiseUrl = `https://link-to.net/9061250/${(Math.random() * 1000).toFixed(3)}/dynamic?r=${encodedDestination}`;

  return NextResponse.json(
    {
      token: session.token,
      completed: false,
      checkpointUrl: linkvertiseUrl,
    },
    { headers: CORS_HEADERS }
  );
}
