import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../squad/providers/squad_provider.dart';
import '../providers/lineup_provider.dart';

/// Selection area bottom sheet displaying the best-suited replacement candidates
/// for a touched player based on the deterministic recommendation engine.
class TransferRecommendationSheet extends ConsumerStatefulWidget {
  final PlayerCandidate player;
  final VoidCallback onSubstituteRequested;
  final VoidCallback? onCaptaincyRequested;

  const TransferRecommendationSheet({
    super.key,
    required this.player,
    required this.onSubstituteRequested,
    this.onCaptaincyRequested,
  });

  @override
  ConsumerState<TransferRecommendationSheet> createState() =>
      _TransferRecommendationSheetState();
}

class _TransferRecommendationSheetState
    extends ConsumerState<TransferRecommendationSheet> {
  List<PlayerCandidate>? _candidates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final list = await ref
        .read(lineupNotifierProvider.notifier)
        .getTransferRecommendationsForPlayer(widget.player);
    if (mounted) {
      setState(() {
        _candidates = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final squadState = ref.watch(squadNotifierProvider);
    final bankTenths = squadState.bankTenths;
    final maxSpendTenths = widget.player.priceTenths + bankTenths;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusSheet),
        ),
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill handle
              Center(
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  margin: const EdgeInsets.only(bottom: AppTokens.space12),
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Player card being replaced
              Container(
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.accent, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.player.position,
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.player.webName,
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 16.0,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Current: ${AppFormatters.formatMoneyTenths(widget.player.priceTenths)} · ${widget.player.xp} xP',
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Text(
                        'Budget: ${AppFormatters.formatMoneyTenths(maxSpendTenths)}',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTokens.space16),

              // Header for recommendations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECOMMENDED REPLACEMENTS',
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.0,
                    ),
                  ),
                  Text(
                    'Ranked by Net xP',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.accent,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.space8),

              // Recommendation candidate list
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(color: colors.accent),
                  ),
                )
              else if (_candidates == null || _candidates!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTokens.space16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Text(
                    'No transfer replacements found within your current budget.',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _candidates!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space8),
                    itemBuilder: (context, index) {
                      final c = _candidates![index];
                      final netGain = c.xp - widget.player.xp;
                      final costDelta = c.priceTenths - widget.player.priceTenths;
                      final isGainPositive = netGain > 0;

                      return Container(
                        padding: const EdgeInsets.all(AppTokens.space12),
                        decoration: BoxDecoration(
                          color: colors.bgElevated,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(
                            color: index == 0 ? colors.accent : colors.borderSubtle,
                            width: index == 0 ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank number
                            Container(
                              width: 24.0,
                              height: 24.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 0 ? colors.accent : colors.bgSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  color: index == 0 ? colors.accentOn : colors.textPrimary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space12),

                            // Player Name & Cost
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.webName,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  Text(
                                    '${AppFormatters.formatMoneyTenths(c.priceTenths)} · ${costDelta >= 0 ? '+${AppFormatters.formatMoneyTenths(costDelta)}' : AppFormatters.formatMoneyTenths(costDelta)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: colors.textSecondary,
                                      fontSize: 11.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Expected Points & Gain
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${c.xp} xP',
                                  style: AppTextStyles.numeric.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.0,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: isGainPositive
                                        ? colors.statusOk.withValues(alpha: 0.15)
                                        : colors.borderSubtle,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    isGainPositive
                                        ? '+${netGain.toStringAsFixed(1)} xP'
                                        : '${netGain.toStringAsFixed(1)} xP',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isGainPositive ? colors.statusOk : colors.textSecondary,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: AppTokens.space12),

                            // Transfer CTA
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.accent),
                              tooltip: 'Open in Transfer Lab',
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push('/transfers');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              if (widget.onCaptaincyRequested != null) ...[
                const SizedBox(height: AppTokens.space8),
                TextButton.icon(
                  icon: Icon(Icons.star_outline_rounded, size: 16, color: colors.accent),
                  label: Text('Captaincy & Breakdown Options', style: TextStyle(color: colors.accent, fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onCaptaincyRequested?.call();
                  },
                ),
              ],
              const SizedBox(height: AppTokens.space12),

              // Bottom Actions: Substitute or View Details
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Substitute',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.swap_vert_rounded, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSubstituteRequested();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: AppButton(
                      label: 'Transfer Lab',
                      variant: AppButtonVariant.primary,
                      leading: const Icon(Icons.swap_horiz_rounded, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/transfers');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
