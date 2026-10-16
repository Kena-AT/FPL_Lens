import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

enum AppTextFieldType {
  standard,
  email,
  password,
  numeric,
}

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final AppTextFieldType type;
  final bool enabled;
  final int? maxLength;
  final Widget? suffix;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.onChanged,
    this.type = AppTextFieldType.standard,
    this.enabled = true,
    this.maxLength,
    this.suffix,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;
  late final FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _obscured = widget.type == AppTextFieldType.password;
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final isFocused = _internalFocusNode.hasFocus;

    TextInputType keyboardType;
    List<TextInputFormatter> formatters = [];
    Iterable<String>? autofillHints;

    switch (widget.type) {
      case AppTextFieldType.email:
        keyboardType = TextInputType.emailAddress;
        autofillHints = const [AutofillHints.email];
        break;
      case AppTextFieldType.password:
        keyboardType = TextInputType.visiblePassword;
        autofillHints = const [AutofillHints.password];
        break;
      case AppTextFieldType.numeric:
        keyboardType = TextInputType.number;
        formatters = [FilteringTextInputFormatter.digitsOnly];
        break;
      case AppTextFieldType.standard:
        keyboardType = TextInputType.text;
        break;
    }

    Color borderColor;
    double borderWidth;

    if (hasError) {
      borderColor = AppTokens.statusOut;
      borderWidth = 1.5;
    } else if (isFocused) {
      borderColor = AppTokens.neonPrimary;
      borderWidth = 1.5;
    } else {
      borderColor = AppTokens.borderSubtle;
      borderWidth = 1.0;
    }

    Widget? effectiveSuffix = widget.suffix;
    if (widget.type == AppTextFieldType.password) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppTokens.textSecondary,
          size: 20.0,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label always stays above field
        Text(
          widget.label,
          style: AppTextStyles.label.copyWith(
            color: hasError ? AppTokens.statusOut : AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Container(
          decoration: BoxDecoration(
            color: AppTokens.bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
          child: TextField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            obscureText: _obscured,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            autofillHints: autofillHints,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            style: AppTextStyles.body.copyWith(
              color: widget.enabled ? AppTokens.textPrimary : AppTokens.textDisabled,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.body.copyWith(color: AppTokens.textDisabled),
              border: InputBorder.none,
              counterText: '',
              suffixIcon: effectiveSuffix,
              contentPadding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        if (hasError)
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14.0, color: AppTokens.statusOut),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Text(
                  widget.error!,
                  style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
                ),
              ),
            ],
          )
        else if (widget.helper != null && widget.helper!.isNotEmpty)
          Text(
            widget.helper!,
            style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
          ),
      ],
    );
  }
}
