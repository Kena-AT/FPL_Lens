import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import 'app_button.dart';

class ConfirmSheet extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmSheet({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel = "Cancel",
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = "Cancel",
    bool isDestructive = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConfirmSheet(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
        border: Border(
          top: BorderSide(color: AppTokens.borderSubtle, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.all(AppTokens.space24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              body,
              style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: AppTokens.space24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.large,
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop(false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
