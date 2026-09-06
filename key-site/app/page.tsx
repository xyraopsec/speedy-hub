"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";

const BACKEND_API = process.env.NEXT_PUBLIC_API_URL || "https://dashboard-ten-peach-19.vercel.app";

function KeyPortal() {
  const searchParams = useSearchParams();
  const [key, setKey] = useState<string | null>(null);
  const [checkpointUrl, setCheckpointUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const urlKey = searchParams.get("key");
    const urlError = searchParams.get("error");

    if (urlKey) {
      setKey(urlKey);
      localStorage.setItem("speedy_unlocked_key", urlKey);
      setLoading(false);
      return;
    }

    if (urlError) {
      setError(
        urlError === "invalid_signature"
          ? "Verification failed: security signature mismatched."
          : "Session expired or invalid. Please try again."
      );
    }

    const saved = localStorage.getItem("speedy_unlocked_key");
    if (saved) {
      setKey(saved);
      setLoading(false);
      return;
    }

    // Fetch dynamic checkpoint URL
    async function loadCheckpoint() {
      try {
        const res = await fetch(`${BACKEND_API}/api/checkpoint`);
        const data = await res.json();
        if (data.key) {
          setKey(data.key);
          localStorage.setItem("speedy_unlocked_key", data.key);
        } else if (data.checkpointUrl) {
          setCheckpointUrl(data.checkpointUrl);
        }
      } catch {
        setError("Could not connect to the key server.");
      } finally {
        setLoading(false);
      }
    }

    loadCheckpoint();
  }, [searchParams]);

  const copyKey = () => {
    if (!key) return;
    try {
      if (navigator?.clipboard?.writeText) {
        navigator.clipboard.writeText(key);
      } else {
        const input = document.createElement("textarea");
        input.value = key;
        document.body.appendChild(input);
        input.select();
        document.execCommand("copy");
        document.body.removeChild(input);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      // Fallback
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    }
  };

  return (
    <main className="min-h-screen bg-[#070709] text-zinc-300 font-mono flex flex-col justify-between p-6 antialiased">
      {/* Top bar */}
      <header className="flex items-center justify-between max-w-lg w-full mx-auto text-xs border-b border-zinc-900 pb-4">
        <div className="flex items-center gap-2 text-zinc-100 font-semibold tracking-wide">
          <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          SPEEDY HUB
        </div>
        <a
          href="https://discord.gg/q5En862zuM"
          target="_blank"
          rel="noreferrer"
          className="text-zinc-500 hover:text-zinc-300 transition-colors"
        >
          discord / support ↗
        </a>
      </header>

      {/* Main card */}
      <div className="max-w-lg w-full mx-auto my-auto py-8">
        <div className="border border-zinc-800/80 bg-[#0d0d11] p-6 sm:p-8 rounded-lg shadow-2xl space-y-6">
          <div className="space-y-1">
            <h1 className="text-base font-semibold text-white tracking-tight">Access Gateway</h1>
            <p className="text-xs text-zinc-500 leading-relaxed">
              Generate a 24-hour hardware-bound license key for Speedy Hub.
            </p>
          </div>

          {error && (
            <div className="p-3 rounded bg-red-950/30 border border-red-900/50 text-red-400 text-xs">
              {error}
            </div>
          )}

          {loading ? (
            <div className="py-8 flex flex-col items-center justify-center gap-2 text-zinc-500 text-xs">
              <div className="w-4 h-4 border border-zinc-600 border-t-red-500 rounded-full animate-spin"></div>
              <span>Connecting gateway...</span>
            </div>
          ) : key ? (
            /* State: Key Unlocked */
            <div className="space-y-4">
              <div className="p-4 rounded bg-emerald-950/20 border border-emerald-900/40 text-emerald-400 text-xs flex items-center justify-between">
                <span>Checkpoint passed. 24h key generated.</span>
                <span className="font-semibold text-[10px] uppercase tracking-wider bg-emerald-500/20 px-2 py-0.5 rounded">Active</span>
              </div>

              <div className="space-y-2">
                <label className="text-[11px] text-zinc-500 uppercase tracking-wider">Your License Key</label>
                <div className="flex items-center gap-2">
                  <input
                    readOnly
                    value={key}
                    className="flex-1 bg-black/60 border border-zinc-800 rounded px-3 py-2 text-xs text-white font-mono select-all focus:outline-none"
                  />
                  <button
                    onClick={copyKey}
                    className={`px-4 py-2 rounded text-xs font-semibold transition-all ${
                      copied
                        ? "bg-emerald-600 text-white"
                        : "bg-red-600 hover:bg-red-500 text-white"
                    }`}
                  >
                    {copied ? "Copied" : "Copy"}
                  </button>
                </div>
              </div>

              <div className="text-[11px] text-zinc-500 space-y-1 pt-2 border-t border-zinc-900">
                <p>1. Open Roblox and execute Speedy Hub.</p>
                <p>2. Paste key into the prompt and click Verify.</p>
              </div>
            </div>
          ) : (
            /* State: Start Checkpoint */
            <div className="space-y-5">
              <div className="border border-zinc-800/60 bg-black/40 rounded p-4 text-xs space-y-2">
                <div className="flex justify-between text-zinc-400">
                  <span>Step</span>
                  <span className="text-zinc-200">1 of 1</span>
                </div>
                <div className="flex justify-between text-zinc-400">
                  <span>Provider</span>
                  <span className="text-zinc-200">Linkvertise</span>
                </div>
                <div className="flex justify-between text-zinc-400">
                  <span>Access Duration</span>
                  <span className="text-zinc-200">24 Hours</span>
                </div>
              </div>

              <a
                href={checkpointUrl || "#"}
                className={`w-full block text-center py-2.5 rounded text-xs font-semibold transition-all ${
                  checkpointUrl
                    ? "bg-red-600 hover:bg-red-500 text-white cursor-pointer"
                    : "bg-zinc-800 text-zinc-500 cursor-not-allowed"
                }`}
              >
                Proceed to Checkpoint ↗
              </a>

              <p className="text-[11px] text-zinc-600 text-center leading-relaxed">
                Complete the brief sponsor task on Linkvertise. Upon completion, Linkvertise automatically returns you here with your unlocked key.
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <footer className="max-w-lg w-full mx-auto text-[11px] text-zinc-600 flex justify-between border-t border-zinc-900 pt-4">
        <span>speedy-hub / v4.0</span>
        <span>secure key authorization</span>
      </footer>
    </main>
  );
}

export default function Page() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-[#070709] flex items-center justify-center">
          <div className="w-4 h-4 border border-zinc-600 border-t-red-500 rounded-full animate-spin"></div>
        </div>
      }
    >
      <KeyPortal />
    </Suspense>
  );
}
