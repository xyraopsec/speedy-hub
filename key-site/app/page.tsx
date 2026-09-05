"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";

const BACKEND_API = process.env.NEXT_PUBLIC_API_URL || "https://dashboard-ten-peach-19.vercel.app";
const LINKVERTISE_URL = "https://link-target.net/9061250/yHHc0NYGlzEm";

function KeyPortalContent() {
  const searchParams = useSearchParams();
  const [token, setToken] = useState<string | null>(null);
  const [key, setKey] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [verifying, setVerifying] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean>(false);
  const [hasStarted, setHasStarted] = useState<boolean>(false);

  useEffect(() => {
    async function initSession() {
      try {
        const paramToken = searchParams.get("token");
        const paramPass = searchParams.get("pass");
        const savedToken = paramToken || localStorage.getItem("speedy_standalone_token");

        let url = `${BACKEND_API}/api/checkpoint`;
        if (savedToken) {
          url += `?token=${encodeURIComponent(savedToken)}`;
        }

        const res = await fetch(url);
        const data = await res.json();
        
        if (data.token) {
          setToken(data.token);
          localStorage.setItem("speedy_standalone_token", data.token);

          if (data.key) {
            setKey(data.key);
          } else if (paramPass) {
            // Returned automatically with completion passCode from Linkvertise!
            await autoClaimKey(data.token, paramPass);
          }
        }
      } catch {
        setError("Unable to connect to key server. Please refresh.");
      } finally {
        setLoading(false);
      }
    }
    initSession();
  }, [searchParams]);

  const autoClaimKey = async (sessionToken: string, passCode: string) => {
    setVerifying(true);
    setError(null);
    try {
      const res = await fetch(`${BACKEND_API}/api/checkpoint`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token: sessionToken, passCode }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Checkpoint verification failed.");
      } else if (data.key) {
        setKey(data.key);
      }
    } catch {
      setError("Network error validating checkpoint.");
    } finally {
      setVerifying(false);
    }
  };

  const handleStartCheckpoint = () => {
    setHasStarted(true);
    setError(null);
    window.open(LINKVERTISE_URL, "_blank");
  };

  const handleCopyKey = () => {
    if (!key) return;
    try {
      if (typeof navigator !== "undefined" && navigator?.clipboard?.writeText) {
        navigator.clipboard.writeText(key).catch(() => fallbackCopy(key));
      } else {
        fallbackCopy(key);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      fallbackCopy(key);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const fallbackCopy = (text: string) => {
    try {
      const el = document.createElement("textarea");
      el.value = text;
      el.setAttribute("readonly", "");
      el.style.position = "absolute";
      el.style.left = "-9999px";
      document.body.appendChild(el);
      el.select();
      document.execCommand("copy");
      document.body.removeChild(el);
    } catch (e) {
      console.error("Fallback copy failed", e);
    }
  };

  return (
    <main className="min-h-screen bg-[#09090b] text-zinc-100 flex flex-col items-center justify-center p-4 selection:bg-red-500/20 selection:text-white font-sans">
      <div className="w-full max-w-[420px] bg-[#121215] border border-zinc-800/80 rounded-xl p-6 shadow-xl">
        {/* Top Header */}
        <div className="flex items-center justify-between pb-5 mb-5 border-b border-zinc-800/70">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-red-600 flex items-center justify-center font-black text-white text-sm">
              S
            </div>
            <div>
              <div className="text-sm font-bold tracking-tight text-white leading-tight">Speedy Hub</div>
              <div className="text-[11px] text-zinc-500">Key Generation</div>
            </div>
          </div>
          <a
            href="https://discord.gg/speedy"
            target="_blank"
            rel="noreferrer"
            className="text-[11px] px-2.5 py-1 rounded-md bg-zinc-800 hover:bg-zinc-700 text-zinc-300 font-medium transition-colors border border-zinc-700/50"
          >
            Discord
          </a>
        </div>

        {/* Errors */}
        {error && (
          <div className="mb-4 p-3 rounded-lg bg-red-950/40 border border-red-800/50 text-red-400 text-xs text-center font-medium">
            {error}
          </div>
        )}

        {/* Body states */}
        {loading || verifying ? (
          <div className="py-12 flex flex-col items-center justify-center gap-3">
            <div className="w-5 h-5 border-2 border-zinc-600 border-t-red-500 rounded-full animate-spin" />
            <span className="text-xs text-zinc-400 font-mono">
              {verifying ? "Verifying completion pass..." : "Connecting..."}
            </span>
          </div>
        ) : key ? (
          <div className="space-y-4">
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-emerald-500/10 text-emerald-400 text-sm mb-2 font-bold border border-emerald-500/20">
                ✓
              </div>
              <h2 className="text-sm font-semibold text-white">Key Unlocked</h2>
              <p className="text-xs text-zinc-400 mt-0.5">Valid for 24 hours. Binds to your executor on launch.</p>
            </div>

            <div className="p-3 rounded-lg bg-black/60 border border-zinc-800 flex items-center justify-between gap-2 font-mono text-xs">
              <span className="text-red-400 font-medium truncate select-all">{key}</span>
              <button
                onClick={handleCopyKey}
                className={`px-3 py-1 rounded text-xs font-semibold shrink-0 transition-colors ${
                  copied
                    ? "bg-emerald-600 text-white"
                    : "bg-zinc-800 hover:bg-zinc-700 text-zinc-200 border border-zinc-700"
                }`}
              >
                {copied ? "Copied" : "Copy"}
              </button>
            </div>

            <div className="pt-2 text-center">
              <button
                onClick={() => {
                  localStorage.removeItem("speedy_standalone_token");
                  window.location.href = window.location.pathname;
                }}
                className="text-[11px] text-zinc-500 hover:text-zinc-400 transition-colors"
              >
                Get another key
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <h2 className="text-sm font-semibold text-white">Complete Sponsor Checkpoint</h2>
              <p className="text-xs text-zinc-400 mt-1 leading-relaxed">
                Click below to complete the checkpoint on Linkvertise. When finished, you will be given your completion pass to unlock your 24-hour key.
              </p>
            </div>

            <div className="p-3 rounded-lg bg-zinc-900/50 border border-zinc-800/80 space-y-2 text-xs">
              <div className="flex justify-between items-center text-zinc-400">
                <span>Checkpoint</span>
                <span className="font-mono text-zinc-200">1 of 1</span>
              </div>
              <div className="flex justify-between items-center text-zinc-400">
                <span>Duration</span>
                <span className="text-zinc-200 font-medium">24 Hours</span>
              </div>
            </div>

            <button
              onClick={handleStartCheckpoint}
              className="w-full py-2.5 px-4 rounded-lg bg-red-600 hover:bg-red-500 active:scale-[0.99] text-white text-xs font-semibold transition-all shadow-sm"
            >
              {hasStarted ? "Reopen Checkpoint" : "Start Checkpoint"}
            </button>

            {hasStarted && (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  const form = e.currentTarget;
                  const input = form.elements.namedItem("passCode") as HTMLInputElement;
                  if (input && token) {
                    autoClaimKey(token, input.value);
                  }
                }}
                className="pt-2 space-y-2 border-t border-zinc-800/60"
              >
                <div className="text-[11px] text-zinc-400">
                  Enter the verification code shown at the end of the checkpoint:
                </div>
                <div className="flex gap-2">
                  <input
                    name="passCode"
                    type="text"
                    required
                    placeholder="Enter Code (e.g. A1B2C3D4E5)"
                    className="flex-1 bg-black/40 border border-zinc-800 rounded-lg px-3 py-1.5 text-xs text-white uppercase font-mono placeholder:text-zinc-600 focus:outline-none focus:border-red-500"
                  />
                  <button
                    type="submit"
                    className="px-3 py-1.5 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-200 text-xs font-medium border border-zinc-700 transition-colors"
                  >
                    Claim
                  </button>
                </div>
              </form>
            )}
          </div>
        )}

        <div className="mt-5 pt-4 border-t border-zinc-900 text-center">
          <span className="text-[10px] text-zinc-600 font-mono">Speedy Hub • Secure Key Gateway</span>
        </div>
      </div>
    </main>
  );
}

export default function HomePage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-[#09090b] flex items-center justify-center">
          <div className="w-5 h-5 border-2 border-zinc-600 border-t-red-500 rounded-full animate-spin" />
        </div>
      }
    >
      <KeyPortalContent />
    </Suspense>
  );
}
