import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SuperAdminSupport extends StatefulWidget {
  const SuperAdminSupport({super.key});

  @override
  State<SuperAdminSupport> createState() => _SuperAdminSupportState();
}

class _SuperAdminSupportState extends State<SuperAdminSupport> {
  static const _gold = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _requests = [];
  String _filter = 'all'; // all, open, in_progress, resolved
  String? _expandedId;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('support_requests').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _requests = data.entries
              .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)})
              .toList()
            ..sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));
        });
      } else {
        setState(() => _requests = []);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await FirebaseDatabase.instance.ref('support_requests/$id').update({
      'status': newStatus,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r['status'] == _filter).toList();
  }

  static const _priorityColors = {
    'critical': Color(0xFFEF4444),
    'high': Color(0xFFF97316),
    'medium': Color(0xFFF59E0B),
    'low': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    final openCount = _requests.where((r) => r['status'] == 'open').length;
    final inProgCount = _requests.where((r) => r['status'] == 'in_progress').length;
    final resolvedCount = _requests.where((r) => r['status'] == 'resolved').length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    const Text('Support Requests', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage teacher issues and AI reports',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Quick Stats
                Row(
                  children: [
                    _MiniStat(label: 'Open', count: openCount, color: _gold),
                    const SizedBox(width: 8),
                    _MiniStat(label: 'In Progress', count: inProgCount, color: const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _MiniStat(label: 'Resolved', count: resolvedCount, color: const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 14),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'open', 'in_progress', 'resolved'].map((f) {
                      final isActive = _filter == f;
                      final label = f == 'in_progress' ? 'In Progress' : f[0].toUpperCase() + f.substring(1);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? _gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive ? _gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Text(label,
                              style: TextStyle(
                                color: isActive ? _gold : Colors.white.withValues(alpha: 0.4),
                                fontSize: 11, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Tickets List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white.withValues(alpha: 0.1), size: 48),
                        const SizedBox(height: 12),
                        Text('No tickets', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                        Text('All clear!', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) => _buildTicketCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final isExpanded = _expandedId == ticket['id'];
    final color = _priorityColors[ticket['priority']] ?? _gold;
    final isAi = ticket['source'] == 'ai';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isExpanded ? 0.04 : 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? _gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expandedId = isExpanded ? null : ticket['id']),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(width: 3, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isAi ? const Color(0xFFA855F7) : Colors.white).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
                      color: isAi ? const Color(0xFFA855F7) : Colors.white.withValues(alpha: 0.4),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ticket['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${ticket['teacherName'] ?? 'Unknown'} • ${ticket['createdAt'] != null ? _formatDate(ticket['createdAt']) : ''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      (ticket['priority'] ?? 'medium').toString().toUpperCase(),
                      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.2), size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.03),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    ticket['description'] ?? 'No description provided.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 12),

                  // Reporter details
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Row(
                      children: [
                        Icon(isAi ? Icons.smart_toy_rounded : Icons.person_rounded,
                            color: Colors.white.withValues(alpha: 0.3), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '${ticket['teacherName'] ?? 'Unknown'} (${ticket['teacherEmail'] ?? ''}) • ${isAi ? 'AI Report' : 'Teacher Report'}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Text('Update Status', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (ticket['status'] != 'in_progress')
                        Expanded(child: _ActionButton(
                          label: 'In Progress',
                          icon: Icons.play_circle_outline_rounded,
                          color: const Color(0xFF3B82F6),
                          onTap: () => _updateStatus(ticket['id'], 'in_progress'),
                        )),
                      if (ticket['status'] != 'in_progress' && ticket['status'] != 'resolved')
                        const SizedBox(width: 8),
                      if (ticket['status'] != 'resolved')
                        Expanded(child: _ActionButton(
                          label: 'Resolved',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _updateStatus(ticket['id'], 'resolved'),
                        )),
                      if (ticket['status'] != 'open') ...[
                        const SizedBox(width: 8),
                        Expanded(child: _ActionButton(
                          label: 'Reopen',
                          icon: Icons.replay_rounded,
                          color: _gold,
                          onTap: () => _updateStatus(ticket['id'], 'open'),
                        )),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MiniStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
