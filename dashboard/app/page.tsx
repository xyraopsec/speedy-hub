import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

async function getStats() {
  const [total, today, games] = await Promise.all([
    prisma.execution.count(),
    prisma.execution.count({ where: { createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } }),
    prisma.game.findMany({ include: { _count: { select: { executions: true } } }, orderBy: { order: "asc" } }),
  ]);
  const byGame = games.map(g => ({ name: g.name, count: g._count.executions }));
  return { total, today, byGame, games };
}

export default async function Dashboard() {
  const { total, today, byGame } = await getStats().catch(() => ({ total: 0, today: 0, byGame: [] }));
  return (
    <div className="space-y-6">
      <div className="flex items-baseline justify-between">
        <h1 className="text-[28px] font-black tracking-tight">Overview</h1>
        <span className="text-xs text-white/40 mono">monochrome • color = meaning</span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[
          ["Total Executions", total.toLocaleString(), "all time"],
          ["Today", today.toLocaleString(), "last 24h"],
          ["Games", "20", "cars & moto"],
        ].map(([label, value, sub]) => (
          <div key={label} className="card p-5">
            <div className="text-xs tracking-widest text-white/40">{label as string}</div>
            <div className="text-3xl font-black mt-2 mono">{value as string}</div>
            <div className="text-xs text-white/30 mt-1">{sub as string}</div>
          </div>
        ))}
      </div>

      <div className="card p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold">Executions by Game</h2>
          <span className="text-xs px-2 py-1 rounded-full bg-white text-black font-bold">LIVE</span>
        </div>
        <div className="space-y-2">
          {byGame.length === 0 ? <div className="text-sm text-white/40">No data yet — POST /api/executions from loader</div> : byGame.map(g => (
            <div key={g.name} className="flex items-center gap-3">
              <div className="w-36 text-xs truncate text-white/70">{g.name}</div>
              <div className="flex-1 h-2 bg-white/10 rounded-full overflow-hidden"><div className="h-full bg-[#FF1A1A]" style={{ width: `${Math.min(100, (g.count / Math.max(1, Math.max(...byGame.map(x=>x.count))))*100)}%` }} /></div>
              <div className="w-12 text-right mono text-xs">{g.count}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="card p-6">
        <h2 className="font-semibold mb-3">How loader talks to backend</h2>
        <pre className="bg-black rounded-xl p-4 text-xs overflow-auto text-white/80">{`GET  /api/scripts?universeId=1202096104  -> { code: "-- Lua" }
POST /api/executions  { universeId, placeId, userId } -> 200 { ok: true }`}</pre>
        <p className="text-xs text-white/40 mt-3">Hook this in Loader.lua after Hit.MouseButton1Click — one line. See README.</p>
      </div>
    </div>
  );
}
