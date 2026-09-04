"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  ["Dashboard", "/"],
  ["Scripts", "/scripts"],
  ["Executions", "/executions"],
  ["API Keys", "/keys"],
];

export function MobileNav() {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  return (
    <>
      <button
        onClick={() => setOpen(!open)}
        className="md:hidden w-9 h-9 rounded-lg bg-[#111] border border-[#222] flex items-center justify-center text-white/60 hover:text-white hover:border-[#444] transition-all"
        aria-label="Menu"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          {open ? (
            <>
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </>
          ) : (
            <>
              <line x1="3" y1="12" x2="21" y2="12" />
              <line x1="3" y1="6" x2="21" y2="6" />
              <line x1="3" y1="18" x2="21" y2="18" />
            </>
          )}
        </svg>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-40 md:hidden" onClick={() => setOpen(false)} />
          <div className="fixed inset-y-0 left-0 w-[260px] bg-black border-r border-[#1a1a1a] z-50 md:hidden animate-fade-in">
            <div className="h-[60px] flex items-center gap-3 px-6 border-b border-[#1a1a1a]">
              <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center font-black text-black text-sm shadow-[0_0_15px_rgba(255,255,255,0.2)]">S</div>
              <div>
                <div className="font-black tracking-tight leading-none text-white">SPEEDY</div>
                <div className="text-[9px] tracking-[0.2em] text-white/40 mt-1 uppercase">HUB • DASHBOARD</div>
              </div>
            </div>
            <nav className="p-4 space-y-1.5">
              {NAV.map(([label, href]) => (
                <Link
                  key={label}
                  href={href}
                  className={`flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 ${
                    pathname === href
                      ? "bg-white/10 text-white"
                      : "text-white/60 hover:bg-white/5 hover:text-white"
                  }`}
                >
                  {label}
                </Link>
              ))}
            </nav>
            <div className="absolute bottom-0 left-0 right-0 p-5 border-t border-[#1a1a1a]">
              <div className="flex items-center gap-2 mb-3">
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                <span className="text-[10px] font-bold tracking-widest text-white/50 uppercase">Systems Online</span>
              </div>
              <div className="text-[10px] text-white/30 leading-relaxed uppercase tracking-wider">
                Black & White • Vercel
                <br />Prisma Postgres
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
}
