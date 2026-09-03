import { prisma } from "@/lib/prisma";
import { NextRequest, NextResponse } from "next/server";

// POST /api/executions  { universeId, placeId, userId, username, executor }
export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}));
  const { universeId, placeId, userId, username, executor } = body;
  if (!universeId && !placeId) return NextResponse.json({ error: "universeId or placeId required" }, { status: 400 });

  const game = await prisma.game.findFirst({
    where: universeId ? { universeId: BigInt(universeId) } : { placeId: BigInt(placeId) },
  });
  if (!game) return NextResponse.json({ error: "game not tracked" }, { status: 404 });

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || null;
  const script = await prisma.script.findFirst({ where: { gameId: game.id, isActive: true }, orderBy: { updatedAt: "desc" } });

  await prisma.$transaction([
    prisma.execution.create({
      data: {
        gameId: game.id,
        scriptId: script?.id,
        placeId: placeId ? BigInt(placeId) : null,
        userId: userId ? String(userId) : null,
        username: username || null,
        executor: executor || null,
        ip,
        success: true,
      },
    }),
    ...(script ? [prisma.script.update({ where: { id: script.id }, data: { executionsCount: { increment: 1 } } })] : []),
  ]);

  return NextResponse.json({ ok: true });
}

export async function GET(req: NextRequest) {
  const take = Math.min(100, parseInt(req.nextUrl.searchParams.get("take") || "50"));
  const rows = await prisma.execution.findMany({ orderBy: { createdAt: "desc" }, take, include: { game: true } });
  return NextResponse.json(rows.map((r: any) => ({ ...r, placeId: r.placeId?.toString(), game: { ...r.game, universeId: r.game.universeId.toString(), placeId: r.game.placeId.toString() } })));
}
