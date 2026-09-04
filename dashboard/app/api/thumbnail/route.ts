import { NextRequest, NextResponse } from "next/server";

const FALLBACK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" viewBox="0 0 150 150"><rect width="150" height="150" fill="%23111"/><text x="75" y="78" text-anchor="middle" fill="%23444" font-family="sans-serif" font-size="14" font-weight="bold">No Image</text></svg>`;

// GET /api/thumbnail?type=game&id=123&size=128x128
// GET /api/thumbnail?type=user&id=123&size=150x150
export async function GET(req: NextRequest) {
  const type = req.nextUrl.searchParams.get("type") || "game";
  const id = req.nextUrl.searchParams.get("id");
  const size = req.nextUrl.searchParams.get("size") || "128x128";

  if (!id) {
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=86400" },
    });
  }

  try {
    let url: string;
    if (type === "user") {
      url = `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${id}&size=${size}&format=Png&isCircular=false`;
    } else {
      url = `https://thumbnails.roblox.com/v1/games/icons?universeIds=${id}&size=${size}&format=Png`;
    }

    const res = await fetch(url, { next: { revalidate: 600 } });
    if (!res.ok) throw new Error(`Roblox API ${res.status}`);

    const data = await res.json();
    const item = (data.data || [])[0];

    if (item?.state === "Completed" && item.imageUrl) {
      // Proxy the actual image to avoid CORS issues
      const imgRes = await fetch(item.imageUrl);
      if (imgRes.ok) {
        const buf = await imgRes.arrayBuffer();
        return new NextResponse(buf, {
          headers: {
            "Content-Type": "image/png",
            "Cache-Control": "public, max-age=3600",
          },
        });
      }
    }

    // Image not ready or unavailable
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=300" },
    });
  } catch {
    return new NextResponse(FALLBACK_SVG, {
      headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=300" },
    });
  }
}
