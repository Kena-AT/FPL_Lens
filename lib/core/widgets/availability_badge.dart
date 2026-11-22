import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

enum AvailabilityVariant {
  fit,
  doubtful,
  injured,
  suspended,
  unknown;

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
        return AvailabilityVariant.fit;
      default:
        return AvailabilityVariant.fit;
    }
  }
}

/// AvailabilityBadge per Visual Redesign Design Document §6.1 & §16.
///
/// Refactored from bulky pill to subtle 6dp dot + icon + label.
/// Never relies on colour alone.
class AvailabilityBadge extends StatelessWidget {
  final AvailabilityVariant variant;
  final int? chanceOfPlaying;
  final String? news;
  final String? newsTimestamp;
  final bool showNews;
  final bool compact;
  final String? customLabel;

  const AvailabilityBadge({
    super.key,
    required this.variant,
    this.chanceOfPlaying,
    this.news,
    this.newsTimestamp,
    this.showNews = false,
    this.compact = false,
    this.customLabel,
  });

  factory AvailabilityBadge.fromStatus({
    Key? key,
    required String? status,
    int? chanceOfPlaying,
    String? news,
    String? newsTimestamp,
    bool showNews = false,
    bool compact = false,
    String? customLabel,
  }) {
    return AvailabilityBadge(
      key: key,
      variant: AvailabilityVariant.fromFplStatus(status),
      chanceOfPlaying: chanceOfPlaying,
      news: news,
      newsTimestamp: newsTimestamp,
      showNews: showNews,
      compact: compact,
      customLabel: customLabel,
    );
  }

  Color _getColor(AppColors colors) {
    switch (variant) {
      case AvailabilityVariant.fit:
        return colors.statusOk;
      case AvailabilityVariant.doubtful:
        return colors.statusWarn;
      case AvailabilityVariant.injured:
      case AvailabilityVariant.suspended:
        return colors.statusError;
      case AvailabilityVariant.unknown:
        return colors.textSecondary;
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
      case AvailabilityVariant.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get _label {
    if (customLabel != null) return customLabel!;
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
      case AvailabilityVariant.unknown:
        return 'No data';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = _getColor(colors);

    // Subtle 6dp dot with icon and text per §6.1 & §16
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space4 : AppTokens.space8,
        vertical: AppTokens.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 6dp status dot (§16 requirement)
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTokens.space4),
            Icon(
              _icon,
              size: compact ? 12.0 : 14.0,
              color: color,
            ),
            const SizedBox(width: AppTokens.space4),
            Text(
              _label,
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11.0 : 12.0,
              ),
            ),
          ],
        ),
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
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news!,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Row(
                  children: [
                    if (newsTimestamp != null && newsTimestamp!.isNotEmpty) ...[
                      Text(
                        newsTimestamp!,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.textDisabled,
                        ),
                      ),
                      const SizedBox(width: AppTokens.space8),
                    ],
                    Text(
                      'Source: FPL',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textDisabled,
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
