"use client";

import { Area, AreaChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

type DataPoint = {
  name: string;
  executions: number;
};

export default function ExecutionChart({ data }: { data: DataPoint[] }) {
  if (!data || data.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center text-sm text-white/30 border border-dashed border-white/10 rounded-xl">
        Awaiting execution data to generate chart.
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id="colorExecutions" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#ffffff" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#ffffff" stopOpacity={0} />
          </linearGradient>
        </defs>
        <XAxis 
          dataKey="name" 
          stroke="#333333" 
          fontSize={10} 
          tickLine={false} 
          axisLine={false}
          tick={{ fill: '#666666' }}
        />
        <YAxis 
          stroke="#333333" 
          fontSize={10} 
          tickLine={false} 
          axisLine={false}
          tick={{ fill: '#666666' }}
          tickFormatter={(value) => `${value}`}
        />
        <Tooltip
          contentStyle={{ backgroundColor: '#0a0a0a', borderColor: '#333333', borderRadius: '8px', color: '#ffffff' }}
          itemStyle={{ color: '#ffffff', fontWeight: 'bold' }}
          cursor={{ stroke: '#ffffff', strokeWidth: 1, strokeDasharray: '4 4', opacity: 0.2 }}
        />
        <Area 
          type="monotone" 
          dataKey="executions" 
          stroke="#ffffff" 
          strokeWidth={2}
          fillOpacity={1} 
          fill="url(#colorExecutions)" 
          animationDuration={1500}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
