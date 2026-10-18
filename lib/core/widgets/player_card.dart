import 'package:flutter/material.dart';
import '../formatting/app_formatters.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';

enum PlayerAvailability {
  available,
  doubtful,
  injured,
  suspended,
  unavailable,
}

class PlayerCard extends StatelessWidget {
  final String webName;
  final String positionText; // 'GK', 'DEF', 'MID', 'FWD'
  final String teamShortName;
  final int nowCostTenths;
  final int? purchasePriceTenths;
  final String? priceSource; // 'CONFIRM', 'FROM_TRANSFER', 'CONFIRMED_USER'
  final PlayerAvailability availability;
  final int? chanceOfPlaying;
  final bool isSelected;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback? onTap;
  final VoidCallback? onPriceTap;

  const PlayerCard({
    super.key,
    required this.webName,
    required this.positionText,
    required this.teamShortName,
    required this.nowCostTenths,
    this.purchasePriceTenths,
    this.priceSource,
    this.availability = PlayerAvailability.available,
    this.chanceOfPlaying,
    this.isSelected = false,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.onTap,
    this.onPriceTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status badge
    Widget? statusWidget;
    String statusSemanticText = 'available';

    switch (availability) {
      case PlayerAvailability.injured:
        statusSemanticText = 'injured';
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, size: 12, color: AppTokens.statusOut),
            const SizedBox(width: 4),
            Text(
              'Injured',
              style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
            ),
          ],
        );
        break;
      case PlayerAvailability.doubtful:
        final chanceText = chanceOfPlaying != null ? ', $chanceOfPlaying%' : '';
        statusSemanticText = 'doubtful$chanceText';
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: AppTokens.statusDoubtful),
            const SizedBox(width: 4),
            Text(
              'Doubtful$chanceText',
              style: AppTextStyles.caption.copyWith(color: AppTokens.statusDoubtful),
            ),
          ],
        );
        break;
      case PlayerAvailability.suspended:
        statusSemanticText = 'suspended';
        statusWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block_rounded, size: 12, color: AppTokens.statusOut),
            const SizedBox(width: 4),
            Text(
              'Suspended',
              style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
            ),
          ],
        );
        break;
      case PlayerAvailability.unavailable:
        statusSemanticText = 'not in squad';
        statusWidget = Text(
          'Not in squad',
          style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
        );
        break;
      case PlayerAvailability.available:
        statusSemanticText = 'available';
        statusWidget = null;
        break;
    }

    final priceStatusIsConfirm = priceSource == 'CONFIRM';

    final semantic =
        '$webName, $positionText, $teamShortName, ${AppFormatters.formatMoneyTenths(nowCostTenths)}, $statusSemanticText${isCaptain ? ", Captain" : ""}${isViceCaptain ? ", Vice-captain" : ""}';

    return Semantics(
      label: semantic,
      selected: isSelected,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space12,
          ),
          decoration: BoxDecoration(
            color: AppTokens.bgSurface,
            border: Border(
              bottom: const BorderSide(color: AppTokens.borderSubtle),
              left: isSelected
                  ? const BorderSide(color: AppTokens.neonPrimary, width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              // Position chip
              Container(
                width: 38,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTokens.bgElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: Text(
                  positionText.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),

              // Middle: Name, team and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            webName,
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 16,
                              color: availability == PlayerAvailability.unavailable
                                  ? AppTokens.textDisabled
                                  : AppTokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCaptain) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTokens.goldPrimary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'C',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.bgBase,
                              ),
                            ),
                          ),
                        ] else if (isViceCaptain) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTokens.textSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'V',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.bgBase,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Row(
                      children: [
                        Text(
                          teamShortName.toUpperCase(),
                          style: AppTextStyles.caption,
                        ),
                        if (statusWidget != null) ...[
                          const SizedBox(width: AppTokens.space8),
                          statusWidget,
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Price and source label
              GestureDetector(
                onTap: onPriceTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppFormatters.formatMoneyTenths(nowCostTenths),
                      style: AppTextStyles.numeric.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    if (priceSource != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priceStatusIsConfirm
                              ? AppTokens.statusDoubtful.withValues(alpha: 0.15)
                              : AppTokens.bgElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: priceStatusIsConfirm
                              ? Border.all(color: AppTokens.statusDoubtful.withValues(alpha: 0.5))
                              : null,
                        ),
                        child: Text(
                          priceSource!,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: priceStatusIsConfirm
                                ? AppTokens.statusDoubtful
                                : AppTokens.textSecondary,
                          ),
                        ),
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
