"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  ["Overview", "/"],
  ["Scripts", "/scripts"],
  ["Executions", "/executions"],
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
        className="md:hidden w-8 h-8 rounded-[8px] border border-[#26262C] flex items-center justify-center text-[#A7A7B0]"
        aria-label="Menu"
      >
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          {open ? (
            <>
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </>
          ) : (
            <>
              <line x1="3" y1="7" x2="21" y2="7" />
              <line x1="3" y1="12" x2="21" y2="12" />
              <line x1="3" y1="17" x2="21" y2="17" />
            </>
          )}
        </svg>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 bg-black/70 z-40 md:hidden" onClick={() => setOpen(false)} />
          <div className="fixed inset-y-0 left-0 w-[260px] bg-[#0C0C0F] border-r border-[#202027] z-50 md:hidden">
            <div className="h-16 flex items-center gap-2.5 px-5 border-b border-[#1B1B21]">
              <div className="w-7 h-7 rounded-[8px] bg-[#E5484D] flex items-center justify-center font-bold text-white text-[13px]">
                S
              </div>
              <div className="leading-none">
                <div className="font-semibold text-[15px] text-[#F4F4F5]">Speedy Hub</div>
                <div className="mono text-[11px] text-[#62626C] mt-1">script ops</div>
              </div>
            </div>
            <nav className="p-3">
              <div className="px-2 pb-2 text-[12px] font-medium text-[#62626C]">Workspace</div>
              <div className="space-y-0.5">
                {NAV.map(([label, href]) => (
                  <Link
                    key={label}
                    href={href}
                    className={`block px-2.5 py-2 rounded-[8px] text-[13.5px] ${
                      pathname === href
                        ? "bg-[#17171C] text-[#F4F4F5]"
                        : "text-[#A7A7B0]"
                    }`}
                  >
                    {label}
                  </Link>
                ))}
              </div>
            </nav>
          </div>
        </>
      )}
    </>
  );
}
