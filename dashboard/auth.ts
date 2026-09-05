import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";

// OWNER_PASSWORD_HASH format: "saltHex:sha256Hex(salt + password)".
// Web Crypto only — no Node imports, so this file bundles for Edge (middleware).
function hexToBytes(hex: string): Uint8Array {
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return out;
}

function bytesToHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function slowEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  try {
    const [saltHex, expectedHex] = stored.split(":");
    if (!saltHex || !expectedHex) return false;
    const salt = hexToBytes(saltHex);
    const input = new TextEncoder().encode(
      String.fromCharCode(...salt) + ":" + password
    );
    const digest = await crypto.subtle.digest("SHA-256", input);
    return slowEqual(bytesToHex(digest), expectedHex.toLowerCase());
  } catch {
    return false;
  }
}

// Brute-force throttle: per-instance attempt ledger with lockout.
// (Best-effort on serverless — instances don't share memory. The 119-bit
// random password is what makes guessing infeasible; this stops casual bots.)
const attempts = new Map<string, { count: number; lockedUntil: number }>();

function clientIp(req: any): string {
  const fwd = req?.headers?.get?.("x-forwarded-for");
  if (typeof fwd === "string") return fwd.split(",")[0].trim();
  return "unknown";
}

async function fail(ip: string): Promise<null> {
  const rec = attempts.get(ip) || { count: 0, lockedUntil: 0 };
  rec.count += 1;
  if (rec.count >= 10) rec.lockedUntil = Date.now() + 60_000;
  attempts.set(ip, rec);
  // Progressive delay burns bot time even below the lockout threshold.
  await new Promise((r) => setTimeout(r, Math.min(2000, 200 * rec.count)));
  return null;
}

export const { handlers, auth, signIn, signOut } = NextAuth({
  trustHost: true,
  session: { strategy: "jwt", maxAge: 7 * 24 * 60 * 60 }, // 7 days
  pages: { signIn: "/login" },
  providers: [
    Credentials({
      name: "Owner",
      credentials: {
        username: { label: "Username", type: "text" },
        password: { label: "Password", type: "password" },
      },
      async authorize(credentials, request) {
        const ip = clientIp(request);
        const rec = attempts.get(ip);
        if (rec && rec.lockedUntil > Date.now()) return null;
        const username = String(credentials?.username || "");
        const password = String(credentials?.password || "");
        const wantUser = process.env.OWNER_USERNAME || "";
        const wantHash = process.env.OWNER_PASSWORD_HASH || "";
        if (!username || !password || !wantUser || !wantHash) return fail(ip);
        if (username !== wantUser) return fail(ip);
        if (!(await verifyPassword(password, wantHash))) return fail(ip);
        attempts.delete(ip);
        return { id: "owner", name: "Owner" };
      },
    }),
  ],
});
