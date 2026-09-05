import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { requireOwner, unauthorized } from "@/lib/require-owner";

// PATCH /api/keys/action { id, action: "toggle" | "resetHwid" }
// DELETE /api/keys/action?id=...
export async function PATCH(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const body = await req.json().catch(() => ({}));
  const { id, action } = body;
  if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });

  if (action === "toggle") {
    const key = await prisma.licenseKey.findUnique({ where: { id } });
    if (!key) return NextResponse.json({ error: "not found" }, { status: 404 });
    const updated = await prisma.licenseKey.update({
      where: { id },
      data: { isActive: !key.isActive },
    });
    return NextResponse.json({ ok: true, isActive: updated.isActive });
  }

  if (action === "resetHwid") {
    await prisma.licenseKey.update({
      where: { id },
      data: { hwid: null },
    });
    return NextResponse.json({ ok: true, hwid: null });
  }

  return NextResponse.json({ error: "unknown action" }, { status: 400 });
}

export async function DELETE(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const id = req.nextUrl.searchParams.get("id");
  if (!id) return NextResponse.json({ error: "id required" }, { status: 400 });
  await prisma.licenseKey.delete({ where: { id } });
  return NextResponse.json({ ok: true });
}
