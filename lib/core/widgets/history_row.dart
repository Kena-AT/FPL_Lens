import 'package:flutter/material.dart';
import '../formatting/app_formatters.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

class HistoryRow extends StatelessWidget {
  final Widget child;
  final String semanticLabel;

  const HistoryRow._({
    required this.child,
    required this.semanticLabel,
  });

  factory HistoryRow.gameweek({
    Key? key,
    BuildContext? context,
    required int event,
    required int points,
    required int overallRank,
    int? gameweekRank,
    bool showGwRank = false,
    required int transferCost,
    int? pointsOnBench,
  }) {
    final colors = context != null ? AppColors.of(context) : AppColors.dark;
    final transferHitText = transferCost > 0 ? '-$transferCost' : '0';
    final displayedRank = showGwRank && gameweekRank != null ? gameweekRank : overallRank;
    final rankLabel = showGwRank ? 'GW rank' : 'Rank';
    final semantic =
        'Gameweek $event: $points points, $rankLabel ${AppFormatters.formatRank(displayedRank)}, hit cost $transferHitText';

    return HistoryRow._(
      semanticLabel: semantic,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.screenGutter,
          vertical: AppTokens.space12,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
        child: Row(
          children: [
            // Left: GW chip
            Container(
              width: 58,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                border: Border.all(color: colors.borderSubtle, width: 0.5),
              ),
              child: Text(
                'GW $event',
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space12),

            // Middle: Points and Rank
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${AppFormatters.formatPoints(points)} pts',
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (pointsOnBench != null && pointsOnBench > 0) ...[
                        const SizedBox(width: AppTokens.space8),
                        Text(
                          '(${pointsOnBench}b)',
                          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$rankLabel ${AppFormatters.formatRank(displayedRank)}',
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),

            // Right: Transfer Hit Cost in statusError (§8.13)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transferHitText,
                  style: AppTextStyles.numeric.copyWith(
                    color: transferCost > 0 ? colors.statusError : colors.textSecondary,
                    fontWeight: transferCost > 0 ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hit cost',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  factory HistoryRow.transfer({
    Key? key,
    BuildContext? context,
    required DateTime date,
    required String playerInName,
    required int playerInCostTenths,
    required String playerOutName,
    required int playerOutCostTenths,
    String? priceSource,
  }) {
    final colors = context != null ? AppColors.of(context) : AppColors.dark;
    final semantic =
        'Transfer on ${date.year}-${date.month}-${date.day}: In $playerInName at ${AppFormatters.formatMoneyTenths(playerInCostTenths)}, Out $playerOutName at ${AppFormatters.formatMoneyTenths(playerOutCostTenths)}';

    return HistoryRow._(
      semanticLabel: semantic,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.screenGutter,
          vertical: AppTokens.space12,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
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
                  AppFormatters.formatRelativeTime(date),
                  style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                ),
                if (priceSource != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priceSource,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: priceSource == 'FROM_TRANSFER'
                            ? colors.statusOk
                            : colors.statusWarn,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Row(
              children: [
                // In row
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: colors.statusOk,
                        size: 16,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          playerInName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatMoneyTenths(playerInCostTenths),
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            Row(
              children: [
                // Out row
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_circle_outline_rounded,
                        color: colors.statusError,
                        size: 16,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          playerOutName,
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatMoneyTenths(playerOutCostTenths),
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: child,
    );
  }
}
