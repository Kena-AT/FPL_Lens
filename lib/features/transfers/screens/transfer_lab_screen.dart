import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/optimiser/transfer_optimiser.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/candidate_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hit_warning.dart';
import '../../../core/widgets/pitch_view.dart';
import '../../squad/providers/squad_provider.dart';

/// Screen P12: TransferLabScreen (Spec §6, Frontend Implementation Plan §3).
/// Interactive transfer planning across Horizons 1, 3, and 5 with discount gamma = 0.90.
class TransferLabScreen extends ConsumerStatefulWidget {
  const TransferLabScreen({super.key});

  @override
  ConsumerState<TransferLabScreen> createState() => _TransferLabScreenState();
}

class _TransferLabScreenState extends ConsumerState<TransferLabScreen> {
  int _selectedHorizon = 1; // 1, 3, or 5
  bool _isOptimizing = false;
  TransferMove? _recommendedMove;

  List<PlayerCandidate> _buildCandidatesFromSquad() {
    final squadState = ref.read(squadNotifierProvider);
    return squadState.squad.map((p) {
      final pos = p.position == 'GKP' ? 'GK' : p.position;
      final pStart = (p.chanceOfPlayingNextRound != null)
          ? (p.chanceOfPlayingNextRound! / 100.0).clamp(0.05, 0.95)
          : (p.status == 'out' ? 0.05 : 0.90);
      final xp = (p.nowCostTenths / 20.0).clamp(1.5, 9.5);

      return PlayerCandidate(
        fplId: p.fplId,
        webName: p.webName,
        position: pos,
        clubId: p.teamId,
        priceTenths: p.nowCostTenths,
        sellingPriceTenths: p.sellingPriceTenths,
        xp: double.parse(xp.toStringAsFixed(1)),
        pStart: double.parse(pStart.toStringAsFixed(2)),
        pSub: 0.05,
      );
    }).toList();
  }

  /// Curated candidate pool for transfer exploration
  List<PlayerCandidate> _generateAvailablePool(List<PlayerCandidate> currentSquad) {
    final currentIds = currentSquad.map((p) => p.fplId).toSet();
    const mockTargets = [
      PlayerCandidate(fplId: 101, webName: 'Haaland', position: 'FWD', clubId: 4, priceTenths: 152, sellingPriceTenths: 152, xp: 9.2, pStart: 0.95, pSub: 0.05),
      PlayerCandidate(fplId: 102, webName: 'Salah', position: 'MID', clubId: 3, priceTenths: 128, sellingPriceTenths: 128, xp: 8.8, pStart: 0.96, pSub: 0.05),
      PlayerCandidate(fplId: 103, webName: 'Palmer', position: 'MID', clubId: 6, priceTenths: 110, sellingPriceTenths: 110, xp: 8.2, pStart: 0.94, pSub: 0.05),
      PlayerCandidate(fplId: 104, webName: 'Saka', position: 'MID', clubId: 1, priceTenths: 102, sellingPriceTenths: 102, xp: 7.9, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 105, webName: 'Alexander-Arnold', position: 'DEF', clubId: 3, priceTenths: 72, sellingPriceTenths: 72, xp: 6.5, pStart: 0.90, pSub: 0.05),
      PlayerCandidate(fplId: 106, webName: 'Gabriel', position: 'DEF', clubId: 1, priceTenths: 62, sellingPriceTenths: 62, xp: 5.2, pStart: 0.95, pSub: 0.05),
      PlayerCandidate(fplId: 107, webName: 'Gvardiol', position: 'DEF', clubId: 4, priceTenths: 61, sellingPriceTenths: 61, xp: 5.3, pStart: 0.90, pSub: 0.05),
      PlayerCandidate(fplId: 108, webName: 'Watkins', position: 'FWD', clubId: 7, priceTenths: 91, sellingPriceTenths: 91, xp: 6.9, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 109, webName: 'Wood', position: 'FWD', clubId: 2, priceTenths: 64, sellingPriceTenths: 64, xp: 5.8, pStart: 0.88, pSub: 0.10),
      PlayerCandidate(fplId: 110, webName: 'Mbeumo', position: 'MID', clubId: 8, priceTenths: 78, sellingPriceTenths: 78, xp: 6.4, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 111, webName: 'Raya', position: 'GK', clubId: 1, priceTenths: 56, sellingPriceTenths: 56, xp: 4.9, pStart: 0.98, pSub: 0.02),
      PlayerCandidate(fplId: 112, webName: 'Sels', position: 'GK', clubId: 2, priceTenths: 48, sellingPriceTenths: 48, xp: 4.4, pStart: 0.96, pSub: 0.02),
    ];

    return mockTargets.where((p) => !currentIds.contains(p.fplId)).toList();
  }

  void _runOptimiser() {
    final squadState = ref.read(squadNotifierProvider);
    if (!squadState.hasSquad) return;

    setState(() {
      _isOptimizing = true;
    });

    try {
      final currentSquad = _buildCandidatesFromSquad();
      final pool = _generateAvailablePool(currentSquad);

      final move = TransferOptimiser.optimizeTransfersMultiHorizon(
        currentSquad: currentSquad,
        availablePool: pool,
        bankTenths: squadState.bankTenths,
        freeTransfersAvailable: squadState.freeTransfers,
        horizon: _selectedHorizon,
      );

      setState(() {
        _recommendedMove = move;
        _isOptimizing = false;
      });
    } catch (_) {
      setState(() {
        _isOptimizing = false;
      });
    }
  }

  void _openCandidatePicker(PlayerCandidate playerToReplace) {
    final squadState = ref.read(squadNotifierProvider);
    final maxBudget = squadState.bankTenths + playerToReplace.sellingPriceTenths;
    final currentSquad = _buildCandidatesFromSquad();
    final pool = _generateAvailablePool(currentSquad);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CandidatePicker(
          availableCandidates: pool,
          maxBudgetTenths: maxBudget,
          initialPositionFilter: playerToReplace.position,
          onCandidateSelected: (chosen) {
            // Apply single manual replacement and re-evaluate
            final updatedSquad = currentSquad.map((p) => p.fplId == playerToReplace.fplId ? chosen : p).toList();
            final move = TransferOptimiser.optimizeTransfersHorizon1(
              currentSquad: updatedSquad,
              availablePool: const [],
              bankTenths: squadState.bankTenths,
              freeTransfersAvailable: squadState.freeTransfers,
            );
            setState(() {
              _recommendedMove = TransferMove(
                transfersOut: [playerToReplace],
                transfersIn: [chosen],
                hitCost: TransferOptimiser.computeHitCost(1, squadState.freeTransfers),
                netExpectedPoints: move.lineupResult.totalExpectedPoints,
                lineupResult: move.lineupResult,
                horizon: _selectedHorizon,
              );
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);

    if (!squadState.hasSquad) {
      return Scaffold(
        backgroundColor: AppTokens.bgBase,
        appBar: AppBar(title: const Text('Transfer Lab'), backgroundColor: AppTokens.bgBase),
        body: const Center(
          child: EmptyState(
            icon: Icons.swap_horiz_outlined,
            title: 'No squad loaded',
            body: 'Sync your squad to access Transfer Lab.',
          ),
        ),
      );
    }

    final bankStr = '£${(squadState.bankTenths / 10.0).toStringAsFixed(1)}m';

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Transfer Lab', style: AppTextStyles.headline),
        backgroundColor: AppTokens.bgBase,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isOptimizing
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: AppTokens.neonPrimary),
                  )
                : const Icon(Icons.auto_awesome_rounded, color: AppTokens.neonPrimary),
            tooltip: 'Run Transfer Optimiser',
            onPressed: _isOptimizing ? null : _runOptimiser,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizon Selector (H1, H3, H5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 8.0),
              child: Row(
                children: [
                  _buildHorizonTab(1, 'Horizon 1 (Next GW)'),
                  const SizedBox(width: 8.0),
                  _buildHorizonTab(3, 'Horizon 3'),
                  const SizedBox(width: 8.0),
                  _buildHorizonTab(5, 'Horizon 5'),
                ],
              ),
            ),

            // Status Bar: Bank & Free Transfers
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 8.0),
              padding: const EdgeInsets.all(AppTokens.space12),
              decoration: BoxDecoration(
                color: AppTokens.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('IN THE BANK', bankStr, AppTokens.goldPrimary),
                  Container(width: 1.0, height: 28.0, color: AppTokens.borderSubtle),
                  _buildMetric('FREE TRANSFERS', '${squadState.freeTransfers}', AppTokens.neonPrimary),
                ],
              ),
            ),

            // Hit Warning (if transfers exceed free allowance)
            if (_recommendedMove != null && _recommendedMove!.hitCost > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 4.0),
                child: HitWarning(
                  hitCost: _recommendedMove!.hitCost,
                  transferCount: _recommendedMove!.transferCount,
                  freeTransfers: squadState.freeTransfers,
                ),
              ),

            // Recommended Transfer Move Card
            if (_recommendedMove != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 8.0),
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: AppTokens.bgElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.neonPrimary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _recommendedMove!.transfersOut.isEmpty
                              ? 'RECOMMENDED: ROLL TRANSFER'
                              : 'RECOMMENDED MOVE (${_recommendedMove!.transferCount} TRANSFER)',
                          style: AppTextStyles.label.copyWith(
                            color: AppTokens.neonPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${_recommendedMove!.netExpectedPoints.toStringAsFixed(1)} xP',
                          style: AppTextStyles.numeric.copyWith(
                            color: AppTokens.neonPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    if (_recommendedMove!.transfersOut.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('OUT', style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut)),
                                const SizedBox(height: 2.0),
                                Text(
                                  _recommendedMove!.transfersOut.map((p) => p.webName).join(', '),
                                  style: AppTextStyles.headline.copyWith(fontSize: 14.0),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, color: AppTokens.textSecondary),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('IN', style: AppTextStyles.caption.copyWith(color: AppTokens.statusAvailable)),
                                const SizedBox(height: 2.0),
                                Text(
                                  _recommendedMove!.transfersIn.map((p) => p.webName).join(', '),
                                  style: AppTextStyles.headline.copyWith(fontSize: 14.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No transfer improves your projected squad value after hit costs.',
                        style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary, fontSize: 13.0),
                      ),
                  ],
                ),
              ),

            // Projected Squad Pitch Preview
            if (_recommendedMove != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 8.0),
                child: Text(
                  'PROJECTED LINEUP',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
              PitchView(
                startingXi: _recommendedMove!.lineupResult.startingXi,
                captain: _recommendedMove!.lineupResult.captain,
                viceCaptain: _recommendedMove!.lineupResult.viceCaptain,
                onPlayerTap: (p) => _openCandidatePicker(p),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(AppTokens.screenGutter),
                child: Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.neonPrimary,
                      side: const BorderSide(color: AppTokens.neonPrimary),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    ),
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Find Optimal Transfers'),
                    onPressed: _runOptimiser,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizonTab(int h, String title) {
    final isSelected = _selectedHorizon == h;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedHorizon = h;
          });
          _runOptimiser();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.neonPrimary.withValues(alpha: 0.15) : AppTokens.bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            border: Border.all(
              color: isSelected ? AppTokens.neonPrimary : AppTokens.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              'H$h',
              style: TextStyle(
                color: isSelected ? AppTokens.neonPrimary : AppTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: AppTextStyles.numeric.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }
}
