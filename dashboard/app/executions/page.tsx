import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

async function getAvatarUrls(userIds: string[]): Promise<Record<string, string>> {
  if (userIds.length === 0) return {};
  const unique = [...new Set(userIds.filter(Boolean))];
  if (unique.length === 0) return {};

  const avatars: Record<string, string> = {};

  // Batch in groups of 100 (Roblox API limit)
  for (let i = 0; i < unique.length; i += 100) {
    const batch = unique.slice(i, i + 100);
    try {
      const res = await fetch(
        `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${batch.join(",")}&size=150x150&format=Png&isCircular=false`,
        { next: { revalidate: 300 } } // cache 5 min
      );
      if (res.ok) {
        const data = await res.json();
        for (const item of data.data || []) {
          if (item.state === "Completed" && item.imageUrl) {
            avatars[String(item.targetId)] = item.imageUrl;
          }
        }
      }
    } catch {}
  }
  return avatars;
}

export default async function ExecutionsPage() {
  const rows = await prisma.execution.findMany({
    orderBy: { createdAt: "desc" },
    take: 100,
    include: { game: true, script: true },
  }).catch(() => []);

  const userIds = rows.map((r) => r.userId).filter(Boolean) as string[];
  const avatars = await getAvatarUrls(userIds);

  return (
    <div className="space-y-10 animate-fade-in">
      <div className="flex items-center justify-between border-b border-[#1a1a1a] pb-6">
        <div>
          <h1 className="text-4xl font-black tracking-tighter text-white">Executions</h1>
          <p className="text-sm text-white/50 mt-2">Real-time log of every payload execution from the loader.</p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10">
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
          <span className="text-xs text-white/70 font-medium">Monitoring</span>
        </div>
      </div>

      <div className="card overflow-hidden">
        <div className="px-6 py-5 border-b border-[#1a1a1a] flex items-center justify-between bg-[#0a0a0a]">
          <h2 className="font-bold text-white tracking-tight">Recent Activity</h2>
          <span className="text-[10px] font-bold tracking-widest uppercase mono text-white/40">{rows.length} Records</span>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-[#050505] text-white/40 text-[10px] uppercase tracking-widest font-bold">
              <tr>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Timestamp</th>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Target Game</th>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">User</th>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Payload</th>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Executor</th>
                <th className="text-right p-4 font-bold border-b border-[#1a1a1a]">IP</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1a1a1a]">
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-16 text-center">
                    <div className="flex flex-col items-center">
                      <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-white/30">
                          <path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"/>
                          <path d="M12 6v6l4 2"/>
                        </svg>
                      </div>
                      <div className="text-sm font-bold text-white/60">No executions yet</div>
                      <div className="text-xs text-white/40 mt-1 max-w-xs">Executions will appear here when someone runs a script from the loader.</div>
                    </div>
                  </td>
                </tr>
              ) : rows.map((r) => {
                const uid = r.userId || "";
                const avatarUrl = avatars[uid];
                return (
                  <tr key={r.id} className="hover:bg-[#0c0c0c] transition-colors group">
                    <td className="p-4 mono text-xs text-white/50 group-hover:text-white/80 transition-colors whitespace-nowrap">
                      {new Date(r.createdAt).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "medium" })}
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2.5">
                        <img
                          src={`https://thumbnails.roblox.com/v1/games/icons?universeIds=${r.game.universeId.toString()}&size=48x48&format=Png`}
                          alt=""
                          className="w-8 h-8 rounded-lg object-cover border border-[#222]"
                          onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
                        />
                        <div>
                          <div className="font-bold text-white/90 group-hover:text-white transition-colors text-sm">{r.game.name}</div>
                          <div className="text-[10px] text-white/30 mono">{r.game.universeId.toString()}</div>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2.5">
                        {avatarUrl ? (
                          <img
                            src={avatarUrl}
                            alt=""
                            className="w-8 h-8 rounded-full object-cover border border-[#333]"
                            onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
                          />
                        ) : uid ? (
                          <div className="w-8 h-8 rounded-full bg-[#1a1a1a] border border-[#333] flex items-center justify-center text-[10px] font-bold text-white/40">
                            {r.username?.[0]?.toUpperCase() || "?"}
                          </div>
                        ) : (
                          <div className="w-8 h-8 rounded-full bg-[#111] border border-[#222] flex items-center justify-center text-[10px] text-white/20">
                            —
                          </div>
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
      </div>
    </div>
  );
}
