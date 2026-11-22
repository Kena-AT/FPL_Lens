import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'player_chip.dart';

/// Component D7: PitchView (Frontend Implementation Plan §4.1 & Visual Redesign §8.9).
/// Custom-painted tactical pitch showing starting XI arranged by formation.
class PitchView extends StatelessWidget {
  final List<PlayerCandidate> startingXi;
  final PlayerCandidate? captain;
  final PlayerCandidate? viceCaptain;
  final int? selectedPlayerId;
  final int? substitutingPlayerId;
  final ValueChanged<PlayerCandidate>? onPlayerTap;
  final ValueChanged<PlayerCandidate>? onPlayerLongPress;
  final void Function(PlayerCandidate incoming, PlayerCandidate target)? onPlayerSwap;

  const PitchView({
    super.key,
    required this.startingXi,
    this.captain,
    this.viceCaptain,
    this.selectedPlayerId,
    this.substitutingPlayerId,
    this.onPlayerTap,
    this.onPlayerLongPress,
    this.onPlayerSwap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gks = startingXi.where((p) => p.position == 'GK').toList();
    final defs = startingXi.where((p) => p.position == 'DEF').toList();
    final mids = startingXi.where((p) => p.position == 'MID').toList();
    final fwds = startingXi.where((p) => p.position == 'FWD').toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: colors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: CustomPaint(
          painter: _PitchPainter(colors: colors),
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
        final isSubCandidate = substitutingPlayerId != null && substitutingPlayerId != p.fplId;

        return PlayerChip(
          player: p,
          isCaptain: captain?.fplId == p.fplId,
          isViceCaptain: viceCaptain?.fplId == p.fplId,
          isSelected: selectedPlayerId == p.fplId || substitutingPlayerId == p.fplId,
          isSwapCandidate: isSubCandidate,
          onTap: () => onPlayerTap?.call(p),
          onLongPress: () => onPlayerLongPress?.call(p),
          onAcceptDrop: (incoming) => onPlayerSwap?.call(incoming, p),
        );
      }).toList(),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final AppColors colors;

  _PitchPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    // Pitch background gradient from theme tokens
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.pitchTop, colors.pitchBottom],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
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
      ..color = Colors.white.withValues(alpha: 0.25)
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
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
