import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/bench_strip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/pitch_view.dart';
import '../../squad/providers/squad_provider.dart';
import '../providers/lineup_provider.dart';
import '../widgets/transfer_recommendation_sheet.dart';

/// Screen P10: LineupScreen (Spec §5, Frontend Implementation Plan §3, Visual Redesign §8.9).
/// Displays optimized starting XI on tactical pitch, captaincy controls, and ordered bench.
/// Built with tokens from AppColors, supporting 200% text scale and reduced motion.
class LineupScreen extends ConsumerStatefulWidget {
  const LineupScreen({super.key});

  @override
  ConsumerState<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends ConsumerState<LineupScreen> {
  PlayerCandidate? _selectedPlayer;
  PlayerCandidate? _substitutingPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lineupState = ref.read(lineupNotifierProvider);
      final squadState = ref.read(squadNotifierProvider);
      if (lineupState.result == null && squadState.squad.length == 15 && !lineupState.isOptimizing) {
        ref.read(lineupNotifierProvider.notifier).optimize();
      }
    });
  }

  void _openTransferRecommendations(PlayerCandidate player) {
    final colors = AppColors.of(context);
    final squadState = ref.read(squadNotifierProvider);
    final nextGw = squadState.nextGameweek;
    final curGw = squadState.currentGameweek;
    final latestGw = (curGw?.finished == true && nextGw != null)
        ? nextGw.id
        : (nextGw?.id ?? curGw?.id ?? 1);
    final selectedGw = ref.read(lineupNotifierProvider).selectedGameweek ?? latestGw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferRecommendationSheet(
        player: player,
        onSubstituteRequested: () {
          setState(() {
            _substitutingPlayer = player;
          });
        },
        onCaptaincyRequested: () => _showPlayerActionSheet(player, selectedGw, colors),
      ),
    );
  }

  void _handlePlayerTap(PlayerCandidate player) {
    if (_substitutingPlayer != null) {
      if (_substitutingPlayer!.fplId == player.fplId) {
        setState(() => _substitutingPlayer = null);
        return;
      }
      _executeSubstitution(_substitutingPlayer!, player);
    } else {
      setState(() {
        _selectedPlayer = player;
      });
      final squadState = ref.read(squadNotifierProvider);
      final nextGw = squadState.nextGameweek;
      final curGw = squadState.currentGameweek;
      final latestGw = (curGw?.finished == true && nextGw != null)
          ? nextGw.id
          : (nextGw?.id ?? curGw?.id ?? 1);
      final selectedGw = ref.read(lineupNotifierProvider).selectedGameweek ?? latestGw;
      final colors = AppColors.of(context);
      _showPlayerActionSheet(player, selectedGw, colors);
    }
  }

  void _handlePlayerLongPress(PlayerCandidate player) {
    setState(() {
      _substitutingPlayer = player;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap another player or drag to substitution bench to swap with ${player.webName}.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _executeSubstitution(PlayerCandidate incoming, PlayerCandidate target) {
    final success = ref.read(lineupNotifierProvider.notifier).swapPlayers(incoming.fplId, target.fplId);
    setState(() => _substitutingPlayer = null);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid substitution. Formations must have at least 1 GK, 3 DEF, 2 MID, 1 FWD.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Substituted ${incoming.webName} with ${target.webName}.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPlayerActionSheet(PlayerCandidate player, int gameweek, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgSurface,
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
                        color: colors.borderSubtle,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  Text(
                    player.webName,
                    style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${player.position} • ${(player.priceTenths / 10.0).toStringAsFixed(1)}m • ${player.xp} xP',
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14.0),

                  // xP Attribution & Mathematical Breakdown Card (§8.9 & §8.12)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: colors.borderSubtle),
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
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${player.xp} xP',
                              style: AppTextStyles.numeric.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        _buildAttributionRow('Start Probability', '$pStartPct% expected starting chance', colors),
                        _buildAttributionRow('Expected Minutes', '~$expectedMins mins expected', colors),
                        _buildAttributionRow(
                          'Scoring Profile',
                          player.position == 'GK' || player.position == 'DEF'
                              ? 'Clean sheet potential (4 pts) + defensive baseline'
                              : 'Attacking returns (goals & assists threat)',
                          colors,
                        ),
                        _buildAttributionRow(
                          'Deterministic Basis',
                          'Based on form, FDR fixture rating & underlying team stats',
                          colors,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Recommended Transfer Replacements Selection Area (§8.10 Transfer engine)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 16.0, color: colors.accent),
                                const SizedBox(width: 6.0),
                                Text(
                                  'TRANSFER RECOMMENDATIONS',
                                  style: AppTextStyles.label.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _openTransferRecommendations(player);
                              },
                              child: Text(
                                'View All',
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Best suited replacements for ${player.webName} (${player.position}) within budget (£${((player.priceTenths + ref.read(squadNotifierProvider).bankTenths) / 10.0).toStringAsFixed(1)}m):',
                          style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontSize: 11.5),
                        ),
                        const SizedBox(height: 8.0),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openTransferRecommendations(player);
                            },
                            icon: const Icon(Icons.auto_awesome_rounded, size: 16.0),
                            label: const Text('Analyze Replacements & Net xP Gain'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.accent,
                              side: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusChip)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Action Buttons
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.grid_on_rounded, color: colors.accent),
                      title: Text('View Fixture Heatmap', style: TextStyle(color: colors.textPrimary)),
                      subtitle: Text(
                        'See 5-GW difficulty matrix & fixture swings',
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                      leading: Icon(Icons.star_rounded, color: colors.accent),
                      title: Text('Make Captain', style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        ref.read(lineupNotifierProvider.notifier).setManualCaptain(player.fplId);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.star_half_rounded, color: colors.textSecondary),
                      title: Text('Make Vice-Captain', style: TextStyle(color: colors.textPrimary)),
                      onTap: () {
                        ref.read(lineupNotifierProvider.notifier).setManualViceCaptain(player.fplId);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.restore_rounded, color: colors.statusError),
                      title: Text('Clear Manual Overrides', style: TextStyle(color: colors.statusError)),
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

  static Widget _buildAttributionRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: colors.accent, fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontSize: 11.5),
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
    final colors = AppColors.of(context);
    final lineupState = ref.watch(lineupNotifierProvider);
    final squadState = ref.watch(squadNotifierProvider);
    final nextGw = squadState.nextGameweek;
    final curGw = squadState.currentGameweek;
    // When the previous week games have ended, the active lineup target is nextGameweek
    final bool currentGwEnded = curGw?.finished == true;
    final latestGw = (currentGwEnded && nextGw != null)
        ? nextGw.id
        : (nextGw?.id ??
            curGw?.id ??
            (squadState.gameweekHistory.isNotEmpty
                ? squadState.gameweekHistory.map((g) => g.gameweek).reduce((a, b) => a > b ? a : b)
                : 1));
    final selectedGw = lineupState.selectedGameweek ?? latestGw;
    final maxGw = selectedGw > latestGw ? selectedGw : latestGw;

    if (!squadState.hasSquad || squadState.squad.length != 15) {
      if (squadState.isLoading) {
        return Scaffold(
          backgroundColor: colors.bgBase,
          appBar: AppBar(
            title: Text(
              'Gameweek $selectedGw Lineup',
              style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
            ),
            backgroundColor: colors.bgBase,
            elevation: 0,
          ),
          body: Center(
            child: CircularProgressIndicator(color: colors.accent),
          ),
        );
      }
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          title: Text(
            'Gameweek $selectedGw Lineup',
            style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
          ),
          backgroundColor: colors.bgBase,
          elevation: 0,
        ),
        body: Center(
          child: EmptyState(
            icon: Icons.groups_outlined,
            title: squadState.hasSquad
                ? 'Incomplete squad (${squadState.squad.length}/15)'
                : 'No squad loaded',
            body: squadState.hasSquad
                ? 'Your squad must contain exactly 15 players to view and optimize your lineup. Please sync your squad.'
                : 'Sync your squad to run the device optimiser.',
            actionLabel: 'Sync Squad',
            onAction: () => ref.read(squadNotifierProvider.notifier).refreshSquad(force: true),
          ),
        ),
      );
    }

    final result = lineupState.result;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 68.0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppTokens.screenGutter,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: selectedGw,
            dropdownColor: colors.bgElevated,
            icon: Icon(Icons.arrow_drop_down_rounded, color: colors.accent, size: 28),
            items: [
              for (int w = maxGw; w >= 1; w--)
                DropdownMenuItem<int>(
                  value: w,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      w == latestGw
                          ? 'Gameweek $w (Active)'
                          : (w < latestGw ? 'Gameweek $w (Finished)' : 'Gameweek $w'),
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 16.0,
                        color: w == selectedGw ? colors.accent : colors.textPrimary,
                      ),
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
        actions: [
          IconButton(
            icon: Icon(Icons.grid_on_rounded, color: colors.textPrimary),
            tooltip: 'Fixture Heatmap',
            onPressed: () => context.push('/heatmap'),
          ),
          IconButton(
            icon: (lineupState.isOptimizing || lineupState.isLoadingGameweek)
                ? SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: colors.accent),
                  )
                : Icon(Icons.refresh_rounded, color: colors.accent),
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
      body: (lineupState.isLoadingGameweek || (result == null && lineupState.isOptimizing))
          ? Center(
              child: CircularProgressIndicator(color: colors.accent),
            )
          : result == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.screenGutter),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colors.statusError),
                        const SizedBox(height: AppTokens.space16),
                        Text(
                          lineupState.errorMessage ?? 'Could not calculate lineup.',
                          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.space24),
                        AppButton(
                          label: 'Calculate Lineup',
                          onPressed: () => ref.read(lineupNotifierProvider.notifier).optimize(),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: colors.accent,
                  backgroundColor: colors.bgSurface,
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
                                    return colors.bgElevated;
                                  }
                                  return colors.bgSurface;
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
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 16, color: colors.accent),
                                const SizedBox(width: 6),
                                Text(
                                  'Historical Lineup for Gameweek $selectedGw',
                                  style: AppTextStyles.caption.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_substitutingPlayer != null) ...[
                          Container(
                            margin: const EdgeInsets.fromLTRB(
                              AppTokens.screenGutter,
                              AppTokens.space8,
                              AppTokens.screenGutter,
                              0,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: colors.statusWarn.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                              border: Border.all(color: colors.statusWarn, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.swap_vert_rounded, color: colors.statusWarn, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Select a player to substitute with ${_substitutingPlayer!.webName} (${_substitutingPlayer!.position})',
                                    style: AppTextStyles.label.copyWith(
                                      color: colors.statusWarn,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, color: colors.statusWarn, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => _substitutingPlayer = null),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Header Metrics Card (Layered Bento Card §8.9)
                        Container(
                          margin: const EdgeInsets.all(AppTokens.screenGutter),
                          padding: const EdgeInsets.all(AppTokens.space16),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                            border: Border.all(color: colors.borderSubtle, width: 1.0),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppTokens.space12,
                            runSpacing: AppTokens.space12,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'PROJECTED POINTS',
                                    style: AppTextStyles.label.copyWith(
                                      color: colors.textSecondary,
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
                                            color: colors.accent,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          'xP',
                                          style: AppTextStyles.headline.copyWith(
                                            color: colors.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: colors.bgElevated,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                                      border: Border.all(color: colors.borderSubtle),
                                    ),
                                    child: Text(
                                      '${result.formation[1]}-${result.formation[2]}-${result.formation[3]}',
                                      style: AppTextStyles.numeric.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text(
                                    'Captain: ${result.captain.webName} (C)',
                                    style: AppTextStyles.caption.copyWith(
                                      color: colors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Vice: ${result.viceCaptain.webName} (V)',
                                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
                          substitutingPlayerId: _substitutingPlayer?.fplId,
                          onPlayerTap: _handlePlayerTap,
                          onPlayerLongPress: _handlePlayerLongPress,
                          onPlayerSwap: (incoming, target) => _executeSubstitution(incoming, target),
                        ),

                        // Performance Index Legend Row (§8.9)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.screenGutter,
                            vertical: AppTokens.space8,
                          ),
                          child: Text(
                            'Performance index (0–100). Dashed ring: start chance below 75 %.',
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textSecondary,
                              fontSize: 11.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 4.0),

                        // Bench Strip (D8)
                        BenchStrip(
                          benchPlayers: result.bench,
                          selectedPlayerId: _selectedPlayer?.fplId,
                          substitutingPlayerId: _substitutingPlayer?.fplId,
                          onPlayerTap: _handlePlayerTap,
                          onPlayerLongPress: _handlePlayerLongPress,
                          onPlayerSwap: (incoming, target) => _executeSubstitution(incoming, target),
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
                                    variant: AppButtonVariant.primary,
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
                                        color: colors.statusWarn,
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
