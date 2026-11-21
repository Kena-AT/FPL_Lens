import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// Type of metric change represented by [DeltaChip].
enum DeltaType {
  price,
  points,
  rank,
  custom,
}

/// Unified delta chip for all changes (rank, pts, price) per Visual Redesign §6.3 & §16.
///
/// Enforces directional glyphs (▲ / ▼), tabular numeral alignment,
/// and accessible semantic labels. Never relies on colour alone.
class DeltaChip extends StatelessWidget {
  final double? delta;
  final String? customText;
  final DeltaType type;
  final String? unit;
  final bool compact;
  final bool invertPolarity;

  const DeltaChip({
    super.key,
    this.delta,
    this.customText,
    this.type = DeltaType.points,
    this.unit,
    this.compact = false,
    this.invertPolarity = false,
  }) : assert(delta != null || customText != null, 'Either delta or customText must be provided.');

  const DeltaChip.price({
    Key? key,
    required double delta,
    bool compact = false,
  }) : this(
          key: key,
          delta: delta,
          type: DeltaType.price,
          compact: compact,
        );

  const DeltaChip.points({
    Key? key,
    required double delta,
    String? unit = 'xP',
    bool compact = false,
  }) : this(
          key: key,
          delta: delta,
          type: DeltaType.points,
          unit: unit,
          compact: compact,
        );

  DeltaChip.rank({
    Key? key,
    required int rankDelta,
    bool compact = false,
    bool invertPolarity = false,
  }) : this(
          key: key,
          delta: rankDelta.toDouble(),
          type: DeltaType.rank,
          compact: compact,
          invertPolarity: invertPolarity,
        );

  bool get _isPositive {
    if (delta == null) return false;
    final effective = invertPolarity ? -delta! : delta!;
    return effective > 0.0001;
  }

  bool get _isNegative {
    if (delta == null) return false;
    final effective = invertPolarity ? -delta! : delta!;
    return effective < -0.0001;
  }

  bool get _isNeutral => !_isPositive && !_isNegative;

  String get _formattedText {
    if (customText != null) return customText!;
    final d = delta ?? 0.0;

    switch (type) {
      case DeltaType.price:
        if (_isNeutral) return '£0.0m';
        final prefix = _isPositive ? '+£' : '−£';
        return '$prefix${d.abs().toStringAsFixed(1)}m';

      case DeltaType.points:
        if (_isNeutral) return '0.0 ${unit ?? ""}';
        final prefix = _isPositive ? '+' : '−';
        final unitSuffix = unit != null ? ' $unit' : '';
        return '$prefix${d.abs().toStringAsFixed(1)}$unitSuffix';

      case DeltaType.rank:
        if (_isNeutral) return '0';
        final prefix = _isPositive ? '▲ ' : '▼ ';
        return '$prefix${d.abs().toInt()}';

      case DeltaType.custom:
        final prefix = _isPositive ? '+' : (_isNegative ? '−' : '');
        final unitSuffix = unit != null ? ' $unit' : '';
        return '$prefix${d.abs().toStringAsFixed(1)}$unitSuffix';
    }
  }

  String get _glyph {
    if (_isPositive) return '▲';
    if (_isNegative) return '▼';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (_isPositive) {
      textColor = colors.statusOk;
      bgColor = colors.statusOk.withValues(alpha: 0.12);
      borderColor = colors.statusOk.withValues(alpha: 0.30);
    } else if (_isNegative) {
      textColor = colors.statusError;
      bgColor = colors.statusError.withValues(alpha: 0.12);
      borderColor = colors.statusError.withValues(alpha: 0.30);
    } else {
      textColor = colors.textSecondary;
      bgColor = colors.borderSubtle.withValues(alpha: 0.20);
      borderColor = colors.borderSubtle;
    }

    final text = _formattedText;
    final glyph = _glyph;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space4 : AppTokens.space8,
        vertical: compact ? 2.0 : AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (glyph.isNotEmpty && type != DeltaType.rank) ...[
            Text(
              glyph,
              style: TextStyle(
                fontSize: compact ? 9.0 : 10.0,
                color: textColor,
                height: 1.0,
              ),
            ),
            const SizedBox(width: AppTokens.space2),
          ],
          Text(
            text,
            style: AppTextStyles.label.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11.0 : 12.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    final semanticDescriptor = _isPositive
        ? 'Increase of $text'
        : (_isNegative ? 'Decrease of $text' : 'No change, $text');

    return Semantics(
      label: semanticDescriptor,
      child: content,
    );
  }
}
