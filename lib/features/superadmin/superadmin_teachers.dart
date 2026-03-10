import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SuperAdminTeachers extends StatefulWidget {
  const SuperAdminTeachers({super.key});

  @override
  State<SuperAdminTeachers> createState() => _SuperAdminTeachersState();
}

class _SuperAdminTeachersState extends State<SuperAdminTeachers> {
  static const _gold = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _teachers = [];
  String _search = '';
  String _filter = 'all'; // all, online, offline
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseDatabase.instance.ref('users').onValue.listen((event) {
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
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _isOnline(Map<String, dynamic> t) {
    final lastLogin = t['lastLogin'];
    if (lastLogin == null) return false;
    final ts = DateTime.tryParse(lastLogin.toString())?.millisecondsSinceEpoch ?? 0;
    return DateTime.now().millisecondsSinceEpoch - ts < 30 * 60 * 1000;
  }

  List<Map<String, dynamic>> get _filtered {
    return _teachers.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final email = (t['email'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(_search.toLowerCase()) || email.contains(_search.toLowerCase());
      if (_filter == 'online') return matchesSearch && _isOnline(t);
      if (_filter == 'offline') return matchesSearch && !_isOnline(t);
      return matchesSearch;
    }).toList();
  }

  Future<void> _deleteTeacher(Map<String, dynamic> teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Remove Teacher', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${teacher['name'] ?? teacher['email']}? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseDatabase.instance.ref('users/${teacher['uid']}').remove();
      await FirebaseDatabase.instance.ref('pending_approvals/${teacher['uid']}').remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${teacher['name'] ?? 'Teacher'} removed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _teachers.where(_isOnline).length;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_rounded, color: _gold, size: 22),
                    const SizedBox(width: 10),
                    const Text('Teachers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_teachers.length} registered • $onlineCount online',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                Row(
                  children: ['all', 'online', 'offline'].map((f) {
                    final isActive = _filter == f;
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (f == 'online') Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
                              if (f == 'offline') Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2))),
                              Text(
                                f[0].toUpperCase() + f.substring(1),
                                style: TextStyle(
                                  color: isActive ? _gold : Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Teacher List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_rounded, color: Colors.white.withValues(alpha: 0.1), size: 48),
                        const SizedBox(height: 12),
                        Text('No teachers found', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) => _buildTeacherCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final online = _isOnline(teacher);
    final name = teacher['name'] ?? 'Unnamed';
    final email = teacher['email'] ?? 'No email';
    final isApproved = teacher['isApproved'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: online ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: online ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: online ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.4),
                  fontSize: 16, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              ],
            ),
          ),

          // Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    online ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: online ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.3),
                      fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isApproved ? '✓ Approved' : '⏳ Pending',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Delete
          GestureDetector(
            onTap: () => _deleteTeacher(teacher),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.white.withValues(alpha: 0.2), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
