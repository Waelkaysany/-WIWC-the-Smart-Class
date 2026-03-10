import { useState, useEffect } from 'react';
import { ref, onValue, update } from 'firebase/database';
import { db } from '../services/firebase';
import SuperAdminLayout from '../components/superadmin/SuperAdminLayout';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MessageSquareWarning,
  Search,
  Clock,
  User,
  Bot,
  CheckCircle2,
  XCircle,
  Loader2,
  Filter,
  AlertTriangle,
  Shield,
  ArrowUpRight,
  ChevronDown,
} from 'lucide-react';

const priorityConfig = {
  critical: { color: '#EF4444', bg: 'rgba(239,68,68,0.1)', border: 'rgba(239,68,68,0.2)', label: 'Critical' },
  high: { color: '#F97316', bg: 'rgba(249,115,22,0.1)', border: 'rgba(249,115,22,0.2)', label: 'High' },
  medium: { color: '#F59E0B', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.2)', label: 'Medium' },
  low: { color: '#3B82F6', bg: 'rgba(59,130,246,0.1)', border: 'rgba(59,130,246,0.2)', label: 'Low' },
};

const statusConfig = {
  open: { color: '#F59E0B', bg: 'rgba(245,158,11,0.08)', label: 'Open' },
  in_progress: { color: '#3B82F6', bg: 'rgba(59,130,246,0.08)', label: 'In Progress' },
  resolved: { color: '#10B981', bg: 'rgba(16,185,129,0.08)', label: 'Resolved' },
};

export default function SupportRequests() {
  const [requests, setRequests] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterPriority, setFilterPriority] = useState('all');
  const [expandedId, setExpandedId] = useState(null);
  const [updating, setUpdating] = useState(null);

  useEffect(() => {
    const supportRef = ref(db, 'support_requests');
    const unsub = onValue(supportRef, (snap) => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data)
          .map(([id, val]) => ({ id, ...val }))
          .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
        setRequests(arr);
      } else {
        setRequests([]);
      }
    });
    return () => unsub();
  }, []);

  async function updateStatus(ticketId, newStatus) {
    setUpdating(ticketId);
    try {
      await update(ref(db, `support_requests/${ticketId}`), {
        status: newStatus,
        updatedAt: new Date().toISOString(),
      });
    } catch (err) {
      console.error('Failed to update ticket:', err);
    } finally {
      setUpdating(null);
    }
  }

  const filtered = requests.filter((r) => {
    const matchesSearch =
      (r.title || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (r.description || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (r.teacherName || '').toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = filterStatus === 'all' || r.status === filterStatus;
    const matchesPriority = filterPriority === 'all' || r.priority === filterPriority;
    return matchesSearch && matchesStatus && matchesPriority;
  });

  const openCount = requests.filter(r => r.status === 'open').length;
  const inProgressCount = requests.filter(r => r.status === 'in_progress').length;
  const resolvedCount = requests.filter(r => r.status === 'resolved').length;

  return (
    <SuperAdminLayout>
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3 mb-2">
          <MessageSquareWarning className="w-5 h-5 text-amber-500" />
          <h1 className="text-2xl font-bold text-white">Support Requests</h1>
        </div>
        <p className="text-sm text-gray-500">
          Manage teacher issues and AI-detected problems
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {[
          { label: 'Open', count: openCount, color: '#F59E0B', icon: AlertTriangle },
          { label: 'In Progress', count: inProgressCount, color: '#3B82F6', icon: Loader2 },
          { label: 'Resolved', count: resolvedCount, color: '#10B981', icon: CheckCircle2 },
        ].map((stat) => (
          <div
            key={stat.label}
            className="rounded-xl p-4 border border-white/[0.04]"
            style={{ background: 'rgba(15,12,25,0.95)' }}
          >
            <div className="flex items-center gap-2 mb-2">
              <stat.icon className="w-3.5 h-3.5" style={{ color: stat.color }} />
              <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider">{stat.label}</span>
            </div>
            <p className="text-2xl font-bold text-white">{stat.count}</p>
          </div>
        ))}
      </div>

      {/* Search & Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-600" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search tickets..."
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
          {['all', 'open', 'in_progress', 'resolved'].map((status) => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-3 py-2.5 rounded-xl text-[10px] font-bold uppercase tracking-wider transition-all ${filterStatus === status ? 'text-white' : 'text-gray-500 hover:text-gray-300'
                }`}
              style={filterStatus === status ? {
                background: 'linear-gradient(135deg, rgba(245,158,11,0.12) 0%, rgba(217,119,6,0.08) 100%)',
                border: '1px solid rgba(245,158,11,0.15)',
              } : {
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid rgba(255,255,255,0.04)',
              }}
            >
              {status === 'in_progress' ? 'In Progress' : status === 'all' ? 'All' : status}
            </button>
          ))}
        </div>
      </div>

      {/* Tickets List */}
      <div className="space-y-3">
        <AnimatePresence>
          {filtered.length === 0 ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="rounded-2xl border border-white/5 p-16 text-center"
              style={{ background: 'rgba(15,12,25,0.95)' }}
            >
              <Shield className="w-10 h-10 text-gray-700 mx-auto mb-3" />
              <p className="text-sm text-gray-500">No tickets found</p>
              <p className="text-xs text-gray-600 mt-1">All clear! No support requests match your filters.</p>
            </motion.div>
          ) : (
            filtered.map((ticket, i) => {
              const priority = priorityConfig[ticket.priority] || priorityConfig.medium;
              const status = statusConfig[ticket.status] || statusConfig.open;
              const isExpanded = expandedId === ticket.id;

              return (
                <motion.div
                  key={ticket.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  transition={{ delay: i * 0.03 }}
                  className="rounded-2xl border overflow-hidden transition-all"
                  style={{
                    background: 'linear-gradient(135deg, rgba(15,12,25,0.95) 0%, rgba(20,15,30,0.9) 100%)',
                    border: `1px solid ${isExpanded ? 'rgba(245,158,11,0.1)' : 'rgba(255,255,255,0.04)'}`,
                  }}
                >
                  {/* Ticket Header */}
                  <button
                    onClick={() => setExpandedId(isExpanded ? null : ticket.id)}
                    className="w-full flex items-center gap-4 p-5 text-left transition-colors hover:bg-white/[0.01]"
                  >
                    {/* Priority bar */}
                    <div className="w-1 h-10 rounded-full flex-shrink-0" style={{ background: priority.color }} />

                    {/* Source icon */}
                    <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                      style={{
                        background: ticket.source === 'ai' ? 'rgba(168,85,247,0.1)' : 'rgba(255,255,255,0.03)',
                        border: ticket.source === 'ai' ? '1px solid rgba(168,85,247,0.15)' : '1px solid rgba(255,255,255,0.05)',
                      }}
                    >
                      {ticket.source === 'ai' ? (
                        <Bot className="w-4 h-4 text-purple-400" />
                      ) : (
                        <User className="w-4 h-4 text-gray-400" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-white truncate">{ticket.title}</p>
                      <div className="flex items-center gap-3 mt-1">
                        <span className="text-[10px] text-gray-500">{ticket.teacherName || 'Unknown'}</span>
                        <span className="text-[10px] text-gray-600">•</span>
                        <span className="text-[10px] text-gray-500 flex items-center gap-1">
                          <Clock className="w-2.5 h-2.5" />
                          {ticket.createdAt
                            ? new Date(ticket.createdAt).toLocaleDateString('en-US', {
                              month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
                            })
                            : 'Unknown'
                          }
                        </span>
                      </div>
                    </div>

                    {/* Badges */}
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <span className="px-2 py-1 rounded-lg text-[10px] font-bold uppercase"
                        style={{ background: priority.bg, color: priority.color, border: `1px solid ${priority.border}` }}
                      >
                        {priority.label}
                      </span>
                      <span className="px-2 py-1 rounded-lg text-[10px] font-bold"
                        style={{ background: status.bg, color: status.color }}
                      >
                        {status.label}
                      </span>
                    </div>

                    <ChevronDown
                      className={`w-4 h-4 text-gray-600 transition-transform flex-shrink-0 ${isExpanded ? 'rotate-180' : ''}`}
                    />
                  </button>

                  {/* Expanded Details */}
                  <AnimatePresence>
                    {isExpanded && (
                      <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        className="overflow-hidden"
                      >
                        <div className="px-5 pb-5 border-t border-white/[0.03] pt-4">
                          <div className="grid grid-cols-2 gap-6">
                            {/* Description */}
                            <div>
                              <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-2">Description</p>
                              <p className="text-xs text-gray-300 leading-relaxed">{ticket.description || 'No description provided.'}</p>

                              <div className="mt-4 p-3 rounded-xl" style={{ background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.04)' }}>
                                <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1.5">Reporter Details</p>
                                <p className="text-xs text-gray-400">{ticket.teacherName} ({ticket.teacherEmail || 'No email'})</p>
                                <p className="text-[10px] text-gray-600 mt-0.5">Source: {ticket.source === 'ai' ? '🤖 AI Assistant' : '👤 Teacher'}</p>
                              </div>
                            </div>

                            {/* Actions */}
                            <div>
                              <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-3">Update Status</p>
                              <div className="space-y-2">
                                {ticket.status !== 'in_progress' && (
                                  <motion.button
                                    whileHover={{ scale: 1.01 }}
                                    whileTap={{ scale: 0.99 }}
                                    onClick={() => updateStatus(ticket.id, 'in_progress')}
                                    disabled={updating === ticket.id}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-blue-400 transition-all disabled:opacity-50"
                                    style={{ background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.15)' }}
                                  >
                                    {updating === ticket.id ? (
                                      <div className="w-3.5 h-3.5 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin" />
                                    ) : (
                                      <ArrowUpRight className="w-3.5 h-3.5" />
                                    )}
                                    Mark In Progress
                                  </motion.button>
                                )}

                                {ticket.status !== 'resolved' && (
                                  <motion.button
                                    whileHover={{ scale: 1.01 }}
                                    whileTap={{ scale: 0.99 }}
                                    onClick={() => updateStatus(ticket.id, 'resolved')}
                                    disabled={updating === ticket.id}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-emerald-400 transition-all disabled:opacity-50"
                                    style={{ background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.15)' }}
                                  >
                                    {updating === ticket.id ? (
                                      <div className="w-3.5 h-3.5 border-2 border-emerald-500/30 border-t-emerald-500 rounded-full animate-spin" />
                                    ) : (
                                      <CheckCircle2 className="w-3.5 h-3.5" />
                                    )}
                                    Mark Resolved
                                  </motion.button>
                                )}

                                {ticket.status !== 'open' && (
                                  <motion.button
                                    whileHover={{ scale: 1.01 }}
                                    whileTap={{ scale: 0.99 }}
                                    onClick={() => updateStatus(ticket.id, 'open')}
                                    disabled={updating === ticket.id}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-amber-400 transition-all disabled:opacity-50"
                                    style={{ background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.15)' }}
                                  >
                                    <XCircle className="w-3.5 h-3.5" />
                                    Reopen
                                  </motion.button>
                                )}
                              </div>

                              {ticket.updatedAt && (
                                <p className="text-[10px] text-gray-600 mt-3 text-center">
                                  Last updated: {new Date(ticket.updatedAt).toLocaleString()}
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </motion.div>
              );
            })
          )}
        </AnimatePresence>
      </div>
    </SuperAdminLayout>
  );
}
