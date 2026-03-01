import { motion } from 'framer-motion';
import { LayoutDashboard, Users, lightbulb, Settings, LogOut, Cpu, Activity } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { Link, useLocation } from 'react-router-dom';

const menuItems = [
  { icon: LayoutDashboard, label: 'Overview', path: '/' },
  { icon: Cpu, label: 'Devices', path: '/devices' },
  { icon: Users, label: 'Students', path: '/students' },
  { icon: Activity, label: 'Analytics', path: '/analytics' },
  { icon: Settings, label: 'Settings', path: '/settings' },
];

export default function Sidebar() {
  const { logout } = useAuth();
  const location = useLocation();

  return (
    <motion.div
      initial={{ x: -100, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      className="h-screen w-64 fixed left-0 top-0 glass border-r border-white/5 flex flex-col p-6 z-50"
    >
      <div className="flex items-center gap-3 mb-10">
        <div className="w-10 h-10 bg-primary/20 rounded-xl flex items-center justify-center border border-primary/30">
          <Activity className="text-primary w-6 h-6" />
        </div>
        <div>
          <h1 className="text-xl font-bold tracking-tight text-white">WIWC</h1>
          <p className="text-xs text-gray-400">Admin Console</p>
        </div>
      </div>

      <nav className="flex-1 space-y-2">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link key={item.path} to={item.path}>
              <div
                className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 group relative overflow-hidden ${isActive ? 'bg-primary/20 text-white' : 'text-gray-400 hover:bg-white/5 hover:text-white'
                  }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute inset-0 bg-primary/10 border-l-2 border-primary"
                  />
                )}
                <item.icon className={`w-5 h-5 ${isActive ? 'text-primary' : 'group-hover:text-white transition-colors'}`} />
                <span className="font-medium relative z-10">{item.label}</span>
              </div>
            </Link>
          );
        })}
      </nav>

      <div className="pt-6 border-t border-white/5">
        <button
          onClick={logout}
          className="flex items-center gap-3 px-4 py-3 text-gray-400 hover:text-error hover:bg-error/10 w-full rounded-xl transition-all"
        >
          <LogOut className="w-5 h-5" />
          <span className="font-medium">Sign Out</span>
        </button>
      </div>
    </motion.div>
  );
}
