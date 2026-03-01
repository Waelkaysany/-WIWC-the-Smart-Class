import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../theme/tokens.dart';
import '../services/ai_chat_service.dart';

/// A premium card widget for confirming/cancelling AI-proposed device actions.
class ActionProposalCard extends StatelessWidget {
  final ActionProposal proposal;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ActionProposalCard({
    super.key,
    required this.proposal,
    required this.onConfirm,
    required this.onCancel,
  });

  IconData _getDeviceIcon(String deviceId) {
    switch (deviceId) {
      case 'lights':
        return Icons.lightbulb_outline;
      case 'door':
        return Icons.lock_outline;
      case 'projector':
        return Icons.videocam_outlined;
      case 'board':
        return Icons.desktop_windows_outlined;
      case 'ac':
        return Icons.ac_unit;
      case 'speakers':
        return Icons.speaker_outlined;
      case 'window_left':
      case 'window_right':
        return Icons.window_outlined;
      default:
        return Icons.devices_other;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'on':
      case 'open':
        return const Color(0xFF00E676);
      case 'off':
      case 'close':
        return const Color(0xFFFF5252);
      default:
        return const Color(0xFF448AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = proposal.isConfirmed || proposal.isCancelled;
    final actionColor = _getActionColor(proposal.action);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            actionColor.withValues(alpha: 0.08),
            context.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: actionColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: actionColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getDeviceIcon(proposal.deviceId),
                    color: actionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action Proposal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: actionColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        proposal.deviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? (proposal.isConfirmed
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15))
                        : actionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isResolved
                        ? (proposal.isConfirmed ? '✅ Done' : '❌ Cancelled')
                        : '⏳ Pending',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isResolved
                              ? (proposal.isConfirmed
                                  ? const Color(0xFF00E676)
                                  : Colors.grey)
                              : actionColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Description
            Text(
              proposal.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
            ),

            // Action row
            if (!isResolved) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
