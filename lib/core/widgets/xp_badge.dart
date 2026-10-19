import 'package:flutter/material.dart';
import '../theme/tokens.dart';

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
    // Curated aesthetic tint based on xP range
    Color badgeColor;
    Color textColor;

    if (xp >= 6.0) {
      badgeColor = AppTokens.statusAvailable.withValues(alpha: 0.15);
      textColor = AppTokens.statusAvailable;
    } else if (xp >= 4.0) {
      badgeColor = AppTokens.goldPrimary.withValues(alpha: 0.15);
      textColor = AppTokens.goldPrimary;
    } else if (xp >= 2.0) {
      badgeColor = AppTokens.statusDoubtful.withValues(alpha: 0.15);
      textColor = AppTokens.statusDoubtful;
    } else {
      badgeColor = AppTokens.statusOut.withValues(alpha: 0.15);
      textColor = AppTokens.statusOut;
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
