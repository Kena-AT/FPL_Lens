import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'xp_badge.dart';

/// Component D6: PlayerChip (Frontend Implementation Plan §4.1).
/// Compact player display used on pitch formations and bench strips.
class PlayerChip extends StatelessWidget {
  final PlayerCandidate player;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isSelected;
  final bool isSwapCandidate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<PlayerCandidate>? onAcceptDrop;

  const PlayerChip({
    super.key,
    required this.player,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.isSelected = false,
    this.isSwapCandidate = false,
    this.onTap,
    this.onLongPress,
    this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final priceStr = '£${(player.priceTenths / 10.0).toStringAsFixed(1)}m';

    final chipContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        child: Container(
          width: 72.0,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isSwapCandidate
                ? colors.statusWarn.withValues(alpha: 0.25)
                : isSelected
                    ? colors.accent.withValues(alpha: 0.2)
                    : colors.bgElevated.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            border: Border.all(
              color: isSwapCandidate
                  ? colors.statusWarn
                  : isSelected
                      ? colors.accent
                      : isCaptain
                          ? colors.accent
                          : colors.borderSubtle,
              width: isSwapCandidate || isCaptain || isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Captain / Vice-captain badge row
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28.0,
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _positionColor(player.position, colors),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        player.position,
                        style: TextStyle(
                          color: _positionColor(player.position, colors),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (isCaptain || isViceCaptain)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: isCaptain ? colors.accent : colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isCaptain ? 'C' : 'V',
                          style: TextStyle(
                            color: colors.bgBase,
                            fontSize: 8.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3.0),
              // Web name
              Text(
                player.webName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2.0),
              // xP badge
              XpBadge(xp: player.xp, isCompact: true),
              const SizedBox(height: 1.0),
              // Price
              Text(
                priceStr,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return DragTarget<PlayerCandidate>(
      onWillAcceptWithDetails: (details) => details.data.fplId != player.fplId,
      onAcceptWithDetails: (details) => onAcceptDrop?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<PlayerCandidate>(
          data: player,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.88,
              child: Container(
                width: 76.0,
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  border: Border.all(color: colors.accent, width: 2.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8.0, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.webName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player.xp} xP',
                      style: TextStyle(color: colors.accent, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: chipContent,
          ),
          child: chipContent,
        );
      },
    );
  }

  Color _positionColor(String pos, AppColors colors) {
    switch (pos) {
      case 'GK':
        return const Color(0xFFF59E0B);
      case 'DEF':
        return const Color(0xFF3B82F6);
      case 'MID':
        return const Color(0xFF10B981);
      case 'FWD':
        return const Color(0xFFEF4444);
      default:
        return colors.textSecondary;
    }
  }
}
