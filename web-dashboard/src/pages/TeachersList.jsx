import { useState, useEffect } from 'react';
import { ref, onValue, remove, get } from 'firebase/database';
import { db } from '../services/firebase';
import SuperAdminLayout from '../components/superadmin/SuperAdminLayout';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Users,
  Search,
  Trash2,
  Wifi,
  WifiOff,
  Clock,
  Mail,
  Shield,
  UserX,
  Filter,
  X,
  AlertTriangle,
  Crown,
  Calendar,
} from 'lucide-react';

export default function TeachersList() {
  const [teachers, setTeachers] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('all'); // all, online, offline
  const [showDeleteModal, setShowDeleteModal] = useState(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsub = onValue(usersRef, (snap) => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data)
          .map(([uid, val]) => ({ uid, ...val }))
          .filter(u => u.role === 'teacher');
        setTeachers(arr);
      } else {
        setTeachers([]);
      }
    });
    return () => unsub();
  }, []);

  function isOnline(teacher) {
    if (!teacher.lastLogin) return false;
    const lastLogin = new Date(teacher.lastLogin).getTime();
    return Date.now() - lastLogin < 30 * 60 * 1000;
  }

  async function handleDelete(teacher) {
    setDeleting(true);
    try {
      // Remove from RTDB
      await remove(ref(db, `users/${teacher.uid}`));
      // Also remove any pending approvals
      await remove(ref(db, `pending_approvals/${teacher.uid}`));
      setShowDeleteModal(null);
    } catch (err) {
      console.error('Failed to delete teacher:', err);
    } finally {
      setDeleting(false);
    }
  }

  const filtered = teachers.filter((t) => {
    const matchesSearch =
      (t.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.email || '').toLowerCase().includes(searchQuery.toLowerCase());

    if (filterStatus === 'online') return matchesSearch && isOnline(t);
    if (filterStatus === 'offline') return matchesSearch && !isOnline(t);
    return matchesSearch;
  });

  const onlineCount = teachers.filter(isOnline).length;

  return (
    <SuperAdminLayout>
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <Users className="w-5 h-5 text-amber-500" />
              <h1 className="text-2xl font-bold text-white">Teachers</h1>
            </div>
            <p className="text-sm text-gray-500">
              Manage all registered teachers • {teachers.length} total • {onlineCount} online
            </p>
          </div>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-600" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by name or email..."
            className="w-full pl-10 pr-4 py-3 rounded-xl text-sm text-white placeholder-gray-600 focus:outline-none transition-all"
            style={{
              background: 'rgba(15,12,25,0.95)',
              border: '1px solid rgba(255,255,255,0.06)',
            }}
            onFocus={(e) => e.target.style.border = '1px solid rgba(245,158,11,0.2)'}
            onBlur={(e) => e.target.style.border = '1px solid rgba(255,255,255,0.06)'}
          />
        </div>
        <div className="flex gap-2">
          {['all', 'online', 'offline'].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-4 py-2.5 rounded-xl text-xs font-semibold uppercase tracking-wider transition-all ${filterStatus === status
                  ? 'text-white'
                  : 'text-gray-500 hover:text-gray-300'
                }`}
              style={filterStatus === status ? {
                background: 'linear-gradient(135deg, rgba(245,158,11,0.12) 0%, rgba(217,119,6,0.08) 100%)',
                border: '1px solid rgba(245,158,11,0.15)',
              } : {
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid rgba(255,255,255,0.04)',
              }}
            >
              {status === 'online' && <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-400 mr-1.5" />}
              {status === 'offline' && <span className="inline-block w-1.5 h-1.5 rounded-full bg-gray-500 mr-1.5" />}
              {status}
            </button>
          ))}
        </div>
      </div>

      {/* Teachers List */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="rounded-2xl border border-white/5 overflow-hidden"
        style={{
          background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
        }}
      >
        {/* Table Header */}
        <div className="grid grid-cols-12 gap-4 px-6 py-3 border-b border-white/5"
          style={{ background: 'rgba(255,255,255,0.01)' }}
        >
          <div className="col-span-4 text-[10px] font-bold text-gray-500 uppercase tracking-widest">Teacher</div>
          <div className="col-span-3 text-[10px] font-bold text-gray-500 uppercase tracking-widest">Status</div>
          <div className="col-span-3 text-[10px] font-bold text-gray-500 uppercase tracking-widest">Last Activity</div>
          <div className="col-span-2 text-[10px] font-bold text-gray-500 uppercase tracking-widest text-right">Actions</div>
        </div>

        {/* Rows */}
        <AnimatePresence>
          {filtered.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <UserX className="w-10 h-10 text-gray-700 mx-auto mb-3" />
              <p className="text-sm text-gray-500">No teachers found</p>
            </div>
          ) : (
            filtered.map((teacher, i) => {
              const online = isOnline(teacher);
              return (
                <motion.div
                  key={teacher.uid}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 10 }}
                  transition={{ delay: i * 0.03 }}
                  className="grid grid-cols-12 gap-4 px-6 py-4 border-b border-white/[0.02] hover:bg-white/[0.01] transition-colors items-center"
                >
                  {/* Teacher Info */}
                  <div className="col-span-4 flex items-center gap-3">
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{
                        background: online
                          ? 'linear-gradient(135deg, rgba(16,185,129,0.15) 0%, rgba(5,150,105,0.1) 100%)'
                          : 'rgba(255,255,255,0.03)',
                        border: `1px solid ${online ? 'rgba(16,185,129,0.2)' : 'rgba(255,255,255,0.05)'}`,
                      }}
                    >
                      <span className="text-sm font-bold" style={{ color: online ? '#10B981' : '#6B7280' }}>
                        {(teacher.name || '?')[0].toUpperCase()}
                      </span>
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-white truncate">{teacher.name || 'Unnamed'}</p>
                      <p className="text-[10px] text-gray-500 truncate flex items-center gap-1">
                        <Mail className="w-2.5 h-2.5" />
                        {teacher.email || 'No email'}
                      </p>
                    </div>
                  </div>

                  {/* Status */}
                  <div className="col-span-3">
                    <div className="flex items-center gap-2">
                      {online ? (
                        <>
                          <div className="relative">
                            <div className="w-2 h-2 rounded-full bg-emerald-400" />
                            <div className="w-2 h-2 rounded-full bg-emerald-400 absolute inset-0 animate-ping opacity-40" />
                          </div>
                          <span className="text-xs font-medium text-emerald-400">Online</span>
                        </>
                      ) : (
                        <>
                          <div className="w-2 h-2 rounded-full bg-gray-600" />
                          <span className="text-xs font-medium text-gray-500">Offline</span>
                        </>
                      )}
                    </div>
                    <p className="text-[10px] text-gray-600 mt-0.5">
                      {teacher.isApproved ? '✓ Approved' : '⏳ Pending'}
                    </p>
                  </div>

                  {/* Last Activity */}
                  <div className="col-span-3">
                    <div className="flex items-center gap-1.5 text-xs text-gray-400">
                      <Clock className="w-3 h-3" />
                      {teacher.lastLogin
                        ? new Date(teacher.lastLogin).toLocaleDateString('en-US', {
                          month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
                        })
                        : 'Never'
                      }
                    </div>
                    <div className="flex items-center gap-1.5 text-[10px] text-gray-600 mt-0.5">
                      <Calendar className="w-2.5 h-2.5" />
                      Joined {teacher.createdAt
                        ? new Date(teacher.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
                        : 'Unknown'
                      }
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="col-span-2 flex justify-end">
                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => setShowDeleteModal(teacher)}
                      className="p-2 rounded-lg text-gray-600 hover:text-red-400 hover:bg-red-500/10 transition-all"
                      title="Remove teacher"
                    >
                      <Trash2 className="w-4 h-4" />
                    </motion.button>
                  </div>
                </motion.div>
              );
            })
          )}
        </AnimatePresence>
      </motion.div>

      {/* Delete Modal */}
      <AnimatePresence>
        {showDeleteModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4"
            style={{ background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)' }}
            onClick={() => !deleting && setShowDeleteModal(null)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-sm rounded-2xl p-6 border border-white/5"
              style={{
                background: 'linear-gradient(135deg, rgba(15,12,25,0.98) 0%, rgba(20,15,30,0.98) 100%)',
                boxShadow: '0 25px 60px rgba(0,0,0,0.5)',
              }}
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-xl bg-red-500/10 flex items-center justify-center">
                  <AlertTriangle className="w-5 h-5 text-red-500" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white">Remove Teacher</h3>
                  <p className="text-[10px] text-gray-500">This action cannot be undone</p>
                </div>
              </div>

              <p className="text-xs text-gray-400 mb-6">
                Are you sure you want to remove <strong className="text-white">{showDeleteModal.name || showDeleteModal.email}</strong>?
                Their data will be permanently deleted from the system.
              </p>

              <div className="flex gap-3">
                <button
                  onClick={() => setShowDeleteModal(null)}
                  disabled={deleting}
                  className="flex-1 px-4 py-2.5 rounded-xl text-xs font-semibold text-gray-400 transition-all"
                  style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.06)' }}
                >
                  Cancel
                </button>
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={() => handleDelete(showDeleteModal)}
                  disabled={deleting}
                  className="flex-1 px-4 py-2.5 rounded-xl text-xs font-bold text-white disabled:opacity-50 transition-all flex items-center justify-center gap-2"
                  style={{
                    background: 'linear-gradient(135deg, #EF4444 0%, #DC2626 100%)',
                    boxShadow: '0 4px 15px rgba(239,68,68,0.25)',
                  }}
                >
                  {deleting ? (
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <>
                      <Trash2 className="w-3.5 h-3.5" />
                      Remove
                    </>
                  )}
                </motion.button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </SuperAdminLayout>
  );
}
