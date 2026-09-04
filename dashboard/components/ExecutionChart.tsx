"use client";

import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

type DataPoint = {
  name: string;
  executions: number;
};

const AXIS = "#62626C";
const GRID = "#1B1B21";

export default function ExecutionChart({ data }: { data: DataPoint[] }) {
  if (!data || data.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center text-[13px] text-[#62626C] border border-dashed border-[#2A2A31] rounded-[8px]">
        No execution data for this period.
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 8, right: 4, left: -8, bottom: 0 }}>
        <defs>
          <linearGradient id="execFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#F4F4F5" stopOpacity={0.14} />
            <stop offset="100%" stopColor="#F4F4F5" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid stroke={GRID} vertical={false} />
        <XAxis
          dataKey="name"
          stroke={GRID}
          fontSize={11}
          tickLine={false}
          axisLine={false}
          tick={{ fill: AXIS }}
          dy={6}
        />
        <YAxis
          stroke={GRID}
          fontSize={11}
          tickLine={false}
          axisLine={false}
          tick={{ fill: AXIS }}
          tickFormatter={(value) => `${value}`}
          allowDecimals={false}
          width={36}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: "#101014",
            borderColor: "#2A2A31",
            borderRadius: "8px",
            color: "#F4F4F5",
            fontSize: 12,
          }}
          itemStyle={{ color: "#F4F4F5" }}
          labelStyle={{ color: "#62626C" }}
          cursor={{ stroke: "#34343C", strokeWidth: 1 }}
        />
        <Area
          type="monotone"
          dataKey="executions"
          stroke="#EDEDEF"
          strokeWidth={1.5}
          fillOpacity={1}
          fill="url(#execFill)"
          isAnimationActive={false}
          dot={false}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
