import { prisma } from "@/lib/prisma";
import { KeyRound, Plus, Trash2, Copy, Shield } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function KeysPage() {
  const keys = await prisma.apiKey.findMany({ orderBy: { createdAt: "desc" } }).catch(() => []);

  return (
    <div className="space-y-6 md:space-y-10 animate-fade-in">
      <div className="border-b border-[#1a1a1a] pb-6">
        <h1 className="text-3xl sm:text-4xl font-black tracking-tighter text-white">API Keys</h1>
        <p className="text-sm text-white/50 mt-2 flex items-center gap-2">
          <KeyRound className="w-4 h-4 text-white/30" />
          Manage external API access tokens for third-party integrations.
        </p>
      </div>

      <div className="card p-5 md:p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-white tracking-tight flex items-center gap-2">
            <Shield className="w-5 h-5 text-white/50" />
            Active Keys
          </h2>
          <span className="text-[10px] uppercase tracking-widest font-bold text-white/40 border border-[#333] px-2 py-1 rounded">
            {keys.length} Keys
          </span>
        </div>

        {keys.length === 0 ? (
          <div className="p-16 flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 rounded-full bg-white/5 border border-white/10 flex items-center justify-center mb-4">
              <KeyRound className="w-6 h-6 text-white/30" />
            </div>
            <div className="text-sm font-bold text-white/60">No API keys yet.</div>
            <div className="text-xs text-white/40 mt-1 max-w-xs">
              Create keys to authenticate external tools and services with the Speedy Hub backend.
            </div>
          </div>
        ) : (
          <div className="space-y-3">
            {keys.map((k) => (
              <div key={k.id} className="flex items-center justify-between p-4 rounded-lg bg-[#0a0a0a] border border-[#1a1a1a] hover:border-[#333] transition-colors group">
                <div className="flex items-center gap-3">
                  <KeyRound className="w-4 h-4 text-white/30" />
                  <div>
                    <div className="text-sm font-bold text-white/80">{k.name}</div>
                    <div className="text-xs text-white/30 mono mt-0.5">{k.key.slice(0, 8)}...{k.key.slice(-4)}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2 text-xs text-white/30">
                  {k.lastUsed && (
                    <span className="mono">Last used {new Date(k.lastUsed).toLocaleDateString()}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
