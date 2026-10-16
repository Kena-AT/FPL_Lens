import 'package:flutter/material.dart';
import '../network/error_mapper.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final String? customActionLabel;
  final VoidCallback? onCustomAction;

  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.customActionLabel,
    this.onCustomAction,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (error.kind) {
      case AppErrorKind.offline:
        icon = Icons.wifi_off_outlined;
        break;
      case AppErrorKind.timeout:
      case AppErrorKind.fplUnavailable:
        icon = Icons.cloud_off_outlined;
        break;
      case AppErrorKind.rateLimited:
        icon = Icons.timer_outlined;
        break;
      case AppErrorKind.unauthenticated:
        icon = Icons.lock_outline;
        break;
      default:
        icon = Icons.error_outline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: AppTokens.statusOut),
            const SizedBox(height: AppTokens.space16),
            Text(
              error.kind == AppErrorKind.offline
                  ? "No connection"
                  : error.kind == AppErrorKind.fplUnavailable
                      ? "FPL unavailable"
                      : "Something went wrong",
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              error.message,
              style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space24),
            if (error.retryable && onRetry != null) ...[
              AppButton(
                label: "Try again",
                onPressed: onRetry,
                size: AppButtonSize.medium,
              ),
            ] else if (customActionLabel != null && onCustomAction != null) ...[
              AppButton(
                label: customActionLabel!,
                onPressed: onCustomAction,
                size: AppButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
