import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";
import { requireOwner, unauthorized } from "@/lib/require-owner";

// GET /api/scripts?universeId=1202096104&placeId=3357602286
export async function GET(req: NextRequest) {
  const uni = req.nextUrl.searchParams.get("universeId");
  const place = req.nextUrl.searchParams.get("placeId");
  if (!uni && !place) return NextResponse.json({ error: "universeId or placeId required" }, { status: 400 });

  const game = await prisma.game.findFirst({
    where: uni ? { universeId: BigInt(uni) } : { placeId: BigInt(place!) },
    include: { scripts: { where: { isActive: true }, orderBy: { updatedAt: "desc" }, take: 1 } },
  });
  if (!game || game.scripts.length === 0) return NextResponse.json({ error: "no script" }, { status: 404 });
  const s = game.scripts[0];
  return NextResponse.json({ game: game.name, version: s.version, code: s.code }, {
    headers: { "Cache-Control": "no-store" }
  });
}

// POST /api/scripts  { universeId, name, version, code }
export async function POST(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const { universeId, name, version, code } = await req.json();
  if (!universeId || !code) return NextResponse.json({ error: "missing" }, { status: 400 });
  const game = await prisma.game.findUnique({ where: { universeId: BigInt(universeId) } });
  if (!game) return NextResponse.json({ error: "game not found" }, { status: 404 });
  const script = await prisma.script.create({ data: { gameId: game.id, name: name || game.name, version: version || "1.0.0", code } });
  return NextResponse.json({ ok: true, id: script.id });
}
