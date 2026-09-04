import { NextRequest, NextResponse } from "next/server";

const FALLBACK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="%23111"/><text x="75" y="78" text-anchor="middle" fill="%23444" font-family="sans-serif" font-size="14" font-weight="bold">No Image</text></svg>`;

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
  try {
    const res = await fetch(
      `https://thumbnails.roblox.com/v1/games/icons?universeIds=${universeId}&size=${size}&format=Png`,
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
  const type = req.nextUrl.searchParams.get("type") || "game";
  const id = req.nextUrl.searchParams.get("id");
  const size = req.nextUrl.searchParams.get("size") || "128x128";

  if (!id) {
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=86400" },
    });
  }

  if (type === "user") {
    try {
      const res = await fetch(
        `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${id}&size=${size}&format=Png&isCircular=false`,
        { next: { revalidate: 600 } }
      );
      if (res.ok) {
        const data = await res.json();
        const item = (data.data || [])[0];
        if (item?.state === "Completed" && item.imageUrl) {
          const imgRes = await fetch(item.imageUrl);
          if (imgRes.ok) {
            const buf = await imgRes.arrayBuffer();
            return new NextResponse(buf, {
              headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=3600" },
            });
          }
        }
      }
    } catch {}
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=300" },
    });
  }

  // Game thumbnail — try as universeId first
  let buf = await fetchGameIcon(id, size);

  // If empty, resolve placeId → universeId
  if (!buf) {
    const resolved = await resolveUniverseId(id);
    if (resolved && resolved !== id) {
      buf = await fetchGameIcon(resolved, size);
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
