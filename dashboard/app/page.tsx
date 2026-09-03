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
    <div className="space-y-10">
      <div className="flex items-baseline justify-between border-b border-[#1a1a1a] pb-6">
        <div>
          <h1 className="text-4xl font-black tracking-tighter text-white">Overview</h1>
          <p className="text-sm text-white/50 mt-2">Track performance across all your scripts in real-time.</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10">
          <div className="w-2 h-2 rounded-full bg-white animate-pulse" />
          <span className="text-xs text-white/70 font-medium">Live</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          ["Total Executions", total.toLocaleString(), "Lifetime runs across all games"],
          ["Today's Volume", today.toLocaleString(), "Executions in the last 24 hours"],
          ["Active Games", "20", "Currently monitored universes"],
        ].map(([label, value, sub]) => (
          <div key={label} className="card p-6 relative overflow-hidden group">
            {/* Subtle gradient glow effect on hover */}
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            
            <div className="relative z-10">
              <div className="text-xs font-semibold tracking-wider text-white/50 uppercase">{label as string}</div>
              <div className="text-4xl font-black mt-3 text-white tracking-tight">{value as string}</div>
              <div className="text-xs text-white/40 mt-3 flex items-center gap-2">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-white/30"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>
                {sub as string}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 card p-8">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-lg font-bold text-white tracking-tight">Execution Distribution</h2>
            <button className="text-xs text-white/50 hover:text-white transition-colors">View All →</button>
          </div>
          <div className="space-y-4">
            {byGame.length === 0 ? (
              <div className="text-sm text-white/40 py-8 text-center border border-dashed border-white/10 rounded-xl">
                Awaiting execution data.
              </div>
            ) : byGame.map((g, i) => (
              <div key={g.name} className="flex items-center gap-4 group">
                <div className="w-6 text-xs text-white/30 mono font-medium">{(i + 1).toString().padStart(2, '0')}</div>
                <div className="w-48 text-sm truncate text-white/80 font-medium group-hover:text-white transition-colors">{g.name}</div>
                <div className="flex-1 h-1.5 bg-[#111] rounded-full overflow-hidden">
                  <div className="h-full bg-white relative" style={{ width: `${Math.min(100, (g.count / Math.max(1, Math.max(...byGame.map(x=>x.count))))*100)}%` }}>
                    <div className="absolute inset-0 bg-[linear-gradient(90deg,transparent,rgba(255,255,255,0.5),transparent)] -translate-x-full group-hover:animate-[shimmer_1.5s_infinite]" />
                  </div>
                </div>
                <div className="w-16 text-right mono text-xs font-semibold text-white/70">{g.count.toLocaleString()}</div>
              </div>
            ))}
          </div>
        </div>
        
        <div className="card p-8 bg-gradient-to-b from-[#0a0a0a] to-[#040404]">
          <h2 className="text-lg font-bold text-white tracking-tight mb-4">Integration</h2>
          <p className="text-sm text-white/60 mb-6 leading-relaxed">
            The loader communicates with the backend seamlessly. Just add one line in <code className="bg-white/10 text-white px-1.5 py-0.5 rounded text-xs mono">Loader.lua</code>.
          </p>
          
          <div className="space-y-3">
            <div className="bg-black border border-[#1a1a1a] rounded-xl p-4 overflow-hidden relative group">
              <div className="absolute inset-0 bg-white/[0.02] opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="text-[10px] text-white/40 mb-2 tracking-widest font-bold uppercase">Fetch Script</div>
              <pre className="text-xs text-white/80 mono leading-relaxed">GET /api/scripts?universeId=ID</pre>
            </div>
            
            <div className="bg-black border border-[#1a1a1a] rounded-xl p-4 overflow-hidden relative group">
              <div className="absolute inset-0 bg-white/[0.02] opacity-0 group-hover:opacity-100 transition-opacity" />
              <div className="text-[10px] text-white/40 mb-2 tracking-widest font-bold uppercase">Log Execution</div>
              <pre className="text-xs text-white/80 mono leading-relaxed">POST /api/executions</pre>
            </div>
          </div>
          
          <button className="w-full mt-6 py-3 rounded-xl bg-white text-black font-bold text-sm hover:bg-white/90 transition-colors">
            Read Documentation
          </button>
        </div>
      </div>
    </div>
  );
}
