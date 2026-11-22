import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable full-screen background widget that renders a football field in both
/// color (rich pitch greens) and structure (alternating mown lawn stripes,
/// touchlines, and tactical field markings).
class FootballPitchBackground extends StatelessWidget {
  final Widget child;

  const FootballPitchBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _FootballFieldPainter(
              colors: colors,
              isDark: colors.isDark,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _FootballFieldPainter extends CustomPainter {
  final AppColors colors;
  final bool isDark;

  const _FootballFieldPainter({
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Rich base stadium grass gradient
    final grassTop = isDark ? const Color(0xFF0C2417) : const Color(0xFFE4F0E6);
    final grassMid = isDark ? const Color(0xFF081A11) : const Color(0xFFD6E8D9);
    final grassBottom = isDark ? const Color(0xFF05120B) : const Color(0xFFC7DECB);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [grassTop, grassMid, grassBottom],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Alternating mown lawn stripes across the pitch
    const int stripeCount = 14;
    final stripeHeight = size.height / stripeCount;
    final stripePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.025)
          : Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stripeCount; i += 2) {
      final stripeRect = Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight);
      canvas.drawRect(stripeRect, stripePaint);
    }

    // 3. Subtle pitch boundary markings & center circle
    final lineAlpha = isDark ? 0.06 : 0.08;
    final pitchLinePaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1B4D2E)).withValues(alpha: lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const margin = 12.0;
    final fieldRect = Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(8.0)),
      pitchLinePaint,
    );

    // Halfway line
    final centerY = size.height * 0.48;
    canvas.drawLine(
      Offset(margin, centerY),
      Offset(size.width - margin, centerY),
      pitchLinePaint,
    );

    // Center circle & spot
    canvas.drawCircle(Offset(size.width / 2.0, centerY), 64.0, pitchLinePaint);
    final spotPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF1B4D2E)).withValues(alpha: lineAlpha * 1.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2.0, centerY), 3.0, spotPaint);

    // Subtle corner arcs
    const arcRadius = 16.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(margin, margin), radius: arcRadius),
      0,
      1.57,
      false,
      pitchLinePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - margin, margin), radius: arcRadius),
      1.57,
      1.57,
      false,
      pitchLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FootballFieldPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
