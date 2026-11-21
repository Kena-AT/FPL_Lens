import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Style variants for [AppLoadingIndicator].
enum LoadingIndicatorStyle {
  circular,
  linear,
}

/// Unified loading indicator per Visual Redesign Design Document §4.5 & §16.
///
/// Features clean Electric Cyan progress, reduced motion awareness,
/// and optional status text.
class AppLoadingIndicator extends StatelessWidget {
  final LoadingIndicatorStyle style;
  final double? value;
  final String? message;
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.style = LoadingIndicatorStyle.circular,
    this.value,
    this.message,
    this.size = 36.0,
    this.strokeWidth = 2.5,
  });

  const AppLoadingIndicator.linear({
    super.key,
    this.value,
    this.message,
    this.strokeWidth = 4.0,
  })  : style = LoadingIndicatorStyle.linear,
        size = double.infinity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget indicator;
    if (style == LoadingIndicatorStyle.linear) {
      indicator = ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: SizedBox(
          height: strokeWidth,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: colors.bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      );
    } else {
      indicator = SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: reduceMotion ? (value ?? 0.75) : value,
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          backgroundColor: colors.bgElevated,
        ),
      );
    }

    if (message != null && message!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            indicator,
            const SizedBox(height: AppTokens.space16),
            Text(
              message!,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(child: indicator);
  }
}
