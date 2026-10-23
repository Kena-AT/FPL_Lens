import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

enum AvailabilityVariant {
  fit,
  doubtful,
  injured,
  suspended;

  static AvailabilityVariant fromFplStatus(String? status) {
    if (status == null) return AvailabilityVariant.fit;
    switch (status.toLowerCase()) {
      case 'd':
        return AvailabilityVariant.doubtful;
      case 'i':
        return AvailabilityVariant.injured;
      case 's':
        return AvailabilityVariant.suspended;
      case 'u':
      case 'n':
        return AvailabilityVariant.injured;
      case 'a':
      default:
        return AvailabilityVariant.fit;
    }
  }
}

/// D10 AvailabilityBadge per Frontend Implementation Plan §D10.
/// Displays status dot + icon + text badge. Never relies on colour alone.
class AvailabilityBadge extends StatelessWidget {
  final AvailabilityVariant variant;
  final int? chanceOfPlaying;
  final String? news;
  final String? newsTimestamp;
  final bool showNews;

  const AvailabilityBadge({
    super.key,
    required this.variant,
    this.chanceOfPlaying,
    this.news,
    this.newsTimestamp,
    this.showNews = false,
  });

  factory AvailabilityBadge.fromStatus({
    Key? key,
    required String? status,
    int? chanceOfPlaying,
    String? news,
    String? newsTimestamp,
    bool showNews = false,
  }) {
    return AvailabilityBadge(
      key: key,
      variant: AvailabilityVariant.fromFplStatus(status),
      chanceOfPlaying: chanceOfPlaying,
      news: news,
      newsTimestamp: newsTimestamp,
      showNews: showNews,
    );
  }

  Color get _statusColor {
    switch (variant) {
      case AvailabilityVariant.fit:
        return AppTokens.statusAvailable;
      case AvailabilityVariant.doubtful:
        return AppTokens.statusDoubtful;
      case AvailabilityVariant.injured:
      case AvailabilityVariant.suspended:
        return AppTokens.statusOut;
    }
  }

  IconData get _icon {
    switch (variant) {
      case AvailabilityVariant.fit:
        return Icons.check_circle_rounded;
      case AvailabilityVariant.doubtful:
        return Icons.warning_rounded;
      case AvailabilityVariant.injured:
        return Icons.cancel_rounded;
      case AvailabilityVariant.suspended:
        return Icons.block_rounded;
    }
  }

  String get _label {
    switch (variant) {
      case AvailabilityVariant.fit:
        return 'Fit';
      case AvailabilityVariant.doubtful:
        if (chanceOfPlaying != null) {
          return 'Doubtful, $chanceOfPlaying%';
        }
        return 'Doubtful';
      case AvailabilityVariant.injured:
        return 'Injured';
      case AvailabilityVariant.suspended:
        return 'Suspended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppTokens.space4),
          Text(
            _label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (!showNews || (news == null || news!.trim().isEmpty)) {
      return Semantics(
        label: 'Availability: $_label',
        child: badge,
      );
    }

    return Semantics(
      label: 'Availability: $_label. News: $news',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(height: AppTokens.space8),
          Container(
            padding: const EdgeInsets.all(AppTokens.space12),
            decoration: BoxDecoration(
              color: AppTokens.bgElevated,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppTokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news!,
                  style: AppTextStyles.body.copyWith(
                    color: AppTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Row(
                  children: [
                    if (newsTimestamp != null && newsTimestamp!.isNotEmpty) ...[
                      Text(
                        newsTimestamp!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppTokens.textDisabled,
                        ),
                      ),
                      const SizedBox(width: AppTokens.space8),
                    ],
                    Text(
                      'Source: FPL',
                      style: AppTextStyles.caption.copyWith(
                        color: AppTokens.textDisabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
