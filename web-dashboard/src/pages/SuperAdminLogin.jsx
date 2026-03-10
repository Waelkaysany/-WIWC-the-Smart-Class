import { useState } from 'react';
import { useSuperAdmin } from '../context/SuperAdminContext';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Shield, User, Lock, ChevronRight, Loader2, Crown } from 'lucide-react';

export default function SuperAdminLogin() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useSuperAdmin();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Simulate a brief authentication delay
    await new Promise(r => setTimeout(r, 800));

    const success = login(username, password);
    if (success) {
      navigate('/superadmin');
    } else {
      setError('Invalid credentials. Access denied.');
    }
    setLoading(false);
  }

  return (
    <div className="relative min-h-screen w-full flex items-center justify-center overflow-hidden bg-[#050510]">
      {/* Animated Background — Gold/Amber theme */}
      <motion.div
        animate={{
          scale: [1, 1.3, 1],
          rotate: [0, 120, 0],
        }}
        transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
        className="absolute top-[-25%] left-[-15%] w-[700px] h-[700px] rounded-full blur-[150px]"
        style={{ background: 'radial-gradient(circle, rgba(255,170,0,0.15) 0%, transparent 70%)' }}
      />
      <motion.div
        animate={{
          scale: [1, 1.5, 1],
          x: [0, 80, 0],
          y: [0, -40, 0],
        }}
        transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
        className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] rounded-full blur-[130px]"
        style={{ background: 'radial-gradient(circle, rgba(139,92,246,0.12) 0%, transparent 70%)' }}
      />
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          y: [0, 60, 0],
        }}
        transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
        className="absolute top-[30%] right-[20%] w-[400px] h-[400px] rounded-full blur-[120px]"
        style={{ background: 'radial-gradient(circle, rgba(255,215,0,0.08) 0%, transparent 70%)' }}
      />

      {/* Floating particles */}
      {[...Array(6)].map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-1 h-1 rounded-full bg-amber-400/30"
          style={{
            left: `${15 + i * 15}%`,
            top: `${20 + (i % 3) * 25}%`,
          }}
          animate={{
            y: [0, -30, 0],
            opacity: [0.2, 0.6, 0.2],
          }}
          transition={{
            duration: 3 + i * 0.5,
            repeat: Infinity,
            delay: i * 0.4,
          }}
        />
      ))}

      {/* Login Card */}
      <motion.div
        initial={{ opacity: 0, y: 30, scale: 0.9 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.6, type: "spring", stiffness: 100 }}
        className="relative z-10 w-full max-w-md mx-4"
      >
        {/* Premium glass card */}
        <div className="p-8 sm:p-10 rounded-2xl border border-amber-500/10 backdrop-blur-2xl"
          style={{
            background: 'linear-gradient(135deg, rgba(15,15,25,0.9) 0%, rgba(20,15,30,0.85) 100%)',
            boxShadow: '0 25px 60px -12px rgba(0,0,0,0.5), 0 0 40px -8px rgba(255,170,0,0.1), inset 0 1px 0 rgba(255,215,0,0.05)',
          }}
        >
          {/* Crown Icon */}
          <div className="flex flex-col items-center mb-8">
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.2 }}
              className="relative"
            >
              <div className="w-20 h-20 rounded-2xl flex items-center justify-center mb-4"
                style={{
                  background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 50%, #B45309 100%)',
                  boxShadow: '0 8px 30px rgba(245,158,11,0.35)',
                }}
              >
                <Crown className="w-10 h-10 text-white" />
              </div>
              {/* Glow ring */}
              <motion.div
                animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.1, 0.3] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="absolute inset-0 rounded-2xl"
                style={{ boxShadow: '0 0 40px rgba(245,158,11,0.25)' }}
              />
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="text-3xl font-bold tracking-tight"
              style={{
                background: 'linear-gradient(135deg, #FCD34D 0%, #F59E0B 50%, #D97706 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
              }}
            >
              SuperAdmin
            </motion.h1>
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              className="text-gray-500 mt-2 text-center text-sm"
            >
              WIWC Command Center • Restricted Access
            </motion.p>
          </div>

          {error && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="mb-5 p-3 rounded-xl text-sm text-center font-medium"
              style={{
                background: 'rgba(239,68,68,0.1)',
                border: '1px solid rgba(239,68,68,0.2)',
                color: '#EF4444',
              }}
            >
              <div className="flex items-center justify-center gap-2">
                <Shield className="w-4 h-4" />
                {error}
              </div>
            </motion.div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400 uppercase tracking-wider ml-1">Username</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <User className="h-4.5 w-4.5 text-gray-600 group-focus-within:text-amber-500 transition-colors" />
                </div>
                <input
                  type="text"
                  required
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="block w-full pl-11 pr-4 py-3.5 rounded-xl text-white placeholder-gray-600 focus:outline-none transition-all text-sm"
                  style={{
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid rgba(255,255,255,0.06)',
                    boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.2)',
                  }}
                  onFocus={(e) => e.target.style.border = '1px solid rgba(245,158,11,0.3)'}
                  onBlur={(e) => e.target.style.border = '1px solid rgba(255,255,255,0.06)'}
                  placeholder="Enter username"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-gray-400 uppercase tracking-wider ml-1">Password</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <Lock className="h-4.5 w-4.5 text-gray-600 group-focus-within:text-amber-500 transition-colors" />
                </div>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="block w-full pl-11 pr-4 py-3.5 rounded-xl text-white placeholder-gray-600 focus:outline-none transition-all text-sm"
                  style={{
                    background: 'rgba(0,0,0,0.3)',
                    border: '1px solid rgba(255,255,255,0.06)',
                    boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.2)',
                  }}
                  onFocus={(e) => e.target.style.border = '1px solid rgba(245,158,11,0.3)'}
                  onBlur={(e) => e.target.style.border = '1px solid rgba(255,255,255,0.06)'}
                  placeholder="••••••••"
                />
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              disabled={loading}
              type="submit"
              className="w-full flex items-center justify-center py-3.5 px-4 text-white font-bold rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed group text-sm"
              style={{
                background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 50%, #B45309 100%)',
                boxShadow: '0 8px 25px rgba(245,158,11,0.25)',
              }}
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <>
                  <Shield className="w-4 h-4 mr-2" />
                  Access Command Center
                  <ChevronRight className="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
                </>
              )}
            </motion.button>
          </form>

          <div className="mt-8 flex items-center justify-center gap-2 text-xs text-gray-600">
            <Shield className="w-3 h-3" />
            <p>Military-grade encrypted • WIWC Enterprise</p>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
