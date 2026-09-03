import { prisma } from "@/lib/prisma";
import ExecutionChart from "@/components/ExecutionChart";
import { Activity, Gamepad2, Zap, ArrowRight, BarChart3, Terminal } from "lucide-react";
import Link from "next/link";

export const dynamic = "force-dynamic";

async function getStats() {
  const [total, today, games, recentExecutions] = await Promise.all([
    prisma.execution.count(),
    prisma.execution.count({ where: { createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } }),
    prisma.game.findMany({ include: { _count: { select: { executions: true } } }, orderBy: { order: "asc" } }),
    prisma.execution.findMany({ 
      where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
      select: { createdAt: true }
    })
  ]);
  
  const byGame = games.map(g => ({ name: g.name, count: g._count.executions }));
  
  // Process chart data (executions per day for the last 7 days)
  const chartData = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toLocaleDateString('en-US', { weekday: 'short' });
    
    // Count executions for this specific day
    const count = recentExecutions.filter(e => {
      const eDate = new Date(e.createdAt);
      return eDate.getDate() === d.getDate() && eDate.getMonth() === d.getMonth();
    }).length;
    
    chartData.push({ name: dateStr, executions: count });
  }

  return { total, today, byGame, games, chartData };
}

export default async function Dashboard() {
  const { total, today, byGame, games, chartData } = await getStats().catch(() => ({ total: 0, today: 0, byGame: [], games: [], chartData: [] }));
  
  return (
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row md:items-end justify-between border-b border-[#1a1a1a] pb-6 gap-4">
        <div>
          <h1 className="text-4xl font-black tracking-tighter text-white">Overview</h1>
          <p className="text-sm text-white/50 mt-2 flex items-center gap-2">
            <Activity className="w-4 h-4 text-white/30" />
            Track performance across all your scripts in real-time.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link href="/scripts" className="px-4 py-2 rounded-lg bg-white/5 border border-white/10 text-white/70 hover:bg-white/10 hover:text-white text-sm font-semibold transition-colors flex items-center gap-2">
            <Terminal className="w-4 h-4" />
            New Script
          </Link>
          <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/5 border border-white/10">
            <div className="w-2 h-2 rounded-full bg-white animate-pulse" />
            <span className="text-xs text-white/70 font-bold uppercase tracking-widest">Live</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[
          ["Total Executions", total.toLocaleString(), "Lifetime runs", <Activity key="1" className="w-4 h-4" />],
          ["Today's Volume", today.toLocaleString(), "Last 24 hours", <Zap key="2" className="w-4 h-4" />],
          ["Active Games", games.length.toString(), "Monitored universes", <Gamepad2 key="3" className="w-4 h-4" />],
        ].map(([label, value, sub, icon]) => (
          <div key={label as string} className="card p-6 relative overflow-hidden group hover:-translate-y-1 transition-all duration-300">
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            <div className="relative z-10">
              <div className="flex items-center justify-between mb-4">
                <div className="text-[10px] font-bold tracking-widest text-white/40 uppercase">{label as string}</div>
                <div className="text-white/20 group-hover:text-white/60 transition-colors">{icon}</div>
              </div>
              <div className="text-4xl font-black text-white tracking-tight mono">{value as string}</div>
              <div className="text-[11px] text-white/40 mt-4 flex items-center gap-1.5 font-medium">
                <div className="w-1 h-1 rounded-full bg-white/30 group-hover:bg-white transition-colors" />
                {sub as string}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2 card p-8 flex flex-col min-h-[400px]">
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-3">
              <BarChart3 className="w-5 h-5 text-white/50" />
              <h2 className="text-lg font-bold text-white tracking-tight">Execution Volume (7 Days)</h2>
            </div>
          </div>
          <div className="flex-1 w-full min-h-[300px]">
            <ExecutionChart data={chartData} />
          </div>
        </div>
        
        <div className="card p-8 bg-gradient-to-b from-[#0a0a0a] to-[#040404] flex flex-col">
          <h2 className="text-lg font-bold text-white tracking-tight mb-6 flex items-center gap-3">
            <Gamepad2 className="w-5 h-5 text-white/50" />
            Game Distribution
          </h2>
          <div className="space-y-5 flex-1 overflow-auto custom-scrollbar pr-2">
            {byGame.length === 0 ? (
              <div className="text-sm text-white/40 py-8 text-center border border-dashed border-white/10 rounded-xl h-full flex items-center justify-center">
                Deploy a script to see distribution.
              </div>
            ) : byGame.map((g, i) => (
              <div key={g.name} className="group">
                <div className="flex items-center justify-between mb-2">
                  <div className="text-sm truncate text-white/80 font-semibold group-hover:text-white transition-colors">{g.name}</div>
                  <div className="mono text-xs font-bold text-white/60">{g.count.toLocaleString()}</div>
                </div>
                <div className="w-full h-1.5 bg-[#111] rounded-full overflow-hidden">
                  <div className="h-full bg-white relative rounded-full transition-all duration-1000 ease-out" style={{ width: `${Math.min(100, (g.count / Math.max(1, Math.max(...byGame.map(x=>x.count))))*100)}%` }}>
                    <div className="absolute inset-0 bg-[linear-gradient(90deg,transparent,rgba(255,255,255,0.5),transparent)] -translate-x-full group-hover:animate-[shimmer_1.5s_infinite]" />
                  </div>
                </div>
              </div>
            ))}
          </div>
          {byGame.length > 0 && (
            <Link href="/games" className="mt-6 flex items-center justify-center gap-2 text-xs font-bold uppercase tracking-widest text-white/50 hover:text-white transition-colors py-3 border border-white/10 rounded-xl hover:bg-white/5">
              View All Games
              <ArrowRight className="w-4 h-4" />
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
