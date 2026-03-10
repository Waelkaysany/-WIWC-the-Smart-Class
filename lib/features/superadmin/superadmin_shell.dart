import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'superadmin_dashboard.dart';
import 'superadmin_teachers.dart';
import 'superadmin_support.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _currentTab = 0;

  static const _gold = Color(0xFFF59E0B);
  static const _goldDark = Color(0xFFD97706);

  final _pages = const [
    SuperAdminDashboard(),
    SuperAdminTeachers(),
    SuperAdminSupport(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A14), Color(0xFF0F1115)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(
          index: _currentTab,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A),
          border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.08), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Teachers',
                  isActive: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                ),
                _NavItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  isActive: _currentTab == 2,
                  onTap: () => setState(() => _currentTab = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const _gold = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _gold.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: _gold.withValues(alpha: 0.15)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _gold : Colors.white.withValues(alpha: 0.3),
              size: 22,
              shadows: isActive
                  ? [Shadow(color: _gold.withValues(alpha: 0.5), blurRadius: 12)]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _gold : Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
