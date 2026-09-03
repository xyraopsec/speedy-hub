import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";
export default async function ExecutionsPage() {
  const rows = await prisma.execution.findMany({ orderBy: { createdAt: "desc" }, take: 100, include: { game: true, script: true } }).catch(()=>[]);
  return (
    <div className="space-y-6">
      <h1 className="text-[28px] font-black tracking-tight">Executions</h1>
      <p className="text-sm text-white/50">Every Loader.lua Click → POST /api/executions • live</p>
      <div className="rounded-[20px] border border-[#242428] overflow-hidden">
        <div className="overflow-auto">
          <table className="w-full text-sm">
            <thead className="bg-[#111113] text-white/40 text-xs tracking-widest">
              <tr><th className="text-left p-3">TIME</th><th className="text-left p-3">GAME</th><th className="text-left p-3">USER</th><th className="text-left p-3">SCRIPT</th><th className="text-right p-3">IP</th></tr>
            </thead>
            <tbody className="divide-y divide-[#242428]">
              {rows.length===0? <tr><td colSpan={5} className="p-6 text-center text-white/40">No executions yet. Loader will POST on each card Click.</td></tr> :
              rows.map(r=>(
                <tr key={r.id} className="hover:bg-white/[0.04]">
                  <td className="p-3 mono text-xs text-white/60">{new Date(r.createdAt).toLocaleString()}</td>
                  <td className="p-3 font-bold">{r.game.name}<span className="text-white/30 font-normal mono text-xs ml-2">{r.game.universeId.toString()}</span></td>
                  <td className="p-3 mono text-xs">{r.username || r.userId || "—"}</td>
                  <td className="p-3 text-xs">{r.script?.version || "—"}</td>
                  <td className="p-3 mono text-xs text-right text-white/40">{r.ip || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
