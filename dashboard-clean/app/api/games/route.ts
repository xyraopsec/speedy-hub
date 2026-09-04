import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  const games = await prisma.game.findMany({
    where: {
      isActive: true,
      scripts: { some: { isActive: true } },
    },
    orderBy: { order: "asc" },
    select: {
      name: true,
      universeId: true,
      placeId: true,
      order: true,
      scripts: {
        where: { isActive: true },
        take: 1,
        select: { version: true },
      },
    },
  });

  return NextResponse.json(
    games.map((g) => ({
      name: g.name,
      universeId: g.universeId.toString(),
      placeId: g.placeId.toString(),
      order: g.order,
      version: g.scripts[0]?.version,
    })),
    { headers: { "Cache-Control": "no-store" } }
  );
}
