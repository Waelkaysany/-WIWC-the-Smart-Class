import { useState, useEffect } from 'react';
import { ref, onValue, get } from 'firebase/database';
import { db } from '../services/firebase';
import SuperAdminLayout from '../components/superadmin/SuperAdminLayout';
import { motion } from 'framer-motion';
import {
  Users,
  GraduationCap,
  AlertTriangle,
  Activity,
  Crown,
  Clock,
  Wifi,
  WifiOff,
  MessageSquareWarning,
  DoorOpen,
  TrendingUp,
} from 'lucide-react';

function StatCard({ title, value, icon: Icon, gradient, subtitle, pulse }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="relative overflow-hidden rounded-2xl p-5 border border-white/5"
      style={{
        background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
        boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
      }}
    >
      <div className="absolute top-0 right-0 w-24 h-24 rounded-full blur-3xl opacity-10" style={{ background: gradient }} />
      <div className="flex items-start justify-between mb-3">
        <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: gradient, boxShadow: `0 4px 15px ${gradient}40` }}>
          <Icon className="w-5 h-5 text-white" />
        </div>
        {pulse && (
          <div className="flex items-center gap-1.5">
            <div className="relative">
              <div className="w-2 h-2 rounded-full bg-emerald-400" />
              <div className="w-2 h-2 rounded-full bg-emerald-400 absolute inset-0 animate-ping opacity-50" />
            </div>
            <span className="text-[10px] text-emerald-400 font-medium">LIVE</span>
          </div>
        )}
      </div>
      <p className="text-3xl font-bold text-white mb-0.5">{value}</p>
      <p className="text-xs text-gray-500 font-medium">{title}</p>
      {subtitle && <p className="text-[10px] text-gray-600 mt-1">{subtitle}</p>}
    </motion.div>
  );
}

export default function SuperAdminDashboard() {
  const [teachers, setTeachers] = useState([]);
  const [classrooms, setClassrooms] = useState({});
  const [supportRequests, setSupportRequests] = useState([]);
  const [sessions, setSessions] = useState([]);

  useEffect(() => {
    // Listen to users
    const usersRef = ref(db, 'users');
    const unsubUsers = onValue(usersRef, (snap) => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data).map(([uid, val]) => ({ uid, ...val }));
        setTeachers(arr.filter(u => u.role === 'teacher'));
      }
    });

    // Listen to classrooms
    const classRef = ref(db, 'classrooms');
    const unsubClass = onValue(classRef, (snap) => {
      if (snap.exists()) setClassrooms(snap.val());
    });

    // Listen to support requests
    const supportRef = ref(db, 'support_requests');
    const unsubSupport = onValue(supportRef, (snap) => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data).map(([id, val]) => ({ id, ...val }));
        setSupportRequests(arr.sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || '')));
      } else {
        setSupportRequests([]);
      }
    });

    // Listen to sessions
    const sessRef = ref(db, 'classSessions');
    const unsubSess = onValue(sessRef, (snap) => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data).map(([id, val]) => ({ id, ...val }));
        setSessions(arr.sort((a, b) => (b.startedAt || 0) - (a.startedAt || 0)));
      }
    });

    return () => { unsubUsers(); unsubClass(); unsubSupport(); unsubSess(); };
  }, []);

  const onlineTeachers = teachers.filter(t => {
    if (!t.lastLogin) return false;
    const lastLogin = new Date(t.lastLogin).getTime();
    // Consider online if logged in within last 30 minutes
    return Date.now() - lastLogin < 30 * 60 * 1000;
  });

  const takenClasses = Object.values(classrooms).filter(c => c.status === 'taken');
  const openTickets = supportRequests.filter(r => r.status === 'open');
  const activeSessions = sessions.filter(s => s.status === 'ACTIVE');
  const recentSessions = sessions.slice(0, 8);

  const containerVariants = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.08 } },
  };

  return (
    <SuperAdminLayout>
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-2">
          <Crown className="w-5 h-5 text-amber-500" />
          <h1 className="text-2xl font-bold text-white">Command Center</h1>
        </div>
        <p className="text-sm text-gray-500">Real-time overview of your WIWC Smart Classroom ecosystem</p>
      </div>

      {/* Stats Grid */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8"
      >
        <StatCard
          title="Total Teachers"
          value={teachers.length}
          icon={Users}
          gradient="linear-gradient(135deg, #6366F1, #4F46E5)"
          subtitle={`${onlineTeachers.length} currently online`}
        />
        <StatCard
          title="Online Now"
          value={onlineTeachers.length}
          icon={Wifi}
          gradient="linear-gradient(135deg, #10B981, #059669)"
          pulse
          subtitle="Active in last 30 min"
        />
        <StatCard
          title="Classes In Use"
          value={takenClasses.length}
          icon={DoorOpen}
          gradient="linear-gradient(135deg, #F59E0B, #D97706)"
          subtitle={`of ${Object.keys(classrooms).length} total classes`}
        />
        <StatCard
          title="Open Tickets"
          value={openTickets.length}
          icon={MessageSquareWarning}
          gradient={openTickets.length > 0 ? "linear-gradient(135deg, #EF4444, #DC2626)" : "linear-gradient(135deg, #6B7280, #4B5563)"}
          subtitle={openTickets.length > 0 ? "Needs attention" : "All clear"}
        />
      </motion.div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Classroom Status */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="lg:col-span-3 rounded-2xl border border-white/5 p-6"
          style={{
            background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
          }}
        >
          <div className="flex items-center justify-between mb-5">
            <div className="flex items-center gap-2">
              <GraduationCap className="w-4 h-4 text-amber-500" />
              <h2 className="text-sm font-bold text-white">Classroom Status</h2>
            </div>
            <span className="text-[10px] text-gray-600 font-medium uppercase tracking-wider">Real-time</span>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {Object.entries(classrooms).map(([id, room]) => (
              <div
                key={id}
                className="rounded-xl p-4 border transition-all"
                style={{
                  background: room.status === 'taken'
                    ? 'rgba(245,158,11,0.05)'
                    : 'rgba(255,255,255,0.01)',
                  border: room.status === 'taken'
                    ? '1px solid rgba(245,158,11,0.15)'
                    : '1px solid rgba(255,255,255,0.04)',
                }}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-bold text-white">{room.name}</span>
                  <div className={`w-2 h-2 rounded-full ${room.status === 'taken' ? 'bg-amber-500' : 'bg-emerald-400'}`}
                    style={{ boxShadow: room.status === 'taken' ? '0 0 8px rgba(245,158,11,0.4)' : '0 0 8px rgba(16,185,129,0.4)' }}
                  />
                </div>
                <p className="text-[10px] text-gray-500 font-medium">{room.grade}</p>
                {room.takenBy && (
                  <div className="mt-2 flex items-center gap-1.5">
                    <div className="w-4 h-4 rounded-full bg-amber-500/20 flex items-center justify-center">
                      <Users className="w-2.5 h-2.5 text-amber-500" />
                    </div>
                    <span className="text-[10px] text-amber-500/80 font-medium truncate">{room.takenBy.name}</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="lg:col-span-2 rounded-2xl border border-white/5 p-6"
          style={{
            background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
          }}
        >
          <div className="flex items-center gap-2 mb-5">
            <Activity className="w-4 h-4 text-amber-500" />
            <h2 className="text-sm font-bold text-white">Recent Sessions</h2>
          </div>

          <div className="space-y-2 max-h-[380px] overflow-y-auto pr-1">
            {recentSessions.length === 0 ? (
              <p className="text-xs text-gray-600 text-center py-8">No sessions yet</p>
            ) : (
              recentSessions.map((session) => (
                <div
                  key={session.id}
                  className="flex items-center gap-3 p-3 rounded-xl border border-white/[0.03]"
                  style={{ background: 'rgba(255,255,255,0.01)' }}
                >
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${session.status === 'ACTIVE' ? 'bg-emerald-500/10' : 'bg-gray-500/10'
                    }`}>
                    {session.status === 'ACTIVE' ? (
                      <Wifi className="w-3.5 h-3.5 text-emerald-400" />
                    ) : (
                      <WifiOff className="w-3.5 h-3.5 text-gray-500" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-white truncate">{session.teacherName || 'Unknown'}</p>
                    <p className="text-[10px] text-gray-500">
                      {session.classId} • {session.status === 'ACTIVE' ? 'Active now' : 'Ended'}
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="text-[10px] text-gray-600">
                      {session.startedAt ? new Date(session.startedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ''}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </motion.div>
      </div>

      {/* Recent Support Tickets */}
      {supportRequests.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="mt-6 rounded-2xl border border-white/5 p-6"
          style={{
            background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
          }}
        >
          <div className="flex items-center justify-between mb-5">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-500" />
              <h2 className="text-sm font-bold text-white">Latest Support Tickets</h2>
            </div>
            <a href="/superadmin/support" className="text-[11px] text-amber-500 hover:text-amber-400 font-medium transition-colors">
              View All →
            </a>
          </div>

          <div className="space-y-2">
            {supportRequests.slice(0, 4).map((ticket) => (
              <div
                key={ticket.id}
                className="flex items-center gap-4 p-3 rounded-xl border border-white/[0.03]"
                style={{ background: 'rgba(255,255,255,0.01)' }}
              >
                <div className={`w-2 h-8 rounded-full flex-shrink-0 ${ticket.priority === 'critical' ? 'bg-red-500' :
                    ticket.priority === 'high' ? 'bg-orange-500' :
                      ticket.priority === 'medium' ? 'bg-amber-500' : 'bg-blue-500'
                  }`} />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-semibold text-white truncate">{ticket.title}</p>
                  <p className="text-[10px] text-gray-500 truncate">{ticket.description}</p>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${ticket.status === 'open' ? 'bg-amber-500/10 text-amber-500' :
                      ticket.status === 'in_progress' ? 'bg-blue-500/10 text-blue-500' :
                        'bg-emerald-500/10 text-emerald-500'
                    }`}>
                    {ticket.status === 'in_progress' ? 'In Progress' : ticket.status}
                  </span>
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${ticket.source === 'ai' ? 'bg-purple-500/10 text-purple-400' : 'bg-gray-500/10 text-gray-400'
                    }`}>
                    {ticket.source === 'ai' ? '🤖 AI' : '👤 Teacher'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      )}
    </SuperAdminLayout>
  );
}
