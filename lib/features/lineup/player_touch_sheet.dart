import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/layer3/player_touch_viewmodel.dart';
import '../../core/optimiser/player_candidate.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// Opens the Player Touch bottom sheet per Engine Design §10.
Future<void> showPlayerTouchSheet({
  required BuildContext context,
  required PlayerTouchViewModel viewModel,
  required int gameweek,
  required VoidCallback onMakeCaptain,
  required VoidCallback onMakeViceCaptain,
  required VoidCallback onClearOverrides,
  ValueChanged<PlayerTouchTransferOption>? onSelectTransfer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTokens.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
    ),
    builder: (ctx) => PlayerTouchSheet(
      viewModel: viewModel,
      gameweek: gameweek,
      onMakeCaptain: onMakeCaptain,
      onMakeViceCaptain: onMakeViceCaptain,
      onClearOverrides: onClearOverrides,
      onSelectTransfer: onSelectTransfer,
    ),
  );
}

/// Player Action & Transfer Recommendation Sheet (§10.1).
class PlayerTouchSheet extends StatelessWidget {
  final PlayerTouchViewModel viewModel;
  final int gameweek;
  final VoidCallback onMakeCaptain;
  final VoidCallback onMakeViceCaptain;
  final VoidCallback onClearOverrides;
  final ValueChanged<PlayerTouchTransferOption>? onSelectTransfer;

  const PlayerTouchSheet({
    super.key,
    required this.viewModel,
    required this.gameweek,
    required this.onMakeCaptain,
    required this.onMakeViceCaptain,
    required this.onClearOverrides,
    this.onSelectTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final player = viewModel.outgoingPlayer;
    final pStartPct = (player.pStart * 100).round();
    final expectedMins = (player.pStart * 90).round();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: AppTokens.borderSubtle,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),

                // 1. Header (§10.1): Name, position, price, xP, availability & confidence
                Text(
                  player.webName,
                  style: AppTextStyles.headline.copyWith(color: AppTokens.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4.0),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      '${player.position} • £${(player.priceTenths / 10.0).toStringAsFixed(1)}m • ${player.xp.toStringAsFixed(1)} xP',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                    ),
                    _ConfidencePill(confidence: viewModel.confidence),
                  ],
                ),
                const SizedBox(height: 14.0),

                // 2. Transfer Recommendations (§10.1, §10.5)
                _buildTransferSection(context),
                const SizedBox(height: 12.0),

                // 4. Captaincy (§10.1: blocked for bench players)
                _buildCaptaincyActions(context),
                const SizedBox(height: 12.0),

                // 5. xP Attribution & Mathematical Breakdown Card (§10.1)
                _buildXpBreakdownCard(player, pStartPct, expectedMins),
                const SizedBox(height: 12.0),

                // 6. Heatmap & 7. View Details (§10.1)
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(Icons.grid_on_rounded, color: AppTokens.goldPrimary),
                    title: const Text('View Fixture Heatmap', style: TextStyle(color: AppTokens.textPrimary)),
                    subtitle: const Text(
                      'See 5-GW difficulty matrix & fixture swings',
                      style: TextStyle(color: AppTokens.textSecondary, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/heatmap');
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(Icons.person_search_rounded, color: AppTokens.textSecondary),
                    title: const Text('View Player Details', style: TextStyle(color: AppTokens.textPrimary)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/player/${player.fplId}?gw=$gameweek');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 18, color: AppTokens.goldPrimary),
                  const SizedBox(width: 6.0),
                  Flexible(
                    child: Text(
                      PlayerTouchMessages.title.toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                        color: AppTokens.goldPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              if (!viewModel.isStale && viewModel.allOptions.length > 3)
                TextButton(
                  onPressed: () => _showCompareMoreSheet(context),
                  child: const Text(PlayerTouchMessages.compareMore),
                ),
            ],
          ),
          if (viewModel.isBenchPlayer && !viewModel.isStale) ...[
            const SizedBox(height: 4.0),
            Text(
              PlayerTouchMessages.benchNote,
              style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8.0),
          if (viewModel.isStale || viewModel.topOptions.isEmpty)
            Text(
              viewModel.emptyReason ?? PlayerTouchMessages.none,
              style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary, fontSize: 13),
            )
          else
            ...viewModel.topOptions.map((opt) => _TransferOptionRow(
                  option: opt,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onSelectTransfer != null) {
                      onSelectTransfer!(opt);
                    } else {
                      context.go('/transfers');
                    }
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildCaptaincyActions(BuildContext context) {
    if (viewModel.isBenchPlayer) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppTokens.textSecondary),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                PlayerTouchMessages.captainBenchBlocked,
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.star_rounded, color: AppTokens.goldPrimary),
            title: const Text('Make Captain', style: TextStyle(color: AppTokens.textPrimary)),
            onTap: () {
              onMakeCaptain();
              Navigator.of(context).pop();
            },
          ),
        ),
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.star_half_rounded, color: AppTokens.textSecondary),
            title: const Text('Make Vice-Captain', style: TextStyle(color: AppTokens.textPrimary)),
            onTap: () {
              onMakeViceCaptain();
              Navigator.of(context).pop();
            },
          ),
        ),
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: const Icon(Icons.restore_rounded, color: AppTokens.statusOut),
            title: const Text('Clear Manual Overrides', style: TextStyle(color: AppTokens.statusOut)),
            onTap: () {
              onClearOverrides();
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildXpBreakdownCard(PlayerCandidate player, int pStartPct, int expectedMins) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'xP CALCULATION EXPLANATION',
                  style: AppTextStyles.label.copyWith(
                    color: AppTokens.goldPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '${player.xp.toStringAsFixed(1)} xP',
                style: AppTextStyles.numeric.copyWith(
                  color: AppTokens.goldPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          _attrRow('Start Probability', '$pStartPct% expected starting chance'),
          _attrRow('Expected Minutes', '~$expectedMins mins expected'),
          _attrRow(
            'Scoring Profile',
            player.position == 'GK' || player.position == 'DEF'
                ? 'Clean sheet potential (4 pts) + defensive baseline'
                : 'Attacking returns (goals & assists threat)',
          ),
          _attrRow(
            'Deterministic Basis',
            'Based on form, FDR fixture rating & underlying team stats',
          ),
        ],
      ),
    );
  }

  Widget _attrRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTokens.goldPrimary, fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary, fontSize: 11.5),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompareMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${PlayerTouchMessages.title}: ${viewModel.outgoingPlayer.webName}',
                  style: AppTextStyles.headline.copyWith(color: AppTokens.textPrimary),
                ),
                const SizedBox(height: 12.0),
                ...viewModel.allOptions.map((opt) => _TransferOptionRow(
                      option: opt,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        context.go('/transfers');
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferOptionRow extends StatelessWidget {
  final PlayerTouchTransferOption option;
  final VoidCallback onTap;

  const _TransferOptionRow({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = option.incomingPlayer;
    final gainSign = option.rawGain >= 0 ? '+' : '';
    final hitText = option.hitCost > 0 ? ' • -${option.hitCost} hit' : '';
    final semLabel =
        '${p.webName}, ${option.formattedPriceDelta}, net gain $gainSign${option.rawGain.toStringAsFixed(1)} xP, ${option.confidence} confidence';

    return Semantics(
      button: true,
      label: semLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.webName} (£${(p.priceTenths / 10.0).toStringAsFixed(1)}m)',
                      style: AppTextStyles.body.copyWith(
                        color: AppTokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${option.formattedPriceDelta}$hitText • ${option.confidence}',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$gainSign${option.rawGain.toStringAsFixed(1)} xP',
                      style: AppTextStyles.numeric.copyWith(
                        color: AppTokens.goldPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '[${option.interval80.$1.toStringAsFixed(1)}, ${option.interval80.$2.toStringAsFixed(1)}]',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final String confidence;

  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Text(
        confidence,
        style: AppTextStyles.caption.copyWith(
          color: AppTokens.goldPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
