import { NextResponse } from "next/server";
import { auth } from "@/auth";

// Loader-facing endpoints that executors call WITHOUT a session.
// Everything else requires the owner session.
//   Public:  GET  /api/games
//            GET  /api/scripts        (payload fetch; POST deploys -> locked)
//            POST /api/executions     (run logging; GET reads IPs -> locked)
//            POST /api/keys/validate  (key check; management stays locked)
//            /login, /get-key, /api/auth/*
//   Locked:  all other pages, thumbnails, every other API route + method.
function isPublic(pathname: string, method: string): boolean {
  if (pathname === "/login") return true;
  if (pathname === "/get-key") return true;
  if (pathname === "/checkpoint") return true;
  if (pathname.startsWith("/api/auth")) return true;
  if (pathname.startsWith("/api/checkpoint")) return true;
  if (method === "GET" && pathname === "/api/games") return true;
  if (method === "GET" && pathname === "/api/scripts") return true;
  if (method === "POST" && pathname === "/api/executions") return true;
  if (method === "POST" && pathname === "/api/keys/validate") return true;
  return false;
}

export default auth((req) => {
  const { pathname } = req.nextUrl;
  if (isPublic(pathname, req.method)) return NextResponse.next();
  if (req.auth) return NextResponse.next();

  // API consumers get JSON, browsers get the login page.
  if (pathname.startsWith("/api/")) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }
  const url = req.nextUrl.clone();
  url.pathname = "/login";
  url.searchParams.set("callbackUrl", pathname);
  return NextResponse.redirect(url);
});

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|favicon.svg).*)"],
};
