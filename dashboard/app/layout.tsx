import "./globals.css";
import { Inter } from "next/font/google";
const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata = { title: "Speedy Hub — Dashboard", description: "Manage 20 car & moto scripts, track executions" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} antialiased bg-[#08080A] text-white min-h-screen`}>
        <div className="flex min-h-screen">
          <aside className="w-[240px] border-r border-[#242428] bg-[#0A0A0C] hidden md:flex flex-col sticky top-0 h-screen">
            <div className="h-[64px] flex items-center gap-3 px-6 border-b border-[#242428]">
              <div className="w-8 h-8 rounded-lg bg-[#FF1A1A] flex items-center justify-center font-black text-sm">S</div>
              <div><div className="font-black tracking-tight leading-none">SPEEDY</div><div className="text-[10px] tracking-[0.18em] text-white/50">HUB • DASHBOARD</div></div>
            </div>
            <nav className="p-3 space-y-1 text-sm">
              {[
                ["Dashboard", "/"],
                ["Games (20)", "/games"],
                ["Scripts", "/scripts"],
                ["Executions", "/executions"],
                ["API Keys", "/keys"],
              ].map(([label, href]) => (
                <a key={label} href={href} className="flex items-center px-3 py-2 rounded-lg hover:bg-white/[0.06] transition text-white/80 hover:text-white">{label}</a>
              ))}
            </nav>
            <div className="mt-auto p-4 border-t border-[#242428] text-xs text-white/40">Black & White • Vercel • Prisma Postgres</div>
          </aside>
          <main className="flex-1 min-w-0">
            <header className="h-[64px] border-b border-[#242428] bg-[#08080A]/80 backdrop-blur sticky top-0 z-20 flex items-center justify-between px-6">
              <div className="text-sm text-white/60">discord.gg/speedy • v3.8</div>
              <div className="w-8 h-8 rounded-full bg-white text-black grid place-items-center font-bold text-xs">AD</div>
            </header>
            <div className="p-6 md:p-8 max-w-[1280px] mx-auto">{children}</div>
          </main>
        </div>
      </body>
    </html>
  );
}
