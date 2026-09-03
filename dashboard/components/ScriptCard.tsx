"use client";

import { useState, useTransition, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Pencil, Trash2, Power, PowerOff, Save, X, Copy, Check } from "lucide-react";

type Script = {
  id: string;
  name: string;
  version: string;
  code: string;
  isActive: boolean;
  executionsCount: number;
  updatedAt: Date;
  game: {
    id: string;
    name: string;
    universeId: bigint;
    placeId: bigint;
  };
};

export default function ScriptCard({ script }: { script: Script }) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [editing, setEditing] = useState(false);
  const [editCode, setEditCode] = useState(script.code);
  const [editVersion, setEditVersion] = useState(script.version);
  const [deleting, setDeleting] = useState(false);
  const [copied, setCopied] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const deleteConfirmRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    if (editing && textareaRef.current) {
      textareaRef.current.focus();
      textareaRef.current.setSelectionRange(0, 0);
    }
  }, [editing]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 2500);
  };

  const handleToggle = async () => {
    const res = await fetch("/api/scripts/action", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: script.id, action: "toggle" }),
    });
    if (res.ok) {
      showToast(script.isActive ? "Deactivated" : "Activated");
      startTransition(() => router.refresh());
    }
  };

  const handleDelete = async () => {
    const res = await fetch("/api/scripts/action", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: script.id }),
    });
    if (res.ok) {
      showToast("Script deleted");
      startTransition(() => router.refresh());
    }
    deleteConfirmRef.current?.close();
  };

  const handleSave = async () => {
    const res = await fetch("/api/scripts/action", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: script.id,
        action: "update",
        code: editCode,
        version: editVersion,
      }),
    });
    if (res.ok) {
      setEditing(false);
      showToast("Script updated");
      startTransition(() => router.refresh());
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(script.code);
    setCopied(true);
    showToast("Copied to clipboard");
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <>
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 bg-white text-black px-5 py-3 rounded-xl font-bold text-sm shadow-[0_0_30px_rgba(255,255,255,0.2)] animate-fade-in">
          {toast}
        </div>
      )}

      <div className="p-6 flex flex-col md:flex-row gap-5 items-start hover:bg-[#0c0c0c] transition-colors group">
        <div className="w-14 h-14 rounded-xl bg-black border border-[#222] overflow-hidden flex-shrink-0 relative shadow-md">
          <img
            src={`https://thumbnails.roblox.com/v1/games/icons?universeIds=${script.game.universeId.toString()}&size=128x128&format=Png`}
            alt=""
            className="w-full h-full object-cover filter grayscale group-hover:grayscale-0 transition-all duration-500"
          />
          <div className="absolute inset-0 ring-1 ring-inset ring-white/10 rounded-xl" />
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-3 mb-1.5">
            <span className="font-black text-lg text-white tracking-tight">{script.game.name}</span>

            {editing ? (
              <input
                value={editVersion}
                onChange={(e) => setEditVersion(e.target.value)}
                className="w-20 px-2 py-0.5 rounded text-[10px] font-bold bg-black text-white mono border border-[#444] focus:border-white focus:outline-none"
              />
            ) : (
              <div className="flex items-center gap-1.5 px-2 py-0.5 rounded text-[10px] font-bold bg-[#1a1a1a] text-white/70 mono border border-[#222]">
                v{script.version}
              </div>
            )}

            <div
              className={`flex items-center gap-1.5 px-2.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-widest border cursor-pointer select-none ${
                script.isActive
                  ? "bg-white text-black border-white shadow-[0_0_15px_rgba(255,255,255,0.4)]"
                  : "bg-transparent text-white/30 border-[#222] hover:border-[#444]"
              }`}
              onClick={handleToggle}
              title={script.isActive ? "Click to deactivate" : "Click to activate"}
            >
              {script.isActive && <div className="w-1.5 h-1.5 rounded-full bg-black animate-pulse" />}
              {script.isActive ? "Active" : "Archived"}
            </div>
          </div>

          <div className="text-[11px] text-white/40 flex items-center gap-3 mb-4 font-medium uppercase tracking-wider">
            <span className="mono">ID: {script.game.universeId.toString()}</span>
            <span className="text-[#333]">&bull;</span>
            <span>{new Date(script.updatedAt).toLocaleString(undefined, { dateStyle: "long", timeStyle: "short" })}</span>
          </div>

          {editing ? (
            <div className="space-y-3">
              <textarea
                ref={textareaRef}
                value={editCode}
                onChange={(e) => setEditCode(e.target.value)}
                rows={14}
                className="w-full bg-[#050505] border border-[#444] rounded-lg p-5 text-xs font-mono text-white/80 focus:outline-none focus:border-white focus:text-white transition-colors resize-y custom-scrollbar"
              />
              <div className="flex items-center gap-3">
                <button
                  onClick={handleSave}
                  className="bg-white hover:bg-white/90 text-black font-bold px-5 py-2 rounded-lg text-xs flex items-center gap-2 transition-all"
                >
                  <Save className="w-3.5 h-3.5" /> Save Changes
                </button>
                <button
                  onClick={() => { setEditing(false); setEditCode(script.code); setEditVersion(script.version); }}
                  className="text-white/40 hover:text-white text-xs font-bold px-4 py-2 rounded-lg border border-[#333] hover:border-[#555] transition-all flex items-center gap-2"
                >
                  <X className="w-3.5 h-3.5" /> Cancel
                </button>
              </div>
            </div>
          ) : (
            <div className="relative rounded-lg border border-[#222] bg-[#050505] overflow-hidden group-hover:border-[#333] transition-colors">
              <div className="absolute top-0 left-0 w-full h-6 bg-gradient-to-b from-[#111] to-transparent pointer-events-none z-10" />
              <pre className="p-5 text-xs font-mono text-white/50 overflow-auto max-h-[160px] custom-scrollbar leading-relaxed">
                {script.code}
              </pre>
            </div>
          )}
        </div>

        <div className="text-right md:w-40 shrink-0 flex flex-col items-end gap-3 pt-1">
          <div className="text-center">
            <span className="text-[10px] text-white/30 font-bold uppercase tracking-widest flex items-center gap-1.5 justify-center">
              Executions
            </span>
            <span className="text-2xl font-black mono text-white group-hover:scale-105 transition-transform origin-right drop-shadow-md block mt-1">
              {script.executionsCount.toLocaleString()}
            </span>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={handleCopy}
              className="w-8 h-8 rounded-lg bg-[#111] border border-[#222] hover:border-[#444] hover:bg-[#1a1a1a] transition-all flex items-center justify-center text-white/40 hover:text-white"
              title="Copy code"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-green-500" /> : <Copy className="w-3.5 h-3.5" />}
            </button>
            <button
              onClick={() => setEditing(true)}
              className="w-8 h-8 rounded-lg bg-[#111] border border-[#222] hover:border-[#444] hover:bg-[#1a1a1a] transition-all flex items-center justify-center text-white/40 hover:text-white"
              title="Edit script"
            >
              <Pencil className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={handleToggle}
              className="w-8 h-8 rounded-lg bg-[#111] border border-[#222] hover:border-[#444] hover:bg-[#1a1a1a] transition-all flex items-center justify-center text-white/40 hover:text-white"
              title={script.isActive ? "Deactivate" : "Activate"}
            >
              {script.isActive ? <PowerOff className="w-3.5 h-3.5" /> : <Power className="w-3.5 h-3.5" />}
            </button>
            <button
              onClick={() => deleteConfirmRef.current?.showModal()}
              className="w-8 h-8 rounded-lg bg-[#111] border border-[#222] hover:border-red-500/50 hover:bg-red-500/10 transition-all flex items-center justify-center text-white/40 hover:text-red-400"
              title="Delete script"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      <dialog
        ref={deleteConfirmRef}
        className="backdrop:bg-black/70 bg-transparent border border-[#333] rounded-2xl p-0 max-w-md w-full"
      >
        <div className="bg-[#111] rounded-2xl p-8 space-y-5">
          <div>
            <h3 className="text-lg font-black text-white">Delete Script</h3>
            <p className="text-sm text-white/50 mt-2">
              This will permanently remove <span className="text-white font-bold">{script.name}</span> (v{script.version}) for{" "}
              <span className="text-white font-bold">{script.game.name}</span>. This cannot be undone.
            </p>
          </div>
          <div className="flex items-center gap-3 justify-end">
            <button
              onClick={() => deleteConfirmRef.current?.close()}
              className="text-white/50 hover:text-white text-sm font-bold px-4 py-2.5 rounded-lg border border-[#333] hover:border-[#555] transition-all"
            >
              Cancel
            </button>
            <button
              onClick={handleDelete}
              className="bg-red-600 hover:bg-red-500 text-white font-bold px-5 py-2.5 rounded-lg text-sm transition-all shadow-[0_0_15px_rgba(239,68,68,0.2)]"
            >
              Delete Permanently
            </button>
          </div>
        </div>
      </dialog>
    </>
  );
}
