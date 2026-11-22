import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/optimiser/lineup_optimiser.dart';
import '../../../core/optimiser/player_candidate.dart';
import '../../../core/storage/app_database.dart';
import '../../../data/models/fpl_models.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../squad/providers/squad_provider.dart';

class LineupState {
  final int? selectedGameweek;
  final bool isLoadingGameweek;
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
    this.selectedGameweek,
    this.isLoadingGameweek = false,
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
    int? selectedGameweek,
    bool? isLoadingGameweek,
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
      selectedGameweek: selectedGameweek ?? this.selectedGameweek,
      isLoadingGameweek: isLoadingGameweek ?? this.isLoadingGameweek,
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
      if (next.hasSquad && next.squad.length == 15 && (state.result == null || prev?.squad != next.squad) && !state.isOptimizing) {
        optimize();
      }
    });

    // If squad is ALREADY available when LineupNotifier is initialized, trigger optimization immediately
    final currentSquad = _ref.read(squadNotifierProvider);
    if (currentSquad.hasSquad && currentSquad.squad.length == 15 && !state.isOptimizing) {
      Future.microtask(() => optimize());
    }
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

    var starterRows = sorted.where((p) => p.positionOrder >= 1 && p.positionOrder <= 11).toList();
    var benchRows = sorted.where((p) => p.positionOrder >= 12 && p.positionOrder <= 15).toList();

    // Resilient fallback if positionOrder is not standard 1..15
    if (starterRows.length != 11 || benchRows.length != 4) {
      starterRows = sorted.take(11).toList();
      benchRows = sorted.skip(11).take(4).toList();
    }

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

      // Persist to Drift database in background (isolated so it never blocks UI state)
      try {
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
      } catch (_) {
        // Cache write failure should not prevent lineup display
      }
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

  /// Swaps two players between starting XI and bench (or bench reorder),
  /// validating real FPL formation rules (min 1 GK, 3 DEF, 2 MID, 1 FWD).
  bool swapPlayers(int playerAId, int playerBId) {
    if (state.result == null || playerAId == playerBId) return false;

    final startingXi = List<PlayerCandidate>.from(state.result!.startingXi);
    final bench = List<PlayerCandidate>.from(state.result!.bench);

    final aInStarting = startingXi.indexWhere((p) => p.fplId == playerAId);
    final aInBench = bench.indexWhere((p) => p.fplId == playerAId);
    final bInStarting = startingXi.indexWhere((p) => p.fplId == playerBId);
    final bInBench = bench.indexWhere((p) => p.fplId == playerBId);

    // Case 1: Swap Starter and Bench player
    if (aInStarting != -1 && bInBench != -1) {
      final pA = startingXi[aInStarting];
      final pB = bench[bInBench];

      // Goalkeepers can only be swapped with Goalkeepers
      if ((pA.position == 'GK' && pB.position != 'GK') ||
          (pB.position == 'GK' && pA.position != 'GK')) {
        return false;
      }

      final newStartingXi = List<PlayerCandidate>.from(startingXi);
      newStartingXi[aInStarting] = pB;

      // Validate formation constraints: 1 GK, >= 3 DEF, >= 2 MID, >= 1 FWD
      final defs = newStartingXi.where((p) => p.position == 'DEF').length;
      final mids = newStartingXi.where((p) => p.position == 'MID').length;
      final fwds = newStartingXi.where((p) => p.position == 'FWD').length;

      if (defs < 3 || mids < 2 || fwds < 1) {
        return false;
      }

      final newBench = List<PlayerCandidate>.from(bench);
      newBench[bInBench] = pA;

      var newCaptain = state.result!.captain;
      var newViceCaptain = state.result!.viceCaptain;
      if (newCaptain.fplId == pA.fplId) {
        newCaptain = pB;
      }
      if (newViceCaptain.fplId == pA.fplId) {
        newViceCaptain = pB;
      }

      final formation = [1, defs, mids, fwds];
      final totalXp = newStartingXi.fold<double>(0.0, (sum, p) => sum + p.xp) + newCaptain.xp;

      final updatedResult = LineupResult(
        startingXi: newStartingXi,
        captain: newCaptain,
        viceCaptain: newViceCaptain,
        bench: newBench,
        formation: formation,
        totalExpectedPoints: double.parse(totalXp.toStringAsFixed(1)),
        captaincyScore: newCaptain.xp,
        benchOrderScore: state.result!.benchOrderScore,
        isQuickModeFallback: state.result!.isQuickModeFallback,
      );

      state = state.copyWith(
        result: updatedResult,
        isRecommendedMode: false,
      );
      return true;
    }

    // Case 2: Swap Bench and Starter player (symmetric)
    if (aInBench != -1 && bInStarting != -1) {
      return swapPlayers(playerBId, playerAId);
    }

    // Case 3: Reorder bench slots
    if (aInBench != -1 && bInBench != -1) {
      final pA = bench[aInBench];
      final pB = bench[bInBench];
      if (pA.position == 'GK' || pB.position == 'GK') return false;

      final newBench = List<PlayerCandidate>.from(bench);
      newBench[aInBench] = pB;
      newBench[bInBench] = pA;

      state = state.copyWith(
        result: LineupResult(
          startingXi: state.result!.startingXi,
          captain: state.result!.captain,
          viceCaptain: state.result!.viceCaptain,
          bench: newBench,
          formation: state.result!.formation,
          totalExpectedPoints: state.result!.totalExpectedPoints,
          captaincyScore: state.result!.captaincyScore,
          benchOrderScore: state.result!.benchOrderScore,
          isQuickModeFallback: state.result!.isQuickModeFallback,
        ),
      );
      return true;
    }

    return false;
  }

  /// Generates top transfer recommendations for a specific player based on the deterministic optimiser
  Future<List<PlayerCandidate>> getTransferRecommendationsForPlayer(
    PlayerCandidate player, {
    int limit = 5,
  }) async {
    final squadState = _ref.read(squadNotifierProvider);
    final fplRepo = _ref.read(fplRepositoryProvider);
    final maxSpendTenths = player.priceTenths + squadState.bankTenths;
    final currentSquadIds = squadState.squad.map((p) => p.fplId).toSet();

    try {
      final playersSearch = await fplRepo.searchPlayers('', limit: 600);
      final gw = squadState.nextGameweek?.id ?? squadState.currentGameweek?.id ?? 1;
      final xpMap = <int, double>{};

      try {
        final bundle = await fplRepo.getProjectionBundle(gw);
        final pList = bundle['players'] as List<dynamic>? ?? [];
        for (final p in pList) {
          final id = p['fpl_id'] as int?;
          final fixtures = p['fixtures'] as List<dynamic>? ?? [];
          double total = 0.0;
          for (final f in fixtures) {
            total += (f['expected_points'] as num?)?.toDouble() ?? 0.0;
          }
          if (id != null && total > 0) {
            xpMap[id] = double.parse(total.toStringAsFixed(1));
          }
        }
      } catch (_) {}

      final candidates = <PlayerCandidate>[];
      for (final p in playersSearch) {
        final fplId = (p['fpl_id'] as num?)?.toInt() ?? 0;
        if (currentSquadIds.contains(fplId)) continue;

        final rawPos = (p['position'] as String?) ?? 'MID';
        final normPos = rawPos == 'GKP' ? 'GK' : rawPos;
        if (normPos != player.position) continue;

        final cost = (p['now_cost'] as num?)?.toInt() ?? 50;
        if (cost > maxSpendTenths) continue;

        final name = (p['web_name'] as String?) ?? 'Player $fplId';
        final clubId = (p['team_fpl_id'] as num?)?.toInt() ?? 1;
        final chance = (p['chance_of_playing_next_round'] as num?)?.toDouble();
        final status = (p['status'] as String?) ?? 'a';
        final pStart = (chance != null)
            ? (chance / 100.0).clamp(0.05, 0.95)
            : (status == 'out' ? 0.05 : 0.90);
        final xp = xpMap[fplId] ?? ((cost / 20.0) * (status == 'a' ? 1.0 : 0.4)).clamp(1.5, 9.5);

        candidates.add(PlayerCandidate(
          fplId: fplId,
          webName: name,
          position: normPos,
          clubId: clubId,
          priceTenths: cost,
          sellingPriceTenths: cost,
          xp: double.parse(xp.toStringAsFixed(1)),
          pStart: double.parse(pStart.toStringAsFixed(2)),
          pSub: 0.05,
        ));
      }

      candidates.sort((a, b) => b.xp.compareTo(a.xp));
      return candidates.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> selectGameweek(int gw) async {
    final squadState = _ref.read(squadNotifierProvider);
    final latestGw = squadState.nextGameweek?.id ??
        squadState.currentGameweek?.id ??
        (squadState.gameweekHistory.isNotEmpty
            ? squadState.gameweekHistory.map((g) => g.gameweek).reduce((a, b) => a > b ? a : b)
            : 1);

    if (gw >= latestGw) {
      state = state.copyWith(selectedGameweek: gw, isLoadingGameweek: false);
      optimize();
      return;
    }

    state = state.copyWith(selectedGameweek: gw, isLoadingGameweek: true, errorMessage: null);

    try {
      final teamId = squadState.entry?.id;
      if (teamId == null) {
        state = state.copyWith(isLoadingGameweek: false, errorMessage: 'Team details not loaded');
        return;
      }

      final fplRepo = _ref.read(fplRepositoryProvider);
      final squadResp = await fplRepo.getSquad(teamId, gw: gw);

      if (squadResp.picks.isEmpty) {
        state = state.copyWith(isLoadingGameweek: false, errorMessage: 'No picks found for Gameweek $gw');
        return;
      }

      // Build candidates for historical gameweek
      final candidates = squadResp.picks.map((pick) {
        final pos = pick.playerPosition ?? _defaultPosition(pick.position);
        final xp = ((pick.nowCost ?? 60) / 20.0).clamp(1.5, 9.5);
        return PlayerCandidate(
          fplId: pick.element,
          webName: pick.webName ?? 'Player #${pick.element}',
          position: pos == 'GKP' ? 'GK' : pos,
          clubId: pick.teamFplId ?? 1,
          priceTenths: pick.nowCost ?? 60,
          sellingPriceTenths: pick.nowCost ?? 60,
          xp: double.parse(xp.toStringAsFixed(1)),
          pStart: 0.95,
          pSub: 0.05,
        );
      }).toList();

      final candidateMap = {for (final c in candidates) c.fplId: c};
      final sortedPicks = List<PickModel>.from(squadResp.picks)
        ..sort((a, b) => a.position.compareTo(b.position));

      final starterPicks = sortedPicks.where((p) => p.position >= 1 && p.position <= 11).toList();
      final benchPicks = sortedPicks.where((p) => p.position >= 12 && p.position <= 15).toList();

      final startingXi = starterPicks
          .map((p) => candidateMap[p.element] ?? candidates.first)
          .toList()
        ..sort((a, b) {
          final posWeight = {'GK': 0, 'DEF': 1, 'MID': 2, 'FWD': 3};
          return (posWeight[a.position] ?? 99).compareTo(posWeight[b.position] ?? 99);
        });

      final bench = benchPicks
          .map((p) => candidateMap[p.element] ?? candidates.first)
          .toList();

      final capPick = sortedPicks.firstWhere(
        (p) => p.isCaptain || p.multiplier >= 2,
        orElse: () => sortedPicks.first,
      );
      final vicePick = sortedPicks.firstWhere(
        (p) => p.isViceCaptain,
        orElse: () => sortedPicks.length > 1 ? sortedPicks[1] : sortedPicks.first,
      );

      final captain = candidateMap[capPick.element] ?? startingXi.first;
      final viceCaptain = candidateMap[vicePick.element] ?? (startingXi.length > 1 ? startingXi[1] : startingXi.first);

      final counts = LineupOptimiser.formationCounts(startingXi);
      final formation = [
        counts['GK'] ?? 1,
        counts['DEF'] ?? 3,
        counts['MID'] ?? 4,
        counts['FWD'] ?? 3,
      ];
      final totalXp = startingXi.fold<double>(0.0, (sum, p) => sum + p.xp) + captain.xp;

      final historicalResult = LineupResult(
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

      state = state.copyWith(
        result: historicalResult,
        currentResult: historicalResult,
        recommendedResult: null,
        isRecommendedMode: false,
        isLoadingGameweek: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingGameweek: false,
        errorMessage: 'Failed to load Gameweek $gw lineup: $e',
      );
    }
  }

  String _defaultPosition(int positionOrder) {
    if (positionOrder == 1 || positionOrder == 12) return 'GK';
    if (positionOrder <= 6) return 'DEF';
    if (positionOrder <= 11) return 'MID';
    return 'FWD';
  }
}

final lineupNotifierProvider = StateNotifierProvider<LineupNotifier, LineupState>((ref) {
  return LineupNotifier(ref);
});
