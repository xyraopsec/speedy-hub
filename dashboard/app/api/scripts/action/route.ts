import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { revalidatePath } from "next/cache";
import { requireOwner, unauthorized } from "@/lib/require-owner";

// PATCH /api/scripts/action  { id, action: "toggle" | "update", code?, version? }
export async function PATCH(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const { id, action, code, version } = await req.json();
  if (!id || !action) return NextResponse.json({ error: "missing" }, { status: 400 });

  if (action === "toggle") {
    const script = await prisma.script.findUnique({ where: { id } });
    if (!script) return NextResponse.json({ error: "not found" }, { status: 404 });
    await prisma.script.update({ where: { id }, data: { isActive: !script.isActive } });
    revalidatePath("/scripts");
    return NextResponse.json({ ok: true, isActive: !script.isActive });
  }

  if (action === "update") {
    const data: Record<string, any> = {};
    if (code !== undefined) data.code = code;
    if (version !== undefined) data.version = version;
    if (Object.keys(data).length === 0) return NextResponse.json({ error: "nothing to update" }, { status: 400 });
    await prisma.script.update({ where: { id }, data });
    revalidatePath("/scripts");
    return NextResponse.json({ ok: true });
  }

  return NextResponse.json({ error: "unknown action" }, { status: 400 });
}

// DELETE /api/scripts/action  { id }
export async function DELETE(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const { id } = await req.json();
  if (!id) return NextResponse.json({ error: "missing id" }, { status: 400 });

  const script = await prisma.script.findUnique({ where: { id } });
  if (!script) return NextResponse.json({ error: "not found" }, { status: 404 });

  await prisma.script.delete({ where: { id } });
  revalidatePath("/scripts");
  return NextResponse.json({ ok: true });
}
