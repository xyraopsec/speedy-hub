import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";
import { Terminal, UploadCloud, FileCode2, History, Activity } from "lucide-react";

export const dynamic = "force-dynamic";

async function createScript(formData: FormData) {
  "use server";
  try {
    const universeIdStr = String(formData.get("universeId") || "").trim();
    const name = String(formData.get("name") || "").trim();
    const version = String(formData.get("version") || "1.0.0").trim();
    const code = String(formData.get("code") || "").trim();
    
    if (!universeIdStr || !code) return;
    
    let universeId: bigint;
    try {
      universeId = BigInt(universeIdStr);
    } catch {
      return; // Invalid number
    }
    
    // ensure game exists (auto-create if missing)
    let game = await prisma.game.findUnique({ where: { universeId } });
    if (!game) {
      let placeIdStr = String(formData.get("placeId") || universeIdStr).trim();
      let placeId: bigint;
      try {
        placeId = BigInt(placeIdStr);
      } catch {
        placeId = universeId; // fallback
      }
      // Default name if none provided for a new game
      const gameName = name || `Universe ${universeIdStr.slice(0, 8)}`;
      game = await prisma.game.create({ 
        data: { 
          name: gameName, 
          universeId, 
          placeId, 
          order: 99 
        } 
      });
    }
    
    await prisma.script.create({ 
      data: { 
        gameId: game.id, 
        name: name || game.name, 
        version, 
        code 
      } 
    });
    
    revalidatePath("/scripts");
    revalidatePath("/games");
  } catch (error) {
    console.error("Failed to create script:", error);
  }
}

export default async function ScriptsPage() {
  const scripts = await prisma.script.findMany({ include: { game: true }, orderBy: { updatedAt: "desc" }, take: 50 }).catch(() => []);

  return (
    <div className="space-y-10 animate-fade-in">
      <div className="border-b border-[#1a1a1a] pb-6">
        <h1 className="text-4xl font-black tracking-tighter text-white">Scripts</h1>
        <p className="text-sm text-white/50 mt-2 flex items-center gap-2">
          <Terminal className="w-4 h-4 text-white/30" />
          Deploy and manage versioned Lua payloads without touching the loader.
        </p>
      </div>

      <form action={createScript} className="card p-8 space-y-6 relative overflow-hidden group">
        <div className="absolute top-0 left-0 w-1 h-full bg-white opacity-20 group-focus-within:opacity-100 transition-opacity" />
        
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-white tracking-tight flex items-center gap-2">
            <UploadCloud className="w-5 h-5 text-white/50" />
            Deploy New Payload
          </h2>
          <span className="text-[10px] uppercase tracking-widest font-bold text-white/40 border border-[#333] px-2 py-1 rounded">Secure</span>
        </div>
        
        <div className="grid md:grid-cols-3 gap-6">
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Target Universe ID</span>
            <input 
              name="universeId" 
              required 
              placeholder="e.g. 1202096104" 
              className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors mono" 
            />
            <input 
              name="placeId" 
              placeholder="Place ID (optional fallback)" 
              className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-2.5 text-sm text-white focus:outline-none focus:border-white transition-colors mono mt-2 hidden" 
            />
          </label>
          
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Internal Name</span>
            <input 
              name="name" 
              placeholder="e.g. Core System v2" 
              className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors placeholder:text-white/20" 
            />
          </label>
          
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Version Tag</span>
            <input 
              name="version" 
              defaultValue="1.0.0" 
              className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors mono" 
            />
          </label>
        </div>
        
        <label className="space-y-2 block mt-6">
          <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase flex items-center gap-1.5">
            <FileCode2 className="w-3.5 h-3.5" />
            Lua Payload Source
          </span>
          <textarea 
            name="code" 
            required 
            rows={10} 
            placeholder='print("Payload initialized")' 
            className="w-full bg-[#050505] border border-[#222] hover:border-[#444] rounded-lg p-5 text-sm font-mono text-white/80 focus:outline-none focus:border-white focus:text-white transition-colors resize-y custom-scrollbar" 
          />
        </label>
        
        <div className="flex items-center gap-4 pt-2">
          <button className="bg-white hover:bg-white/90 text-black font-bold px-8 py-3.5 rounded-lg transition-all shadow-[0_0_15px_rgba(255,255,255,0.1)] hover:shadow-[0_0_25px_rgba(255,255,255,0.25)] hover:scale-[1.02] flex items-center gap-2">
            <UploadCloud className="w-5 h-5" />
            Deploy Payload to Universe
          </button>
          <span className="text-xs text-white/40 hidden sm:block">Saves to database and sets as active version automatically.</span>
        </div>
      </form>

      <div className="card overflow-hidden">
        <div className="px-6 py-5 border-b border-[#1a1a1a] flex items-center justify-between bg-[#0a0a0a]">
          <h2 className="font-bold text-white tracking-tight flex items-center gap-2">
            <History className="w-4 h-4 text-white/50" />
            Deployment History
          </h2>
          <span className="text-[10px] font-bold tracking-widest uppercase mono text-white/40">{scripts.length} Records</span>
        </div>
        
        <div className="divide-y divide-[#1a1a1a]">
          {scripts.length === 0 ? (
             <div className="p-16 flex flex-col items-center justify-center text-center">
                <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4">
                  <Terminal className="w-6 h-6 text-white/30" />
                </div>
                <div className="text-sm font-bold text-white/60">No scripts deployed yet.</div>
                <div className="text-xs text-white/40 mt-1 max-w-xs">Use the form above to deploy your first Lua payload to a universe.</div>
             </div>
          ) : scripts.map(s => (
            <div key={s.id} className="p-6 flex flex-col md:flex-row gap-5 items-start hover:bg-[#0c0c0c] transition-colors group">
              <div className="w-14 h-14 rounded-xl bg-black border border-[#222] overflow-hidden flex-shrink-0 relative shadow-md">
                <img src={`https://thumbnails.roblox.com/v1/games/icons?universeIds=${s.game.universeId.toString()}&size=128x128&format=Png`} alt="" className="w-full h-full object-cover filter grayscale group-hover:grayscale-0 transition-all duration-500" />
                <div className="absolute inset-0 ring-1 ring-inset ring-white/10 rounded-xl" />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex flex-wrap items-center gap-3 mb-1.5">
                  <span className="font-black text-lg text-white tracking-tight">{s.game.name}</span>
                  <div className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#1a1a1a] text-white/70 mono border border-[#222]">
                    v{s.version}
                  </div>
                  <div className={`flex items-center gap-1.5 px-2.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-widest border ${s.isActive ? "bg-white text-black border-white shadow-[0_0_15px_rgba(255,255,255,0.4)]" : "bg-transparent text-white/30 border-[#222]"}`}>
                    {s.isActive && <div className="w-1.5 h-1.5 rounded-full bg-black animate-pulse" />}
                    {s.isActive ? "Active" : "Archived"}
                  </div>
                </div>
                
                <div className="text-[11px] text-white/40 flex items-center gap-3 mb-4 font-medium uppercase tracking-wider">
                  <span className="mono">ID: {s.game.universeId.toString()}</span>
                  <span className="text-[#333]">•</span>
                  <span>{new Date(s.updatedAt).toLocaleString(undefined, { dateStyle: 'long', timeStyle: 'short' })}</span>
                </div>
                
                <div className="relative rounded-lg border border-[#222] bg-[#050505] overflow-hidden group-hover:border-[#333] transition-colors">
                  <div className="absolute top-0 left-0 w-full h-6 bg-gradient-to-b from-[#111] to-transparent pointer-events-none z-10" />
                  <pre className="p-5 text-xs font-mono text-white/50 overflow-auto max-h-[160px] custom-scrollbar leading-relaxed">
                    {s.code}
                  </pre>
                </div>
              </div>
              
              <div className="text-right md:w-32 shrink-0 flex flex-col items-end gap-1 pt-1">
                <span className="text-[10px] text-white/30 font-bold uppercase tracking-widest flex items-center gap-1.5">
                  <Activity className="w-3 h-3" />
                  Executions
                </span>
                <span className="text-2xl font-black mono text-white group-hover:scale-105 transition-transform origin-right drop-shadow-md">{s.executionsCount.toLocaleString()}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
