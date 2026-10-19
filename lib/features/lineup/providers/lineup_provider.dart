import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/optimiser/lineup_optimiser.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/storage/app_database.dart';
import '../../squad/providers/squad_provider.dart';

class LineupState {
  final LineupResult? result;
  final LineupResult? currentResult;
  final LineupResult? recommendedResult;
  final bool isRecommendedMode;
  final bool isOptimizing;
  final bool isQuickMode;
  final int? manualCaptainId;
  final int? manualViceCaptainId;
  final String? errorMessage;

  const LineupState({
    this.result,
    this.currentResult,
    this.recommendedResult,
    this.isRecommendedMode = false,
    this.isOptimizing = false,
    this.isQuickMode = false,
    this.manualCaptainId,
    this.manualViceCaptainId,
    this.errorMessage,
  });

  LineupState copyWith({
    LineupResult? result,
    LineupResult? currentResult,
    LineupResult? recommendedResult,
    bool? isRecommendedMode,
    bool? isOptimizing,
    bool? isQuickMode,
    int? manualCaptainId,
    int? manualViceCaptainId,
    String? errorMessage,
  }) {
    return LineupState(
      result: result ?? this.result,
      currentResult: currentResult ?? this.currentResult,
      recommendedResult: recommendedResult ?? this.recommendedResult,
      isRecommendedMode: isRecommendedMode ?? this.isRecommendedMode,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      isQuickMode: isQuickMode ?? this.isQuickMode,
      manualCaptainId: manualCaptainId ?? this.manualCaptainId,
      manualViceCaptainId: manualViceCaptainId ?? this.manualViceCaptainId,
      errorMessage: errorMessage,
    );
  }
}

class LineupNotifier extends StateNotifier<LineupState> {
  final Ref _ref;

  LineupNotifier(this._ref) : super(const LineupState()) {
    // Automatically trigger optimization when squad is ready or changes
    _ref.listen<SquadState>(squadNotifierProvider, (prev, next) {
      if (next.hasSquad && (state.result == null || prev?.squad != next.squad) && !state.isOptimizing) {
        optimize();
      }
    });
  }

  /// Converts Drift squad player records into PlayerCandidate models for the optimiser
  List<PlayerCandidate> _buildCandidates(List<SquadPlayersTableData> squad) {
    return squad.map((p) {
      // Normalise position code ('GKP' -> 'GK')
      final pos = p.position == 'GKP' ? 'GK' : p.position;

      // Map chance of playing to P(Start)
      double pStart;
      if (p.status == 'out') {
        pStart = 0.05;
      } else if (p.chanceOfPlayingNextRound != null) {
        pStart = (p.chanceOfPlayingNextRound! / 100.0).clamp(0.05, 0.95);
      } else if (p.status == 'doubtful') {
        pStart = 0.50;
      } else {
        pStart = 0.92;
      }

      // Base projected points: use multiplier or status-weighted default
      final xp = (p.nowCostTenths / 20.0).clamp(1.5, 9.5) * (pStart >= 0.7 ? 1.0 : 0.6);

      return PlayerCandidate(
        fplId: p.fplId,
        webName: p.webName,
        position: pos,
        clubId: p.teamId,
        priceTenths: p.nowCostTenths,
        sellingPriceTenths: p.sellingPriceTenths,
        xp: double.parse(xp.toStringAsFixed(1)),
        pStart: double.parse(pStart.toStringAsFixed(2)),
        pSub: 0.08,
      );
    }).toList();
  }

  /// Builds a LineupResult strictly reflecting the user's actual FPL squad lineup and bench order
  LineupResult _buildCurrentLineup(
    List<SquadPlayersTableData> squad,
    List<PlayerCandidate> candidates,
  ) {
    final candidateMap = {for (final c in candidates) c.fplId: c};

    // Sort squad by positionOrder (1 to 15)
    final sorted = List<SquadPlayersTableData>.from(squad)
      ..sort((a, b) => a.positionOrder.compareTo(b.positionOrder));

    final starterRows = sorted.where((p) => p.positionOrder >= 1 && p.positionOrder <= 11).toList();
    final benchRows = sorted.where((p) => p.positionOrder >= 12 && p.positionOrder <= 15).toList();

    // Group starters: GK, DEF, MID, FWD
    final startingXi = starterRows.map((r) => candidateMap[r.fplId]!).toList()
      ..sort((a, b) {
        final posWeight = {'GK': 0, 'DEF': 1, 'MID': 2, 'FWD': 3};
        return (posWeight[a.position] ?? 99).compareTo(posWeight[b.position] ?? 99);
      });

    final bench = benchRows.map((r) => candidateMap[r.fplId]!).toList();

    // Captain & Vice Captain
    PlayerCandidate? captain;
    PlayerCandidate? viceCaptain;

    if (state.manualCaptainId != null) {
      captain = startingXi.where((p) => p.fplId == state.manualCaptainId).firstOrNull;
    }
    if (state.manualViceCaptainId != null) {
      viceCaptain = startingXi.where((p) => p.fplId == state.manualViceCaptainId).firstOrNull;
    }

    captain ??= startingXi.firstWhere(
      (p) {
        final row = sorted.firstWhere((s) => s.fplId == p.fplId, orElse: () => sorted.first);
        return row.isCaptain || row.multiplier >= 2;
      },
      orElse: () => startingXi.first,
    );

    viceCaptain ??= startingXi.firstWhere(
      (p) {
        if (p.fplId == captain!.fplId) return false;
        final row = sorted.firstWhere((s) => s.fplId == p.fplId, orElse: () => sorted.first);
        return row.isViceCaptain;
      },
      orElse: () => startingXi.firstWhere(
        (p) => p.fplId != captain!.fplId,
        orElse: () => startingXi.first,
      ),
    );

    final counts = LineupOptimiser.formationCounts(startingXi);
    final formation = [
      counts['GK'] ?? 1,
      counts['DEF'] ?? 3,
      counts['MID'] ?? 4,
      counts['FWD'] ?? 3,
    ];

    final totalXp = startingXi.fold<double>(0.0, (sum, p) => sum + p.xp) + captain.xp;

    return LineupResult(
      startingXi: startingXi,
      captain: captain,
      viceCaptain: viceCaptain,
      bench: bench,
      formation: formation,
      totalExpectedPoints: double.parse(totalXp.toStringAsFixed(1)),
      captaincyScore: captain.xp,
      benchOrderScore: 0.0,
      isQuickModeFallback: false,
    );
  }

  /// Runs the pure Dart device optimiser and builds current lineup
  Future<void> optimize({bool forceFallback = false}) async {
    final squadState = _ref.read(squadNotifierProvider);
    if (!squadState.hasSquad || squadState.squad.length != 15) {
      state = state.copyWith(errorMessage: 'Squad must have 15 players to optimize lineup');
      return;
    }

    state = state.copyWith(isOptimizing: true, errorMessage: null);

    try {
      final candidates = _buildCandidates(squadState.squad);

      // Build User's Current FPL Lineup
      final currentLineup = _buildCurrentLineup(squadState.squad, candidates);

      // Run pure Dart optimiser for recommended lineup
      var recommendedLineup = LineupOptimiser.optimizeLineup(
        candidates,
        forceFallback: forceFallback,
      );

      // Handle manual overrides if set
      if (state.manualCaptainId != null || state.manualViceCaptainId != null) {
        PlayerCandidate? newCaptain = recommendedLineup.captain;
        PlayerCandidate? newViceCaptain = recommendedLineup.viceCaptain;

        if (state.manualCaptainId != null) {
          final matched = recommendedLineup.startingXi.where((p) => p.fplId == state.manualCaptainId).firstOrNull;
          if (matched != null) newCaptain = matched;
        }
        if (state.manualViceCaptainId != null) {
          final matched = recommendedLineup.startingXi.where((p) => p.fplId == state.manualViceCaptainId).firstOrNull;
          if (matched != null && matched.fplId != newCaptain.fplId) {
            newViceCaptain = matched;
          }
        }

        recommendedLineup = LineupResult(
          startingXi: recommendedLineup.startingXi,
          captain: newCaptain,
          viceCaptain: newViceCaptain,
          bench: recommendedLineup.bench,
          formation: recommendedLineup.formation,
          totalExpectedPoints: recommendedLineup.totalExpectedPoints,
          captaincyScore: recommendedLineup.captaincyScore,
          benchOrderScore: recommendedLineup.benchOrderScore,
          isQuickModeFallback: recommendedLineup.isQuickModeFallback,
        );
      }

      final active = state.isRecommendedMode ? recommendedLineup : currentLineup;

      state = state.copyWith(
        result: active,
        currentResult: currentLineup,
        recommendedResult: recommendedLineup,
        isOptimizing: false,
        isQuickMode: recommendedLineup.isQuickModeFallback,
      );

      // Persist to Drift database
      final db = _ref.read(appDatabaseProvider);
      final gw = squadState.nextGameweek?.id ?? squadState.currentGameweek?.id ?? 1;

      await db.into(db.lineupResultsTable).insertOnConflictUpdate(
            LineupResultsTableCompanion(
              gameweek: drift.Value(gw),
              starting11FplIds: drift.Value(active.startingXi.map((p) => p.fplId).join(',')),
              benchFplIds: drift.Value(active.bench.map((p) => p.fplId).join(',')),
              captainFplId: drift.Value(active.captain.fplId),
              viceCaptainFplId: drift.Value(active.viceCaptain.fplId),
              projectedTotalPoints: drift.Value(active.totalExpectedPoints),
              modelVersion: const drift.Value('v1.5'),
              projectionRunId: drift.Value('run_${DateTime.now().millisecondsSinceEpoch}'),
              computedAt: drift.Value(DateTime.now()),
            ),
          );
    } catch (e) {
      state = state.copyWith(
        isOptimizing: false,
        errorMessage: 'Optimisation failed: $e',
      );
    }
  }

  void setRecommendedMode(bool isRecommended) {
    final active = isRecommended ? state.recommendedResult : state.currentResult;
    state = state.copyWith(
      isRecommendedMode: isRecommended,
      result: active ?? state.result,
    );
  }

  void setManualCaptain(int fplId) {
    state = state.copyWith(manualCaptainId: fplId);
    optimize();
  }

  void setManualViceCaptain(int fplId) {
    state = state.copyWith(manualViceCaptainId: fplId);
    optimize();
  }

  void clearOverrides() {
    state = state.copyWith(manualCaptainId: null, manualViceCaptainId: null);
    optimize();
  }
}

final lineupNotifierProvider = StateNotifierProvider<LineupNotifier, LineupState>((ref) {
  return LineupNotifier(ref);
});
