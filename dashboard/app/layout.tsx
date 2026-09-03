import "./globals.css";
import { Inter } from "next/font/google";
import Link from "next/link";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata = { title: "Speedy Hub — Dashboard", description: "Manage 20 car & moto scripts, track executions", icons: { icon: "/favicon.svg" } };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} antialiased min-h-screen selection:bg-white selection:text-black`}>
        <div className="flex min-h-screen">
          {/* Sidebar */}
          <aside className="w-[240px] border-r border-[#1a1a1a] bg-black hidden md:flex flex-col sticky top-0 h-screen z-30">
            <div className="h-[72px] flex items-center gap-3 px-6 border-b border-[#1a1a1a]">
              <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center font-black text-black text-sm shadow-[0_0_15px_rgba(255,255,255,0.2)]">S</div>
              <div>
                <div className="font-black tracking-tight leading-none text-white">SPEEDY</div>
                <div className="text-[9px] tracking-[0.2em] text-white/40 mt-1 uppercase">HUB • DASHBOARD</div>
              </div>
            </div>
            
            <nav className="p-4 space-y-1.5 text-sm flex-1">
              {[
                ["Dashboard", "/"],
                ["Games (20)", "/games"],
                ["Scripts", "/scripts"],
                ["Executions", "/executions"],
                ["API Keys", "/keys"],
              ].map(([label, href]) => (
                <Link 
                  key={label} 
                  href={href} 
                  className="group flex items-center justify-between px-3 py-2.5 rounded-lg hover:bg-white/5 transition-all duration-300 text-white/60 hover:text-white"
                >
                  <span className="font-medium">{label}</span>
                  <div className="w-1.5 h-1.5 rounded-full bg-white opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                </Link>
              ))}
            </nav>
            
            <div className="p-5 border-t border-[#1a1a1a]">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Systems Online</span>
              </div>
              <div className="text-[10px] text-white/30 leading-relaxed uppercase tracking-wider">
                Black & White • Vercel
                <br />Prisma Postgres
              </div>
            </div>
          </aside>
          
          {/* Main Content */}
          <main className="flex-1 min-w-0 bg-[#040404]">
            <header className="h-[72px] border-b border-[#1a1a1a] glass-header sticky top-0 z-20 flex items-center justify-between px-8">
              <div className="flex items-center gap-3">
                <div className="text-xs font-medium text-white/40 hover:text-white/80 transition-colors cursor-pointer">discord.gg/speedy</div>
                <div className="w-1 h-1 rounded-full bg-white/20" />
                <div className="text-xs font-mono text-white/40">v3.8</div>
              </div>
              <div className="flex items-center gap-4">
                <button className="w-9 h-9 rounded-full bg-[#111] border border-[#222] hover:border-[#444] hover:bg-[#1a1a1a] transition-all flex items-center justify-center text-white/60 hover:text-white">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path><path d="M13.73 21a2 2 0 0 1-3.46 0"></path></svg>
                </button>
                <div className="w-9 h-9 rounded-full bg-white text-black flex items-center justify-center font-bold text-xs cursor-pointer shadow-[0_0_10px_rgba(255,255,255,0.15)] hover:shadow-[0_0_15px_rgba(255,255,255,0.3)] transition-shadow">AD</div>
              </div>
            </header>
            
            <div className="p-8 md:p-10 max-w-[1400px] mx-auto animate-fade-in">
              {children}
            </div>
          </main>
        </div>
      </body>
    </html>
  );
}
