import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  static const _gold = Color(0xFFF59E0B);
  static const _goldDark = Color(0xFFD97706);

  List<Map<String, dynamic>> _teachers = [];
  Map<String, dynamic> _classrooms = {};
  List<Map<String, dynamic>> _supportRequests = [];
  final _subs = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final db = FirebaseDatabase.instance;

    _subs.add(db.ref('users').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _teachers = data.entries
              .map((e) => {'uid': e.key, ...Map<String, dynamic>.from(e.value as Map)})
              .where((u) => u['role'] == 'teacher')
              .toList();
        });
      }
    }));

    _subs.add(db.ref('classrooms').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        setState(() => _classrooms = Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    }));

    _subs.add(db.ref('support_requests').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _supportRequests = data.entries
              .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)})
              .toList()
            ..sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        });
      } else {
        setState(() => _supportRequests = []);
      }
    }));
  }

  @override
  void dispose() {
    for (final sub in _subs) sub.cancel();
    super.dispose();
  }

  int get _onlineCount {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _teachers.where((t) {
      final lastLogin = t['lastLogin'];
      if (lastLogin == null) return false;
      final ts = DateTime.tryParse(lastLogin.toString())?.millisecondsSinceEpoch ?? 0;
      return now - ts < 30 * 60 * 1000;
    }).length;
  }

  int get _takenClasses =>
      _classrooms.values.where((c) => (c as Map)['status'] == 'taken').length;

  int get _openTickets =>
      _supportRequests.where((r) => r['status'] == 'open').length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFCD34D), _gold],
                      ).createShader(b),
                      child: const Text(
                        'Command Center',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      'Real-time ecosystem overview',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),
                // Logout
                IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: Icon(Icons.logout_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  tooltip: 'Log Out',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Teachers',
                  value: '${_teachers.length}',
                  icon: Icons.people_rounded,
                  gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  sub: '$_onlineCount online',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Online Now',
                  value: '$_onlineCount',
                  icon: Icons.wifi_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  sub: 'Last 30 min',
                  pulse: true,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Classes In Use',
                  value: '$_takenClasses',
                  icon: Icons.meeting_room_rounded,
                  gradient: const [_gold, _goldDark],
                  sub: 'of ${_classrooms.length} total',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Open Tickets',
                  value: '$_openTickets',
                  icon: Icons.error_outline_rounded,
                  gradient: _openTickets > 0
                      ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                      : const [Color(0xFF6B7280), Color(0xFF4B5563)],
                  sub: _openTickets > 0 ? 'Needs attention' : 'All clear',
                )),
              ],
            ),

            const SizedBox(height: 24),

            // Classroom Status
            _SectionHeader(title: 'Classroom Status', icon: Icons.school_rounded),
            const SizedBox(height: 12),
            _buildClassroomGrid(),

            const SizedBox(height: 24),

            // Recent Support Tickets
            if (_supportRequests.isNotEmpty) ...[
              _SectionHeader(title: 'Latest Support Tickets', icon: Icons.support_agent_rounded),
              const SizedBox(height: 12),
              ..._supportRequests.take(3).map(_buildTicketCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomGrid() {
    if (_classrooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Center(child: Text('No classrooms', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: _classrooms.length,
      itemBuilder: (context, i) {
        final entry = _classrooms.entries.toList()[i];
        final room = Map<String, dynamic>.from(entry.value as Map);
        final isTaken = room['status'] == 'taken';
        final takenBy = room['takenBy'] as Map?;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isTaken ? _gold.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTaken ? _gold.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room['name'] ?? entry.key,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTaken ? _gold : const Color(0xFF10B981),
                      boxShadow: [BoxShadow(color: (isTaken ? _gold : const Color(0xFF10B981)).withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                  ),
                ],
              ),
              Text(room['grade'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600)),
              if (takenBy != null)
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 12, color: _gold.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (takenBy['name'] ?? 'Unknown').toString(),
                        style: TextStyle(color: _gold.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Text('Available', style: TextStyle(color: const Color(0xFF10B981).withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final priorityColors = {
      'critical': const Color(0xFFEF4444),
      'high': const Color(0xFFF97316),
      'medium': _gold,
      'low': const Color(0xFF3B82F6),
    };
    final color = priorityColors[ticket['priority']] ?? _gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${ticket['teacherName'] ?? 'Unknown'} • ${ticket['source'] == 'ai' ? '🤖 AI' : '👤 Teacher'}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              (ticket['priority'] ?? 'medium').toString().toUpperCase(),
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final List<Color> gradient;
  final bool pulse;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.sub,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.25), blurRadius: 10)],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const Spacer(),
              if (pulse) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: gradient.first)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600)),
          Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 9)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  static const _gold = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
