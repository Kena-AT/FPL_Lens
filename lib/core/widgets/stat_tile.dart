import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

enum StatTileVariant {
  standard,
  positive,
  negative,
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final StatTileVariant variant;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.variant = StatTileVariant.standard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor;
    Widget? trendIcon;

    switch (variant) {
      case StatTileVariant.positive:
        valueColor = AppTokens.statusAvailable;
        trendIcon = const Icon(
          Icons.arrow_upward_rounded,
          size: 18,
          color: AppTokens.statusAvailable,
        );
        break;
      case StatTileVariant.negative:
        valueColor = AppTokens.statusOut;
        trendIcon = const Icon(
          Icons.arrow_downward_rounded,
          size: 18,
          color: AppTokens.statusOut,
        );
        break;
      case StatTileVariant.standard:
        valueColor = AppTokens.textPrimary;
        trendIcon = null;
        break;
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.numeric.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
              if (trendIcon != null) ...[
                const SizedBox(width: AppTokens.space4),
                trendIcon,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.space4),
            Text(
              subtitle!,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: content,
      );
    }

    return Semantics(
      label: '$label: $value${subtitle != null ? ", $subtitle" : ""}',
      child: content,
    );
  }
}
