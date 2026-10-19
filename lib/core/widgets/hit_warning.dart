import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Component D15: HitWarning (Frontend Implementation Plan §4.1, Spec §6.2).
/// Displays clear warning and points penalty when transfers exceed free allowance.
class HitWarning extends StatelessWidget {
  final int hitCost; // e.g. 4, 8, 12
  final int transferCount;
  final int freeTransfers;
  final VoidCallback? onDismiss;

  const HitWarning({
    super.key,
    required this.hitCost,
    required this.transferCount,
    required this.freeTransfers,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (hitCost <= 0) return const SizedBox.shrink();

    final extraTransfers = transferCount - freeTransfers;
    final message = extraTransfers == 1
        ? '1 transfer exceeds your free transfer allowance.'
        : '$extraTransfers transfers exceed your free transfer allowance.';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.statusDoubtful.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: AppTokens.statusDoubtful.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.space8),
            decoration: BoxDecoration(
              color: AppTokens.statusDoubtful.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTokens.statusDoubtful,
              size: 20.0,
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Hit Penalty: -$hitCost pts',
                      style: AppTextStyles.label.copyWith(
                        color: AppTokens.statusDoubtful,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18.0),
              color: AppTokens.textSecondary,
              onPressed: onDismiss,
              tooltip: 'Dismiss warning',
            ),
        ],
      ),
    );
  }
}
