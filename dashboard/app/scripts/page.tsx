import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";
import ScriptCard from "@/components/ScriptCard";

export const dynamic = "force-dynamic";

async function createScript(formData: FormData) {
  "use server";
  const { auth } = await import("@/auth");
  const session = await auth().catch(() => null);
  if (!session?.user) return;
  try {
    const universeIdStr = String(formData.get("universeId") || "").trim();
    const name = String(formData.get("name") || "").trim();
    const version = String(formData.get("version") || "1.0.0").trim();
    const code = String(formData.get("code") || "").trim();

    if (!universeIdStr || !code) return;

    let universeId: bigint;
    try {
      universeId = BigInt(universeIdStr);
    } catch {
      return;
    }

    let game = await prisma.game.findUnique({ where: { universeId } });
    if (!game) {
      const placeIdStr = String(formData.get("placeId") || universeIdStr).trim();
      let placeId: bigint;
      try {
        placeId = BigInt(placeIdStr);
      } catch {
        placeId = universeId;
      }
      const gameName = name || `Universe ${universeIdStr.slice(0, 8)}`;
      game = await prisma.game.create({ data: { name: gameName, universeId, placeId, order: 99 } });
    }

    const created = await prisma.script.create({ data: { gameId: game.id, name: name || game.name, version, code } });
    // Obfuscate on deploy (free MoonVeil API; spends 1 of 2 daily reqs).
    // Previous builds are kept on failure, so the loader never breaks.
    const { runObfuscation } = await import("@/lib/obfuscate");
    await runObfuscation(created.id, code).catch((e) => console.error("Obfuscation failed:", e));
    revalidatePath("/scripts");
  } catch (error) {
    console.error("Failed to create script:", error);
  }
}
export default async function ScriptsPage() {
  const scripts = await prisma.script
    .findMany({
      include: { game: true },
      orderBy: { updatedAt: "desc" },
      take: 50,
    })
    .catch(() => []);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display font-semibold text-[28px] leading-none text-[#F4F4F5]">Scripts</h1>
          <p className="text-[13.5px] text-[#A7A7B0] mt-2">
            {scripts.length === 0
              ? "No payloads yet. Deploy the first one below."
              : `${scripts.length} deployed payload${scripts.length === 1 ? "" : "s"}, newest first.`}
          </p>
        </div>
      </div>

      <form action={createScript} className="panel p-5 md:p-6">
        <h2 className="text-[13.5px] font-semibold text-[#F4F4F5]">Deploy payload</h2>
        <p className="text-[12.5px] text-[#62626C] mt-1 mb-5">
          Creates the game record if the universe ID is new, then saves this as the active version.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Universe ID *</span>
            <input name="universeId" required placeholder="1202096104" className="input mono" inputMode="numeric" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Place ID</span>
            <input name="placeId" placeholder="Same as universe" className="input mono" inputMode="numeric" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Name</span>
            <input name="name" placeholder="Core System" className="input" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Version</span>
            <input name="version" defaultValue="1.0.0" className="input mono" />
          </label>
        </div>

        <label className="block mt-3.5">
          <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Lua source *</span>
          <textarea
            name="code"
            required
            rows={10}
            placeholder={'print("Payload initialized")'}
            className="input mono ops-code resize-y"
            spellCheck={false}
          />
        </label>

        <div className="mt-4">
          <button className="btn-primary px-5 py-2.5 w-full sm:w-auto">Deploy payload</button>
        </div>
      </form>

      <div className="panel overflow-hidden">
        <div className="px-5 py-3.5 border-b border-[#1B1B21] flex items-center justify-between">
          <h2 className="text-[13.5px] font-semibold text-[#F4F4F5]">Deployed scripts</h2>
          <span className="mono text-[12px] text-[#62626C]">{scripts.length}</span>
        </div>

        <div className="panel-divide">
          {scripts.length === 0 ? (
            <div className="p-10 text-center">
              <div className="text-[13.5px] text-[#A7A7B0]">Nothing deployed.</div>
              <div className="text-[12.5px] text-[#62626C] mt-1">Fill in the form above to ship your first payload.</div>
            </div>
          ) : (
            scripts.map((s) => (
              <ScriptCard
                key={s.id}
                script={JSON.parse(
                  JSON.stringify(s, (key, value) => (typeof value === "bigint" ? value.toString() : value))
                )}
              />
            ))
          )}
        </div>
      </div>
    </div>
  );
}
