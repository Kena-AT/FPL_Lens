import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// Glassmorphism container per Visual Redesign Design Document §4.4 & §16.
///
/// Provides frosted glass with Gaussian blur (default 20dp) and subtle border.
/// Includes progressive fallback for reduced motion or low-end rendering:
/// when animations are disabled, renders solid [AppColors.bgSurface] with no blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final List<BoxShadow>? shadows;
  final bool? disableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.border,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.shadows,
    this.disableBlur,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final mediaQuery = MediaQuery.maybeOf(context);
    final shouldDisableBlur = disableBlur ?? (mediaQuery?.disableAnimations ?? false);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppTokens.radiusCard);

    // Fallback: solid background without blur when reduce motion / fallback is active
    if (shouldDisableBlur) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        alignment: alignment,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: effectiveRadius,
          border: border ?? Border.all(color: colors.borderSubtle, width: 1.0),
          boxShadow: shadows ??
              (!colors.isDark
                  ? const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12.0,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null),
        ),
        padding: padding,
        child: child,
      );
    }

    final effectiveColor = color ?? colors.bgGlass;
    final effectiveBorder = border ??
        Border.all(
          color: colors.borderGlass,
          width: 1.0,
        );

    final effectiveShadows = shadows ??
        (!colors.isDark
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24.0,
                  offset: Offset(0, 8),
                ),
              ]
            : null);

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: effectiveRadius,
              border: effectiveBorder,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
