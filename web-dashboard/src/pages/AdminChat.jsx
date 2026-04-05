import { useState, useEffect, useRef } from 'react';
import { ref, onValue, push, set, update } from 'firebase/database';
import { db } from '../services/firebase';
import SuperAdminLayout from '../components/superadmin/SuperAdminLayout';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MessageSquare,
  Send,
  Search,
  User,
  Check,
  CheckCheck,
  Wifi,
  WifiOff,
} from 'lucide-react';

// ── Helpers ──────────────────────────────────────────────────────────────────
function formatTime(ts) {
  if (!ts) return '';
  const d = new Date(ts);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function formatDate(ts) {
  if (!ts) return '';
  const d = new Date(ts);
  const today = new Date();
  if (d.toDateString() === today.toDateString()) return 'Today';
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  if (d.toDateString() === yesterday.toDateString()) return 'Yesterday';
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

function getInitials(name) {
  if (!name) return '?';
  return name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
}

// ── Gradient colours cycling per user ────────────────────────────────────────
const GRADIENTS = [
  'linear-gradient(135deg,#6366F1,#4F46E5)',
  'linear-gradient(135deg,#F59E0B,#D97706)',
  'linear-gradient(135deg,#10B981,#059669)',
  'linear-gradient(135deg,#EC4899,#DB2777)',
  'linear-gradient(135deg,#3B82F6,#2563EB)',
  'linear-gradient(135deg,#8B5CF6,#7C3AED)',
];
function userGradient(uid) {
  let hash = 0;
  for (let i = 0; i < uid.length; i++) hash = uid.charCodeAt(i) + ((hash << 5) - hash);
  return GRADIENTS[Math.abs(hash) % GRADIENTS.length];
}

// ── Sub-components ────────────────────────────────────────────────────────────
function Avatar({ uid, name, size = 'md' }) {
  const sz = size === 'sm' ? 'w-8 h-8 text-xs' : size === 'lg' ? 'w-12 h-12 text-base' : 'w-10 h-10 text-sm';
  return (
    <div
      className={`${sz} rounded-xl flex items-center justify-center font-bold text-white flex-shrink-0`}
      style={{ background: userGradient(uid || name || '?') }}
    >
      {getInitials(name)}
    </div>
  );
}

function MessageBubble({ msg, isAdmin }) {
  return (
    <div className={`flex ${isAdmin ? 'justify-end' : 'justify-start'} mb-2`}>
      <div
        className={`max-w-[70%] px-4 py-2.5 rounded-2xl ${isAdmin ? 'rounded-br-sm' : 'rounded-bl-sm'
          } text-sm leading-relaxed`}
        style={
          isAdmin
            ? {
              background: 'linear-gradient(135deg, rgba(245,158,11,0.18) 0%, rgba(217,119,6,0.14) 100%)',
              border: '1px solid rgba(245,158,11,0.2)',
              color: '#FDE68A',
            }
            : {
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid rgba(255,255,255,0.07)',
              color: '#D1D5DB',
            }
        }
      >
        <p className="whitespace-pre-wrap break-words">{msg.text}</p>
        <div className={`flex items-center gap-1 mt-1 ${isAdmin ? 'justify-end' : 'justify-start'}`}>
          <span style={{ fontSize: '10px', opacity: 0.45 }}>{formatTime(msg.timestamp)}</span>
          {isAdmin && (
            msg.read
              ? <CheckCheck style={{ width: 11, height: 11, opacity: 0.6, color: '#34D399' }} />
              : <Check style={{ width: 11, height: 11, opacity: 0.4 }} />
          )}
        </div>
      </div>
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────
export default function AdminChat() {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [search, setSearch] = useState('');
  const [unreadCounts, setUnreadCounts] = useState({});
  const bottomRef = useRef(null);

  // ── Admin Online Presence ──
  useEffect(() => {
    const onlineRef = ref(db, 'admin_status/online');
    set(onlineRef, true);
    const handleUnload = () => set(onlineRef, false);
    window.addEventListener('beforeunload', handleUnload);
    return () => {
      set(onlineRef, false);
      window.removeEventListener('beforeunload', handleUnload);
    };
  }, []);

  // Load all users
  useEffect(() => {
    const usersRef = ref(db, 'users');
    return onValue(usersRef, snap => {
      if (snap.exists()) {
        const arr = Object.entries(snap.val()).map(([uid, val]) => ({ uid, ...val }));
        setUsers(arr.sort((a, b) => (a.displayName || a.email || '').localeCompare(b.displayName || b.email || '')));
      }
    });
  }, []);

  // Track unread counts per user (messages where sender='user' and read=false)
  useEffect(() => {
    const unsubs = [];
    users.forEach(u => {
      const msgRef = ref(db, `admin_chats/${u.uid}/messages`);
      const unsub = onValue(msgRef, snap => {
        if (snap.exists()) {
          const msgs = Object.values(snap.val());
          const count = msgs.filter(m => m.sender === 'user' && !m.read).length;
          setUnreadCounts(prev => ({ ...prev, [u.uid]: count }));
        }
      });
      unsubs.push(unsub);
    });
    return () => unsubs.forEach(u => u());
  }, [users]);

  // Load messages for selected user & mark them as read
  useEffect(() => {
    if (!selectedUser) return;
    const msgRef = ref(db, `admin_chats/${selectedUser.uid}/messages`);
    const unsub = onValue(msgRef, snap => {
      if (snap.exists()) {
        const data = snap.val();
        const arr = Object.entries(data)
          .map(([id, val]) => ({ id, ...val }))
          .sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
        setMessages(arr);

        // Mark unread user messages as read
        arr.forEach(m => {
          if (m.sender === 'user' && !m.read) {
            update(ref(db, `admin_chats/${selectedUser.uid}/messages/${m.id}`), { read: true });
          }
        });
      } else {
        setMessages([]);
      }
    });
    return unsub;
  }, [selectedUser]);

  // Auto-scroll
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  async function sendMessage() {
    const text = input.trim();
    if (!text || !selectedUser) return;
    setInput('');
    const msgRef = ref(db, `admin_chats/${selectedUser.uid}/messages`);
    const newMsg = {
      text,
      sender: 'admin',
      timestamp: Date.now(),
      read: false,
    };
    await push(msgRef, newMsg);
    // Update conversation meta
    await set(ref(db, `admin_chats/${selectedUser.uid}/meta`), {
      lastMessage: text,
      lastTimestamp: Date.now(),
      lastSender: 'admin',
    });
  }

  function handleKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }

  const filtered = users.filter(u => {
    const q = search.toLowerCase();
    return (
      (u.displayName || '').toLowerCase().includes(q) ||
      (u.email || '').toLowerCase().includes(q)
    );
  });

  const isOnline = u => {
    if (!u.lastLogin) return false;
    return Date.now() - new Date(u.lastLogin).getTime() < 30 * 60 * 1000;
  };

  // Group messages by date
  const groupedMessages = messages.reduce((acc, msg) => {
    const dateKey = formatDate(msg.timestamp);
    if (!acc[dateKey]) acc[dateKey] = [];
    acc[dateKey].push(msg);
    return acc;
  }, {});

  return (
    <SuperAdminLayout>
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <MessageSquare className="w-5 h-5 text-amber-500" />
          <h1 className="text-2xl font-bold text-white">Messages</h1>
        </div>
        <p className="text-sm text-gray-500">Chat directly with teachers and users in real-time</p>
      </div>

      {/* Chat Layout */}
      <div
        className="flex rounded-2xl border border-white/5 overflow-hidden"
        style={{
          height: 'calc(100vh - 220px)',
          minHeight: 500,
          background: 'linear-gradient(135deg, rgba(15,12,25,0.97) 0%, rgba(20,15,30,0.95) 100%)',
        }}
      >
        {/* ── Left: Contact List ──────────────────────────────── */}
        <div className="w-80 flex-shrink-0 flex flex-col border-r border-white/5">
          {/* Search */}
          <div className="p-4 border-b border-white/5">
            <div
              className="flex items-center gap-2 px-3 py-2 rounded-xl"
              style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)' }}
            >
              <Search className="w-4 h-4 text-gray-500 flex-shrink-0" />
              <input
                className="flex-1 bg-transparent text-sm text-white placeholder-gray-600 outline-none"
                placeholder="Search users…"
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>

          {/* List */}
          <div className="flex-1 overflow-y-auto">
            {filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full gap-3 text-gray-600">
                <User className="w-8 h-8 opacity-40" />
                <p className="text-xs">No users found</p>
              </div>
            ) : (
              filtered.map(u => {
                const unread = unreadCounts[u.uid] || 0;
                const active = selectedUser?.uid === u.uid;
                const online = isOnline(u);
                return (
                  <button
                    key={u.uid}
                    onClick={() => setSelectedUser(u)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-left transition-all"
                    style={{
                      background: active
                        ? 'linear-gradient(135deg, rgba(245,158,11,0.1) 0%, rgba(217,119,6,0.06) 100%)'
                        : 'transparent',
                      borderRight: active ? '2px solid rgba(245,158,11,0.4)' : '2px solid transparent',
                    }}
                  >
                    <div className="relative">
                      <Avatar uid={u.uid} name={u.displayName || u.email} />
                      <div
                        className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2`}
                        style={{
                          borderColor: '#0A0A14',
                          background: online ? '#34D399' : '#4B5563',
                          boxShadow: online ? '0 0 6px rgba(52,211,153,0.6)' : 'none',
                        }}
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-semibold text-white truncate">
                          {u.displayName || u.email?.split('@')[0]}
                        </p>
                        {unread > 0 && (
                          <span
                            className="text-[10px] font-bold text-black px-1.5 py-0.5 rounded-full flex-shrink-0"
                            style={{ background: '#F59E0B' }}
                          >
                            {unread}
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-gray-500 truncate">{u.email}</p>
                      <p className="text-[10px] text-gray-600 capitalize mt-0.5">{u.role || 'user'}</p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* ── Right: Chat Window ──────────────────────────────── */}
        <div className="flex-1 flex flex-col">
          {selectedUser ? (
            <>
              {/* Chat Header */}
              <div
                className="px-6 py-4 flex items-center gap-3 border-b border-white/5 flex-shrink-0"
                style={{ background: 'rgba(255,255,255,0.01)' }}
              >
                <div className="relative">
                  <Avatar uid={selectedUser.uid} name={selectedUser.displayName || selectedUser.email} size="lg" />
                  <div
                    className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full border-2"
                    style={{
                      borderColor: '#0A0A14',
                      background: isOnline(selectedUser) ? '#34D399' : '#4B5563',
                      boxShadow: isOnline(selectedUser) ? '0 0 8px rgba(52,211,153,0.6)' : 'none',
                    }}
                  />
                </div>
                <div>
                  <p className="text-sm font-bold text-white">
                    {selectedUser.displayName || selectedUser.email?.split('@')[0]}
                  </p>
                  <div className="flex items-center gap-1.5 mt-0.5">
                    {isOnline(selectedUser)
                      ? <Wifi className="w-3 h-3 text-emerald-400" />
                      : <WifiOff className="w-3 h-3 text-gray-500" />}
                    <span className="text-[11px] text-gray-500">
                      {isOnline(selectedUser) ? 'Online' : 'Offline'}
                    </span>
                    <span className="text-gray-700 mx-1">•</span>
                    <span className="text-[11px] text-gray-600 capitalize">{selectedUser.role || 'user'}</span>
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto px-6 py-4">
                {Object.keys(groupedMessages).length === 0 ? (
                  <div className="flex flex-col items-center justify-center h-full gap-3 text-gray-600">
                    <MessageSquare className="w-10 h-10 opacity-30" />
                    <p className="text-sm">No messages yet. Say hello!</p>
                  </div>
                ) : (
                  Object.entries(groupedMessages).map(([dateKey, msgs]) => (
                    <div key={dateKey}>
                      {/* Date separator */}
                      <div className="flex items-center gap-3 my-4">
                        <div className="flex-1 h-px bg-white/5" />
                        <span
                          className="text-[10px] font-semibold text-gray-600 uppercase tracking-widest px-2 py-1 rounded-md"
                          style={{ background: 'rgba(255,255,255,0.03)' }}
                        >
                          {dateKey}
                        </span>
                        <div className="flex-1 h-px bg-white/5" />
                      </div>
                      {msgs.map(msg => (
                        <AnimatePresence key={msg.id}>
                          <motion.div
                            initial={{ opacity: 0, y: 6 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.2 }}
                          >
                            <MessageBubble msg={msg} isAdmin={msg.sender === 'admin'} />
                          </motion.div>
                        </AnimatePresence>
                      ))}
                    </div>
                  ))
                )}
                <div ref={bottomRef} />
              </div>

              {/* Input Bar */}
              <div className="px-6 py-4 border-t border-white/5 flex-shrink-0">
                <div
                  className="flex items-end gap-3 rounded-2xl px-4 py-3"
                  style={{
                    background: 'rgba(255,255,255,0.04)',
                    border: '1px solid rgba(255,255,255,0.07)',
                  }}
                >
                  <textarea
                    className="flex-1 bg-transparent text-sm text-white placeholder-gray-600 outline-none resize-none leading-relaxed"
                    style={{ maxHeight: 120 }}
                    rows={1}
                    placeholder={`Message ${selectedUser.displayName || selectedUser.email?.split('@')[0]}…`}
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={handleKeyDown}
                    onInput={e => {
                      e.target.style.height = 'auto';
                      e.target.style.height = `${Math.min(e.target.scrollHeight, 120)}px`;
                    }}
                  />
                  <button
                    onClick={sendMessage}
                    disabled={!input.trim()}
                    className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 transition-all"
                    style={{
                      background: input.trim()
                        ? 'linear-gradient(135deg, #F59E0B, #D97706)'
                        : 'rgba(255,255,255,0.05)',
                      boxShadow: input.trim() ? '0 4px 15px rgba(245,158,11,0.3)' : 'none',
                      opacity: input.trim() ? 1 : 0.4,
                    }}
                  >
                    <Send className="w-4 h-4 text-white" />
                  </button>
                </div>
                <p className="text-[10px] text-gray-700 mt-2 text-center">
                  Press <kbd className="text-gray-500">Enter</kbd> to send · <kbd className="text-gray-500">Shift+Enter</kbd> for new line
                </p>
              </div>
            </>
          ) : (
            /* Empty state */
            <div className="flex-1 flex flex-col items-center justify-center gap-4 text-gray-600">
              <div
                className="w-16 h-16 rounded-2xl flex items-center justify-center"
                style={{ background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.12)' }}
              >
                <MessageSquare className="w-8 h-8 text-amber-500/50" />
              </div>
              <div className="text-center">
                <p className="text-sm font-semibold text-gray-400">No conversation selected</p>
                <p className="text-xs mt-1">Pick a user from the list to start chatting</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </SuperAdminLayout>
  );
}
