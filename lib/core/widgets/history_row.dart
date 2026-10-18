import 'package:flutter/material.dart';
import '../formatting/app_formatters.dart';
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
    required int event,
    required int points,
    required int overallRank,
    required int transferCost,
    int? pointsOnBench,
  }) {
    final transferHitText = transferCost > 0 ? '-$transferCost' : 'No hit';
    final semantic =
        'Gameweek $event: $points points, rank ${AppFormatters.formatRank(overallRank)}, transfers $transferHitText';

    return HistoryRow._(
      semanticLabel: semantic,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        decoration: const BoxDecoration(
          color: AppTokens.bgSurface,
          border: Border(bottom: BorderSide(color: AppTokens.borderSubtle)),
        ),
        child: Row(
          children: [
            // Left: GW chip
            Container(
              width: 56,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.bgElevated,
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Text(
                'GW $event',
                style: AppTextStyles.label.copyWith(
                  color: AppTokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space16),

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
                        ),
                      ),
                      if (pointsOnBench != null && pointsOnBench > 0) ...[
                        const SizedBox(width: AppTokens.space8),
                        Text(
                          '(${pointsOnBench}b)',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    'Rank ${AppFormatters.formatRank(overallRank)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Right: Transfer Cost
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transferHitText,
                  style: AppTextStyles.numeric.copyWith(
                    color: transferCost > 0
                        ? AppTokens.statusOut
                        : AppTokens.textSecondary,
                    fontWeight: transferCost > 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  'Transfers',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
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
    required DateTime date,
    required String playerInName,
    required int playerInCostTenths,
    required String playerOutName,
    required int playerOutCostTenths,
    String? priceSource,
  }) {
    final semantic =
        'Transfer on ${date.year}-${date.month}-${date.day}: In $playerInName at ${AppFormatters.formatMoneyTenths(playerInCostTenths)}, Out $playerOutName at ${AppFormatters.formatMoneyTenths(playerOutCostTenths)}';

    return HistoryRow._(
      semanticLabel: semantic,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        decoration: const BoxDecoration(
          color: AppTokens.bgSurface,
          border: Border(bottom: BorderSide(color: AppTokens.borderSubtle)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppFormatters.formatRelativeTime(date),
                  style: AppTextStyles.caption,
                ),
                if (priceSource != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTokens.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priceSource,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: priceSource == 'FROM_TRANSFER'
                            ? AppTokens.statusAvailable
                            : AppTokens.statusDoubtful,
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
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTokens.statusAvailable,
                        size: 16,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          playerInName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatMoneyTenths(playerInCostTenths),
                        style: AppTextStyles.numeric.copyWith(fontSize: 13),
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
                      const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: AppTokens.statusOut,
                        size: 16,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        child: Text(
                          playerOutName,
                          style: AppTextStyles.body.copyWith(
                            color: AppTokens.textSecondary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatMoneyTenths(playerOutCostTenths),
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 13,
                          color: AppTokens.textSecondary,
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
