import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Component D9: XpBadge (Spec §5, Frontend Implementation Plan §4.1).
/// Displays deterministic expected points with clear aesthetic styling.
class XpBadge extends StatelessWidget {
  final double xp;
  final bool isCompact;
  final bool showLabel;
  final Color? customBackground;

  const XpBadge({
    super.key,
    required this.xp,
    this.isCompact = false,
    this.showLabel = true,
    this.customBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    // Curated aesthetic tint based on xP range (Visual Redesign §4.1 & §8.9)
    Color badgeColor;
    Color textColor;

    if (xp >= 6.0) {
      badgeColor = colors.statusOk.withValues(alpha: 0.15);
      textColor = colors.statusOk;
    } else if (xp >= 4.0) {
      badgeColor = colors.accent.withValues(alpha: 0.15);
      textColor = colors.accent;
    } else if (xp >= 2.0) {
      badgeColor = colors.statusWarn.withValues(alpha: 0.15);
      textColor = colors.statusWarn;
    } else {
      badgeColor = colors.statusError.withValues(alpha: 0.15);
      textColor = colors.statusError;
    }

    final displayText = showLabel
        ? '${xp.toStringAsFixed(1)} xP'
        : xp.toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6.0 : 8.0,
        vertical: isCompact ? 2.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: customBackground ?? badgeColor,
        borderRadius: BorderRadius.circular(isCompact ? 4.0 : 6.0),
        border: Border.all(
          color: (customBackground ?? textColor).withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: isCompact ? 10.0 : 12.0,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
