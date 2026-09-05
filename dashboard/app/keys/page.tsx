import { prisma } from "@/lib/prisma";
import { revalidatePath } from "next/cache";
import { generateKey } from "@/lib/keys";
import { KeyRow } from "@/components/KeyRow";

export const dynamic = "force-dynamic";

async function createKey(formData: FormData) {
  "use server";
  const { auth } = await import("@/auth");
  const session = await auth().catch(() => null);
  if (!session?.user) return;

  const note = String(formData.get("note") || "").trim() || null;
  const daysStr = String(formData.get("days") || "").trim();
  const maxExecStr = String(formData.get("maxExecutions") || "").trim();
  const countStr = String(formData.get("count") || "1").trim();

  const count = Math.max(1, Math.min(50, parseInt(countStr, 10) || 1));
  const days = daysStr ? parseInt(daysStr, 10) : null;
  const maxExecutions = maxExecStr ? parseInt(maxExecStr, 10) : null;

  const expiresAt = days && days > 0 ? new Date(Date.now() + days * 86400 * 1000) : null;

  const entries = Array.from({ length: count }).map(() => ({
    key: generateKey(),
    note,
    expiresAt,
    maxExecutions,
  }));

  await prisma.licenseKey.createMany({ data: entries });
  revalidatePath("/keys");
}

export default async function KeysPage() {
  const keys = await prisma.licenseKey
    .findMany({
      orderBy: { createdAt: "desc" },
      take: 100,
      include: { _count: { select: { executions: true } } },
    })
    .catch(() => []);

  const total = keys.length;
  const active = keys.filter((k) => k.isActive).length;
  const bound = keys.filter((k) => k.hwid).length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display font-semibold text-[28px] leading-none text-[#F4F4F5]">License Keys</h1>
          <p className="text-[13.5px] text-[#A7A7B0] mt-2">
            Server-enforced access keys. Bound to HWID on first valid use.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="chip">
            <span className="text-[#62626C]">Total:</span> <span className="mono text-[#F4F4F5]">{total}</span>
          </div>
          <div className="chip">
            <span className="text-[#62626C]">Active:</span> <span className="mono text-[#46A758]">{active}</span>
          </div>
          <div className="chip">
            <span className="text-[#62626C]">Bound:</span> <span className="mono text-[#A7A7B0]">{bound}</span>
          </div>
        </div>
      </div>

      <form action={createKey} className="panel p-5 md:p-6">
        <h2 className="text-[13.5px] font-semibold text-[#F4F4F5]">Generate Keys</h2>
        <p className="text-[12.5px] text-[#62626C] mt-1 mb-4">
          Create one or multiple random 64-bit keys. Keys bind to executor machine on first run.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Note / Tag</span>
            <input name="note" placeholder="VIP user, giveaway, etc." className="input" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Duration (days)</span>
            <input name="days" placeholder="Blank = lifetime" className="input mono" type="number" min="1" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Max Executions</span>
            <input name="maxExecutions" placeholder="Blank = unlimited" className="input mono" type="number" min="1" />
          </label>
          <label className="block">
            <span className="block text-[12.5px] font-medium text-[#A7A7B0] mb-1.5">Quantity</span>
            <input name="count" defaultValue="1" className="input mono" type="number" min="1" max="50" />
          </label>
        </div>
        <div className="mt-4 flex justify-end">
          <button type="submit" className="btn btn-primary">
            Generate Key(s)
          </button>
        </div>
      </form>

      <div className="panel overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#202027] bg-[#0C0C0F] text-[12px] font-medium text-[#62626C]">
                <th className="py-3 px-4">Key</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Bound HWID</th>
                <th className="py-3 px-4">Executions</th>
                <th className="py-3 px-4">Expires</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {keys.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-[#62626C] text-[13px]">
                    No license keys generated yet.
                  </td>
                </tr>
              ) : (
                keys.map((k) => (
                  <KeyRow
                    key={k.id}
                    license={{
                      ...k,
                      expiresAt: k.expiresAt ? k.expiresAt.toISOString() : null,
                      lastUsedAt: k.lastUsedAt ? k.lastUsedAt.toISOString() : null,
                      createdAt: k.createdAt.toISOString(),
                    }}
                  />
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
