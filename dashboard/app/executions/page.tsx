import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export default async function ExecutionsPage() {
  const rows = await prisma.execution.findMany({
    orderBy: { createdAt: "desc" },
    take: 100,
    include: { game: true, script: true },
  }).catch(() => []);

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[#1a1a1a] pb-6 gap-4">
        <div>
          <h1 className="text-3xl sm:text-4xl font-black tracking-tighter text-white">Executions</h1>
          <p className="text-sm text-white/50 mt-2">Real-time log of every payload execution from the loader.</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10 shrink-0">
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
          <span className="text-xs text-white/70 font-medium">Monitoring</span>
        </div>
      </div>

      <div className="card overflow-hidden">
        <div className="px-6 py-4 border-b border-[#1a1a1a] flex items-center justify-between bg-[#0a0a0a]">
          <h2 className="font-bold text-white tracking-tight">Recent Activity</h2>
          <span className="text-[10px] font-bold tracking-widest uppercase mono text-white/40">{rows.length} Records</span>
        </div>
        
        {rows.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-white/30">
                <path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"/>
                <path d="M12 6v6l4 2"/>
              </svg>
            </div>
            <div className="text-sm font-bold text-white/60">No executions yet</div>
            <div className="text-xs text-white/40 mt-1 max-w-xs">Executions will appear here when someone runs a script from the loader.</div>
          </div>
        ) : (
          <>
            {/* Desktop table */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-[#050505] text-white/40 text-[10px] uppercase tracking-widest font-bold">
                  <tr>
                    <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">When</th>
                    <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Game</th>
                    <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">User</th>
                    <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Version</th>
                    <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Executor</th>
                    <th className="text-right p-4 font-bold border-b border-[#1a1a1a]">IP</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#1a1a1a]">
                  {rows.map((r) => {
                    const uid = r.userId || "";
                    return (
                      <tr key={r.id} className="hover:bg-[#0c0c0c] transition-colors group">
                        <td className="p-4 mono text-xs text-white/50 group-hover:text-white/80 transition-colors whitespace-nowrap">
                          {new Date(r.createdAt).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" })}
                        </td>
                        <td className="p-4">
                          <div className="flex items-center gap-2.5">
                            <img
                              src={`/api/thumbnail?type=game&id=${r.game.universeId.toString()}&size=150x150`}
                              alt=""
                              className="w-8 h-8 rounded-lg object-cover border border-[#222] bg-[#111]"
                            />
                            <div>
                              <div className="font-bold text-white/90 group-hover:text-white transition-colors text-sm">{r.game.name}</div>
                              <div className="text-[10px] text-white/30 mono">{r.game.universeId.toString()}</div>
                            </div>
                          </div>
                        </td>
                        <td className="p-4">
                          <div className="flex items-center gap-2.5">
                            {uid ? (
                              <img
                                src={`/api/thumbnail?type=user&id=${uid}&size=150x150`}
                                alt=""
                                className="w-8 h-8 rounded-full object-cover border border-[#333] bg-[#111]"
                              />
                            ) : (
                              <div className="w-8 h-8 rounded-full bg-[#111] border border-[#222] flex items-center justify-center text-[10px] text-white/20">—</div>
                            )}
                            <div>
                              <div className="font-medium text-white/80 text-sm">{r.username || "—"}</div>
                              {uid && <div className="text-[10px] text-white/30 mono">{uid}</div>}
                            </div>
                          </div>
                        </td>
                        <td className="p-4">
                          <span className="px-2 py-1 rounded text-xs font-bold bg-[#1a1a1a] text-white/80 mono border border-[#222]">
                            v{r.script?.version || "—"}
                          </span>
                        </td>
                        <td className="p-4 text-xs text-white/40 mono">
                          {r.executor || "—"}
                        </td>
                        <td className="p-4 mono text-xs text-right text-white/40 group-hover:text-white/60 transition-colors">
                          {r.ip || "—"}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Mobile cards */}
            <div className="md:hidden divide-y divide-[#1a1a1a]">
              {rows.map((r) => {
                const uid = r.userId || "";
                return (
                  <div key={r.id} className="p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <img
                          src={`/api/thumbnail?type=game&id=${r.game.universeId.toString()}&size=150x150`}
                          alt=""
                          className="w-10 h-10 rounded-lg object-cover border border-[#222] bg-[#111]"
                        />
                        <div>
                          <div className="font-bold text-white text-sm">{r.game.name}</div>
                          <div className="mono text-[10px] text-white/30">{new Date(r.createdAt).toLocaleString(undefined, { dateStyle: "short", timeStyle: "short" })}</div>
                        </div>
                      </div>
                      <span className="px-2 py-1 rounded text-[10px] font-bold bg-[#1a1a1a] text-white/80 mono border border-[#222]">
                        v{r.script?.version || "—"}
                      </span>
                    </div>
                    <div className="flex items-center gap-2.5 pl-[52px]">
                      {uid ? (
                        <img
                          src={`/api/thumbnail?type=user&id=${uid}&size=150x150`}
                          alt=""
                          className="w-6 h-6 rounded-full object-cover border border-[#333] bg-[#111]"
                        />
                      ) : null}
                      <span className="text-xs text-white/60">{r.username || "—"}</span>
                      {r.executor && <span className="text-[10px] text-white/30 mono ml-auto">{r.executor}</span>}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
