import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/bench_strip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/pitch_view.dart';
import '../../squad/providers/squad_provider.dart';
import '../providers/lineup_provider.dart';

/// Screen P10: LineupScreen (Spec §5, Frontend Implementation Plan §3).
/// Displays optimized starting XI, captain, and ordered bench.
class LineupScreen extends ConsumerStatefulWidget {
  const LineupScreen({super.key});

  @override
  ConsumerState<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends ConsumerState<LineupScreen> {
  PlayerCandidate? _selectedPlayer;

  void _showPlayerActionSheet(PlayerCandidate player, int gameweek) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      builder: (context) {
        final pStartPct = (player.pStart * 100).round();
        final expectedMins = (player.pStart * 90).round();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Text(
                    player.webName,
                    style: AppTextStyles.headline.copyWith(color: AppTokens.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${player.position} • ${(player.priceTenths / 10.0).toStringAsFixed(1)}m • ${player.xp} xP',
                    style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14.0),

                  // xP Attribution & Mathematical Breakdown Card
                  Container(
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
                            Text(
                              'xP CALCULATION EXPLANATION',
                              style: AppTextStyles.label.copyWith(
                                color: AppTokens.goldPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${player.xp} xP',
                              style: AppTextStyles.numeric.copyWith(
                                color: AppTokens.goldPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        _buildAttributionRow('Start Probability', '$pStartPct% expected starting chance'),
                        _buildAttributionRow('Expected Minutes', '~$expectedMins mins expected'),
                        _buildAttributionRow(
                          'Scoring Profile',
                          player.position == 'GK' || player.position == 'DEF'
                              ? 'Clean sheet potential (4 pts) + defensive baseline'
                              : 'Attacking returns (goals & assists threat)',
                        ),
                        _buildAttributionRow(
                          'Deterministic Basis',
                          'Based on form, FDR fixture rating & underlying team stats',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Action Buttons
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.grid_on_rounded, color: AppTokens.goldPrimary),
                      title: const Text('View Fixture Heatmap', style: TextStyle(color: AppTokens.textPrimary)),
                      subtitle: const Text('See 5-GW difficulty matrix & fixture swings', style: TextStyle(color: AppTokens.textSecondary, fontSize: 11)),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/heatmap');
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.star_rounded, color: AppTokens.goldPrimary),
                      title: const Text('Make Captain', style: TextStyle(color: AppTokens.textPrimary)),
                      onTap: () {
                        ref.read(lineupNotifierProvider.notifier).setManualCaptain(player.fplId);
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
                        ref.read(lineupNotifierProvider.notifier).setManualViceCaptain(player.fplId);
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
                        ref.read(lineupNotifierProvider.notifier).clearOverrides();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildAttributionRow(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    final lineupState = ref.watch(lineupNotifierProvider);
    final squadState = ref.watch(squadNotifierProvider);
    final latestGw = squadState.nextGameweek?.id ??
        squadState.currentGameweek?.id ??
        (squadState.gameweekHistory.isNotEmpty
            ? squadState.gameweekHistory.map((g) => g.gameweek).reduce((a, b) => a > b ? a : b)
            : 1);
    final selectedGw = lineupState.selectedGameweek ?? latestGw;

    if (!squadState.hasSquad) {
      return Scaffold(
        backgroundColor: AppTokens.bgBase,
        appBar: AppBar(
          title: Text('Gameweek $selectedGw Lineup', style: AppTextStyles.headline),
          backgroundColor: AppTokens.bgBase,
          elevation: 0,
        ),
        body: const Center(
          child: EmptyState(
            icon: Icons.groups_outlined,
            title: 'No squad loaded',
            body: 'Sync your squad to run the device optimiser.',
          ),
        ),
      );
    }

    final result = lineupState.result;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedGw,
            dropdownColor: AppTokens.bgElevated,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTokens.goldPrimary, size: 28),
            items: [
              for (int w = latestGw; w >= 1; w--)
                DropdownMenuItem<int>(
                  value: w,
                  child: Text(
                    w == latestGw ? 'Gameweek $w (Latest)' : 'Gameweek $w',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: 16.0,
                      color: w == selectedGw ? AppTokens.goldPrimary : AppTokens.textPrimary,
                    ),
                  ),
                ),
            ],
            onChanged: (newGw) {
              if (newGw != null && newGw != selectedGw) {
                ref.read(lineupNotifierProvider.notifier).selectGameweek(newGw);
              }
            },
          ),
        ),
        backgroundColor: AppTokens.bgBase,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on_rounded, color: AppTokens.goldPrimary),
            tooltip: 'Fixture Heatmap',
            onPressed: () => context.push('/heatmap'),
          ),
          IconButton(
            icon: (lineupState.isOptimizing || lineupState.isLoadingGameweek)
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: AppTokens.neonPrimary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppTokens.neonPrimary),
            tooltip: 'Refresh Lineup',
            onPressed: (lineupState.isOptimizing || lineupState.isLoadingGameweek)
                ? null
                : () async {
                    if (selectedGw == latestGw) {
                      await ref.read(squadNotifierProvider.notifier).refreshSquad(force: true);
                      await ref.read(lineupNotifierProvider.notifier).optimize();
                    } else {
                      await ref.read(lineupNotifierProvider.notifier).selectGameweek(selectedGw);
                    }
                  },
          ),
        ],
      ),
      body: (result == null || lineupState.isLoadingGameweek)
          ? const Center(
              child: CircularProgressIndicator(color: AppTokens.neonPrimary),
            )
          : RefreshIndicator(
              color: AppTokens.neonPrimary,
              backgroundColor: AppTokens.bgSurface,
              onRefresh: () async {
                if (selectedGw == latestGw) {
                  await ref.read(squadNotifierProvider.notifier).refreshSquad(force: true);
                  await ref.read(lineupNotifierProvider.notifier).optimize();
                } else {
                  await ref.read(lineupNotifierProvider.notifier).selectGameweek(selectedGw);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selectedGw == latestGw) ...[
                      // Switcher between My Lineup and Recommended
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.screenGutter,
                          AppTokens.space8,
                          AppTokens.screenGutter,
                          0,
                        ),
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('My Lineup'),
                              icon: Icon(Icons.person_pin_circle_outlined, size: 16),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Recommended'),
                              icon: Icon(Icons.auto_awesome_outlined, size: 16),
                            ),
                          ],
                          selected: {lineupState.isRecommendedMode},
                          onSelectionChanged: (val) {
                            ref.read(lineupNotifierProvider.notifier).setRecommendedMode(val.first);
                          },
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppTokens.bgElevated;
                              }
                              return AppTokens.bgSurface;
                            }),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(
                          AppTokens.screenGutter,
                          AppTokens.space8,
                          AppTokens.screenGutter,
                          0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: AppTokens.bgSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(color: AppTokens.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_rounded, size: 16, color: AppTokens.goldPrimary),
                            const SizedBox(width: 6),
                            Text(
                              'Historical Lineup for Gameweek $selectedGw',
                              style: AppTextStyles.caption.copyWith(color: AppTokens.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Header Metrics Card
                    Container(
                      margin: const EdgeInsets.all(AppTokens.screenGutter),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space16,
                        vertical: AppTokens.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.bgSurface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROJECTED POINTS',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppTokens.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        result.totalExpectedPoints.toStringAsFixed(1),
                                        style: AppTextStyles.display.copyWith(
                                          fontSize: 28.0,
                                          color: AppTokens.neonPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'xP',
                                        style: AppTextStyles.headline.copyWith(
                                          color: AppTokens.neonPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: AppTokens.bgElevated,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                                    border: Border.all(color: AppTokens.borderSubtle),
                                  ),
                                  child: Text(
                                    '${result.formation[1]}-${result.formation[2]}-${result.formation[3]}',
                                    style: AppTextStyles.numeric.copyWith(
                                      color: AppTokens.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  'Captain: ${result.captain.webName} (C)',
                                  style: AppTextStyles.caption.copyWith(color: AppTokens.goldPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Vice: ${result.viceCaptain.webName} (V)',
                                  style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pitch View (D7)
                    PitchView(
                      startingXi: result.startingXi,
                      captain: result.captain,
                      viceCaptain: result.viceCaptain,
                      selectedPlayerId: _selectedPlayer?.fplId,
                      onPlayerTap: (p) {
                        setState(() {
                          _selectedPlayer = p;
                        });
                        _showPlayerActionSheet(p, selectedGw);
                      },
                      onPlayerLongPress: (p) => _showPlayerActionSheet(p, selectedGw),
                    ),

                    const SizedBox(height: 12.0),

                    // Bench Strip (D8)
                    BenchStrip(
                      benchPlayers: result.bench,
                      selectedPlayerId: _selectedPlayer?.fplId,
                      onPlayerTap: (p) {
                        setState(() {
                          _selectedPlayer = p;
                        });
                        _showPlayerActionSheet(p, selectedGw);
                      },
                      onPlayerLongPress: (p) => _showPlayerActionSheet(p, selectedGw),
                    ),

                    const SizedBox(height: 16.0),

                    // Freshness & Stale Handling (Frontend Plan P10 / Spec §10)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
                      child: FreshnessLabel(
                        lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                        staleThreshold: const Duration(minutes: 10),
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // Save Lineup Action
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
                      child: Builder(
                        builder: (context) {
                          final lastSync = squadState.lastSyncTime ?? DateTime.now();
                          final isStale = DateTime.now().difference(lastSync) > const Duration(minutes: 10);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppButton(
                                label: 'Save lineup',
                                onPressed: isStale
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Lineup saved.')),
                                        );
                                      },
                              ),
                              if (isStale) ...[
                                const SizedBox(height: 6.0),
                                Text(
                                  'Projections are out of date. Sync to save.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppTokens.statusDoubtful,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
    );
  }
}
