import { prisma } from "@/lib/prisma";
import Link from "next/link";

export const dynamic = "force-dynamic";

async function thumbFor(universeId: string) {
  try {
    const r = await fetch(`https://thumbnails.roblox.com/v1/games/icons?universeIds=${universeId}&size=512x512&format=Png&isCircular=false`, { next: { revalidate: 86400 } });
    const j = await r.json();
    return j?.data?.[0]?.imageUrl || null;
  } catch { return null; }
}

export default async function GamesPage() {
  const games = await prisma.game.findMany({ orderBy: { order: "asc" }, include: { _count: { select: { scripts: true, executions: true } } } }).catch(() => []);
  // if empty, show seed placeholder from Loader.lua universeIds
  const seed = games.length === 0 ? [
    { name: "Driving Empire", universeId: "1202096104", placeId: "3357602286" },
    { name: "Greenville", universeId: "371263894", placeId: "891852901" },
    { name: "Southwest Florida", universeId: "1223555379", placeId: "1948063469" },
    { name: "Ultimate Driving", universeId: "5370313807", placeId: "5481977539" },
    { name: "Vehicle Simulator", universeId: "128894195", placeId: "1713919481" },
    { name: "Pacifico 2", universeId: "8710553023", placeId: "8710555530" },
    { name: "Midnight Racing: Tokyo", universeId: "142823291", placeId: "8668473321" },
    { name: "Car Crushers 2", universeId: "654732683", placeId: "654732683" },
    { name: "Vehicle Legends", universeId: "1480782352", placeId: "4566572536" },
    { name: "ER:LC", universeId: "2534724415", placeId: "2534724715" },
    { name: "Taxi Boss", universeId: "1047336831", placeId: "6690848885" },
    { name: "Drift Paradise", universeId: "13322300479", placeId: "13322300479" },
    { name: "Car Dealership Tycoon", universeId: "605887098", placeId: "1554960397" },
    { name: "Jailbreak", universeId: "606849621", placeId: "606849621" },
    { name: "A Dusty Trip", universeId: "5650396773", placeId: "16389395869" },
    { name: "Driving Simulator", universeId: "4646475446", placeId: "4727715908" },
    { name: "Automotive Tycoon", universeId: "3108293283", placeId: "3286570058" },
    { name: "Moto Trackday Project", universeId: "10570812351", placeId: "10570812351" },
    { name: "Motorcycle Mayhem", universeId: "891380602", placeId: "891380733" },
    { name: "Car Factory Tycoon", universeId: "2167018139", placeId: "2167018139" },
  ] : [];

  const list = games.length ? await Promise.all(games.map(async g => ({ ...g, thumbUrl: await thumbFor(g.universeId.toString()), universeId: g.universeId.toString(), placeId: g.placeId.toString() }))) : [];

  return (
    <div className="space-y-10">
      <div className="flex items-center justify-between border-b border-[#1a1a1a] pb-6">
        <div>
          <h1 className="text-4xl font-black tracking-tighter text-white">Games</h1>
          <p className="text-sm text-white/50 mt-2">Manage scripts across 20 monitored universes.</p>
        </div>
        <Link href="/scripts" className="bg-white text-black px-5 py-2.5 rounded-full text-sm font-bold hover:scale-105 transition-transform duration-200 shadow-[0_0_20px_rgba(255,255,255,0.15)] hover:shadow-[0_0_30px_rgba(255,255,255,0.3)] flex items-center gap-2">
          <span>Add Script</span>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
        </Link>
      </div>

      {games.length === 0 && (
        <div className="rounded-xl border border-dashed border-[#333] bg-[#0a0a0a] p-6 text-sm text-white/60 flex items-center justify-between">
          <span>No games in database. They will auto-create on first script upload.</span>
          <code className="bg-white/10 px-2 py-1 rounded text-xs mono text-white">npx prisma db push</code>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {(games.length ? list : await Promise.all(seed.map(async s => ({ ...s, thumbUrl: await thumbFor(s.universeId), _count: { scripts: 0, executions: 0 } })))).map((g: any) => (
          <div key={g.name} className="group rounded-[16px] overflow-hidden border border-[#1a1a1a] bg-[#040404] hover:border-[#333] transition-all duration-300 hover:shadow-[0_8px_30px_rgb(0,0,0,0.5)]">
            <div className="aspect-[16/10] bg-[#0a0a0a] relative overflow-hidden">
              {g.thumbUrl ? (
                <img src={g.thumbUrl} alt={g.name} className="w-full h-full object-cover group-hover:scale-105 group-hover:opacity-80 transition-all duration-500 filter grayscale group-hover:grayscale-0" />
              ) : (
                <div className="w-full h-full grid place-items-center text-white/20 text-xs">NO THUMB</div>
              )}
              <div className="absolute top-3 left-3 bg-black/60 backdrop-blur-md px-2.5 py-1 rounded-full text-[10px] tracking-widest font-bold text-white/90 border border-white/10">
                {g.universeId.slice(0, 8)}
              </div>
              <div className="absolute inset-0 bg-gradient-to-t from-[#040404] via-[#040404]/50 to-transparent" />
              <div className="absolute bottom-4 left-4 right-4">
                <div className="text-lg font-black leading-tight text-white">{g.name}</div>
                <div className="text-[10px] text-white/40 mono mt-1 tracking-wider uppercase">Place: {g.placeId}</div>
              </div>
            </div>
            
            <div className="p-4 flex items-center justify-between border-t border-[#1a1a1a] bg-[#080808] group-hover:bg-[#0c0c0c] transition-colors">
              <div className="flex flex-col gap-0.5">
                <span className="text-[10px] text-white/40 tracking-widest uppercase font-semibold">Stats</span>
                <span className="text-xs text-white/80 mono">{g._count?.scripts ?? 0} Scripts • {g._count?.executions ?? 0} Runs</span>
              </div>
              <Link href={`/scripts?game=${encodeURIComponent(g.name)}`} className="opacity-0 translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300 w-8 h-8 rounded-full bg-white text-black flex items-center justify-center hover:scale-110">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
              </Link>
            </div>
          </div>
        ))}
      </div>

      <div className="rounded-2xl border border-[#1a1a1a] p-8 bg-gradient-to-b from-[#0a0a0a] to-[#040404] relative overflow-hidden group">
        <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:opacity-20 transition-opacity">
           <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
        </div>
        
        <h3 className="text-xl font-black text-white tracking-tight mb-2">Automated Script Loading</h3>
        <p className="text-sm text-white/50 mb-6 max-w-2xl">No need to manually update your games. Upload your Lua code here and the loader will fetch the active version automatically.</p>
        
        <div className="grid md:grid-cols-3 gap-4">
          {[
            { step: "01", title: "Select Game", desc: "Choose a universe from the grid above and click the action button." },
            { step: "02", title: "Paste Code", desc: "Paste your Lua script, set a version number, and hit save." },
            { step: "03", title: "Auto-Fetch", desc: "Loader immediately receives the code via API without republishing." }
          ].map((item) => (
            <div key={item.step} className="p-4 rounded-xl bg-black border border-[#1a1a1a]">
              <div className="text-[10px] text-white/30 font-black tracking-widest mb-2">{item.step}</div>
              <div className="text-sm font-bold text-white mb-1">{item.title}</div>
              <div className="text-xs text-white/50 leading-relaxed">{item.desc}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
