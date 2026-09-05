"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  ["Overview", "/"],
  ["Scripts", "/scripts"],
  ["Keys", "/keys"],
  ["Executions", "/executions"],
];

export function SideNav() {
  const pathname = usePathname();
  return (
    <div className="space-y-0.5">
      {NAV.map(([label, href]) => {
        const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
        return (
          <Link
            key={label}
            href={href}
            className={`flex items-center gap-2.5 px-2.5 py-2 rounded-[8px] text-[13.5px] transition-colors ${
              active ? "bg-[#17171C] text-[#F4F4F5]" : "text-[#A7A7B0] hover:bg-[#141419] hover:text-[#F4F4F5]"
            }`}
          >
            <span className={`w-[3px] h-4 rounded-full ${active ? "bg-[#E5484D]" : "bg-transparent"}`} />
            {label}
          </Link>
        );
      })}
    </div>
  );
}
