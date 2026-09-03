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

export default async function ScriptsPage({ searchParams }: { searchParams: { game?: string } }) {
  const games = await getGames();
  const scripts = await prisma.script.findMany({ include: { game: true }, orderBy: { updatedAt: "desc" }, take: 50 }).catch(() => []);
  const preselect = searchParams?.game ? games.find(g => g.name === searchParams.game)?.universeId.toString() || "" : "";

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-[28px] font-black tracking-tight">Scripts</h1>
        <p className="text-sm text-white/50">Add Lua per Game ID • versioned • loader fetches active one • no Loader.lua edit</p>
      </div>

      <form action={createScript} className="rounded-[20px] border border-[#242428] bg-[#111113] p-6 space-y-4">
        <div className="grid md:grid-cols-3 gap-4">
          <label className="space-y-2">
            <span className="text-xs tracking-widest text-white/40">GAME (universeId)</span>
            <select name="universeId" defaultValue={preselect} required className="w-full bg-black border border-[#242428] rounded-xl px-3 py-2.5 text-sm">
              <option value="">— select game —</option>
              {games.map(g => <option key={g.id} value={g.universeId.toString()}>{g.name} • {g.universeId.toString()}</option>)}
            </select>
            <input name="placeId" placeholder="placeId (optional, auto = universeId)" className="w-full bg-black border border-[#242428] rounded-xl px-3 py-2.5 text-sm mt-2" />
          </label>
          <label className="space-y-2">
            <span className="text-xs tracking-widest text-white/40">NAME</span>
            <input name="name" placeholder="Driving Empire v2" className="w-full bg-black border border-[#242428] rounded-xl px-3 py-2.5 text-sm" />
          </label>
          <label className="space-y-2">
            <span className="text-xs tracking-widest text-white/40">VERSION</span>
            <input name="version" defaultValue="1.0.0" className="w-full bg-black border border-[#242428] rounded-xl px-3 py-2.5 text-sm mono" />
          </label>
        </div>
        <label className="space-y-2 block">
          <span className="text-xs tracking-widest text-white/40">LUA CODE</span>
          <textarea name="code" required rows={10} placeholder='print("Speedy Hub")' className="w-full bg-black border border-[#242428] rounded-xl p-3 text-sm font-mono" />
        </label>
        <button className="bg-[#FF1A1A] hover:bg-[#E81818] text-white font-black px-6 py-2.5 rounded-xl transition">Save Script</button>
        <span className="text-xs text-white/30 ml-3">Saves to DB → Loader.lua GETs it automatically</span>
      </form>

      <div className="rounded-[20px] border border-[#242428] overflow-hidden">
        <div className="px-5 py-4 border-b border-[#242428] flex items-center justify-between">
          <h2 className="font-bold">Recent Scripts</h2>
          <span className="text-xs mono text-white/40">{scripts.length} total</span>
        </div>
        <div className="divide-y divide-[#242428]">
          {scripts.length === 0 ? <div className="p-6 text-sm text-white/40">No scripts yet. Paste one above.</div> : scripts.map(s => (
            <div key={s.id} className="p-4 flex gap-4 items-start">
              <img src={`https://thumbnails.roblox.com/v1/games/icons?universeIds=${s.game.universeId.toString()}&size=128x128&format=Png`} alt="" className="w-12 h-12 rounded-xl bg-[#0A0A0C] object-cover border border-[#242428]" onError={(e)=>((e.target as HTMLImageElement).style.display='none')} />
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-sm">{s.game.name}</span>
                  <span className="text-xs px-2 py-0.5 rounded-full bg-white text-black font-bold mono">{s.version}</span>
                  <span className={`text-[10px] px-2 py-1 rounded-full font-bold ${s.isActive ? "bg-[#FF1A1A] text-white" : "bg-white/10 text-white/50"}`}>{s.isActive ? "ACTIVE" : "OFF"}</span>
                </div>
                <div className="text-xs mono text-white/40">{s.game.universeId.toString()} • {new Date(s.updatedAt).toLocaleString()}</div>
                <pre className="mt-2 bg-black rounded-xl p-3 text-xs overflow-auto max-h-[120px] text-white/70">{s.code.slice(0, 600)}{s.code.length>600?"…":""}</pre>
              </div>
              <div className="text-right">
                <div className="text-xs mono text-white/60">{s.executionsCount} runs</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
