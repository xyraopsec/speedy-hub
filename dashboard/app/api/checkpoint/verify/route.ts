import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";

export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get("token");
  if (!token) {
    return NextResponse.redirect(new URL("/", req.url));
  }

  const passCode = crypto
    .createHash("sha256")
    .update(`speedy_${token}_target_2026`)
    .digest("hex")
    .substring(0, 10)
    .toUpperCase();

  // Redirect back to the key site with verification code
  return NextResponse.redirect(`https://speedy-keys-eight.vercel.app?token=${encodeURIComponent(token)}&pass=${passCode}`);
}
