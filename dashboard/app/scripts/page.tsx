import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";

export const dynamic = "force-dynamic";

async function getGames() {
  return prisma.game.findMany({ orderBy: { order: "asc" } }).catch(() => []);
}

async function createScript(formData: FormData) {
  "use server";
  const universeId = String(formData.get("universeId") || "");
  const name = String(formData.get("name") || "");
  const version = String(formData.get("version") || "1.0.0");
  const code = String(formData.get("code") || "");
  if (!universeId || !code) return;
  // ensure game exists (auto-create if missing)
  let game = await prisma.game.findUnique({ where: { universeId: BigInt(universeId) } });
  if (!game) {
    const placeId = String(formData.get("placeId") || universeId);
    game = await prisma.game.create({ data: { name: name || `Game ${universeId.slice(0,6)}`, universeId: BigInt(universeId), placeId: BigInt(placeId), order: 99 } });
  }
  await prisma.script.create({ data: { gameId: game.id, name: name || game.name, version, code } });
  revalidatePath("/scripts");
  revalidatePath("/games");
}

export default async function ScriptsPage({ searchParams }: { searchParams: Promise<{ game?: string }> }) {
  const games = await getGames();
  const scripts = await prisma.script.findMany({ include: { game: true }, orderBy: { updatedAt: "desc" }, take: 50 }).catch(() => []);
  const sp = await searchParams;
  const preselect = sp?.game ? games.find(g => g.name === sp.game)?.universeId.toString() || "" : "";

  return (
    <div className="space-y-10">
      <div className="border-b border-[#1a1a1a] pb-6">
        <h1 className="text-4xl font-black tracking-tighter text-white">Scripts</h1>
        <p className="text-sm text-white/50 mt-2">Deploy and manage versioned Lua payloads without touching the loader.</p>
      </div>

      <form action={createScript} className="card p-8 space-y-6 relative overflow-hidden group">
        <div className="absolute top-0 left-0 w-1 h-full bg-white opacity-20 group-focus-within:opacity-100 transition-opacity" />
        
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-lg font-bold text-white tracking-tight">Deploy New Script</h2>
          <span className="text-[10px] uppercase tracking-widest font-bold text-white/40">Secure Upload</span>
        </div>
        
        <div className="grid md:grid-cols-3 gap-6">
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Target Universe</span>
            <div className="relative">
              <select name="universeId" defaultValue={preselect} required className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors appearance-none">
                <option value="">— select target —</option>
                {games.map(g => <option key={g.id} value={g.universeId.toString()}>{g.name} ({g.universeId.toString()})</option>)}
              </select>
              <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-white/40"><polyline points="6 9 12 15 18 9"></polyline></svg>
              </div>
            </div>
            <input name="placeId" placeholder="placeId (optional fallback)" className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-white transition-colors mt-2" />
          </label>
          
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Internal Name</span>
            <input name="name" placeholder="e.g. Core System v2" className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors placeholder:text-white/20" />
          </label>
          
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Version Tag</span>
            <input name="version" defaultValue="1.0.0" className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors mono" />
          </label>
        </div>
        
        <label className="space-y-2 block mt-6">
          <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Lua Payload</span>
          <textarea name="code" required rows={8} placeholder='print("Payload initialized")' className="w-full bg-[#050505] border border-[#222] hover:border-[#444] rounded-lg p-4 text-sm font-mono text-white/80 focus:outline-none focus:border-white focus:text-white transition-colors resize-y custom-scrollbar" />
        </label>
        
        <div className="flex items-center gap-4 pt-2">
          <button className="bg-white hover:bg-white/90 text-black font-bold px-8 py-3 rounded-lg transition-all shadow-[0_0_15px_rgba(255,255,255,0.1)] hover:shadow-[0_0_25px_rgba(255,255,255,0.25)] hover:scale-[1.02] flex items-center gap-2">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
            Deploy Payload
          </button>
          <span className="text-xs text-white/30 hidden sm:block">Automatically becomes active version for the loader.</span>
        </div>
      </form>

      <div className="card overflow-hidden">
        <div className="px-6 py-5 border-b border-[#1a1a1a] flex items-center justify-between bg-[#0a0a0a]">
          <h2 className="font-bold text-white tracking-tight">Deployment History</h2>
          <span className="text-[10px] font-bold tracking-widest uppercase mono text-white/40">{scripts.length} Records</span>
        </div>
        
        <div className="divide-y divide-[#1a1a1a]">
          {scripts.length === 0 ? (
             <div className="p-10 text-sm text-white/30 text-center font-medium">No scripts deployed yet.</div>
          ) : scripts.map(s => (
            <div key={s.id} className="p-6 flex flex-col md:flex-row gap-5 items-start hover:bg-[#0c0c0c] transition-colors group">
              <div className="w-14 h-14 rounded-xl bg-black border border-[#222] overflow-hidden flex-shrink-0 relative">
                <img src={`https://thumbnails.roblox.com/v1/games/icons?universeIds=${s.game.universeId.toString()}&size=128x128&format=Png`} alt="" className="w-full h-full object-cover filter grayscale group-hover:grayscale-0 transition-all duration-500" onError={(e)=>((e.target as HTMLImageElement).style.display='none')} />
                <div className="absolute inset-0 ring-1 ring-inset ring-white/10 rounded-xl" />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex flex-wrap items-center gap-3 mb-1">
                  <span className="font-bold text-base text-white">{s.game.name}</span>
                  <div className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#1a1a1a] text-white/70 mono border border-[#222]">
                    v{s.version}
                  </div>
                  <div className={`flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border ${s.isActive ? "bg-white text-black border-white shadow-[0_0_10px_rgba(255,255,255,0.3)]" : "bg-transparent text-white/30 border-[#222]"}`}>
                    {s.isActive && <div className="w-1.5 h-1.5 rounded-full bg-black animate-pulse" />}
                    {s.isActive ? "Active" : "Archived"}
                  </div>
                </div>
                
                <div className="text-xs text-white/40 flex items-center gap-3 mb-3">
                  <span className="mono">ID: {s.game.universeId.toString()}</span>
                  <span>•</span>
                  <span>{new Date(s.updatedAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}</span>
                </div>
                
                <div className="relative rounded-lg border border-[#222] bg-[#050505] overflow-hidden group-hover:border-[#333] transition-colors">
                  <div className="absolute top-0 left-0 w-full h-6 bg-gradient-to-b from-[#111] to-transparent pointer-events-none" />
                  <pre className="p-4 text-xs font-mono text-white/60 overflow-auto max-h-[120px] custom-scrollbar leading-relaxed">
                    {s.code}
                  </pre>
                </div>
              </div>
              
              <div className="text-right md:w-24 shrink-0 flex flex-col items-end gap-1 pt-1">
                <span className="text-[10px] text-white/30 font-bold uppercase tracking-widest">Executions</span>
                <span className="text-lg font-black mono text-white/80">{s.executionsCount.toLocaleString()}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
