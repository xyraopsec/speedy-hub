import { prisma } from "@/lib/prisma";

// Free MoonVeil API: POST https://moonveil.cc/api/v2/obf  { script, options }
// Bearer MOONVEIL_KEY. Success = text/plain obfuscated Luau.
// Free plan: 2 obfuscations/day — every deploy/update/retry spends one.

export type ObfOutcome =
  | { ok: true; code: string }
  | { ok: false; error: string; unconfigured?: boolean };

async function callMoonVeil(code: string, options: Record<string, unknown>): Promise<ObfOutcome> {
  const key = process.env.MOONVEIL_KEY;
  if (!key) return { ok: false, error: "MOONVEIL_KEY is not set", unconfigured: true };

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 55_000);
  try {
    const res = await fetch("https://moonveil.cc/api/v2/obf", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ script: code, options }),
      signal: ctrl.signal,
    });
    if (res.ok) {
      const out = await res.text();
      if (!out || out.length < 10) return { ok: false, error: "empty result from obfuscator" };
      return { ok: true, code: out };
    }
    let msg = `obfuscator responded ${res.status}`;
    try {
      const data = await res.json();
      if (data?.error) msg = String(data.error);
    } catch {
      /* keep default */
    }
    if (res.status === 429) msg += " (daily quota reached — retry tomorrow or upgrade)";
    return { ok: false, error: msg };
  } catch (e: any) {
    if (e?.name === "AbortError") return { ok: false, error: "obfuscation timed out after 55s" };
    return { ok: false, error: `obfuscator unreachable: ${e?.message || e}` };
  } finally {
    clearTimeout(timer);
  }
}

export async function obfuscateScript(code: string): Promise<ObfOutcome> {
  // Try VM mode first (stronger). Free plan allows the "skid" VM only —
  // on 403 fall back to defaults (still protected, just milder).
  const first = await callMoonVeil(code, { compileType: "vm", vmType: "skid" });
  if (first.ok) return first;
  if (!first.error.includes("403") && !first.error.toLowerCase().includes("forbidden")
    && !first.error.toLowerCase().includes("not allowed")) {
    return first;
  }
  return callMoonVeil(code, {});
}

// Runs obfuscation for a script row and persists the outcome.
// Previous obfuscatedCode is only overwritten on success, so the loader
// never loses its last good build to a failed job.
export async function runObfuscation(scriptId: string, code: string): Promise<ObfOutcome> {
  await prisma.script.update({
    where: { id: scriptId },
    data: { obfuscationStatus: "processing", obfuscationError: null },
  });
  const result = await obfuscateScript(code);
  if (result.ok) {
    await prisma.script.update({
      where: { id: scriptId },
      data: {
        obfuscatedCode: result.code,
        obfuscationStatus: "ready",
        obfuscationError: null,
        obfuscatedAt: new Date(),
      },
    });
  } else {
    await prisma.script.update({
      where: { id: scriptId },
      data: {
        obfuscationStatus: result.unconfigured ? "unconfigured" : "failed",
        obfuscationError: result.error,
      },
    });
  }
  return result;
}
