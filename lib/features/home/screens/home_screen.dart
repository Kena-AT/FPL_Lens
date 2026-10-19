import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../squad/providers/squad_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadState = ref.watch(squadNotifierProvider);
    final nextGw = squadState.nextGameweek ?? squadState.currentGameweek;

    // Calculate deadline countdown
    String countdownStr = 'TBD';
    String deadlineDateStr = '';
    if (nextGw?.deadlineTime != null) {
      final diff = nextGw!.deadlineTime!.difference(DateTime.now());
      countdownStr = AppFormatters.formatCountdown(diff);
      deadlineDateStr =
          '${nextGw.deadlineTime!.day} ${_monthName(nextGw.deadlineTime!.month)} ${nextGw.deadlineTime!.hour.toString().padLeft(2, '0')}:${nextGw.deadlineTime!.minute.toString().padLeft(2, '0')} UTC';
    }

    final totalSquadValueTenths = squadState.squad.fold<int>(
      0,
      (sum, p) => sum + p.nowCostTenths,
    );
    final effectiveSquadValue = squadState.squadValueTenths > 0
        ? squadState.squadValueTenths
        : (totalSquadValueTenths > 0 ? totalSquadValueTenths : 1000);

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Home', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTokens.neonPrimary,
        backgroundColor: AppTokens.bgSurface,
        onRefresh: () async {
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
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          children: [
            // Unconfirmed prices banner if any need confirming
            if (squadState.unconfirmedCount > 0) ...[
              GestureDetector(
                onTap: () => context.push('/squad/prices'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppTokens.space16),
                  padding: const EdgeInsets.all(AppTokens.space12),
                  decoration: BoxDecoration(
                    color: AppTokens.statusDoubtful.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppTokens.statusDoubtful.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTokens.statusDoubtful, size: 20),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          '${squadState.unconfirmedCount} player prices need confirmation.',
                          style: AppTextStyles.caption.copyWith(color: AppTokens.statusDoubtful),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTokens.statusDoubtful, size: 20),
                    ],
                  ),
                ),
              ),
            ],

            // 1. Deadline Card
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
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
                        nextGw != null ? nextGw.name : 'Next deadline',
                        style: AppTextStyles.label,
                      ),
                      if (deadlineDateStr.isNotEmpty)
                        Text(
                          deadlineDateStr,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    countdownStr,
                    style: AppTextStyles.numeric.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.goldPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  FreshnessLabel(
                    lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // 2. Summary row of 3 StatTiles: Squad value, Bank, Free transfers
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Squad value',
                    value: AppFormatters.formatMoneyTenths(effectiveSquadValue),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: StatTile(
                    label: 'In bank',
                    value: AppFormatters.formatMoneyTenths(squadState.bankTenths),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: StatTile(
                    label: 'Transfers',
                    value: '${squadState.freeTransfers}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),

            // 3. Projection Card
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projected total', style: AppTextStyles.headline),
                  const SizedBox(height: AppTokens.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '--',
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      FreshnessLabel(
                        lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space16),
                  AppButton(
                    label: 'View lineup',
                    onPressed: () => context.push('/lineup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // 4. Quick Actions
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Squad'),
                  onPressed: () => context.go('/squad'),
                  backgroundColor: AppTokens.bgSurface,
                ),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                  onPressed: () => context.push('/history'),
                  backgroundColor: AppTokens.bgSurface,
                ),
                ActionChip(
                  avatar: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Prices'),
                  onPressed: () => context.push('/squad/prices'),
                  backgroundColor: AppTokens.bgSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
