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
    <div className="space-y-8">
      <div className="flex items-end justify-between">
        <div>
          <h1 className="text-[28px] font-black tracking-tight">Games</h1>
          <p className="text-sm text-white/50 mt-1">20 car & moto games • click thumbnail to manage scripts • black/white system</p>
        </div>
        <Link href="/scripts" className="bg-white text-black px-4 py-2 rounded-xl text-sm font-bold hover:bg-white/90 transition">+ Add Script</Link>
      </div>

      {games.length === 0 && (
        <div className="rounded-2xl border border-[#242428] bg-[#111113] p-4 text-sm text-white/60">
          No games in DB yet. <span className="text-white font-bold">Seed</span> will auto-create on first POST /api/scripts or run <code className="bg-black px-2 py-1 rounded">npx prisma db push</code> + seed. Showing 20 placeholder cards below.
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {(games.length ? list : await Promise.all(seed.map(async s => ({ ...s, thumbUrl: await thumbFor(s.universeId), _count: { scripts: 0, executions: 0 } })))).map((g: any) => (
          <div key={g.name} className="group rounded-[20px] overflow-hidden border border-[#242428] bg-[#111113] hover:bg-[#17171A] hover:border-white/15 transition">
            <div className="aspect-[16/10] bg-[#0A0A0C] relative overflow-hidden">
              {g.thumbUrl ? <img src={g.thumbUrl} alt={g.name} className="w-full h-full object-cover group-hover:scale-[1.03] transition duration-500" /> : <div className="w-full h-full grid place-items-center text-white/20 text-xs">no thumb</div>}
              <div className="absolute top-3 left-3 bg-black/70 backdrop-blur px-2 py-1 rounded-full text-[10px] tracking-widest font-bold">{g.universeId.slice(0, 8)}</div>
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />
              <div className="absolute bottom-3 left-3 right-3">
                <div className="text-sm font-black leading-none">{g.name}</div>
                <div className="text-[11px] text-white/60 mono">{g.placeId}</div>
              </div>
            </div>
            <div className="p-3 flex items-center justify-between text-xs">
              <span className="text-white/50 mono">{g._count?.scripts ?? 0} scripts • {g._count?.executions ?? 0} runs</span>
              <Link href={`/scripts?game=${encodeURIComponent(g.name)}`} className="bg-[#FF1A1A] text-white px-3 py-1.5 rounded-full font-bold text-xs hover:bg-[#E81818] transition">Add script</Link>
            </div>
          </div>
        ))}
      </div>

      <div className="rounded-2xl border border-dashed border-white/10 p-6 bg-black/20">
        <h3 className="font-bold">How to add a script (no code)</h3>
        <ol className="list-decimal ml-5 mt-2 text-sm text-white/60 space-y-1">
          <li>Click <b className="text-white">Add script</b> on a game card → you land on Scripts with game pre-selected</li>
          <li>Paste Lua, set version, Save → stored in <code className="bg-white/10 px-1 rounded">Script.code</code></li>
          <li>Loader auto fetches: <code className="bg-white/10 px-1 rounded">GET /api/scripts?universeId=GAMEID</code> — no Loader.lua edit needed</li>
          <li>Every execution auto logs to <code className="bg-white/10 px-1 rounded">/api/executions</code></li>
        </ol>
      </div>
    </div>
  );
}
