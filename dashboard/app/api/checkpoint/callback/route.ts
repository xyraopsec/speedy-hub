import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { issueCheckpointKey } from "@/lib/keys";
import crypto from "crypto";

// GET /api/checkpoint/callback?token=...&sig=...
// Linkvertise target lands here after the user completes the ad task
export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get("token");
  const sig = req.nextUrl.searchParams.get("sig");

  if (!token || !sig) {
    return NextResponse.redirect(new URL("/?error=missing_params", "https://speedy-keys-eight.vercel.app"));
  }

  const session = await prisma.keySession.findUnique({ where: { token } });
  if (!session) {
    return NextResponse.redirect(new URL("/?error=invalid_session", "https://speedy-keys-eight.vercel.app"));
  }

  // Verify HMAC signature
  const secret = process.env.NEXTAUTH_SECRET || "speedy_secret_salt_2026";
  const expectedSig = crypto.createHmac("sha256", secret).update(`${session.token}:${session.id}`).digest("hex").slice(0, 16);

  if (sig !== expectedSig) {
    return NextResponse.redirect(new URL("/?error=invalid_signature", "https://speedy-keys-eight.vercel.app"));
  }

  // Issue 24-hour key
  let issuedKey = session.keyIssued;
  if (!issuedKey) {
    issuedKey = await issueCheckpointKey(`Auto-issued via Linkvertise to ${session.ip || "User"}`);
    await prisma.keySession.update({
      where: { id: session.id },
      data: {
        completedAt: new Date(),
        keyIssued: issuedKey,
        step: 2,
      },
    });
  }

  // Redirect right back to key site with the unlocked key
  return NextResponse.redirect(new URL(`/?key=${encodeURIComponent(issuedKey)}`, "https://speedy-keys-eight.vercel.app"));
}
