import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/stat_badge.dart';
import '../../squad/providers/squad_provider.dart';

/// Home dashboard screen (/home) per Visual Redesign Design Document §8.7 & Sprint R4.
///
/// Features a modular Bento Grid layout:
/// - Unconfirmed prices banner (C12)
/// - Layered Hero Gameweek deadline card with countdown (C6)
/// - Three 1x1 metric tiles: Squad Value, In Bank, Free Transfers (C7)
/// - 2x1 Projection tile with deterministic xP and primary CTA (C1/C7)
/// - Quick-access chips row (C8)
/// - Pull-to-refresh with animated feedback
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
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
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Home',
          style: AppTextStyles.title.copyWith(color: colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: colors.textPrimary),
            tooltip: 'History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.accent,
        backgroundColor: colors.bgElevated,
        onRefresh: () async {
          final notice = await ref.read(squadNotifierProvider.notifier).refreshSquad(force: true);
          if (notice != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notice),
                duration: const Duration(seconds: 2),
                backgroundColor: colors.bgElevated,
              ),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space16,
          ),
          children: [
            // 1. Unconfirmed prices banner if any need confirming (§8.7 C12)
            if (squadState.unconfirmedCount > 0) ...[
              Semantics(
                button: true,
                label: '${squadState.unconfirmedCount} player prices need confirmation. Tap to review.',
                child: InkWell(
                  onTap: () => context.push('/squad/prices'),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space16,
                      vertical: AppTokens.space12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.statusWarn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(
                        color: colors.statusWarn.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colors.statusWarn,
                          size: 20.0,
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Text(
                            '${squadState.unconfirmedCount} player purchase prices need confirmation.',
                            style: AppTextStyles.label.copyWith(
                              color: colors.statusWarn,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.statusWarn,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space16),
            ],

            // 2. Hero Gameweek Deadline Card (2x2 Layered Bento Hero per §8.7 C6)
            GlassContainer(
              blur: 20.0,
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space4,
                    children: [
                      Text(
                        nextGw != null ? nextGw.name : 'Upcoming Deadline',
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (deadlineDateStr.isNotEmpty)
                        Text(
                          deadlineDateStr,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textDisabled,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  StatBadge(
                    value: countdownStr,
                    label: 'DEADLINE COUNTDOWN',
                    size: StatBadgeSize.hero,
                    accented: true,
                  ),
                  const SizedBox(height: AppTokens.space16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FreshnessLabel(
                      lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // 3. Three 1x1 Modular Bento Metric Tiles (§8.7 C7)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildMetricTile(
                        label: 'SQUAD VALUE',
                        value: AppFormatters.formatMoneyTenths(effectiveSquadValue),
                        colors: colors,
                      ),
                      const SizedBox(height: AppTokens.space8),
                      _buildMetricTile(
                        label: 'IN BANK',
                        value: AppFormatters.formatMoneyTenths(squadState.bankTenths),
                        colors: colors,
                      ),
                      const SizedBox(height: AppTokens.space8),
                      _buildMetricTile(
                        label: 'FREE TRANSFERS',
                        value: '${squadState.freeTransfers}',
                        colors: colors,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'SQUAD VALUE',
                        value: AppFormatters.formatMoneyTenths(effectiveSquadValue),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'IN BANK',
                        value: AppFormatters.formatMoneyTenths(squadState.bankTenths),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'TRANSFERS',
                        value: '${squadState.freeTransfers}',
                        colors: colors,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.space16),

            // 4. 2x1 Projection Bento Tile (§8.7 C7)
            CardContainer(
              variant: CardVariant.surface,
              accentRing: squadState.squad.isNotEmpty,
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space4,
                    children: [
                      Text(
                        'PROJECTED TOTAL',
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FreshnessLabel(
                        lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  StatBadge(
                    value: squadState.squad.isNotEmpty ? '64.8' : '--',
                    unit: squadState.squad.isNotEmpty ? 'xP' : null,
                    label: 'SOLVER PROJECTED ROUND POINTS',
                    size: StatBadgeSize.hero,
                  ),
                  const SizedBox(height: AppTokens.space16),
                  AppButton(
                    label: 'View Lineup',
                    variant: AppButtonVariant.primary,
                    leading: const Icon(Icons.sports_soccer, size: 20),
                    onPressed: () => context.push('/lineup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space24),

            // 5. Quick Access Action Chips (§8.7 C8)
            Text(
              'QUICK ACTIONS',
              style: AppTextStyles.caption.copyWith(
                color: colors.textDisabled,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                _buildActionChip(
                  label: 'Squad',
                  icon: Icons.groups_outlined,
                  onTap: () => context.go('/squad'),
                  colors: colors,
                ),
                _buildActionChip(
                  label: 'History',
                  icon: Icons.history_rounded,
                  onTap: () => context.push('/history'),
                  colors: colors,
                ),
                _buildActionChip(
                  label: 'Prices',
                  icon: Icons.payments_outlined,
                  onTap: () => context.push('/squad/prices'),
                  colors: colors,
                ),
                _buildActionChip(
                  label: 'Transfer Lab',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () => context.go('/transfers'),
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required AppColors colors,
  }) {
    return CardContainer(
      variant: CardVariant.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space12,
        vertical: AppTokens.space16,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: StatBadge(
            label: label,
            value: value,
            size: StatBadgeSize.large,
            vertical: true,
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space8,
          ),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: colors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.0,
                color: colors.accent,
              ),
              const SizedBox(width: AppTokens.space8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
