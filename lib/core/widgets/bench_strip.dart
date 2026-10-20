import 'package:flutter/material.dart';
import '../optimiser/player_candidate.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'player_chip.dart';

/// Component D8: BenchStrip (Frontend Implementation Plan §4.1, Spec §5.3).
/// Displays the 4 substitutes in exact substitution order (GK, 1, 2, 3).
class BenchStrip extends StatelessWidget {
  final List<PlayerCandidate> benchPlayers; // Expected length: 4
  final int? selectedPlayerId;
  final ValueChanged<PlayerCandidate>? onPlayerTap;
  final ValueChanged<PlayerCandidate>? onPlayerLongPress;

  const BenchStrip({
    super.key,
    required this.benchPlayers,
    this.selectedPlayerId,
    this.onPlayerTap,
    this.onPlayerLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space12,
        vertical: AppTokens.space12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'BENCH (SUBSTITUTION ORDER)',
                  style: AppTextStyles.label.copyWith(
                    color: AppTokens.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              const Icon(
                Icons.swap_vert_rounded,
                size: 16.0,
                color: AppTokens.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final player = index < benchPlayers.length ? benchPlayers[index] : null;
              final slotLabel = index == 0 ? 'GK' : '$index';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    margin: const EdgeInsets.only(bottom: 4.0),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppTokens.goldPrimary.withValues(alpha: 0.15)
                          : AppTokens.bgElevated,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: index == 0
                            ? AppTokens.goldPrimary.withValues(alpha: 0.4)
                            : AppTokens.borderSubtle,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      slotLabel,
                      style: TextStyle(
                        color: index == 0 ? AppTokens.goldPrimary : AppTokens.textSecondary,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (player != null)
                    PlayerChip(
                      player: player,
                      isSelected: selectedPlayerId == player.fplId,
                      onTap: () => onPlayerTap?.call(player),
                      onLongPress: () => onPlayerLongPress?.call(player),
                    )
                  else
                    Container(
                      width: 72.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: AppTokens.bgElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Empty',
                          style: TextStyle(
                            color: AppTokens.textDisabled,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
