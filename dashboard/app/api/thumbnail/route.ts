import { NextRequest, NextResponse } from "next/server";
import { requireOwner, unauthorized } from "@/lib/require-owner";

const FALLBACK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="%23111"/><text x="75" y="78" text-anchor="middle" fill="%23444" font-family="sans-serif" font-size="14" font-weight="bold">No Image</text></svg>`;

const VALID_GAME_SIZES = ["420x420", "256x256", "150x150", "128x128"];
const VALID_USER_SIZES = ["150x150", "100x100", "60x60", "48x48", "30x30"];

function pickValidSize(requested: string, valid: string[]): string {
  if (valid.includes(requested)) return requested;
  const px = parseInt(requested);
  if (!isNaN(px)) {
    const closest = valid.reduce((prev, curr) =>
      Math.abs(parseInt(curr) - px) < Math.abs(parseInt(prev) - px) ? curr : prev
    );
    return closest;
  }
  return valid[0];
}

async function resolveUniverseId(placeId: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://apis.roblox.com/universes/v1/places/${placeId}/universe`,
      { next: { revalidate: 86400 } }
    );
    if (!res.ok) return null;
    const data = await res.json();
    return data.universeId ? String(data.universeId) : null;
  } catch {
    return null;
  }
}

async function fetchGameIcon(universeId: string, size: string): Promise<ArrayBuffer | null> {
  const validSize = pickValidSize(size, VALID_GAME_SIZES);
  try {
    const res = await fetch(
      `https://thumbnails.roblox.com/v1/games/icons?universeIds=${universeId}&size=${validSize}&format=Png`,
      { next: { revalidate: 600 } }
    );
    if (!res.ok) return null;
    const data = await res.json();
    const item = (data.data || [])[0];
    if (item?.state === "Completed" && item.imageUrl) {
      const imgRes = await fetch(item.imageUrl);
      if (imgRes.ok) return imgRes.arrayBuffer();
    }
    return null;
  } catch {
    return null;
  }
}

async function fetchUserAvatar(userId: string, size: string): Promise<ArrayBuffer | null> {
  const validSize = pickValidSize(size, VALID_USER_SIZES);
  try {
    const res = await fetch(
      `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${userId}&size=${validSize}&format=Png&isCircular=false`,
      { next: { revalidate: 600 } }
    );
    if (!res.ok) return null;
    const data = await res.json();
    const item = (data.data || [])[0];
    if (item?.state === "Completed" && item.imageUrl) {
      const imgRes = await fetch(item.imageUrl);
      if (imgRes.ok) return imgRes.arrayBuffer();
    }
    return null;
  } catch {
    return null;
  }
}

export async function GET(req: NextRequest) {
  if (!(await requireOwner())) return unauthorized();
  const type = req.nextUrl.searchParams.get("type") || "game";
  const id = req.nextUrl.searchParams.get("id");
  const size = req.nextUrl.searchParams.get("size") || "128x128";

  if (!id) {
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=86400" },
    });
  }

  let buf: ArrayBuffer | null = null;

  if (type === "user") {
    buf = await fetchUserAvatar(id, size);
  } else {
    buf = await fetchGameIcon(id, size);
    if (!buf) {
      const resolved = await resolveUniverseId(id);
      if (resolved) {
        buf = await fetchGameIcon(resolved, size);
      }
    }
  }

  if (buf) {
    return new NextResponse(buf, {
      headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=3600" },
    });
  }

  return new NextResponse(FALLBACK_SVG, {
    headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=300" },
  });
}
