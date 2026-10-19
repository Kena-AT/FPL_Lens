import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/tokens.dart';
import 'xp_badge.dart';

/// Component D6: PlayerChip (Frontend Implementation Plan §4.1).
/// Compact player display used on pitch formations and bench strips.
class PlayerChip extends StatelessWidget {
  final PlayerCandidate player;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlayerChip({
    super.key,
    required this.player,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = '£${(player.priceTenths / 10.0).toStringAsFixed(1)}m';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        child: Container(
          width: 72.0,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTokens.neonPrimary.withValues(alpha: 0.2)
                : AppTokens.bgElevated.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            border: Border.all(
              color: isSelected
                  ? AppTokens.neonPrimary
                  : isCaptain
                      ? AppTokens.goldPrimary
                      : AppTokens.borderSubtle,
              width: isCaptain || isSelected ? 1.5 : 1.0,
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
                      color: AppTokens.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _positionColor(player.position),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        player.position,
                        style: TextStyle(
                          color: _positionColor(player.position),
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
                          color: isCaptain ? AppTokens.goldPrimary : AppTokens.textSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isCaptain ? 'C' : 'V',
                          style: const TextStyle(
                            color: Colors.black,
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
                style: const TextStyle(
                  color: AppTokens.textPrimary,
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
                style: const TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _positionColor(String pos) {
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
        return AppTokens.textSecondary;
    }
  }
}
