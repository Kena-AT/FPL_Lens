import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/app_formatters.dart';
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
    final squadState = ref.watch(squadNotifierProvider);
    final gameweeks = squadState.gameweekHistory;
    final transfers = squadState.transfers;

    final latestGw = gameweeks.isNotEmpty ? gameweeks.first : null;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('History', style: AppTextStyles.title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTokens.neonPrimary,
          indicatorWeight: 3,
          labelColor: AppTokens.textPrimary,
          unselectedLabelColor: AppTokens.textSecondary,
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
                  body:
                      'Your history appears after your first finished gameweek of the season.',
                )
              : ListView(
                  children: [
                    // Summary card at top
                    if (latestGw != null)
                      Container(
                        margin: const EdgeInsets.all(AppTokens.screenGutter),
                        padding: const EdgeInsets.all(AppTokens.space16),
                        decoration: BoxDecoration(
                          color: AppTokens.bgSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(color: AppTokens.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Total points', style: AppTextStyles.label),
                                const SizedBox(height: AppTokens.space4),
                                Text(
                                  '${latestGw.totalPoints}',
                                  style: AppTextStyles.numeric.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 40, color: AppTokens.borderSubtle),
                            Column(
                              children: [
                                const Text('Overall rank', style: AppTextStyles.label),
                                const SizedBox(height: AppTokens.space4),
                                Text(
                                  AppFormatters.formatRank(latestGw.overallRank),
                                  style: AppTextStyles.numeric.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.goldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ...gameweeks.map((gw) {
                      return HistoryRow.gameweek(
                        event: gw.gameweek,
                        points: gw.points,
                        overallRank: gw.overallRank,
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
}
