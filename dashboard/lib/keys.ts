import { prisma } from "@/lib/prisma";

export type KeyVerdict =
  | { ok: true; keyId: string }
  | { ok: false; reason: string };

// Single source of truth for key enforcement. Called by:
//  - POST /api/keys/validate  (loader key check)
//  - GET  /api/scripts        (payload gate — THE anti-bypass point)
// Rules: key must exist + active + unexpired + under execution cap +
// HWID must match once bound (first valid use binds it).
export async function validateKey(key: string, hwid: string | null): Promise<KeyVerdict> {
  const clean = String(key || "").trim();
  if (!clean) return { ok: false, reason: "no key provided" };

  const record = await prisma.licenseKey.findUnique({ where: { key: clean } });
  if (!record) return { ok: false, reason: "invalid key" };
  if (!record.isActive) return { ok: false, reason: "key revoked" };
  if (record.expiresAt && record.expiresAt.getTime() < Date.now()) {
    return { ok: false, reason: "key expired" };
  }
  if (record.maxExecutions != null && record.executionsUsed >= record.maxExecutions) {
    return { ok: false, reason: "execution limit reached" };
  }

  const normHwid = hwid && hwid.trim() !== "" ? hwid.trim().slice(0, 128) : null;
  if (record.hwid) {
    if (!normHwid || normHwid !== record.hwid) {
      return { ok: false, reason: "hwid mismatch — key is bound to another machine" };
    }
  } else if (normHwid) {
    // First valid use binds the key to this machine.
    await prisma.licenseKey.update({
      where: { id: record.id },
      data: { hwid: normHwid, lastUsedAt: new Date() },
    });
  }

  return { ok: true, keyId: record.id };
}

// 64-bit key material: SPEEDY-XXXX-XXXX-XXXX-XXXX
export function generateKey(): string {
  const bytes = new Uint8Array(8);
  crypto.getRandomValues(bytes);
  const hex = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
  return `SPEEDY-${hex.slice(0, 4)}-${hex.slice(4, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}`;
}

// Generates a session token for checkpoint progression
export function generateSessionToken(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Issues a 24-hour key upon completing checkpoints
export async function issueCheckpointKey(note: string = "Checkpoint Automated Key"): Promise<string> {
  const key = generateKey();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours
  await prisma.licenseKey.create({
    data: {
      key,
      note,
      expiresAt,
      maxExecutions: null,
    },
  });
  return key;
}
