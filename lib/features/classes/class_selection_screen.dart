import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../state/class_providers.dart';
import '../../state/profile_pic_provider.dart';
import '../../state/theme_provider.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/classroom.dart';
import '../../services/firebase_service.dart';
import '../profile/profile_screen.dart';
import 'class_dashboard_shell.dart';

class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  ConsumerState<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _searchQuery = '';

  // Premium classroom images (using gradient combos as placeholders since no assets)
  static const List<List<Color>> _classGradients = [
    [Color(0xFF1A6B5A), Color(0xFF2BC89B)],
    [Color(0xFF4A6FA5), Color(0xFF6B8DD6)],
    [Color(0xFF9B59B6), Color(0xFFD977BF)],
    [Color(0xFFE67E22), Color(0xFFF1C40F)],
    [Color(0xFF2C3E50), Color(0xFF3498DB)],
    [Color(0xFFE74C3C), Color(0xFFF39C12)],
    [Color(0xFF16A085), Color(0xFF2ECC71)],
    [Color(0xFF8E44AD), Color(0xFF3498DB)],
  ];

  static const List<IconData> _classIcons = [
    Icons.science_rounded,
    Icons.computer_rounded,
    Icons.palette_rounded,
    Icons.history_edu_rounded,
    Icons.calculate_rounded,
    Icons.sports_soccer_rounded,
    Icons.music_note_rounded,
    Icons.language_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final classrooms = ref.watch(classroomsStreamProvider);
    final filter = ref.watch(classFilterProvider);
    final profilePicPath = ref.watch(profilePicProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Teacher';

    final bg = isDark
        ? const Color(0xFF0F1115)
        : const Color(0xFFF5F7FA);
    final cardBg = isDark
        ? const Color(0xFF1A1F2B)
        : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A202C);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF718096);

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Your Session',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to monitor smart devices?',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Toggle search
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Icon(Icons.search_rounded, color: textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search classrooms...',
                      hintStyle: TextStyle(color: textSecondary.withAlpha(120)),
                      prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // ── Filter Chips ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 0, 8),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _FilterChip(
                        label: 'All Classes',
                        isActive: filter == 'All Classes',
                        isDark: isDark,
                        onTap: () => ref.read(classFilterProvider.notifier).state = 'All Classes',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Available',
                        isActive: filter == 'Available',
                        isDark: isDark,
                        onTap: () => ref.read(classFilterProvider.notifier).state = 'Available',
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Taken',
                        isActive: filter == 'Taken',
                        isDark: isDark,
                        onTap: () => ref.read(classFilterProvider.notifier).state = 'Taken',
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
              ),

              // ── Classroom Grid ──
              Expanded(
                child: classrooms.when(
                  data: (rooms) {
                    var filtered = rooms;
                    if (filter == 'Available') {
                      filtered = rooms.where((r) => r.isAvailable).toList();
                    } else if (filter == 'Taken') {
                      filtered = rooms.where((r) => r.isTaken).toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((r) =>
                          r.name.toLowerCase().contains(_searchQuery) ||
                          r.grade.toLowerCase().contains(_searchQuery) ||
                          r.subject.toLowerCase().contains(_searchQuery)
                      ).toList();
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.meeting_room_outlined, size: 64, color: textSecondary.withAlpha(80)),
                            const SizedBox(height: 16),
                            Text('No classrooms found', style: TextStyle(color: textSecondary, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _ClassCard(
                        room: filtered[i],
                        gradient: _classGradients[filtered[i].imageIndex % _classGradients.length],
                        icon: _classIcons[filtered[i].imageIndex % _classIcons.length],
                        isDark: isDark,
                        onTap: () => _handleClassTap(filtered[i]),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error loading classrooms: $e',
                        style: TextStyle(color: textSecondary)),
                  ),
                ),
              ),

              // ── Bottom Teacher Info Bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile picture
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.secondaryGradient,
                      ),
                      child: profilePicPath != null && File(profilePicPath).existsSync()
                          ? ClipOval(
                              child: Image.file(File(profilePicPath),
                                  fit: BoxFit.cover, width: 48, height: 48),
                            )
                          : Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          classrooms.when(
                            data: (rooms) {
                              final activeCount = rooms.where((r) => r.isTaken).length;
                              return Text(
                                'ACTIVE SESSIONS: ${activeCount.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                            loading: () => Text('Loading...', style: TextStyle(color: textSecondary, fontSize: 12)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    // Profile icon
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClassTap(ClassRoom room) async {
    if (room.isTaken) {
      final takenName = room.takenBy?.name ?? 'Unknown';
      final sinceStr = room.takenBy?.sinceFormatted ?? '';
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1F2B)
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text('Class Taken'),
            ],
          ),
          content: Text(
            'This class is currently taken by $takenName ($sinceStr).\n\nPlease wait until they finish or choose another class.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading + enter
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final service = ref.read(classSessionServiceProvider);
    final success = await service.enterClass(room.id);

    if (mounted) Navigator.pop(context); // dismiss loading

    if (success) {
      ref.read(activeClassIdProvider.notifier).state = room.id;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ClassDashboardShell(classId: room.id, className: room.name),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to enter class. It may already be taken.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


}

// ── Filter Chip Widget ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? const Color(0xFF1A1F2B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF718096)),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Class Card Widget ──
class _ClassCard extends StatefulWidget {
  final ClassRoom room;
  final List<Color> gradient;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ClassCard({
    required this.room,
    required this.gradient,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient with icon pattern
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle pattern overlay
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          widget.icon,
                          size: 120,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                      Positioned(
                        left: -10,
                        bottom: -10,
                        child: Icon(
                          widget.icon,
                          size: 80,
                          color: Colors.white.withAlpha(10),
                        ),
                      ),
                    ],
                  ),
                ),

                // Gradient overlay for text readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(120),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // Room badge
                if (widget.room.grade.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.room.grade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.room.isAvailable
                          ? const Color(0xFF2BC89B)
                          : AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.room.isAvailable
                                  ? const Color(0xFF2BC89B)
                                  : AppColors.error)
                              .withAlpha(130),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // Lock icon if taken
                if (widget.room.isTaken)
                  Positioned(
                    top: 10,
                    right: 28,
                    child: Icon(Icons.lock_rounded, color: Colors.white.withAlpha(180), size: 14),
                  ),

                // Content
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.room.isAvailable
                                  ? const Color(0xFF2BC89B)
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.room.isTaken
                                  ? 'Taken by ${widget.room.takenBy?.name ?? "..."}'
                                  : 'Available',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
