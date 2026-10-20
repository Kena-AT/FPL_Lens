import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/tokens.dart';
import 'player_chip.dart';

/// Component D7: PitchView (Frontend Implementation Plan §4.1).
/// Custom-painted tactical pitch showing starting XI arranged by formation.
class PitchView extends StatelessWidget {
  final List<PlayerCandidate> startingXi;
  final PlayerCandidate? captain;
  final PlayerCandidate? viceCaptain;
  final int? selectedPlayerId;
  final ValueChanged<PlayerCandidate>? onPlayerTap;
  final ValueChanged<PlayerCandidate>? onPlayerLongPress;

  const PitchView({
    super.key,
    required this.startingXi,
    this.captain,
    this.viceCaptain,
    this.selectedPlayerId,
    this.onPlayerTap,
    this.onPlayerLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final gks = startingXi.where((p) => p.position == 'GK').toList();
    final defs = startingXi.where((p) => p.position == 'DEF').toList();
    final mids = startingXi.where((p) => p.position == 'MID').toList();
    final fwds = startingXi.where((p) => p.position == 'FWD').toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: CustomPaint(
          painter: _PitchPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Goalkeeper row
                _buildPlayerRow(gks),
                const SizedBox(height: 12.0),
                // Defender row
                _buildPlayerRow(defs),
                const SizedBox(height: 12.0),
                // Midfielder row
                _buildPlayerRow(mids),
                const SizedBox(height: 12.0),
                // Forward row
                _buildPlayerRow(fwds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(List<PlayerCandidate> players) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((p) {
        return PlayerChip(
          player: p,
          isCaptain: captain?.fplId == p.fplId,
          isViceCaptain: viceCaptain?.fplId == p.fplId,
          isSelected: selectedPlayerId == p.fplId,
          onTap: () => onPlayerTap?.call(p),
          onLongPress: () => onPlayerLongPress?.call(p),
        );
      }).toList(),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Pitch background gradient
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: AppTokens.bgPitchGradient,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Pitch outer border line
    const inset = 10.0;
    final pitchRect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    canvas.drawRect(pitchRect, linePaint);

    // Halfway line
    final midY = size.height / 2.0;
    canvas.drawLine(Offset(inset, midY), Offset(size.width - inset, midY), linePaint);

    // Center circle
    final center = Offset(size.width / 2.0, midY);
    canvas.drawCircle(center, 40.0, linePaint);
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, spotPaint);

    // Top penalty box (Goal keeper area)
    final boxW = size.width * 0.55;
    final boxH = size.height * 0.16;
    final topBoxRect = Rect.fromCenter(
      center: Offset(size.width / 2.0, inset + boxH / 2.0),
      width: boxW,
      height: boxH,
    );
    canvas.drawRect(topBoxRect, linePaint);

    // Bottom penalty box
    final bottomBoxRect = Rect.fromCenter(
      center: Offset(size.width / 2.0, size.height - inset - boxH / 2.0),
      width: boxW,
      height: boxH,
    );
    canvas.drawRect(bottomBoxRect, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
