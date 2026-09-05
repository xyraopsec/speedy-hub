"use client";

import { useEffect, useState } from "react";

export default function GetKeyPage() {
  const [token, setToken] = useState<string | null>(null);
  const [step, setStep] = useState<number>(1);
  const [key, setKey] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [countdown, setCountdown] = useState<number>(0);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<boolean>(false);

  // Initialize or resume checkpoint session
  useEffect(() => {
    async function initSession() {
      try {
        const savedToken = localStorage.getItem("speedy_checkpoint_token");
        const url = savedToken ? `/api/checkpoint?token=${encodeURIComponent(savedToken)}` : `/api/checkpoint`;
        const res = await fetch(url);
        const data = await res.json();
        if (data.token) {
          setToken(data.token);
          localStorage.setItem("speedy_checkpoint_token", data.token);
          setStep(data.step || 1);
          if (data.key) setKey(data.key);
        }
      } catch {
        setError("Failed to start session. Please refresh.");
      } finally {
        setLoading(false);
      }
    }
    initSession();
  }, []);

  // Countdown timer for checkpoint progression
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const handleStartCheckpoint = (targetStep: number) => {
    // Starts an ad wait timer (10s) and allows completing the step
    setCountdown(10);
    setError(null);
  };

  const handleCompleteCheckpoint = async (completedStep: number) => {
    if (!token) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/checkpoint", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, stepCompleted: completedStep }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || "Failed to advance step");
      } else {
        setStep(data.step);
        if (data.key) {
          setKey(data.key);
        }
      }
    } catch {
      setError("Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleCopyKey = () => {
    if (!key) return;
    navigator.clipboard.writeText(key);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen bg-[#0d0d10] text-zinc-100 flex flex-col items-center justify-center p-4 selection:bg-red-500/30">
      {/* Background glowing gradients */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-red-600/15 blur-[120px] rounded-full" />
        <div className="absolute -bottom-40 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-orange-600/10 blur-[120px] rounded-full" />
      </div>

      <div className="relative w-full max-w-md bg-[#131317] border border-white/10 rounded-2xl p-6 sm:p-8 shadow-2xl backdrop-blur-xl">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-red-600 to-orange-500 flex items-center justify-center font-black text-white text-lg shadow-lg shadow-red-600/30">
            S
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white flex items-center gap-2">
              SPEEDY HUB <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-red-500/10 border border-red-500/20 text-red-400">Key System</span>
            </h1>
            <p className="text-xs text-zinc-400">Complete 2 short checkpoints to generate your 24h key</p>
          </div>
        </div>

        {/* Steps Progress */}
        <div className="grid grid-cols-3 gap-2 mb-8">
          {[
            { num: 1, label: "Checkpoint 1" },
            { num: 2, label: "Checkpoint 2" },
            { num: 3, label: "Access Key" },
          ].map((s) => {
            const isDone = step > s.num || (s.num === 3 && key);
            const isCurrent = step === s.num && !key;
            return (
              <div
                key={s.num}
                className={`p-2.5 rounded-xl border text-center transition-all ${
                  isDone
                    ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400"
                    : isCurrent
                    ? "bg-red-500/10 border-red-500/40 text-red-400 shadow-sm shadow-red-500/10"
                    : "bg-white/[0.02] border-white/5 text-zinc-600"
                }`}
              >
                <div className="text-[10px] font-mono uppercase font-bold tracking-wider mb-0.5">
                  Step {s.num}
                </div>
                <div className="text-xs font-semibold">{s.label}</div>
              </div>
            );
          })}
        </div>

        {/* Error Alert */}
        {error && (
          <div className="mb-6 p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-xs text-center font-medium">
            {error}
          </div>
        )}

        {/* Dynamic Card Content */}
        {loading ? (
          <div className="py-12 flex flex-col items-center justify-center gap-3">
            <div className="w-8 h-8 rounded-full border-2 border-red-500 border-t-transparent animate-spin" />
            <p className="text-xs text-zinc-400 font-mono">Connecting to key system...</p>
          </div>
        ) : key ? (
          /* Step 3: Key Vend Complete */
          <div className="space-y-6 text-center">
            <div className="w-12 h-12 rounded-full bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center mx-auto text-emerald-400 text-xl font-bold">
              ✓
            </div>
            <div>
              <h2 className="text-lg font-bold text-white mb-1">Your Key is Ready!</h2>
              <p className="text-xs text-zinc-400">Valid for 24 hours on your current machine.</p>
            </div>

            <div className="p-4 rounded-xl bg-black/40 border border-white/10 flex items-center justify-between font-mono text-sm tracking-wide text-zinc-200">
              <span className="truncate mr-2 select-all font-semibold">{key}</span>
              <button
                onClick={handleCopyKey}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all shrink-0 ${
                  copied
                    ? "bg-emerald-500 text-white"
                    : "bg-white/10 hover:bg-white/20 text-white"
                }`}
              >
                {copied ? "Copied!" : "Copy"}
              </button>
            </div>

            <div className="text-left text-xs text-zinc-400 space-y-1 bg-white/[0.02] p-3 rounded-lg border border-white/5 font-mono">
              <p className="text-zinc-300 font-semibold mb-1">How to use:</p>
              <p>1. Open Roblox and execute Speedy Hub</p>
              <p>2. Paste your key into the prompt and hit Verify</p>
              <p>3. Enjoy all games unlocked automatically!</p>
            </div>

            <button
              onClick={() => {
                localStorage.removeItem("speedy_checkpoint_token");
                window.location.reload();
              }}
              className="text-xs text-zinc-500 hover:text-zinc-300 transition-colors underline decoration-dotted"
            >
              Generate another key / Reset
            </button>
          </div>
        ) : (
          /* Checkpoint 1 & 2 Execution */
          <div className="space-y-6">
            <div className="text-center">
              <h2 className="text-base font-semibold text-white mb-1">
                {step === 1 ? "Checkpoint 1 of 2" : "Final Checkpoint"}
              </h2>
              <p className="text-xs text-zinc-400">
                {step === 1
                  ? "Click below to unlock the first checkpoint."
                  : "Almost there! Complete the final step to reveal your key."}
              </p>
            </div>

            <div className="p-4 rounded-xl bg-white/[0.02] border border-white/5 space-y-3">
              <div className="flex items-center justify-between text-xs">
                <span className="text-zinc-400">Required Action</span>
                <span className="font-semibold text-zinc-200">View Sponsored Page</span>
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
            ) : countdown === 0 && step <= 2 ? (
              <div className="space-y-2">
                <button
                  onClick={() => {
                    handleStartCheckpoint(step);
                  }}
                  className="w-full py-3.5 rounded-xl bg-red-600 hover:bg-red-500 active:scale-[0.98] text-white font-semibold text-sm shadow-lg shadow-red-600/25 transition-all"
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
            ) : null}
          </div>
        )}

        {/* Footer info */}
        <div className="mt-8 pt-6 border-t border-white/5 text-center">
          <p className="text-[11px] text-zinc-500">
            Need assistance or direct access?{" "}
            <a
              href="https://discord.gg/speedy"
              target="_blank"
              rel="noreferrer"
              className="text-red-400 hover:text-red-300 underline font-medium"
            >
              Join our Discord
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}
