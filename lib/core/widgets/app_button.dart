import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive,
}

enum AppButtonSize {
  large, // 52 dp height
  medium, // 44 dp height (+ touch target)
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final Widget? leading;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.leading,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEnabled = onPressed != null && !isLoading;
    final height = size == AppButtonSize.large ? 52.0 : 44.0;

    // Minimum touch target padding if medium
    final verticalTouchPadding = size == AppButtonSize.medium ? 2.0 : 0.0;

    Color fillColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        fillColor = isEnabled ? colors.accent : colors.borderSubtle;
        textColor = isEnabled ? colors.accentOn : colors.textDisabled;
        break;
      case AppButtonVariant.secondary:
        fillColor = isEnabled ? colors.bgSurface : colors.bgBase;
        textColor = isEnabled ? colors.textPrimary : colors.textDisabled;
        borderSide = BorderSide(
          color: isEnabled ? colors.borderSubtle : colors.borderSubtle.withValues(alpha: 0.5),
          width: 1.0,
        );
        break;
      case AppButtonVariant.tertiary:
        fillColor = Colors.transparent;
        textColor = isEnabled ? colors.accent : colors.textDisabled;
        break;
      case AppButtonVariant.destructive:
        fillColor = isEnabled ? colors.statusError.withValues(alpha: 0.16) : colors.bgBase;
        textColor = isEnabled ? colors.statusError : colors.textDisabled;
        borderSide = BorderSide(
          color: isEnabled ? colors.statusError : colors.borderSubtle,
          width: 1.0,
        );
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20.0,
        width: 20.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTokens.space8),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: textColor,
                fontSize: size == AppButtonSize.large ? 16.0 : 14.0,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final button = Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        splashColor: variant == AppButtonVariant.primary
            ? colors.accentSoft.withValues(alpha: 0.3)
            : colors.borderSubtle,
        highlightColor: variant == AppButtonVariant.primary
            ? colors.accentSoft
            : colors.borderSubtle.withValues(alpha: 0.5),
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalTouchPadding),
      child: Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        child: button,
      ),
    );
  }
}
