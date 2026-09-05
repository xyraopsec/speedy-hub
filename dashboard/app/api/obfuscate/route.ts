import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { revalidatePath } from "next/cache";
import { requireOwner, unauthorized } from "@/lib/require-owner";

// POST /api/obfuscate  { id } — re-run protection for one script.
// Each call spends 1 of 2 free daily MoonVeil requests.
export async function POST(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const { id } = await req.json().catch(() => ({}));
  if (!id) return NextResponse.json({ error: "missing id" }, { status: 400 });

  const script = await prisma.script.findUnique({ where: { id } });
  if (!script) return NextResponse.json({ error: "not found" }, { status: 404 });

  const { runObfuscation } = await import("@/lib/obfuscate");
  const result = await runObfuscation(id, script.code).catch((e) => ({
    ok: false as const,
    error: `obfuscator unreachable: ${e?.message || e}`,
  }));
  revalidatePath("/scripts");
  if (!result.ok) return NextResponse.json({ ok: false, error: result.error }, { status: 502 });
  return NextResponse.json({ ok: true });
}
