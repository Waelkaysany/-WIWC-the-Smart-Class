import { NavLink, useNavigate } from 'react-router-dom';
import { useSuperAdmin } from '../../context/SuperAdminContext';
import { motion } from 'framer-motion';
import {
  LayoutDashboard,
  Users,
  MessageSquareWarning,
  LogOut,
  Crown,
  Shield,
  Activity,
  ChevronRight,
} from 'lucide-react';

const navItems = [
  { path: '/superadmin', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { path: '/superadmin/teachers', label: 'Teachers', icon: Users },
  { path: '/superadmin/support', label: 'Support Requests', icon: MessageSquareWarning },
];

export default function SuperAdminLayout({ children }) {
  const { logout } = useSuperAdmin();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/superadmin/login');
  }

  return (
    <div className="flex min-h-screen" style={{ background: '#050510' }}>
      {/* Sidebar */}
      <motion.aside
        initial={{ x: -100, opacity: 0 }}
        animate={{ x: 0, opacity: 1 }}
        transition={{ duration: 0.4 }}
        className="w-72 flex flex-col border-r border-white/5 relative overflow-hidden"
        style={{
          background: 'linear-gradient(180deg, rgba(15,10,25,0.98) 0%, rgba(10,8,20,0.99) 100%)',
        }}
      >
        {/* Subtle gradient accent */}
        <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-amber-500/30 to-transparent" />
        <div className="absolute top-0 right-0 w-px h-32 bg-gradient-to-b from-amber-500/20 to-transparent" />

        {/* Logo / Brand */}
        <div className="p-6 pb-2">
          <div className="flex items-center gap-3 mb-1">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center"
              style={{
                background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
                boxShadow: '0 4px 15px rgba(245,158,11,0.25)',
              }}
            >
              <Crown className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold"
                style={{
                  background: 'linear-gradient(135deg, #FCD34D 0%, #F59E0B 100%)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                }}
              >
                WIWC
              </h1>
              <p className="text-[10px] font-semibold text-gray-500 uppercase tracking-widest">Command Center</p>
            </div>
          </div>
        </div>

        {/* Live indicator */}
        <div className="mx-6 mb-6 px-3 py-2 rounded-lg border border-amber-500/10" style={{ background: 'rgba(245,158,11,0.05)' }}>
          <div className="flex items-center gap-2">
            <div className="relative">
              <div className="w-2 h-2 rounded-full bg-emerald-400" />
              <div className="w-2 h-2 rounded-full bg-emerald-400 absolute inset-0 animate-ping opacity-60" />
            </div>
            <span className="text-[11px] font-medium text-gray-400">System Online</span>
            <Activity className="w-3 h-3 text-amber-500/60 ml-auto" />
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-3 space-y-1">
          <p className="text-[10px] font-bold text-gray-600 uppercase tracking-widest px-3 mb-3">Navigation</p>
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.end}
              className={({ isActive }) =>
                `group flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${isActive
                  ? 'text-white'
                  : 'text-gray-500 hover:text-gray-300 hover:bg-white/[0.02]'
                }`
              }
              style={({ isActive }) => isActive ? {
                background: 'linear-gradient(135deg, rgba(245,158,11,0.12) 0%, rgba(217,119,6,0.08) 100%)',
                border: '1px solid rgba(245,158,11,0.15)',
                boxShadow: '0 0 20px rgba(245,158,11,0.05)',
              } : {
                border: '1px solid transparent',
              }}
            >
              <item.icon className="w-[18px] h-[18px]" />
              <span>{item.label}</span>
              <ChevronRight className="w-3.5 h-3.5 ml-auto opacity-0 group-hover:opacity-50 transition-opacity" />
            </NavLink>
          ))}
        </nav>

        {/* Separator */}
        <div className="mx-6 h-px bg-white/5 my-2" />

        {/* Admin Profile & Logout */}
        <div className="p-4">
          <div className="px-3 py-3 rounded-xl flex items-center gap-3 mb-3"
            style={{ background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.04)' }}
          >
            <div className="w-9 h-9 rounded-lg flex items-center justify-center"
              style={{ background: 'linear-gradient(135deg, rgba(245,158,11,0.2) 0%, rgba(217,119,6,0.15) 100%)' }}
            >
              <Shield className="w-4 h-4 text-amber-500" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-white truncate">Kyotaka</p>
              <p className="text-[10px] text-amber-500/60 font-medium uppercase tracking-wide">Super Admin</p>
            </div>
          </div>

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium text-gray-500 hover:text-red-400 hover:bg-red-500/5 transition-all"
            style={{ border: '1px solid transparent' }}
          >
            <LogOut className="w-4 h-4" />
            <span>Log Out</span>
          </button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <div className="p-8 max-w-[1400px] mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
