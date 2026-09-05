import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Speedy Hub — Get License Key",
  description: "Official key distribution system for Speedy Hub Roblox scripts.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className="bg-[#0b0b0e] min-h-screen text-zinc-100 antialiased selection:bg-red-500/30 selection:text-white">
        {children}
      </body>
    </html>
  );
}
