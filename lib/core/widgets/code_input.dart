import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';

class CodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool enabled;

  const CodeInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.addListener(() => setState(() {}));
      return node;
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      if (!MediaQuery.of(context).disableAnimations) {
        _shakeController.forward(from: 0.0);
      }
      _clearAll();
    }
  }

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    if (widget.enabled && _focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String val) {
    if (val.length > 1) {
      // Pasted content handling
      final digits = val.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final fullCode = _currentCode;
      widget.onChanged?.call(fullCode);
      if (fullCode.length == widget.length) {
        _focusNodes.last.unfocus();
        widget.onCompleted?.call(fullCode);
      } else {
        final nextIndex = fullCode.length < widget.length ? fullCode.length : widget.length - 1;
        _focusNodes[nextIndex].requestFocus();
      }
      return;
    }

    widget.onChanged?.call(_currentCode);

    if (val.isNotEmpty) {
      if (index + 1 < widget.length) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentCode.length == widget.length) {
          widget.onCompleted?.call(_currentCode);
        }
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget boxesRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasError = widget.hasError;

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

        return Container(
          width: 48.0,
          height: 56.0,
          margin: EdgeInsets.symmetric(horizontal: index == 0 || index == widget.length - 1 ? 0.0 : 4.0),
          decoration: BoxDecoration(
            color: AppTokens.bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusInput),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: KeyboardListener(
            focusNode: FocusNode(), // pass-through
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: Semantics(
              label: 'Digit ${index + 1} of ${widget.length}',
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.numeric.copyWith(
                  fontSize: 22.0,
                  color: widget.enabled ? AppTokens.textPrimary : AppTokens.textDisabled,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            ),
          ),
        );
      }),
    );

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: boxesRow,
    );
  }
}
