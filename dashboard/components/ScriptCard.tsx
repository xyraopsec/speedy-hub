"use client";

import { useState, useTransition, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Pencil, Trash2, Power, PowerOff, Save, X, Copy, Check, Shield, ShieldAlert, ShieldOff, RefreshCw } from "lucide-react";

type Script = {
  id: string;
  name: string;
  version: string;
  code: string;
  isActive: boolean;
  executionsCount: number;
  updatedAt: Date;
  obfuscationStatus?: string;
  obfuscationError?: string | null;
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
  const [copied, setCopied] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const deleteConfirmRef = useRef<HTMLDialogElement>(null);

  const lineCount = script.code.split("\n").length;

  useEffect(() => {
    if (editing && textareaRef.current) {
      textareaRef.current.focus();
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
      body: JSON.stringify({ id: script.id, action: "update", code: editCode, version: editVersion }),
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

  const handleObfuscate = async () => {
    showToast("Protecting… (spends 1 free request)");
    const res = await fetch("/api/obfuscate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: script.id }),
    });
    if (res.ok) {
      showToast("Protected");
    } else {
      const data = await res.json().catch(() => ({}));
      showToast(data.error || "Protection failed");
    }
    startTransition(() => router.refresh());
  };

  const obStatus = script.obfuscationStatus || "none";
  const obBadge =
    obStatus === "ready" ? (
      <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[#46A758]" title="Loader receives the obfuscated build">
        <Shield className="w-3.5 h-3.5" /> Protected
      </span>
    ) : obStatus === "processing" ? (
      <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[#A7A7B0]">
        <RefreshCw className="w-3.5 h-3.5 animate-spin" /> Protecting…
      </span>
    ) : obStatus === "failed" ? (
      <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[#f2555a]" title={script.obfuscationError || "Protection failed"}>
        <ShieldAlert className="w-3.5 h-3.5" /> Failed
      </span>
    ) : (
      <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[#62626C]" title={obStatus === "unconfigured" ? "Set MOONVEIL_KEY to enable protection" : "No protected build yet"}>
        <ShieldOff className="w-3.5 h-3.5" /> Unprotected
      </span>
    );

  return (
    <>
      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 bg-[#17171C] border border-[#2A2A31] text-[#F4F4F5] px-4 py-2.5 rounded-[8px] text-[13px] font-medium">
          {toast}
        </div>
      )}

      <div className="px-5 py-4 flex flex-col lg:flex-row gap-4">
        <img
          src={`/api/thumbnail?type=game&id=${script.game.universeId.toString()}&size=128x128`}
          alt=""
          className="w-14 h-14 rounded-[8px] object-cover border border-[#26262C] bg-[#0C0C0F] shrink-0"
        />

        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-x-2.5 gap-y-1.5">
            <span className="font-semibold text-[15px] text-[#F4F4F5]">{script.game.name}</span>
            {editing ? (
              <input
                value={editVersion}
                onChange={(e) => setEditVersion(e.target.value)}
                className="input mono !w-24 !py-1 !px-2 !text-[12px]"
                aria-label="Version"
              />
            ) : (
              <span className="chip mono text-[#A7A7B0]">v{script.version}</span>
            )}
            <button
              onClick={handleToggle}
              className={`inline-flex items-center gap-1.5 text-[12.5px] font-medium ${
                script.isActive ? "text-[#F4F4F5]" : "text-[#62626C] hover:text-[#A7A7B0]"
              }`}
              title={script.isActive ? "Click to deactivate" : "Click to activate"}
            >
              <span className={`w-1.5 h-1.5 rounded-full ${script.isActive ? "bg-[#E5484D]" : "bg-[#3A3A42]"}`} />
              {script.isActive ? "Active" : "Archived"}
            </button>
            {obBadge}
          </div>

          <div className="mono text-[11.5px] text-[#62626C] mt-1.5">
            {script.game.universeId.toString()} · {lineCount} lines ·{" "}
            {new Date(script.updatedAt).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" })}
          </div>

          {editing ? (
            <div className="mt-3 space-y-2.5">
              <textarea
                ref={textareaRef}
                value={editCode}
                onChange={(e) => setEditCode(e.target.value)}
                rows={12}
                spellCheck={false}
                className="input mono ops-code resize-y"
              />
              <div className="flex items-center gap-2">
                <button onClick={handleSave} className="btn-primary px-4 py-2 text-[13px] inline-flex items-center gap-2" disabled={isPending}>
                  <Save className="w-3.5 h-3.5" /> Save changes
                </button>
                <button
                  onClick={() => {
                    setEditing(false);
                    setEditCode(script.code);
                    setEditVersion(script.version);
                  }}
                  className="btn-ghost px-4 py-2 text-[13px] inline-flex items-center gap-2"
                >
                  <X className="w-3.5 h-3.5" /> Cancel
                </button>
              </div>
            </div>
          ) : (
            <div className="mt-3 rounded-[8px] border border-[#202027] bg-[#0C0C0F] overflow-hidden">
              <div className="flex items-center justify-between px-3.5 py-2 border-b border-[#1B1B21]">
                <span className="mono text-[11.5px] text-[#62626C]">
                  lua · {lineCount} lines
                </span>
                <button onClick={handleCopy} className="mono text-[11.5px] text-[#A7A7B0] hover:text-[#F4F4F5] inline-flex items-center gap-1.5">
                  {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                  {copied ? "Copied" : "Copy"}
                </button>
              </div>
              <pre className="ops-code p-3.5 text-[#A7A7B0] overflow-auto max-h-[160px]">{script.code}</pre>
            </div>
          )}
        </div>

        <div className="shrink-0 flex lg:flex-col items-center lg:items-end justify-between lg:justify-start gap-2.5 lg:w-[120px] lg:pt-0.5">
          <div className="lg:text-right">
            <div className="font-display font-semibold text-[22px] leading-none tabular-nums">
              {script.executionsCount.toLocaleString()}
            </div>
            <div className="mono text-[11px] text-[#62626C] mt-1">executions</div>
          </div>
          <div className="flex items-center gap-0.5">
            <button onClick={() => setEditing(true)} className="icon-btn" title="Edit script">
              <Pencil className="w-4 h-4" />
            </button>
            <button
              onClick={handleObfuscate}
              className="icon-btn"
              title="Re-run protection (spends 1 free request)"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
            <button onClick={handleToggle} className="icon-btn" title={script.isActive ? "Deactivate" : "Activate"}>
              {script.isActive ? <PowerOff className="w-4 h-4" /> : <Power className="w-4 h-4" />}
            </button>
            <button onClick={() => deleteConfirmRef.current?.showModal()} className="icon-btn danger" title="Delete script">
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      <dialog ref={deleteConfirmRef} className="bg-transparent p-0 max-w-md w-[calc(100%-2rem)]">
        <div className="panel p-6">
          <h3 className="font-display font-semibold text-[17px] text-[#F4F4F5]">Delete this script?</h3>
          <p className="text-[13.5px] text-[#A7A7B0] mt-2 leading-relaxed">
            <span className="text-[#F4F4F5] font-medium">{script.name}</span> (v{script.version}) for{" "}
            <span className="text-[#F4F4F5] font-medium">{script.game.name}</span> will be removed permanently,
            including its execution history.
          </p>
          <div className="flex items-center justify-end gap-2 mt-5">
            <button onClick={() => deleteConfirmRef.current?.close()} className="btn-ghost px-4 py-2 text-[13px]">
              Cancel
            </button>
            <button onClick={handleDelete} className="btn-primary px-4 py-2 text-[13px]">
              Delete
            </button>
          </div>
        </div>
      </dialog>
    </>
  );
}
