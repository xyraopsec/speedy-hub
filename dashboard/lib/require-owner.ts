import { auth } from "@/auth";
import { NextResponse } from "next/server";

// Second layer of defense: every sensitive handler calls this, so auth
// holds even if a request ever reaches the handler without middleware.
export async function requireOwner() {
  const session = await auth().catch(() => null);
  return !!session?.user;
}

export function unauthorized() {
  return NextResponse.json({ error: "unauthorized" }, { status: 401 });
}
