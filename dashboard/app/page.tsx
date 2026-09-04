import { prisma } from "@/lib/prisma";
import ExecutionChart from "@/components/ExecutionChart";
import Link from "next/link";

export const dynamic = "force-dynamic";

async function getStats() {
  const [total, today, games, activeScripts, recentExecutions] = await Promise.all([
    prisma.execution.count(),
    prisma.execution.count({ where: { createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } }),
    prisma.game.findMany({
      include: { _count: { select: { executions: true } } },
      orderBy: { order: "asc" },
      where: { scripts: { some: { isActive: true } } },
    }),
    prisma.script.count({ where: { isActive: true } }),
    prisma.execution.findMany({
      where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
      select: { createdAt: true },
    }),
  ]);

  const byGame = games
    .map((g) => ({ name: g.name, count: g._count.executions }))
    .filter((g) => g.count > 0)
    .sort((a, b) => b.count - a.count);

  const chartData = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toLocaleDateString("en-US", { weekday: "short" });
    const count = recentExecutions.filter((e) => {
      const eDate = new Date(e.createdAt);
      return eDate.getDate() === d.getDate() && eDate.getMonth() === d.getMonth();
    }).length;
    chartData.push({ name: dateStr, executions: count });
  }

  return { total, today, byGame, games, activeScripts, chartData };
}

export default async function Dashboard() {
  const { total, today, byGame, games, activeScripts, chartData } = await getStats().catch(() => ({
    total: 0,
    today: 0,
    byGame: [],
    games: [],
    activeScripts: 0,
    chartData: [],
  }));

  const stats: Array<[string, string, string]> = [
    ["Total executions", total.toLocaleString(), "all time"],
    ["Today", today.toLocaleString(), "last 24 hours"],
    ["Active scripts", activeScripts.toString(), "deployed payloads"],
    ["Games", games.length.toString(), "monitored universes"],
  ];

  const max = Math.max(1, ...byGame.map((x) => x.count));

  return (
    <div className="space-y-6">
      {/* Page head */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display font-semibold text-[28px] leading-none text-[#F4F4F5]">Overview</h1>
          <p className="text-[13.5px] text-[#A7A7B0] mt-2">
            Execution volume and payload health for the last 7 days.
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          <Link href="/executions" className="btn-ghost px-4 py-2.5 inline-flex items-center">
            View log
          </Link>
          <Link href="/scripts" className="btn-primary px-4 py-2.5 inline-flex items-center">
            Deploy script
          </Link>
        </div>
      </div>

      {/* Stat strip — one panel, divided, no icon cards */}
      <div className="panel grid grid-cols-2 lg:grid-cols-4">
        {stats.map(([label, value, sub], i) => (
          <div
            key={label}
            className={`px-5 py-4 ${i > 0 ? "border-l border-[#1B1B21]" : ""} ${
              i >= 2 ? "max-lg:border-t max-lg:border-[#1B1B21]" : ""
            } ${i === 2 ? "max-lg:border-l-0" : ""}`}
          >
            <div className="text-[12.5px] text-[#A7A7B0]">{label}</div>
            <div className="font-display font-semibold text-[28px] leading-tight text-[#F4F4F5] mono-nums tabular-nums">
              {value}
            </div>
            <div className="mono text-[11px] text-[#62626C]">{sub}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        {/* Chart */}
        <div className="xl:col-span-2 panel p-5 md:p-6">
          <div className="flex items-baseline justify-between mb-1">
            <h2 className="text-[13.5px] font-semibold text-[#F4F4F5]">Executions, last 7 days</h2>
            <span className="mono text-[12px] text-[#62626C]">{total.toLocaleString()} total</span>
          </div>
          <p className="text-[12.5px] text-[#62626C] mb-5">Daily payload runs across all games.</p>
          <div className="h-[280px] w-full">
            <ExecutionChart data={chartData} />
          </div>
        </div>

        {/* Ranked distribution */}
        <div className="panel p-5 md:p-6 flex flex-col">
          <h2 className="text-[13.5px] font-semibold text-[#F4F4F5]">Top games</h2>
          <p className="text-[12.5px] text-[#62626C] mt-1 mb-4">Ranked by execution count.</p>
          <div className="flex-1">
            {byGame.length === 0 ? (
              <div className="border border-dashed border-[#2A2A31] rounded-[8px] p-6 text-center">
                <div className="text-[13px] text-[#A7A7B0]">No executions recorded yet.</div>
                <Link href="/scripts" className="btn-ghost inline-flex px-3.5 py-2 mt-3 text-[13px]">
                  Deploy your first payload
                </Link>
              </div>
            ) : (
              <ol className="panel-divide border-t border-b border-[#1B1B21]">
                {byGame.slice(0, 8).map((g, i) => (
                  <li key={g.name} className="flex items-center gap-3 py-2.5">
                    <span className="mono text-[11.5px] text-[#62626C] w-5 shrink-0">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <span className="text-[13.5px] text-[#F4F4F5] truncate flex-1">{g.name}</span>
                    <span className="w-20 h-[3px] rounded-full bg-[#1E1E24] overflow-hidden shrink-0 hidden sm:block">
                      <span className="block h-full bg-[#8E8E99]" style={{ width: `${Math.min(100, (g.count / max) * 100)}%` }} />
                    </span>
                    <span className="mono text-[12px] text-[#A7A7B0] w-12 text-right shrink-0">
                      {g.count.toLocaleString()}
                    </span>
                  </li>
                ))}
              </ol>
            )}
          </div>
          {byGame.length > 0 && (
            <Link href="/scripts" className="btn-ghost mt-4 py-2.5 text-center text-[13px]">
              Manage scripts
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
