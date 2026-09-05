import "./globals.css";
import { Inter, Space_Grotesk, JetBrains_Mono } from "next/font/google";
import { MobileNav } from "@/components/MobileNav";
import { SideNav } from "@/components/SideNav";

const inter = Inter({ subsets: ["latin"], variable: "--font-sans" });
const display = Space_Grotesk({ subsets: ["latin"], weight: ["500", "600", "700"], variable: "--font-display" });
const mono = JetBrains_Mono({ subsets: ["latin"], weight: ["400", "500", "600"], variable: "--font-mono" });

export const metadata = {
  title: "Speedy Hub",
  description: "Script operations: deploy payloads, track executions.",
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} ${display.variable} ${mono.variable} antialiased min-h-screen`} style={{ fontFamily: "var(--font-sans)" }}>
        <div className="flex min-h-screen">
          {/* Sidebar */}
          <aside className="w-[248px] shrink-0 border-r border-[#202027] bg-[#0C0C0F] hidden md:flex flex-col sticky top-0 h-screen">
            <div className="h-16 flex items-center gap-2.5 px-5 border-b border-[#1B1B21]">
              <div className="w-7 h-7 rounded-[8px] bg-[#E5484D] flex items-center justify-center font-bold text-white text-[13px]" style={{ fontFamily: "var(--font-display)" }}>
                S
              </div>
              <div className="leading-none">
                <div className="font-display font-semibold text-[15px] text-[#F4F4F5]">Speedy Hub</div>
                <div className="mono text-[11px] text-[#62626C] mt-1">script ops</div>
              </div>
            </div>

            <nav className="p-3 flex-1">
              <div className="px-2 pb-2 text-[12px] font-medium text-[#62626C]">Workspace</div>
              <SideNav />
            </nav>

            <div className="p-5 border-t border-[#1B1B21]">
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#46A758]" />
                <span className="text-[12.5px] text-[#A7A7B0]">Backend connected</span>
              </div>
              <div className="mono text-[11px] text-[#62626C] mt-1.5">prisma postgres · vercel</div>
            </div>
          </aside>

          {/* Main */}
          <main className="flex-1 min-w-0">
            <header className="h-16 border-b border-[#1B1B21] bg-[#09090B] sticky top-0 z-20 flex items-center justify-between px-4 md:px-8">
              <div className="flex items-center gap-3 min-w-0">
                <MobileNav />
                <span className="mono text-[12px] text-[#62626C] truncate">speedy-hub / dashboard</span>
              </div>
              <div className="flex items-center gap-3">
                <span className="mono text-[12px] text-[#62626C] hidden sm:block">v4.0</span>
                <form
                  action={async () => {
                    "use server";
                    const { signOut } = await import("@/auth");
                    await signOut({ redirectTo: "/login" });
                  }}
                >
                  <button
                    type="submit"
                    title="Sign out"
                    className="w-8 h-8 rounded-[8px] border border-[#26262C] flex items-center justify-center text-[#A7A7B0] hover:text-white hover:bg-[#17171C] transition-colors"
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                      <polyline points="16 17 21 12 16 7" />
                      <line x1="21" y1="12" x2="9" y2="12" />
                    </svg>
                  </button>
                </form>
              </div>
            </header>

            <div className="px-4 md:px-8 py-6 md:py-8 max-w-[1200px] mx-auto">{children}</div>
          </main>
        </div>
      </body>
    </html>
  );
}
