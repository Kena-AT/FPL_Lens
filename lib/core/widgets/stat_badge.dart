import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Size variants for [StatBadge] per Visual Redesign Design Document §16.
enum StatBadgeSize {
  /// 64sp/800 hero numeral for top-level projections and ranks
  hero,

  /// 24sp/700 display numeral for key metrics and secondary heroes
  large,

  /// 18sp/600 figure numeral for card stats and list data
  medium,

  /// 12sp/500 label numeral for compact chips and tight grids
  small,
}

/// Unified component for all statistical metrics across FPL Lens.
/// Enforces tabular numerals, scale contrast, and accessible labels.
class StatBadge extends StatelessWidget {
  final String value;
  final String? label;
  final String? unit;
  final IconData? icon;
  final StatBadgeSize size;
  final Color? color;
  final bool accented;
  final bool vertical;
  final String? semanticLabel;

  const StatBadge({
    super.key,
    required this.value,
    this.label,
    this.unit,
    this.icon,
    this.size = StatBadgeSize.medium,
    this.color,
    this.accented = false,
    this.vertical = true,
    this.semanticLabel,
  });

  TextStyle _getValueStyle(AppColors colors) {
    final effectiveColor = color ?? (accented ? colors.accent : colors.textPrimary);

    switch (size) {
      case StatBadgeSize.hero:
        return AppTextStyles.heroNumeral.copyWith(color: effectiveColor);
      case StatBadgeSize.large:
        return AppTextStyles.display.copyWith(
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
          color: effectiveColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
      case StatBadgeSize.medium:
        return AppTextStyles.figure.copyWith(color: effectiveColor);
      case StatBadgeSize.small:
        return AppTextStyles.label.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: effectiveColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    }
  }

  TextStyle _getLabelStyle(AppColors colors) {
    switch (size) {
      case StatBadgeSize.hero:
        return AppTextStyles.subtitle.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        );
      case StatBadgeSize.large:
        return AppTextStyles.body.copyWith(
          color: colors.textSecondary,
          fontSize: 13.0,
        );
      case StatBadgeSize.medium:
        return AppTextStyles.label.copyWith(color: colors.textSecondary);
      case StatBadgeSize.small:
        return AppTextStyles.caption.copyWith(
          color: colors.textSecondary,
          fontSize: 10.0,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case StatBadgeSize.hero:
        return 32.0;
      case StatBadgeSize.large:
        return 20.0;
      case StatBadgeSize.medium:
        return 16.0;
      case StatBadgeSize.small:
        return 12.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final valueStyle = _getValueStyle(colors);
    final labelStyle = _getLabelStyle(colors);
    final iconSize = _getIconSize();

    Widget valueRow = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: valueStyle.color,
            ),
            SizedBox(width: size == StatBadgeSize.hero ? AppTokens.space8 : AppTokens.space4),
          ],
          Text(
            value,
            style: valueStyle,
          ),
          if (unit != null && unit!.isNotEmpty) ...[
            const SizedBox(width: AppTokens.space2),
            Text(
              unit!,
              style: labelStyle.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    Widget content;
    if (label != null && label!.isNotEmpty) {
      if (vertical) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            valueRow,
            const SizedBox(height: AppTokens.space2),
            Text(
              label!,
              style: labelStyle,
            ),
          ],
        );
      } else {
        content = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label!,
                style: labelStyle,
              ),
              const SizedBox(width: AppTokens.space8),
              valueRow,
            ],
          ),
        );
      }
    } else {
      content = valueRow;
    }

    final accessibleText = semanticLabel ??
        (label != null ? '$label: $value ${unit ?? ""}'.trim() : '$value ${unit ?? ""}'.trim());

    return Semantics(
      label: accessibleText,
      child: content,
    );
  }
}
