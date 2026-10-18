import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/squad_provider.dart';

class PurchasePricesScreen extends ConsumerStatefulWidget {
  const PurchasePricesScreen({super.key});

  @override
  ConsumerState<PurchasePricesScreen> createState() => _PurchasePricesScreenState();
}

class _PurchasePricesScreenState extends ConsumerState<PurchasePricesScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String?> _errors = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);
    // Find players needing price confirmation (or all players if user opened from settings)
    final unconfirmedPlayers = squadState.squad.where((p) => p.priceSource == 'CONFIRM').toList();
    final displayPlayers = unconfirmedPlayers.isNotEmpty ? unconfirmedPlayers : squadState.squad;

    // Ensure controllers exist
    for (final p in displayPlayers) {
      if (!_controllers.containsKey(p.fplId)) {
        final currentEstimateStr = (p.purchasePriceTenths / 10.0).toStringAsFixed(1);
        _controllers[p.fplId] = TextEditingController(text: currentEstimateStr);
      }
    }

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Purchase prices', style: AppTextStyles.title),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/home');
            },
            child: const Text('Skip for now', style: TextStyle(color: AppTokens.textSecondary)),
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
                  // Explanation card
                  Container(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    decoration: BoxDecoration(
                      color: AppTokens.bgSurface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppTokens.borderSubtle),
                    ),
                    child: Text(
                      'Your squad was loaded from FPL. Some purchase prices aren\'t available there. Enter them so profit and sell values are right. You can change them later.',
                      style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space16),

                  // Players needing confirmation
                  ...displayPlayers.map((player) {
                    final controller = _controllers[player.fplId]!;
                    final error = _errors[player.fplId];

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTokens.space12),
                      padding: const EdgeInsets.all(AppTokens.space12),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.webName,
                                      style: AppTextStyles.headline.copyWith(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${player.position} · Current: ${AppFormatters.formatMoneyTenths(player.nowCostTenths)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: player.priceSource == 'CONFIRM'
                                      ? AppTokens.statusDoubtful.withValues(alpha: 0.15)
                                      : AppTokens.bgElevated,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  player.priceSource,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    color: player.priceSource == 'CONFIRM'
                                        ? AppTokens.statusDoubtful
                                        : AppTokens.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.space12),
                          AppTextField(
                            label: 'Purchase price (£m)',
                            type: AppTextFieldType.numeric,
                            controller: controller,
                            error: error,
                            onChanged: (val) {
                              _validateField(player.fplId, val);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Sticky footer
            Container(
              padding: const EdgeInsets.all(AppTokens.screenGutter),
              decoration: const BoxDecoration(
                color: AppTokens.bgSurface,
                border: Border(top: BorderSide(color: AppTokens.borderSubtle)),
              ),
              child: AppButton(
                label: 'Save prices',
                onPressed: () => _savePrices(displayPlayers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateField(int playerId, String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _errors[playerId] = null;
      });
      return;
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0.0 || parsed > 20.0) {
      setState(() {
        _errors[playerId] = 'Enter a price between £0.0m and £20.0m.';
      });
    } else {
      setState(() {
        _errors[playerId] = null;
      });
    }
  }

  Future<void> _savePrices(List<dynamic> players) async {
    bool hasError = false;
    for (final p in players) {
      final text = _controllers[p.fplId]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed == null || parsed < 0.0 || parsed > 20.0) {
          setState(() {
            _errors[p.fplId] = 'Enter a price between £0.0m and £20.0m.';
          });
          hasError = true;
        }
      }
    }

    if (hasError) return;

    final notifier = ref.read(squadNotifierProvider.notifier);
    for (final p in players) {
      final text = _controllers[p.fplId]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final tenths = AppFormatters.parseMoneyToTenths(text);
        if (tenths != null) {
          await notifier.confirmPurchasePrice(p.fplId, tenths);
        }
      }
    }

    if (mounted) {
      context.go('/home');
    }
  }
}
