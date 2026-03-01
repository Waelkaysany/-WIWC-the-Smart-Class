import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
  { time: '09:00', temp: 22, humidity: 45 },
  { time: '09:15', temp: 22.5, humidity: 46 },
  { time: '09:30', temp: 23, humidity: 48 },
  { time: '09:45', temp: 23.2, humidity: 47 },
  { time: '10:00', temp: 24, humidity: 50 },
  { time: '10:15', temp: 23.8, humidity: 49 },
  { time: '10:30', temp: 23.5, humidity: 48 },
];

export default function SensorChart() {
  return (
    <div className="glass-card p-6">
      <h3 className="text-xl font-bold mb-6 text-white">Environment Trends</h3>
      <div className="h-[340px]">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data}>
            <defs>
              <linearGradient id="colorTemp" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#6C63FF" stopOpacity={0.8} />
                <stop offset="95%" stopColor="#6C63FF" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorHum" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#00D4FF" stopOpacity={0.8} />
                <stop offset="95%" stopColor="#00D4FF" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
            <XAxis dataKey="time" stroke="#9ca3af" />
            <YAxis stroke="#9ca3af" />
            <Tooltip
              contentStyle={{ backgroundColor: '#12121f', borderColor: 'rgba(255,255,255,0.1)', color: '#fff' }}
              itemStyle={{ color: '#fff' }}
            />
            <Area type="monotone" dataKey="temp" stroke="#6C63FF" fillOpacity={1} fill="url(#colorTemp)" />
            <Area type="monotone" dataKey="humidity" stroke="#00D4FF" fillOpacity={1} fill="url(#colorHum)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
