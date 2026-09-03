import { prisma } from "@/lib/prisma";
import Link from "next/link";
import { Plus, Gamepad2, Layers } from "lucide-react";

export const dynamic = "force-dynamic";

async function thumbFor(universeId: string) {
  try {
    const r = await fetch(`https://thumbnails.roblox.com/v1/games/icons?universeIds=${universeId}&size=512x512&format=Png&isCircular=false`, { next: { revalidate: 86400 } });
    const j = await r.json();
    return j?.data?.[0]?.imageUrl || null;
  } catch { return null; }
}

export default async function GamesPage() {
  const games = await prisma.game.findMany({ 
    orderBy: { order: "asc" }, 
    include: { _count: { select: { scripts: true, executions: true } } } 
  }).catch(() => []);

  const list = games.length ? await Promise.all(games.map(async g => ({ 
    ...g, 
    thumbUrl: await thumbFor(g.universeId.toString()), 
    universeId: g.universeId.toString(), 
    placeId: g.placeId.toString() 
  }))) : [];

  return (
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row md:items-end justify-between border-b border-[#1a1a1a] pb-6 gap-4">
        <div>
          <h1 className="text-4xl font-black tracking-tighter text-white">Games</h1>
          <p className="text-sm text-white/50 mt-2 flex items-center gap-2">
            <Gamepad2 className="w-4 h-4 text-white/30" />
            Manage scripts across your active universes.
          </p>
        </div>
        <Link href="/scripts" className="bg-white text-black px-6 py-3 rounded-xl text-sm font-bold hover:scale-105 transition-all duration-300 shadow-[0_0_20px_rgba(255,255,255,0.15)] hover:shadow-[0_0_30px_rgba(255,255,255,0.3)] flex items-center gap-2">
          <Plus className="w-5 h-5" />
          <span>Deploy Script</span>
        </Link>
      </div>

      {games.length === 0 && (
        <div className="rounded-3xl border border-dashed border-[#333] bg-gradient-to-b from-[#0a0a0a] to-[#040404] p-16 flex flex-col items-center justify-center text-center animate-fade-in">
          <div className="w-20 h-20 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-6 shadow-[0_0_30px_rgba(255,255,255,0.05)]">
            <Layers className="w-8 h-8 text-white/50" />
          </div>
          <h2 className="text-2xl font-black text-white tracking-tight mb-3">No Universes Tracked</h2>
          <p className="text-white/50 max-w-md mb-8 leading-relaxed">
            You haven't deployed any scripts yet. Games will automatically appear here once you deploy your first script using a Roblox Universe ID.
          </p>
          <Link href="/scripts" className="px-8 py-4 rounded-xl bg-white text-black font-bold flex items-center gap-2 hover:bg-white/90 transition-colors">
            <Plus className="w-5 h-5" />
            Deploy First Script
          </Link>
        </div>
      )}

      {games.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 animate-fade-in">
          {list.map((g: any) => (
            <div key={g.name} className="group rounded-2xl overflow-hidden border border-[#1a1a1a] bg-[#040404] hover:border-[#444] transition-all duration-300 hover:shadow-[0_8px_30px_rgb(0,0,0,0.5)]">
              <div className="aspect-[16/10] bg-[#0a0a0a] relative overflow-hidden">
                {g.thumbUrl ? (
                  <img src={g.thumbUrl} alt={g.name} className="w-full h-full object-cover group-hover:scale-105 group-hover:opacity-80 transition-all duration-700 filter grayscale group-hover:grayscale-0" />
                ) : (
                  <div className="w-full h-full grid place-items-center text-white/20 text-xs font-bold uppercase tracking-widest">No Thumb</div>
                )}
                <div className="absolute top-3 left-3 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-full text-[10px] tracking-widest font-bold text-white/90 border border-white/10 shadow-lg">
                  {g.universeId}
                </div>
                <div className="absolute inset-0 bg-gradient-to-t from-[#040404] via-[#040404]/50 to-transparent" />
                <div className="absolute bottom-4 left-4 right-4">
                  <div className="text-xl font-black leading-tight text-white drop-shadow-md">{g.name}</div>
                  <div className="text-[10px] text-white/50 mono mt-1.5 tracking-wider uppercase">Place ID: {g.placeId}</div>
                </div>
              </div>
              
              <div className="p-5 flex items-center justify-between border-t border-[#1a1a1a] bg-[#080808] group-hover:bg-[#0c0c0c] transition-colors">
                <div className="flex flex-col gap-1">
                  <span className="text-[10px] text-white/30 tracking-widest uppercase font-bold">Statistics</span>
                  <span className="text-sm text-white/80 font-medium">{g._count?.scripts ?? 0} Scripts • <span className="mono text-white/60">{g._count?.executions ?? 0} runs</span></span>
                </div>
                <Link href={`/scripts?game=${encodeURIComponent(g.name)}`} className="opacity-0 translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300 w-10 h-10 rounded-full bg-white text-black flex items-center justify-center hover:scale-110 shadow-[0_0_15px_rgba(255,255,255,0.2)]">
                  <Plus className="w-5 h-5" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
