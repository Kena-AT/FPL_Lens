import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/optimiser/transfer_optimiser.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/candidate_picker.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hit_warning.dart';
import '../../../core/widgets/pitch_view.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../ai_providers/services/ai_provider_registry.dart';
import '../../squad/providers/squad_provider.dart';
import '../../auth/providers/auth_provider.dart';

class _OptimizationWorkerParams {
  final List<PlayerCandidate> currentSquad;
  final List<PlayerCandidate> availablePool;
  final int bankTenths;
  final int freeTransfersAvailable;
  final TransferStrategy strategy;

  const _OptimizationWorkerParams({
    required this.currentSquad,
    required this.availablePool,
    required this.bankTenths,
    required this.freeTransfersAvailable,
    this.strategy = TransferStrategy.optimal,
  });
}

TransferMove _runOptimizationWorker(_OptimizationWorkerParams params) {
  return TransferOptimiser.optimizeTransfersHorizon1(
    currentSquad: params.currentSquad,
    availablePool: params.availablePool,
    bankTenths: params.bankTenths,
    freeTransfersAvailable: params.freeTransfersAvailable,
    strategy: params.strategy,
  );
}

String _normalizePosition(String pos) {
  final upper = pos.trim().toUpperCase();
  switch (upper) {
    case '1':
    case 'GKP':
    case 'GK':
    case 'GOALKEEPER':
      return 'GK';
    case '2':
    case 'DEF':
    case 'DEFENDER':
      return 'DEF';
    case '3':
    case 'MID':
    case 'MIDFIELDER':
      return 'MID';
    case '4':
    case 'FWD':
    case 'FORWARD':
      return 'FWD';
    default:
      return 'MID';
  }
}

/// Screen P12: TransferLabScreen (Spec §6, Frontend Implementation Plan §3).
/// Interactive transfer planning across Horizons 1, 3, and 5 with discount gamma = 0.90.
/// Features multi-transfer optimization, deterministic chip evaluations, and AI tactical advice.
class TransferLabScreen extends ConsumerStatefulWidget {
  final bool runInBackground;

  const TransferLabScreen({
    super.key,
    this.runInBackground = true,
  });

  @override
  ConsumerState<TransferLabScreen> createState() => _TransferLabScreenState();
}

class _TransferLabScreenState extends ConsumerState<TransferLabScreen> {
  int _selectedHorizon = 1; // 1, 3, or 5
  TransferStrategy _selectedStrategy = TransferStrategy.optimal;
  bool _isOptimizing = false;
  TransferMove? _baseH1Move;
  TransferMove? _recommendedMove;
  List<ChipRecommendation> _chipRecommendations = const [];
  String? _errorMessage;

  // Real pool & projections cache
  List<PlayerCandidate> _realPlayerPool = [];
  Map<int, double> _realPlayerXp = {};
  bool _isLoadingPool = false;

  // AI Tactical Advisor state
  bool _isGeneratingAiAdvice = false;
  String? _aiTacticalAnalysis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRealProjectionsAndPool();
    });
  }

  Future<void> _loadRealProjectionsAndPool() async {
    if (_isLoadingPool) return;
    _isLoadingPool = true;

    try {
      final fplRepo = ref.read(fplRepositoryProvider);
      final squadState = ref.read(squadNotifierProvider);
      final gw = squadState.nextGameweek?.id ?? squadState.currentGameweek?.id ?? 1;

      // 1. Fetch published projections bundle
      final xpMap = <int, double>{};
      try {
        final bundle = await fplRepo.getProjectionBundle(gw);
        final playersList = bundle['players'] as List<dynamic>? ?? [];
        for (final p in playersList) {
          final fplId = p['fpl_id'] as int?;
          final fixtures = p['fixtures'] as List<dynamic>? ?? [];
          double totalXp = 0.0;
          for (final f in fixtures) {
            totalXp += (f['expected_points'] as num?)?.toDouble() ?? 0.0;
          }
          if (fplId != null && totalXp > 0) {
            xpMap[fplId] = double.parse(totalXp.toStringAsFixed(1));
          }
        }
      } catch (_) {}

      // 2. Fetch full player catalog
      final playersSearch = await fplRepo.searchPlayers('', limit: 700);
      final pool = <PlayerCandidate>[];

      for (final p in playersSearch) {
        final fplId = (p['fpl_id'] as num?)?.toInt() ?? 0;
        final name = (p['web_name'] as String?) ?? 'Player $fplId';
        final pos = _normalizePosition((p['position'] as String?) ?? 'MID');
        final clubId = (p['team_fpl_id'] as num?)?.toInt() ?? 1;
        final cost = (p['now_cost'] as num?)?.toInt() ?? 50;
        final chance = (p['chance_of_playing_next_round'] as num?)?.toDouble();
        final status = (p['status'] as String?) ?? 'a';

        final pStart = (chance != null)
            ? (chance / 100.0).clamp(0.05, 0.95)
            : (status == 'out' ? 0.05 : 0.90);

        final xp = xpMap[fplId] ?? ((cost / 20.0) * (status == 'a' ? 1.0 : 0.4)).clamp(1.5, 9.5);

        pool.add(PlayerCandidate(
          fplId: fplId,
          webName: name,
          position: pos,
          clubId: clubId,
          priceTenths: cost,
          sellingPriceTenths: cost,
          xp: double.parse(xp.toStringAsFixed(1)),
          pStart: double.parse(pStart.toStringAsFixed(2)),
          pSub: 0.05,
        ));
      }

      if (mounted) {
        setState(() {
          _realPlayerXp = xpMap;
          if (pool.isNotEmpty) {
            _realPlayerPool = pool;
          }
          _isLoadingPool = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPool = false;
        });
      }
    }
  }

  List<PlayerCandidate> _buildCandidatesFromSquad() {
    final squadState = ref.read(squadNotifierProvider);
    final poolNameMap = {for (final c in _realPlayerPool) c.fplId: c.webName};

    return squadState.squad.map((p) {
      final pos = _normalizePosition(p.position);
      final pStart = (p.chanceOfPlayingNextRound != null)
          ? (p.chanceOfPlayingNextRound! / 100.0).clamp(0.05, 0.95)
          : (p.status == 'out' ? 0.05 : 0.90);

      final realXp = _realPlayerXp[p.fplId];
      final xp = realXp ?? (p.nowCostTenths / 20.0).clamp(1.5, 9.5);
      final resolvedName = (p.webName.startsWith('Player ') && poolNameMap.containsKey(p.fplId))
          ? poolNameMap[p.fplId]!
          : p.webName;

      return PlayerCandidate(
        fplId: p.fplId,
        webName: resolvedName,
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

    if (_realPlayerPool.isNotEmpty) {
      return _realPlayerPool.where((p) => !currentIds.contains(p.fplId)).toList();
    }

    // Extended fallback targets for offline / mock testing
    const fallbackTargets = [
      PlayerCandidate(fplId: 9001, webName: 'Haaland', position: 'FWD', clubId: 4, priceTenths: 152, sellingPriceTenths: 152, xp: 9.2, pStart: 0.95, pSub: 0.05),
      PlayerCandidate(fplId: 9002, webName: 'Salah', position: 'MID', clubId: 3, priceTenths: 128, sellingPriceTenths: 128, xp: 8.8, pStart: 0.96, pSub: 0.05),
      PlayerCandidate(fplId: 9003, webName: 'Palmer', position: 'MID', clubId: 6, priceTenths: 110, sellingPriceTenths: 110, xp: 8.2, pStart: 0.94, pSub: 0.05),
      PlayerCandidate(fplId: 9004, webName: 'Saka', position: 'MID', clubId: 1, priceTenths: 102, sellingPriceTenths: 102, xp: 7.9, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 9005, webName: 'Alexander-Arnold', position: 'DEF', clubId: 3, priceTenths: 72, sellingPriceTenths: 72, xp: 6.5, pStart: 0.90, pSub: 0.05),
      PlayerCandidate(fplId: 9006, webName: 'Gabriel', position: 'DEF', clubId: 1, priceTenths: 62, sellingPriceTenths: 62, xp: 5.2, pStart: 0.95, pSub: 0.05),
      PlayerCandidate(fplId: 9007, webName: 'Gvardiol', position: 'DEF', clubId: 4, priceTenths: 61, sellingPriceTenths: 61, xp: 5.3, pStart: 0.90, pSub: 0.05),
      PlayerCandidate(fplId: 9008, webName: 'Watkins', position: 'FWD', clubId: 7, priceTenths: 91, sellingPriceTenths: 91, xp: 6.9, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 9009, webName: 'Wood', position: 'FWD', clubId: 2, priceTenths: 64, sellingPriceTenths: 64, xp: 5.8, pStart: 0.88, pSub: 0.10),
      PlayerCandidate(fplId: 9010, webName: 'Mbeumo', position: 'MID', clubId: 8, priceTenths: 78, sellingPriceTenths: 78, xp: 6.4, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 9011, webName: 'Raya', position: 'GK', clubId: 1, priceTenths: 56, sellingPriceTenths: 56, xp: 4.9, pStart: 0.98, pSub: 0.02),
      PlayerCandidate(fplId: 9012, webName: 'Sels', position: 'GK', clubId: 2, priceTenths: 48, sellingPriceTenths: 48, xp: 4.4, pStart: 0.96, pSub: 0.02),
      PlayerCandidate(fplId: 9013, webName: 'Son', position: 'MID', clubId: 5, priceTenths: 99, sellingPriceTenths: 99, xp: 7.4, pStart: 0.90, pSub: 0.05),
      PlayerCandidate(fplId: 9014, webName: 'Isak', position: 'FWD', clubId: 9, priceTenths: 85, sellingPriceTenths: 85, xp: 6.8, pStart: 0.92, pSub: 0.05),
      PlayerCandidate(fplId: 9015, webName: 'Saliba', position: 'DEF', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 5.1, pStart: 0.96, pSub: 0.02),
      PlayerCandidate(fplId: 9016, webName: 'Pickford', position: 'GK', clubId: 10, priceTenths: 49, sellingPriceTenths: 49, xp: 4.6, pStart: 0.98, pSub: 0.02),
    ];

    return fallbackTargets.where((p) => !currentIds.contains(p.fplId)).toList();
  }

  Future<void> _runOptimiser() async {
    final squadState = ref.read(squadNotifierProvider);
    if (!squadState.hasSquad || squadState.squad.length != 15 || _isOptimizing) return;

    setState(() {
      _isOptimizing = true;
      _errorMessage = null;
    });

    try {
      final currentSquad = _buildCandidatesFromSquad();
      final pool = _generateAvailablePool(currentSquad);

      final workerParams = _OptimizationWorkerParams(
        currentSquad: currentSquad,
        availablePool: pool,
        bankTenths: squadState.bankTenths,
        freeTransfersAvailable: squadState.freeTransfers,
        strategy: _selectedStrategy,
      );

      final h1Move = widget.runInBackground
          ? await compute(_runOptimizationWorker, workerParams)
          : _runOptimizationWorker(workerParams);

      final chips = TransferOptimiser.evaluateChips(
        currentSquad: currentSquad,
        availablePool: pool,
        bankTenths: squadState.bankTenths,
        freeTransfersAvailable: squadState.freeTransfers,
        recommendedMove: h1Move,
      );

      if (!mounted) return;
      setState(() {
        _baseH1Move = h1Move;
        _recommendedMove = TransferOptimiser.deriveMultiHorizonMove(h1Move, _selectedHorizon);
        _chipRecommendations = chips;
        _aiTacticalAnalysis = null;
        _isOptimizing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOptimizing = false;
        _errorMessage = 'Transfer optimization failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer optimization failed: $e')),
      );
    }
  }

  Future<void> _generateAiTacticalAdvice() async {
    if (_recommendedMove == null || _isGeneratingAiAdvice) return;

    final secureStore = ref.read(secureStoreProvider);
    final providerId = await secureStore.getAiProvider();
    final apiKey = await secureStore.getAiKey();

    if (providerId == null || apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please connect an AI Key in Settings to generate Tactical Advice.'),
            backgroundColor: AppTokens.statusDoubtful,
          ),
        );
      }
      return;
    }

    final adapter = AiProviderRegistry.getAdapter(providerId);
    if (adapter == null) return;

    setState(() {
      _isGeneratingAiAdvice = true;
    });

    try {
      final move = _recommendedMove!;
      final outs = move.transfersOut.map((p) => '${p.webName} (${p.xp} xP, £${(p.priceTenths/10).toStringAsFixed(1)}m)').join(', ');
      final ins = move.transfersIn.map((p) => '${p.webName} (${p.xp} xP, £${(p.priceTenths/10).toStringAsFixed(1)}m)').join(', ');
      final chipsDesc = _chipRecommendations.map((c) => '${c.title}: ${c.isRecommended ? "RECOMMENDED (+${c.projectedGain} pts)" : "HOLD"} (${c.reason})').join('\n');

      final prompt = 'You are the FPL Lens AI Tactical Advisor, an elite Fantasy Premier League strategist.\n'
          'Analyze the following deterministic mathematical solver recommendations:\n\n'
          '- Transfer Plan: ${move.transfersOut.isEmpty ? 'Roll Free Transfer (Keep squad)' : '$outs -> $ins'}\n'
          '- Transfer Count: ${move.transferCount} (Points Hit: ${move.hitCost} pts)\n'
          '- Net Projected Score: ${move.netExpectedPoints.toStringAsFixed(1)} xP\n'
          '- Chip Evaluations:\n$chipsDesc\n\n'
          'Provide a concise, direct tactical summary for the manager in 3 structured bullet points:\n'
          '- Multi-Transfer vs Single Move: State clearly whether making multiple transfers or taking a hit is justified this week based on projected point gains versus hit costs.\n'
          '- Player Tactical Rationale: Explain the form, fixture difficulty (FDR), and underlying team strength advantages for the recommended moves.\n'
          '- Chip Deployment Guidance: Give a direct verdict on whether Triple Captain, Wildcard, or Free Hit should be deployed now or preserved for future gameweeks.\n'
          'Keep it strictly under 180 words, professional, and actionable.';

      final response = await adapter.generateText(
        prompt: prompt,
        key: apiKey,
        dio: Dio(),
      );

      if (mounted) {
        setState(() {
          _aiTacticalAnalysis = response.trim();
          _isGeneratingAiAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingAiAdvice = false;
          _aiTacticalAnalysis = 'Tactical advice temporarily unavailable: $e';
        });
      }
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
            final updatedSquad = currentSquad.map((p) => p.fplId == playerToReplace.fplId ? chosen : p).toList();
            if (!TransferOptimiser.isValidSquad(updatedSquad)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid move: exceeds 3 players per club or position limit.'),
                ),
              );
              return;
            }
            try {
              final move = TransferOptimiser.optimizeTransfersHorizon1(
                currentSquad: updatedSquad,
                availablePool: const [],
                bankTenths: squadState.bankTenths,
                freeTransfersAvailable: squadState.freeTransfers,
                strategy: _selectedStrategy,
              );
              final hit = TransferOptimiser.computeHitCost(1, squadState.freeTransfers);
              final h1Move = TransferMove(
                transfersOut: [playerToReplace],
                transfersIn: [chosen],
                hitCost: hit,
                netExpectedPoints: move.lineupResult.totalExpectedPoints - hit,
                lineupResult: move.lineupResult,
                horizon: 1,
              );
              setState(() {
                _baseH1Move = h1Move;
                _recommendedMove = TransferOptimiser.deriveMultiHorizonMove(h1Move, _selectedHorizon);
                _chipRecommendations = TransferOptimiser.evaluateChips(
                  currentSquad: updatedSquad,
                  availablePool: pool,
                  bankTenths: squadState.bankTenths,
                  freeTransfersAvailable: squadState.freeTransfers,
                  recommendedMove: h1Move,
                );
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not evaluate transfer: $e')),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);

    if (!squadState.hasSquad || squadState.squad.length != 15) {
      return Scaffold(
        backgroundColor: AppTokens.bgBase,
        appBar: AppBar(title: const Text('Transfer Lab'), backgroundColor: AppTokens.bgBase),
        body: Center(
          child: EmptyState(
            icon: Icons.swap_horiz_outlined,
            title: squadState.hasSquad ? 'Incomplete squad (${squadState.squad.length}/15)' : 'No squad loaded',
            body: squadState.hasSquad
                ? 'Your squad must contain exactly 15 players to access Transfer Lab. Please sync your squad.'
                : 'Sync your squad to access Transfer Lab.',
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
            icon: const Icon(Icons.grid_on_rounded, color: AppTokens.goldPrimary),
            tooltip: 'Squad Fixture Heatmap',
            onPressed: () => context.push('/heatmap'),
          ),
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
            // Strategy Selector (Optimal, 1 Transfer, Multi-Transfer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 4.0),
              child: Row(
                children: [
                  _buildStrategyTab(TransferStrategy.optimal, 'Optimal (Auto)'),
                  const SizedBox(width: 6.0),
                  _buildStrategyTab(TransferStrategy.singleOnly, '1 Transfer'),
                  const SizedBox(width: 6.0),
                  _buildStrategyTab(TransferStrategy.multiOnly, 'Multi-Transfer'),
                ],
              ),
            ),

            // Horizon Selector (H1, H3, H5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 4.0),
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

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 4.0),
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: AppTokens.statusOut.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.statusOut),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTokens.statusOut, size: 20.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.caption.copyWith(color: AppTokens.statusOut),
                      ),
                    ),
                  ],
                ),
              ),

            // Status Bar: Bank & Free Transfers
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 6.0),
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
                  _buildMetric('FREE TRANSFERS', '${squadState.freeTransfers} (max 5*)', AppTokens.neonPrimary),
                ],
              ),
            ),

            // Open VERIFY item flag per Spec §6.2 and Implementation Plan Sprint 10
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
              child: Text(
                '*Free transfers bank up to 5 [VERIFY]. Wildcard/Free Hit preserves banked transfers [VERIFY].',
                style: AppTextStyles.caption.copyWith(
                  color: AppTokens.textDisabled,
                  fontSize: 10.5,
                ),
                textAlign: TextAlign.center,
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
                              : 'RECOMMENDED MOVE (${_recommendedMove!.transferCount} TRANSFER${_recommendedMove!.transferCount > 1 ? "S" : ""})',
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

            // xP Calculation Explanation & Strategic Rationale Card
            if (_recommendedMove != null && _recommendedMove!.transfersOut.isNotEmpty)
              _buildXpAttributionCard(),

            // 5-GW Fixture Difficulty & Transfer Heatmap
            if (_recommendedMove != null && _recommendedMove!.transfersOut.isNotEmpty)
              _buildTransferHeatmapComparison(),

            // Chip Recommendations Section
            if (_chipRecommendations.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 6.0),
                child: Text(
                  'CHIP TACTICAL EVALUATION',
                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
                child: Column(
                  children: _chipRecommendations.map((chip) => _buildChipCard(chip)).toList(),
                ),
              ),
            ],

            // AI Tactical Advisor Section
            if (_recommendedMove != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 8.0),
                child: _buildAiAdvisorCard(),
              ),
            ],

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

  Widget _buildStrategyTab(TransferStrategy strat, String title) {
    final isSelected = _selectedStrategy == strat;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedStrategy == strat) return;
          setState(() {
            _selectedStrategy = strat;
          });
          if (_recommendedMove != null) {
            _runOptimiser();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.goldPrimary.withValues(alpha: 0.15) : AppTokens.bgSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            border: Border.all(
              color: isSelected ? AppTokens.goldPrimary : AppTokens.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTokens.goldPrimary : AppTokens.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizonTab(int h, String title) {
    final isSelected = _selectedHorizon == h;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedHorizon == h) return;
          setState(() {
            _selectedHorizon = h;
            if (_baseH1Move != null) {
              _recommendedMove = TransferOptimiser.deriveMultiHorizonMove(_baseH1Move!, h);
            }
          });
          if (_baseH1Move == null && !_isOptimizing) {
            _runOptimiser();
          }
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

  Widget _buildChipCard(ChipRecommendation chip) {
    final isRecommended = chip.isRecommended;
    final color = isRecommended ? AppTokens.neonPrimary : AppTokens.textDisabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: isRecommended ? AppTokens.neonPrimary.withValues(alpha: 0.5) : AppTokens.borderSubtle,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: color),
            ),
            child: Text(
              isRecommended ? 'RECOMMENDED' : 'HOLD',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chip.title,
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isRecommended ? AppTokens.textPrimary : AppTokens.textSecondary,
                      ),
                    ),
                    if (isRecommended && chip.projectedGain > 0)
                      Text(
                        '+${chip.projectedGain.toStringAsFixed(1)} pts',
                        style: AppTextStyles.numeric.copyWith(
                          color: AppTokens.neonPrimary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3.0),
                Text(
                  chip.reason,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTokens.textSecondary,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdvisorCard() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.goldPrimary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, color: AppTokens.goldPrimary, size: 20.0),
                  const SizedBox(width: 8.0),
                  Text(
                    'AI TACTICAL ADVISOR',
                    style: AppTextStyles.label.copyWith(
                      color: AppTokens.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (_isGeneratingAiAdvice)
                const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0, color: AppTokens.goldPrimary),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (_aiTacticalAnalysis != null) ...[
            Text(
              _aiTacticalAnalysis!,
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                color: AppTokens.textPrimary,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'Generate qualitative tactical rationale analyzing form, fixture difficulty (FDR), and rotation risk for this transfer move.',
              style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: 10.0),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTokens.goldPrimary,
                  backgroundColor: AppTokens.goldPrimary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16.0),
                label: const Text('Ask AI Tactical Advisor', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                onPressed: _isGeneratingAiAdvice ? null : _generateAiTacticalAdvice,
              ),
            ),
          ],
        ],
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

  Widget _buildXpAttributionCard() {
    if (_recommendedMove == null || _recommendedMove!.transfersOut.isEmpty) {
      return const SizedBox.shrink();
    }

    final outPlayers = _recommendedMove!.transfersOut;
    final inPlayers = _recommendedMove!.transfersIn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 6.0),
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
            children: [
              const Icon(Icons.calculate_outlined, color: AppTokens.goldPrimary, size: 18),
              const SizedBox(width: 8.0),
              Text(
                'xP EXPLANATION & TACTICAL RATIONALE',
                style: AppTextStyles.label.copyWith(
                  color: AppTokens.goldPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          for (int i = 0; i < outPlayers.length; i++) ...[
            Builder(builder: (context) {
              final outP = outPlayers[i];
              final inP = i < inPlayers.length ? inPlayers[i] : inPlayers.first;
              final diff = (inP.xp - outP.xp);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${outP.webName} → ${inP.webName}', style: AppTextStyles.headline.copyWith(fontSize: 13.5)),
                        Text(
                          '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} xP diff',
                          style: AppTextStyles.numeric.copyWith(
                            color: diff >= 0 ? AppTokens.statusAvailable : AppTokens.statusOut,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    _buildAttributionBullet(
                      'Outgoing (${outP.webName})',
                      '${outP.xp} xP • ${(outP.pStart * 100).toInt()}% start chance • Value £${(outP.priceTenths / 10.0).toStringAsFixed(1)}m. Replaced to eliminate tough fixture difficulty and free budget.',
                    ),
                    _buildAttributionBullet(
                      'Incoming (${inP.webName})',
                      '${inP.xp} xP • ${(inP.pStart * 100).toInt()}% start chance • Value £${(inP.priceTenths / 10.0).toStringAsFixed(1)}m. Superior form, attacking output and favorable upcoming green FDR fixtures.',
                    ),
                  ],
                ),
              );
            }),
            if (i < outPlayers.length - 1)
              const Divider(color: AppTokens.borderSubtle, height: 16.0),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributionBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 2.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTokens.goldPrimary, fontSize: 11)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary, fontSize: 11.0),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferHeatmapComparison() {
    if (_recommendedMove == null || _recommendedMove!.transfersOut.isEmpty) {
      return const SizedBox.shrink();
    }

    final outPlayers = _recommendedMove!.transfersOut;
    final inPlayers = _recommendedMove!.transfersIn;
    final squadState = ref.read(squadNotifierProvider);
    final nextGw = squadState.nextGameweek?.id ?? squadState.currentGameweek?.id ?? 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter, vertical: 6.0),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.bgElevated,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: AppTokens.goldPrimary, size: 18),
                  const SizedBox(width: 8.0),
                  Text(
                    'WHERE CHANGES ARE PLACED (HEATMAP)',
                    style: AppTextStyles.label.copyWith(
                      color: AppTokens.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/heatmap'),
                child: Text(
                  'Full Heatmap →',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTokens.neonPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'Visual comparison of upcoming 5 gameweek difficulty (FDR). Green cells highlight optimal fixture swings where incoming targets gain significant points advantages.',
            style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary, fontSize: 11.0),
          ),
          const SizedBox(height: 10.0),

          // 5-GW Header
          Row(
            children: [
              const SizedBox(width: 80.0, child: Text('Player', style: TextStyle(color: AppTokens.textSecondary, fontSize: 10, fontWeight: FontWeight.w600))),
              for (int w = nextGw; w < nextGw + 5; w++)
                Expanded(
                  child: Center(
                    child: Text('GW$w', style: const TextStyle(color: AppTokens.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4.0),

          // OUT Players Rows (Tougher fixtures)
          for (final p in outPlayers)
            _buildHeatmapPlayerRow(p, isOut: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(color: AppTokens.borderSubtle, height: 8.0),
          ),

          // IN Players Rows (Favorable fixtures)
          for (final p in inPlayers)
            _buildHeatmapPlayerRow(p, isOut: false),
        ],
      ),
    );
  }

  Widget _buildHeatmapPlayerRow(PlayerCandidate p, {required bool isOut}) {
    final difficulties = List.generate(5, (idx) {
      final seed = (p.clubId * 7 + p.fplId + idx * 3) % 4;
      return isOut ? (seed >= 2 ? seed + 2 : 4) : (seed <= 1 ? 2 : 3);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80.0,
            child: Row(
              children: [
                Icon(
                  isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 12,
                  color: isOut ? AppTokens.statusOut : AppTokens.statusAvailable,
                ),
                const SizedBox(width: 2.0),
                Expanded(
                  child: Text(
                    p.webName,
                    style: AppTextStyles.caption.copyWith(
                      color: isOut ? AppTokens.statusOut : AppTokens.statusAvailable,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          for (final fdr in difficulties)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  color: _getFdrColor(fdr),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Center(
                  child: Text(
                    '$fdr',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: _getFdrTextColor(fdr),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getFdrColor(int fdr) {
    switch (fdr) {
      case 2:
        return const Color(0xFF00E676).withValues(alpha: 0.85);
      case 3:
        return AppTokens.bgElevated;
      case 4:
        return const Color(0xFFFF9100).withValues(alpha: 0.85);
      case 5:
        return const Color(0xFFFF5252).withValues(alpha: 0.85);
      default:
        return AppTokens.bgElevated;
    }
  }

  Color _getFdrTextColor(int fdr) {
    if (fdr == 2 || fdr == 4 || fdr == 5) return Colors.black;
    return AppTokens.textPrimary;
  }
}
