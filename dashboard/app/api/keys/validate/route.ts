import { NextRequest, NextResponse } from "next/server";
import { validateKey } from "@/lib/keys";

// POST /api/keys/validate  { key, hwid } — public by design (executors
// can't hold a session). No throttle needed: keys carry 64 bits of entropy
// and bind to HWID on first use, so enumeration is infeasible and sharing
// is contained. Failed guesses cost the attacker, not us.
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}));
  const verdict = await validateKey(body.key, body.hwid ?? null);
  if (!verdict.ok) return NextResponse.json(verdict, { status: 403 });
  return NextResponse.json(verdict);
}
