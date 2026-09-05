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
      async authorize(credentials) {
        const username = String(credentials?.username || "");
        const password = String(credentials?.password || "");
        const wantUser = process.env.OWNER_USERNAME || "";
        const wantHash = process.env.OWNER_PASSWORD_HASH || "";
        if (!username || !password || !wantUser || !wantHash) return null;
        if (username !== wantUser) return null;
        if (!(await verifyPassword(password, wantHash))) return null;
        return { id: "owner", name: "Owner" };
      },
    }),
  ],
});
