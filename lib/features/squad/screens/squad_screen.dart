import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/player_card.dart';
import '../providers/squad_provider.dart';

enum SquadViewMode {
  list,
  pitch,
}

class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key});

  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends ConsumerState<SquadScreen> {
  SquadViewMode _viewMode = SquadViewMode.list;

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);
    final players = squadState.squad;

    final totalSquadValueTenths = players.fold<int>(
      0,
      (sum, p) => sum + p.nowCostTenths,
    );
    final effectiveSquadValue = squadState.squadValueTenths > 0
        ? squadState.squadValueTenths
        : (totalSquadValueTenths > 0 ? totalSquadValueTenths : 1000);

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Squad', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh squad',
            onPressed: () async {
              final notice = await ref.read(squadNotifierProvider.notifier).refreshSquad(force: true);
              if (notice != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(notice),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTokens.bgElevated,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: players.isEmpty
          ? EmptyState(
              icon: Icons.group_off_outlined,
              title: 'No squad loaded',
              body: 'Enter your FPL Team ID to load your squad.',
              actionLabel: 'Enter Team ID',
              onAction: () => context.go('/onboarding/team'),
            )
          : Column(
              children: [
                // View Switcher (Pitch / List) & Freshness
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenGutter,
                    vertical: AppTokens.space8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTokens.bgSurface,
                    border: Border(bottom: BorderSide(color: AppTokens.borderSubtle)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SegmentedButton<SquadViewMode>(
                        segments: const [
                          ButtonSegment(
                            value: SquadViewMode.list,
                            label: Text('List'),
                            icon: Icon(Icons.list, size: 16),
                          ),
                          ButtonSegment(
                            value: SquadViewMode.pitch,
                            label: Text('Pitch'),
                            icon: Icon(Icons.sports_soccer, size: 16),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (val) {
                          setState(() {
                            _viewMode = val.first;
                          });
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
                      FreshnessLabel(
                        lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                      ),
                    ],
                  ),
                ),

                // Summary strip: Value · Bank · Free transfers
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenGutter,
                    vertical: AppTokens.space12,
                  ),
                  color: AppTokens.bgSurface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Value: ${AppFormatters.formatMoneyTenths(effectiveSquadValue)}',
                        style: AppTextStyles.numeric.copyWith(fontSize: 13),
                      ),
                      Text(
                        'Bank: ${AppFormatters.formatMoneyTenths(squadState.bankTenths)}',
                        style: AppTextStyles.numeric.copyWith(fontSize: 13),
                      ),
                      Text(
                        '${squadState.freeTransfers} Free transfer${squadState.freeTransfers == 1 ? '' : 's'}',
                        style: AppTextStyles.numeric.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTokens.borderSubtle, height: 1),

                // Content
                Expanded(
                  child: _viewMode == SquadViewMode.list
                      ? _buildListView(players)
                      : _buildPitchViewPlaceholder(players),
                ),
              ],
            ),
    );
  }

  Widget _buildListView(List<SquadPlayersTableData> players) {
    final gks = players.where((p) => p.position == 'GK' || p.position == 'GKP').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final defs = players.where((p) => p.position == 'DEF').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final mids = players.where((p) => p.position == 'MID').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final fwds = players.where((p) => p.position == 'FWD').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));

    return ListView(
      children: [
        if (gks.isNotEmpty) ...[
          _buildGroupHeader('Goalkeepers', gks.length),
          ...gks.map(_buildPlayerItem),
        ],
        if (defs.isNotEmpty) ...[
          _buildGroupHeader('Defenders', defs.length),
          ...defs.map(_buildPlayerItem),
        ],
        if (mids.isNotEmpty) ...[
          _buildGroupHeader('Midfielders', mids.length),
          ...mids.map(_buildPlayerItem),
        ],
        if (fwds.isNotEmpty) ...[
          _buildGroupHeader('Forwards', fwds.length),
          ...fwds.map(_buildPlayerItem),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space8,
      ),
      color: AppTokens.bgBase,
      child: Text(
        '$title ($count)'.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          fontSize: 11,
          letterSpacing: 1.1,
          color: AppTokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPlayerItem(SquadPlayersTableData player) {
    PlayerAvailability availability = PlayerAvailability.available;
    if (player.status == 'i') {
      availability = PlayerAvailability.injured;
    } else if (player.status == 'd') {
      availability = PlayerAvailability.doubtful;
    } else if (player.status == 's') {
      availability = PlayerAvailability.suspended;
    } else if (player.status == 'u') {
      availability = PlayerAvailability.unavailable;
    }

    return PlayerCard(
      webName: player.webName,
      positionText: player.position,
      teamShortName: player.teamShortName,
      nowCostTenths: player.nowCostTenths,
      purchasePriceTenths: player.purchasePriceTenths,
      priceSource: player.priceSource,
      availability: availability,
      chanceOfPlaying: player.chanceOfPlayingNextRound,
      isCaptain: player.isCaptain,
      isViceCaptain: player.isViceCaptain,
      onPriceTap: () => context.push('/squad/prices'),
      onTap: () {
        // Long-press or tap opens purchase price dialog/sheet
        _showPriceInfoSheet(player);
      },
    );
  }

  void _showPriceInfoSheet(SquadPlayersTableData player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSheet)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(player.webName, style: AppTextStyles.headline),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Current cost: ${AppFormatters.formatMoneyTenths(player.nowCostTenths)} · Purchase: ${AppFormatters.formatMoneyTenths(player.purchasePriceTenths)}',
                  style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Selling price: ${AppFormatters.formatMoneyTenths(player.sellingPriceTenths)} (${player.priceSource})',
                  style: AppTextStyles.numeric.copyWith(color: AppTokens.goldPrimary),
                ),
                const SizedBox(height: AppTokens.space24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/squad/prices');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.neonPrimary,
                    foregroundColor: AppTokens.bgBase,
                  ),
                  child: const Text('Edit purchase price'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPitchViewPlaceholder(List<SquadPlayersTableData> players) {
    // Pitch representation for squad preview
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTokens.bgPitchGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 48, color: AppTokens.statusAvailable),
            const SizedBox(height: AppTokens.space16),
            Text(
              '${players.length} Squad Players',
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Interactive PitchView with optimiser lineup in Sprint 9.',
              style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
