"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Power, PowerOff, RotateCcw, Trash2, Copy, Check } from "lucide-react";

interface KeyRowProps {
  license: {
    id: string;
    key: string;
    note: string | null;
    hwid: string | null;
    expiresAt: string | null;
    maxExecutions: number | null;
    executionsUsed: number;
    isActive: boolean;
    lastUsedAt: string | null;
    createdAt: string;
    _count: { executions: number };
  };
}

export function KeyRow({ license }: KeyRowProps) {
  const router = useRouter();
  const [copied, setCopied] = useState(false);
  const [busy, setBusy] = useState(false);

  const copy = () => {
    navigator.clipboard.writeText(license.key);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const toggle = async () => {
    if (busy) return;
    setBusy(true);
    await fetch("/api/keys/action", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: license.id, action: "toggle" }),
    });
    setBusy(false);
    router.refresh();
  };

  const resetHwid = async () => {
    if (busy) return;
    setBusy(true);
    await fetch("/api/keys/action", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: license.id, action: "resetHwid" }),
    });
    setBusy(false);
    router.refresh();
  };

  const remove = async () => {
    if (!confirm(`Delete key ${license.key}?`)) return;
    if (busy) return;
    setBusy(true);
    await fetch(`/api/keys/action?id=${encodeURIComponent(license.id)}`, { method: "DELETE" });
    setBusy(false);
    router.refresh();
  };

  return (
    <tr className="border-b border-[#1B1B21] hover:bg-[#121216] transition-colors">
      <td className="py-3 px-4">
        <div className="flex items-center gap-2">
          <span className="mono font-semibold text-[#F4F4F5] text-[13px]">{license.key}</span>
          <button onClick={copy} className="text-[#62626C] hover:text-[#A7A7B0]" title="Copy key">
            {copied ? <Check className="w-3.5 h-3.5 text-[#46A758]" /> : <Copy className="w-3.5 h-3.5" />}
          </button>
        </div>
        {license.note && <div className="text-[12px] text-[#A7A7B0] mt-0.5">{license.note}</div>}
      </td>
      <td className="py-3 px-4">
        <span
          className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-[6px] text-[11.5px] font-medium ${
            license.isActive ? "bg-[#46A758]/10 text-[#46A758]" : "bg-[#E5484D]/10 text-[#E5484D]"
          }`}
        >
          <span className={`w-1.5 h-1.5 rounded-full ${license.isActive ? "bg-[#46A758]" : "bg-[#E5484D]"}`} />
          {license.isActive ? "Active" : "Revoked"}
        </span>
      </td>
      <td className="py-3 px-4 mono text-[12px] text-[#A7A7B0]">
        {license.hwid ? (
          <div className="flex items-center gap-1.5">
            <span title={license.hwid}>{license.hwid.slice(0, 12)}...</span>
            <button
              onClick={resetHwid}
              disabled={busy}
              className="text-[#62626C] hover:text-[#A7A7B0]"
              title="Reset bound HWID (allows key to bind to a new machine)"
            >
              <RotateCcw className="w-3 h-3" />
            </button>
          </div>
        ) : (
          <span className="text-[#62626C]">Unbound</span>
        )}
      </td>
      <td className="py-3 px-4 mono text-[12px] text-[#A7A7B0]">
        {license.executionsUsed}
        {license.maxExecutions ? ` / ${license.maxExecutions}` : " (inf)"}
      </td>
      <td className="py-3 px-4 text-[12px] text-[#62626C]">
        {license.expiresAt ? new Date(license.expiresAt).toLocaleDateString() : "Lifetime"}
      </td>
      <td className="py-3 px-4 text-right">
        <div className="inline-flex items-center gap-1">
          <button
            onClick={toggle}
            disabled={busy}
            className="p-1.5 rounded-[6px] hover:bg-[#1B1B21] text-[#A7A7B0] hover:text-white"
            title={license.isActive ? "Revoke key" : "Re-activate key"}
          >
            {license.isActive ? <PowerOff className="w-4 h-4" /> : <Power className="w-4 h-4" />}
          </button>
          <button
            onClick={remove}
            disabled={busy}
            className="p-1.5 rounded-[6px] hover:bg-[#E5484D]/10 text-[#62626C] hover:text-[#E5484D]"
            title="Delete key"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </td>
    </tr>
  );
}
