import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/history_row.dart';
import '../../squad/providers/squad_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showGwRank = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final squadState = ref.watch(squadNotifierProvider);
    final gameweeks = squadState.gameweekHistory;
    final transfers = squadState.transfers;

    final latestGw = gameweeks.isNotEmpty ? gameweeks.first : null;

    // Estimate rank percentile
    final overallRank = latestGw?.overallRank ?? 0;
    // Assuming roughly 10.5m FPL managers
    final percentile = overallRank > 0 ? (100.0 - (overallRank / 10500000.0 * 100)).clamp(0.1, 99.9) : null;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text('History', style: AppTextStyles.title.copyWith(color: colors.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accent,
          indicatorWeight: 3,
          labelColor: colors.textPrimary,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Gameweeks'),
            Tab(text: 'Transfers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Gameweeks
          gameweeks.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  title: 'No gameweeks yet',
                  body: 'Your history appears after your first finished gameweek of the season.',
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // 1. Hero rank tile (2×2 layered) per §8.13
                    if (latestGw != null)
                      Container(
                        margin: const EdgeInsets.all(AppTokens.screenGutter),
                        padding: const EdgeInsets.all(AppTokens.space16),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Rank',
                              style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            // Hero Numeral Style (§4.1 / §8.13)
                            Text(
                              AppFormatters.formatRank(latestGw.overallRank),
                              style: AppTextStyles.numeric.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: colors.borderSubtle),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppTokens.space8,
                              runSpacing: AppTokens.space8,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total points', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${latestGw.totalPoints}',
                                      style: AppTextStyles.numeric.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                if (percentile != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Top percentile', style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Top ${(100 - percentile).toStringAsFixed(1)}%',
                                        style: AppTextStyles.numeric.copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: colors.statusOk,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // 2. Chip status tile (§8.13: five season chips in a grid)
                    _buildSeasonChipsTile(colors, gameweeks),

                    // 3. Rank toggle filter chips (§8.13)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.screenGutter,
                        vertical: AppTokens.space8,
                      ),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Overall Rank'),
                            selected: !_showGwRank,
                            selectedColor: colors.accentSoft,
                            backgroundColor: colors.bgSurface,
                            labelStyle: AppTextStyles.caption.copyWith(
                              color: !_showGwRank ? colors.accent : colors.textSecondary,
                              fontWeight: !_showGwRank ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: !_showGwRank ? colors.accent : colors.borderSubtle,
                            ),
                            onSelected: (_) => setState(() => _showGwRank = false),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          ChoiceChip(
                            label: const Text('Gameweek Rank'),
                            selected: _showGwRank,
                            selectedColor: colors.accentSoft,
                            backgroundColor: colors.bgSurface,
                            labelStyle: AppTextStyles.caption.copyWith(
                              color: _showGwRank ? colors.accent : colors.textSecondary,
                              fontWeight: _showGwRank ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: _showGwRank ? colors.accent : colors.borderSubtle,
                            ),
                            onSelected: (_) => setState(() => _showGwRank = true),
                          ),
                        ],
                      ),
                    ),

                    // 4. Gameweek table rows
                    ...gameweeks.map((gw) {
                      return HistoryRow.gameweek(
                        context: context,
                        event: gw.gameweek,
                        points: gw.points,
                        overallRank: gw.overallRank,
                        showGwRank: _showGwRank,
                        transferCost: gw.eventTransfersCost,
                        pointsOnBench: gw.pointsOnBench,
                      );
                    }),
                  ],
                ),

          // Tab 2: Transfers
          transfers.isEmpty
              ? EmptyState(
                  icon: Icons.swap_horiz,
                  title: 'No transfers yet',
                  body: 'Transfers made in this season will show up here.',
                )
              : ListView.builder(
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final t = transfers[index];
                    return HistoryRow.transfer(
                      context: context,
                      date: t.transferTime,
                      playerInName: t.elementInName,
                      playerInCostTenths: t.elementInCostTenths,
                      playerOutName: t.elementOutName,
                      playerOutCostTenths: t.elementOutCostTenths,
                      priceSource: 'FROM_TRANSFER',
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSeasonChipsTile(AppColors colors, List<dynamic> gameweeks) {
    // Standard FPL chips
    final chips = [
      {'name': 'Wildcard 1', 'played': false, 'gw': null},
      {'name': 'Wildcard 2', 'played': false, 'gw': null},
      {'name': 'Free Hit', 'played': false, 'gw': null},
      {'name': 'Triple Captain', 'played': false, 'gw': null},
      {'name': 'Bench Boost', 'played': false, 'gw': null},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space4,
      ),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season Chips',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTokens.space8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips.map((c) {
              final isPlayed = c['played'] as bool;
              final name = c['name'] as String;
              final gw = c['gw'];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPlayed ? colors.bgElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  border: Border.all(
                    color: isPlayed ? colors.borderSubtle : colors.accent,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isPlayed ? '$name (GW $gw)' : '$name AVAILABLE',
                  style: AppTextStyles.caption.copyWith(
                    color: isPlayed ? colors.textDisabled : colors.accent,
                    fontWeight: isPlayed ? FontWeight.normal : FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
