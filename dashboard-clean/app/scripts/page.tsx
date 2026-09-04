import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";
import { Terminal, UploadCloud, FileCode2, History } from "lucide-react";
import ScriptCard from "@/components/ScriptCard";

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
    try { universeId = BigInt(universeIdStr); } catch { return; }
    
    let game = await prisma.game.findUnique({ where: { universeId } });
    if (!game) {
      let placeIdStr = String(formData.get("placeId") || universeIdStr).trim();
      let placeId: bigint;
      try { placeId = BigInt(placeIdStr); } catch { placeId = universeId; }
      const gameName = name || `Universe ${universeIdStr.slice(0, 8)}`;
      game = await prisma.game.create({ data: { name: gameName, universeId, placeId, order: 99 } });
    }
    
    await prisma.script.create({ data: { gameId: game.id, name: name || game.name, version, code } });
    revalidatePath("/scripts");
  } catch (error) {
    console.error("Failed to create script:", error);
  }
}

export default async function ScriptsPage() {
  const scripts = await prisma.script.findMany({
    include: { game: true },
    orderBy: { updatedAt: "desc" },
    take: 50,
  }).catch(() => []);

  return (
    <div className="space-y-6 md:space-y-10 animate-fade-in">
      <div className="border-b border-[#1a1a1a] pb-6">
        <h1 className="text-3xl sm:text-4xl font-black tracking-tighter text-white">Scripts</h1>
        <p className="text-sm text-white/50 mt-2 flex items-center gap-2">
          <Terminal className="w-4 h-4 text-white/30" />
          Deploy, edit, and manage versioned Lua payloads from one place.
        </p>
      </div>

      <form action={createScript} className="card p-5 md:p-8 space-y-6 relative overflow-hidden group">
        <div className="absolute top-0 left-0 w-1 h-full bg-white opacity-20 group-focus-within:opacity-100 transition-opacity" />
        
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-white tracking-tight flex items-center gap-2">
            <UploadCloud className="w-5 h-5 text-white/50" />
            Deploy New Payload
          </h2>
          <span className="text-[10px] uppercase tracking-widest font-bold text-white/40 border border-[#333] px-2 py-1 rounded">Secure</span>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
          <label className="space-y-2 block">
            <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Target Universe ID</span>
            <input 
              name="universeId" 
              required 
              placeholder="e.g. 1202096104" 
              className="w-full bg-black border border-[#222] hover:border-[#444] rounded-lg px-4 py-3 text-sm text-white focus:outline-none focus:border-white transition-colors mono" 
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
        
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 pt-2">
          <button className="w-full sm:w-auto bg-white hover:bg-white/90 text-black font-bold px-8 py-3.5 rounded-lg transition-all shadow-[0_0_15px_rgba(255,255,255,0.1)] hover:shadow-[0_0_25px_rgba(255,255,255,0.25)] hover:scale-[1.02] flex items-center justify-center gap-2">
            <UploadCloud className="w-5 h-5" />
            Deploy Payload
          </button>
          <span className="text-xs text-white/40 hidden sm:block">Saves to database and sets as active version automatically.</span>
        </div>
      </form>

      <div className="card overflow-hidden">
        <div className="px-6 py-5 border-b border-[#1a1a1a] flex items-center justify-between bg-[#0a0a0a]">
          <h2 className="font-bold text-white tracking-tight flex items-center gap-2">
            <History className="w-4 h-4 text-white/50" />
            Deployed Scripts
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
            <ScriptCard key={s.id} script={JSON.parse(JSON.stringify(s, (key, value) => typeof value === "bigint" ? value.toString() : value))} />
          ))}
        </div>
      </div>
    </div>
  );
}
