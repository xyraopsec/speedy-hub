import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export default async function ExecutionsPage() {
  const rows = await prisma.execution
    .findMany({
      orderBy: { createdAt: "desc" },
      take: 100,
      include: { game: true, script: true },
    })
    .catch(() => []);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <h1 className="font-display font-semibold text-[28px] leading-none text-[#F4F4F5]">Executions</h1>
          <p className="text-[13.5px] text-[#A7A7B0] mt-2">
            {rows.length === 0
              ? "Every payload run from the loader lands here."
              : `Last ${rows.length} payload runs, newest first.`}
          </p>
        </div>
        <span className="mono text-[12px] text-[#62626C]">{rows.length} / 100 rows</span>
      </div>

      <div className="panel overflow-hidden">
        {rows.length === 0 ? (
          <div className="p-10 text-center">
            <div className="text-[13.5px] text-[#A7A7B0]">No executions yet.</div>
            <div className="text-[12.5px] text-[#62626C] mt-1">
              Runs appear here as soon as someone executes a payload from the loader.
            </div>
          </div>
        ) : (
          <>
            <div className="hidden md:block overflow-x-auto">
              <table className="ops-table w-full text-[13.5px]">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Game</th>
                    <th>User</th>
                    <th>Version</th>
                    <th>Executor</th>
                    <th style={{ textAlign: "right" }}>IP</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => {
                    const uid = r.userId || "";
                    return (
                      <tr key={r.id}>
                        <td className="mono text-[12px] text-[#A7A7B0] whitespace-nowrap">
                          {new Date(r.createdAt).toLocaleString(undefined, {
                            month: "short",
                            day: "numeric",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </td>
                        <td>
                          <div className="flex items-center gap-2.5 min-w-0">
                            <img
                              src={`/api/thumbnail?type=game&id=${r.game.universeId.toString()}&size=150x150`}
                              alt=""
                              className="w-8 h-8 rounded-[8px] object-cover border border-[#26262C] bg-[#0C0C0F] shrink-0"
                            />
                            <div className="min-w-0">
                              <div className="font-medium text-[#F4F4F5] truncate">{r.game.name}</div>
                              <div className="mono text-[11px] text-[#62626C]">{r.game.universeId.toString()}</div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div className="flex items-center gap-2.5 min-w-0">
                            {uid ? (
                              <img
                                src={`/api/thumbnail?type=user&id=${uid}&size=150x150`}
                                alt=""
                                className="w-7 h-7 rounded-full object-cover border border-[#26262C] bg-[#0C0C0F] shrink-0"
                              />
                            ) : (
                              <div className="w-7 h-7 rounded-full bg-[#0C0C0F] border border-[#26262C] flex items-center justify-center mono text-[10px] text-[#62626C] shrink-0">
                                —
                              </div>
                            )}
                            <div className="min-w-0">
                              <div className="text-[#EDEDEF] truncate">{r.username || "—"}</div>
                              {uid && <div className="mono text-[11px] text-[#62626C]">{uid}</div>}
                            </div>
                          </div>
                        </td>
                        <td>
                          <span className="chip mono text-[#A7A7B0]">v{r.script?.version || "—"}</span>
                        </td>
                        <td className="mono text-[12px] text-[#A7A7B0]">{r.executor || "—"}</td>
                        <td className="mono text-[12px] text-[#A7A7B0] text-right">{r.ip || "—"}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="md:hidden panel-divide">
              {rows.map((r) => {
                const uid = r.userId || "";
                return (
                  <div key={r.id} className="p-4">
                    <div className="flex items-center justify-between gap-3">
                      <div className="flex items-center gap-2.5 min-w-0">
                        <img
                          src={`/api/thumbnail?type=game&id=${r.game.universeId.toString()}&size=150x150`}
                          alt=""
                          className="w-9 h-9 rounded-[8px] object-cover border border-[#26262C] bg-[#0C0C0F] shrink-0"
                        />
                        <div className="min-w-0">
                          <div className="font-medium text-[13.5px] text-[#F4F4F5] truncate">{r.game.name}</div>
                          <div className="mono text-[11px] text-[#62626C]">
                            {new Date(r.createdAt).toLocaleString(undefined, {
                              month: "short",
                              day: "numeric",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </div>
                        </div>
                      </div>
                      <span className="chip mono text-[#A7A7B0] shrink-0">v{r.script?.version || "—"}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-2.5 ml-[46px] text-[12.5px] text-[#A7A7B0]">
                      <span className="truncate">{r.username || "—"}</span>
                      {r.executor && <span className="mono text-[11px] text-[#62626C] ml-auto shrink-0">{r.executor}</span>}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
