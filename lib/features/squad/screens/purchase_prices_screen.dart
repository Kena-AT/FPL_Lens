import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/squad_provider.dart';

class PurchasePricesScreen extends ConsumerStatefulWidget {
  const PurchasePricesScreen({super.key});

  @override
  ConsumerState<PurchasePricesScreen> createState() => _PurchasePricesScreenState();
}

class _PurchasePricesScreenState extends ConsumerState<PurchasePricesScreen> {
  final Map<int, int> _purchasePriceTenths = {};
  bool _isSaving = false;

  int _calculateSellingPrice(int purchaseTenths, int currentTenths) {
    if (currentTenths <= purchaseTenths) {
      return currentTenths;
    }
    // FPL rule: purchase price + half of the rise rounded down
    final rise = currentTenths - purchaseTenths;
    return purchaseTenths + (rise ~/ 2);
  }

  void _stepPrice(int fplId, int deltaTenths) {
    final current = _purchasePriceTenths[fplId] ?? 50;
    final updated = (current + deltaTenths).clamp(35, 200);
    setState(() {
      _purchasePriceTenths[fplId] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final squadState = ref.watch(squadNotifierProvider);
    final unconfirmedPlayers = squadState.squad.where((p) => p.priceSource == 'CONFIRM').toList();
    final displayPlayers = unconfirmedPlayers.isNotEmpty ? unconfirmedPlayers : squadState.squad;

    // Initialize map
    for (final p in displayPlayers) {
      if (!_purchasePriceTenths.containsKey(p.fplId)) {
        _purchasePriceTenths[p.fplId] = p.purchasePriceTenths > 0 ? p.purchasePriceTenths : p.nowCostTenths;
      }
    }

    final bankTenths = squadState.bankTenths;
    final hasUnconfirmed = unconfirmedPlayers.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text('Purchase Prices', style: AppTextStyles.title.copyWith(color: colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Skip', style: TextStyle(color: colors.textSecondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.screenGutter),
                children: [
                  // 1. Header Tile: Bank Balance in Hero Numeral (§8.14) with Estimated label (§9.6)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: colors.borderSubtle),
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
                              'In The Bank',
                              style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                            ),
                            if (hasUnconfirmed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.statusWarn.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Estimated',
                                  style: AppTextStyles.caption.copyWith(
                                    color: colors.statusWarn,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatMoneyTenths(bankTenths),
                          style: AppTextStyles.numeric.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasUnconfirmed
                              ? 'Estimated. Confirm each purchase price to make this exact.'
                              : 'All squad purchase prices are confirmed.',
                          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),

                  // 2. Formula disclaimer note (§9.6: prices.formulaNote)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Text(
                      'Selling price is estimated as: purchase price, plus half of any rise since you bought (rounded down). This rule is not yet verified against official FPL rules.',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  // 3. Player Price Tiles (§8.14)
                  ...displayPlayers.map((player) {
                    final currentPriceTenths = player.nowCostTenths;
                    final purchaseTenths = _purchasePriceTenths[player.fplId] ?? currentPriceTenths;
                    final sellingTenths = _calculateSellingPrice(purchaseTenths, currentPriceTenths);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.space12),
                      padding: const EdgeInsets.all(AppTokens.space12),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.webName,
                                      style: AppTextStyles.headline.copyWith(
                                        fontSize: 16,
                                        color: colors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${player.position} · Current: ${AppFormatters.formatMoneyTenths(currentPriceTenths)}',
                                      style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: player.priceSource == 'CONFIRM'
                                      ? colors.statusWarn.withValues(alpha: 0.15)
                                      : colors.bgElevated,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  player.priceSource == 'CONFIRM' ? 'Needs check' : 'Locked',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    color: player.priceSource == 'CONFIRM'
                                        ? colors.statusWarn
                                        : colors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.space12),

                          // Price Stepper Row (§8.14: + and − with 48dp touch targets)
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppTokens.space8,
                            runSpacing: AppTokens.space8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Purchase Price',
                                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // − Stepper button (min 48×48 dp)
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: IconButton(
                                          icon: Icon(Icons.remove_circle_outline, color: colors.accent),
                                          iconSize: 28,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _stepPrice(player.fplId, -1),
                                          tooltip: 'Decrease purchase price by £0.1m',
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colors.bgElevated,
                                          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                                          border: Border.all(color: colors.borderSubtle),
                                        ),
                                        child: Text(
                                          AppFormatters.formatMoneyTenths(purchaseTenths),
                                          style: AppTextStyles.numeric.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // + Stepper button (min 48×48 dp)
                                      SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: IconButton(
                                          icon: Icon(Icons.add_circle_outline, color: colors.accent),
                                          iconSize: 28,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _stepPrice(player.fplId, 1),
                                          tooltip: 'Increase purchase price by £0.1m',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Estimated Selling Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sell Price',
                                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppFormatters.formatMoneyTenths(sellingTenths),
                                    style: AppTextStyles.numeric.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colors.statusOk,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Sticky footer CTA
            Container(
              padding: const EdgeInsets.all(AppTokens.screenGutter),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(top: BorderSide(color: colors.borderSubtle)),
              ),
              child: AppButton(
                label: 'Confirm & Save Prices',
                isLoading: _isSaving,
                onPressed: () => _savePrices(displayPlayers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrices(List<dynamic> players) async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(squadNotifierProvider.notifier);
      for (final p in players) {
        final tenths = _purchasePriceTenths[p.fplId];
        if (tenths != null) {
          await notifier.confirmPurchasePrice(p.fplId, tenths);
        }
      }
      if (mounted) {
        context.go('/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
