import { motion } from 'framer-motion';

const colorMap = {
  primary: {
    bg: 'bg-primary/10',
    bgIcon: 'bg-primary/20',
    text: 'text-primary',
  },
  secondary: {
    bg: 'bg-secondary/10',
    bgIcon: 'bg-secondary/20',
    text: 'text-secondary',
  },
  accent: {
    bg: 'bg-accent/10',
    bgIcon: 'bg-accent/20',
    text: 'text-accent',
  },
  success: {
    bg: 'bg-success/10',
    bgIcon: 'bg-success/20',
    text: 'text-success',
  },
  warning: {
    bg: 'bg-warning/10',
    bgIcon: 'bg-warning/20',
    text: 'text-warning',
  },
  error: {
    bg: 'bg-error/10',
    bgIcon: 'bg-error/20',
    text: 'text-error',
  },
};

export default function StatsCard({ title, value, icon: Icon, color = 'primary', trend }) {
  const colors = colorMap[color] || colorMap.primary;

  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="glass-card p-6 relative overflow-hidden group"
    >
      <div className={`absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity ${colors.bg} rounded-bl-3xl`}>
        <Icon className={`w-24 h-24 ${colors.text}`} />
      </div>

      <div className="relative z-10">
        <div className="flex items-center gap-3 mb-2">
          <div className={`p-2 rounded-lg ${colors.bgIcon} ${colors.text}`}>
            <Icon className="w-5 h-5" />
          </div>
          <h3 className="text-gray-400 font-medium text-sm uppercase tracking-wider">{title}</h3>
        </div>

        <div className="flex items-baseline gap-2 mt-4">
          <h2 className="text-3xl font-bold font-sans text-white">{value}</h2>
          {trend && (
            <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${trend >= 0 ? 'bg-success/20 text-success' : 'bg-error/20 text-error'}`}>
              {trend > 0 ? '+' : ''}{trend}%
            </span>
          )}
        </div>
      </div>
    </motion.div>
  );
}
