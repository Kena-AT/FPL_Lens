import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'glass_container.dart';

/// Card container variants per Visual Redesign Design Document §4.3, §5 C5 & §16.
enum CardVariant {
  /// Standard solid card with [AppColors.bgSurface], 12dp radius, and subtle border.
  surface,

  /// Frosted glass card with blur, translucent fill, and glass border.
  glass,

  /// Elevated card with [AppColors.bgElevated] for modals and sheets.
  elevated,
}

/// Unified card container for all content cards across FPL Lens.
class CardContainer extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final bool accentRing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const CardContainer({
    super.key,
    required this.child,
    this.variant = CardVariant.surface,
    this.accentRing = false,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppTokens.radiusCard);

    // Accent ring per §5 C5 (1.5dp accent border for single highlighted item)
    final effectiveBorder = accentRing
        ? Border.all(color: colors.accent, width: 1.5)
        : (variant == CardVariant.glass
            ? Border.all(color: colors.borderGlass, width: 1.0)
            : Border.all(color: colors.borderSubtle, width: 1.0));

    if (variant == CardVariant.glass) {
      Widget glassCard = GlassContainer(
        width: width,
        height: height,
        margin: margin,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        padding: padding,
        child: child,
      );

      if (onTap != null) {
        glassCard = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius as BorderRadius?,
            child: glassCard,
          ),
        );
      }

      if (semanticLabel != null) {
        glassCard = Semantics(
          label: semanticLabel,
          button: onTap != null,
          child: glassCard,
        );
      }

      return glassCard;
    }

    final bgColor = variant == CardVariant.elevated ? colors.bgElevated : colors.bgSurface;

    final shadows = !colors.isDark
        ? const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12.0,
              offset: Offset(0, 2),
            ),
          ]
        : null;

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius as BorderRadius?,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel != null || onTap != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}
