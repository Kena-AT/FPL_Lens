import 'package:flutter/material.dart';
import '../formatting/app_formatters.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

class FreshnessLabel extends StatelessWidget {
  final DateTime lastUpdated;
  final Duration staleThreshold;
  final String? customLabel;

  const FreshnessLabel({
    super.key,
    required this.lastUpdated,
    this.staleThreshold = const Duration(minutes: 60),
    this.customLabel,
  });

  bool get isStale => DateTime.now().difference(lastUpdated) > staleThreshold;

  @override
  Widget build(BuildContext context) {
    final stale = isStale;
    final dotColor = stale ? AppTokens.statusDoubtful : AppTokens.statusAvailable;
    final relative = AppFormatters.formatRelativeTime(lastUpdated);

    final text = customLabel ??
        (stale
            ? 'Stale: ${relative.toLowerCase()}. Projections may be out of date'
            : relative);

    return Semantics(
      label: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: stale ? AppTokens.statusDoubtful : AppTokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
