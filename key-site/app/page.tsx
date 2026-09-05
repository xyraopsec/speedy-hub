"use client";

import { useEffect, useState } from "react";

const BACKEND_API = process.env.NEXT_PUBLIC_API_URL || "https://dashboard-ten-peach-19.vercel.app";

export default function HomePage() {
  const [token, setToken] = useState<string | null>(null);
  const [step, setStep] = useState<number>(1);
  const [key, setKey] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [countdown, setCountdown] = useState<number>(0);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean>(false);

  useEffect(() => {
    async function initSession() {
      try {
        const savedToken = localStorage.getItem("speedy_standalone_token");
        const url = savedToken
          ? `${BACKEND_API}/api/checkpoint?token=${encodeURIComponent(savedToken)}`
          : `${BACKEND_API}/api/checkpoint`;

        const res = await fetch(url);
        const data = await res.json();
        if (data.token) {
          setToken(data.token);
          localStorage.setItem("speedy_standalone_token", data.token);
          setStep(data.step || 1);
          if (data.key) setKey(data.key);
        }
      } catch {
        setError("Unable to connect to key server. Please refresh.");
      } finally {
        setLoading(false);
      }
    }
    initSession();
  }, []);

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const handleStartCheckpoint = () => {
    setCountdown(10);
    setError(null);
  };

  const handleCompleteCheckpoint = async (completedStep: number) => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${BACKEND_API}/api/checkpoint`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, stepCompleted: completedStep }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Checkpoint verification failed.");
      } else {
        setStep(data.step);
        if (data.key) setKey(data.key);
      }
    } catch {
      setError("Network error communicating with key server.");
    } finally {
      setLoading(false);
    }
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
    <main className="min-h-screen flex flex-col items-center justify-center p-4 relative overflow-hidden bg-[#09090b]">
      {/* Background glow styling */}
      <div className="absolute -top-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-red-600/15 blur-[140px] rounded-full pointer-events-none" />
      <div className="absolute -bottom-32 left-1/2 -translate-x-1/2 w-[700px] h-[350px] bg-amber-600/10 blur-[140px] rounded-full pointer-events-none" />

      <div className="relative w-full max-w-lg bg-[#111115]/90 border border-white/10 rounded-2xl p-6 sm:p-8 shadow-2xl backdrop-blur-2xl">
        {/* Brand header */}
        <div className="flex items-center justify-between border-b border-white/5 pb-5 mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-red-600 via-red-500 to-orange-500 flex items-center justify-center font-black text-white text-lg shadow-lg shadow-red-600/30">
              S
            </div>
            <div>
              <h1 className="text-lg font-bold text-white tracking-tight flex items-center gap-2">
                SPEEDY HUB
                <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-red-500/10 border border-red-500/20 text-red-400">
                  Key Portal
                </span>
              </h1>
              <p className="text-xs text-zinc-400">Official 24-Hour Access Generator</p>
            </div>
          </div>
          <a
            href="https://discord.gg/speedy"
            target="_blank"
            rel="noreferrer"
            className="text-xs px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-zinc-300 border border-white/10 font-medium transition-all"
          >
            Discord
          </a>
        </div>

        {/* Checkpoint Indicators */}
        <div className="grid grid-cols-3 gap-2.5 mb-7">
          {[
            { num: 1, label: "Checkpoint 1" },
            { num: 2, label: "Checkpoint 2" },
            { num: 3, label: "Get Key" },
          ].map((s) => {
            const isDone = step > s.num || (s.num === 3 && key);
            const isCurrent = step === s.num && !key;
            return (
              <div
                key={s.num}
                className={`p-3 rounded-xl border text-center transition-all ${
                  isDone
                    ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400"
                    : isCurrent
                    ? "bg-red-500/10 border-red-500/40 text-red-400 shadow-md shadow-red-500/10"
                    : "bg-white/[0.02] border-white/5 text-zinc-600"
                }`}
              >
                <div className="text-[10px] font-mono font-bold uppercase tracking-wider mb-0.5">
                  Step 0{s.num}
                </div>
                <div className="text-xs font-semibold">{s.label}</div>
              </div>
            );
          })}
        </div>

        {/* Error Message */}
        {error && (
          <div className="mb-6 p-3.5 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs text-center font-medium">
            {error}
          </div>
        )}

        {/* Content area */}
        {loading ? (
          <div className="py-12 flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 rounded-full border-2 border-red-500 border-t-transparent animate-spin" />
            <p className="text-xs text-zinc-400 font-mono">Initializing key gateway...</p>
          </div>
        ) : key ? (
          /* Step 3: Vend Success */
          <div className="space-y-6 text-center">
            <div className="w-14 h-14 rounded-2xl bg-emerald-500/15 border border-emerald-500/30 flex items-center justify-center mx-auto text-emerald-400 text-2xl font-bold">
              ✓
            </div>
            <div>
              <h2 className="text-lg font-bold text-white mb-1">Your Key is Unlocked!</h2>
              <p className="text-xs text-zinc-400">
                Valid for 24 hours from now. Binds to your executor on first run.
              </p>
            </div>

            <div className="p-4 rounded-xl bg-black/50 border border-white/10 flex items-center justify-between font-mono text-sm tracking-wide text-zinc-100">
              <span className="truncate mr-3 select-all font-semibold text-red-400">{key}</span>
              <button
                onClick={handleCopyKey}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all shrink-0 ${
                  copied
                    ? "bg-emerald-500 text-white"
                    : "bg-red-600 hover:bg-red-500 text-white shadow-md shadow-red-600/30"
                }`}
              >
                {copied ? "Copied!" : "Copy"}
              </button>
            </div>

            <div className="text-left text-xs text-zinc-400 space-y-1.5 bg-white/[0.02] p-4 rounded-xl border border-white/5 font-mono">
              <p className="text-zinc-200 font-semibold">Instructions:</p>
              <p>1. Open Roblox and execute the Speedy Hub loader</p>
              <p>2. Paste your key into the key dialog</p>
              <p>3. Click Verify Key to unlock all scripts</p>
            </div>

            <button
              onClick={() => {
                localStorage.removeItem("speedy_standalone_token");
                window.location.reload();
              }}
              className="text-xs text-zinc-500 hover:text-zinc-300 transition-colors underline decoration-dotted"
            >
              Get another key / Reset
            </button>
          </div>
        ) : (
          /* Step 1 & 2 Checkpoints */
          <div className="space-y-6">
            <div className="text-center">
              <h2 className="text-base font-semibold text-white mb-1">
                {step === 1 ? "Checkpoint 1 of 2" : "Checkpoint 2 of 2"}
              </h2>
              <p className="text-xs text-zinc-400">
                {step === 1
                  ? "Click start to complete the initial sponsor checkpoint."
                  : "Final step! Complete this checkpoint to receive your license key."}
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white/[0.02] border border-white/5 space-y-3">
              <div className="flex items-center justify-between text-xs">
                <span className="text-zinc-400">Required Action</span>
                <span className="font-semibold text-zinc-200">Sponsor Verification</span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-zinc-400">Status</span>
                <span className={`font-mono font-semibold ${countdown > 0 ? "text-amber-400" : "text-zinc-500"}`}>
                  {countdown > 0 ? `Please wait (${countdown}s)` : "Ready"}
                </span>
              </div>
            </div>

            {countdown > 0 ? (
              <button
                disabled
                className="w-full py-3.5 rounded-xl bg-white/5 border border-white/10 text-zinc-400 font-semibold text-sm cursor-not-allowed flex items-center justify-center gap-2"
              >
                <div className="w-4 h-4 border-2 border-zinc-500 border-t-transparent rounded-full animate-spin" />
                Unlocking in {countdown}s...
              </button>
            ) : (
              <div className="space-y-2.5">
                <button
                  onClick={handleStartCheckpoint}
                  className="w-full py-3.5 rounded-xl bg-red-600 hover:bg-red-500 active:scale-[0.99] text-white font-semibold text-sm shadow-lg shadow-red-600/25 transition-all"
                >
                  Start Checkpoint {step}
                </button>
                <button
                  onClick={() => handleCompleteCheckpoint(step)}
                  className="w-full py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-zinc-300 text-xs font-medium border border-white/5 transition-all"
                >
                  I've completed this step &rarr;
                </button>
              </div>
            )}
          </div>
        )}

        <div className="mt-8 pt-5 border-t border-white/5 text-center">
          <p className="text-[11px] text-zinc-500">
            Speedy Hub &copy; 2026 &bull; Secure Key Access Portal
          </p>
        </div>
      </div>
    </main>
  );
}
