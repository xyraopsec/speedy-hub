import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export default async function ExecutionsPage() {
  const rows = await prisma.execution.findMany({ orderBy: { createdAt: "desc" }, take: 100, include: { game: true, script: true } }).catch(()=>[]);
  
  return (
    <div className="space-y-10">
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
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">User Identifier</th>
                <th className="text-left p-4 font-bold border-b border-[#1a1a1a]">Payload Version</th>
                <th className="text-right p-4 font-bold border-b border-[#1a1a1a]">Network IP</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1a1a1a]">
              {rows.length === 0 ? (
                <tr>
                  <td colSpan={5} className="p-10 text-center text-sm text-white/40 font-medium">
                    No executions recorded yet. Listening for POST requests...
                  </td>
                </tr>
              ) : rows.map(r => (
                <tr key={r.id} className="hover:bg-[#0c0c0c] transition-colors group">
                  <td className="p-4 mono text-xs text-white/50 group-hover:text-white/80 transition-colors">
                    {new Date(r.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'medium' })}
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-white/90 group-hover:text-white transition-colors">{r.game.name}</span>
                      <span className="px-1.5 py-0.5 rounded text-[10px] bg-[#1a1a1a] text-white/40 mono border border-[#222]">
                        {r.game.universeId.toString()}
                      </span>
                    </div>
                  </td>
                  <td className="p-4 mono text-xs text-white/70">
                    {r.username || r.userId || "—"}
                  </td>
                  <td className="p-4">
                    <span className="px-2 py-1 rounded text-xs font-bold bg-[#1a1a1a] text-white/80 mono border border-[#222]">
                      v{r.script?.version || "—"}
                    </span>
                  </td>
                  <td className="p-4 mono text-xs text-right text-white/40 group-hover:text-white/60 transition-colors">
                    {r.ip || "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
