import 'dart:math' as math;
import 'formation_validator.dart';
import 'player_candidate.dart';

/// Result of Lineup Optimisation (Spec §5.1, §5.2, §5.3).
class LineupResult {
  final List<PlayerCandidate> startingXi;
  final PlayerCandidate captain;
  final PlayerCandidate viceCaptain;
  final List<PlayerCandidate> bench; // [0] is backup GK, [1..3] outfield
  final List<int> formation; // [GK, DEF, MID, FWD] e.g. [1, 4, 4, 2]
  final double totalExpectedPoints;
  final double captaincyScore;
  final double benchOrderScore;
  final bool isQuickModeFallback;

  const LineupResult({
    required this.startingXi,
    required this.captain,
    required this.viceCaptain,
    required this.bench,
    required this.formation,
    required this.totalExpectedPoints,
    required this.captaincyScore,
    required this.benchOrderScore,
    required this.isQuickModeFallback,
  });

  Map<String, dynamic> toJson() {
    return {
      'formation': formation,
      'starting_xi_ids': startingXi.map((p) => p.fplId).toList(),
      'captain_id': captain.fplId,
      'vice_captain_id': viceCaptain.fplId,
      'bench_ids': bench.map((p) => p.fplId).toList(),
      'total_expected_points': totalExpectedPoints,
      'captaincy_score': captaincyScore,
      'bench_order_score': benchOrderScore,
      'is_quick_mode_fallback': isQuickModeFallback,
    };
  }
}

/// Pure Dart Lineup and Bench Optimiser (Spec §5).
/// Completely free of Flutter and I/O imports.
class LineupOptimiser {
  /// Counts of players by position.
  static Map<String, int> formationCounts(List<PlayerCandidate> xi) {
    var gk = 0;
    var def = 0;
    var mid = 0;
    var fwd = 0;
    for (final p in xi) {
      switch (p.position) {
        case 'GK':
          gk++;
          break;
        case 'DEF':
          def++;
          break;
        case 'MID':
          mid++;
          break;
        case 'FWD':
          fwd++;
          break;
      }
    }
    return {'GK': gk, 'DEF': def, 'MID': mid, 'FWD': fwd};
  }

  /// Validates if an 11-player subset satisfies Spec §5.2 formation rules.
  static bool isValidXi(List<PlayerCandidate> xi) {
    if (xi.length != 11) return false;
    final counts = formationCounts(xi);
    return FormationValidator.isValidCounts(
      counts['GK']!,
      counts['DEF']!,
      counts['MID']!,
      counts['FWD']!,
    );
  }

  /// Enumerates all valid starting XIs from a 15-player squad.
  /// Full set of subsets is C(15, 11) = 1,365.
  static List<List<PlayerCandidate>> enumerateValidXis(List<PlayerCandidate> squad) {
    if (squad.length != 15) {
      throw ArgumentError('Squad must contain exactly 15 players, got ${squad.length}');
    }

    final validXis = <List<PlayerCandidate>>[];
    final current = <PlayerCandidate>[];

    void backtrack(int startIdx, int needed) {
      if (needed == 0) {
        if (isValidXi(current)) {
          validXis.add(List<PlayerCandidate>.from(current));
        }
        return;
      }

      final remaining = squad.length - startIdx;
      if (remaining < needed) return;

      for (var i = startIdx; i <= squad.length - needed; i++) {
        current.add(squad[i]);
        backtrack(i + 1, needed - 1);
        current.removeLast();
      }
    }

    backtrack(0, 11);
    return validXis;
  }

  /// Evaluates all 110 ordered pairs (captain, vice-captain) for a given XI.
  /// Spec §5.1 (v1.4 method): Pair(c, v) = sum_{i in XI} xP_i + xP_c + (1 - q_c) * xP_v
  /// where q_c = P(app_c).
  static (PlayerCandidate captain, PlayerCandidate viceCaptain, double score) evaluateCaptainPair(
    List<PlayerCandidate> xi,
  ) {
    var xiBaseXp = 0.0;
    for (final p in xi) {
      xiBaseXp += p.xp;
    }

    PlayerCandidate? bestC;
    PlayerCandidate? bestV;
    var bestScore = -double.infinity;

    for (var i = 0; i < xi.length; i++) {
      final c = xi[i];
      final qc = c.pApp;
      for (var j = 0; j < xi.length; j++) {
        if (i == j) continue;
        final v = xi[j];
        final pairScore = xiBaseXp + c.xp + (1.0 - qc) * v.xp;
        if (pairScore > bestScore) {
          bestScore = pairScore;
          bestC = c;
          bestV = v;
        }
      }
    }

    return (bestC!, bestV!, bestScore);
  }

  /// Applies official FPL automatic substitutions (Spec §5.2).
  /// bench[0] is backup goalkeeper; bench[1..3] are outfield substitutes in bench order.
  static List<PlayerCandidate> applyFplAutoSubs(
    List<PlayerCandidate> startingXi,
    List<PlayerCandidate> bench,
    Set<int> absentIds,
  ) {
    final xi = <PlayerCandidate>[];
    final absentStarters = <PlayerCandidate>[];

    for (final p in startingXi) {
      if (absentIds.contains(p.fplId)) {
        absentStarters.add(p);
      } else {
        xi.add(p);
      }
    }

    // Goalkeeper replacement
    final starterGkAbsent = absentStarters.any((p) => p.position == 'GK');
    if (starterGkAbsent && bench.isNotEmpty && !absentIds.contains(bench[0].fplId)) {
      xi.add(bench[0]);
    }

    // Outfield replacements in bench order
    var outfieldMissing = absentStarters.where((p) => p.position != 'GK').length;
    final outfieldSubs = bench.skip(1).toList();

    for (final sub in outfieldSubs) {
      if (outfieldMissing == 0) break;
      if (absentIds.contains(sub.fplId) || sub.position == 'GK') continue;

      // Feasibility check per Spec §5.2
      final trial = List<PlayerCandidate>.from(xi)..add(sub);
      final counts = formationCounts(trial);
      final slotsLeft = 11 - trial.length;
      final belowMin = math.max(0, FormationValidator.minDef - counts['DEF']!) +
          math.max(0, FormationValidator.minMid - counts['MID']!) +
          math.max(0, FormationValidator.minFwd - counts['FWD']!);

      final withinMax = counts['DEF']! <= FormationValidator.maxDef &&
          counts['MID']! <= FormationValidator.maxMid &&
          counts['FWD']! <= FormationValidator.maxFwd;

      if (withinMax && belowMin <= slotsLeft) {
        xi.add(sub);
        outfieldMissing--;
      }
    }

    return xi;
  }

  /// Spec §5.3: Exact bench order evaluation over 2^11 = 2,048 starter absence patterns.
  /// Evaluates all 3! = 6 permutations of outfield bench players.
  /// Uses substitute-conditional points for bench players who sub in (Spec §14 ledger requirement).
  static (List<PlayerCandidate> order, double score) evaluateBenchOrders({
    required List<PlayerCandidate> startingXi,
    required PlayerCandidate benchGk,
    required List<PlayerCandidate> benchOutfield,
    bool useSubstituteConditionalPoints = true,
  }) {
    if (benchOutfield.length != 3) {
      throw ArgumentError('Expected exactly 3 outfield bench players, got ${benchOutfield.length}');
    }

    final nStarters = startingXi.length;
    final starterPStarts = startingXi
        .map((p) => math.max(0.001, math.min(0.999, p.pStart)))
        .toList();

    // Precompute absence pattern probabilities
    // Filter states with prob >= 1e-8 for speed (covers >99.9999% probability mass)
    final activeStates = <({double prob, Set<int> absent})>[];

    for (var stateIdx = 0; stateIdx < 2048; stateIdx++) {
      var prob = 1.0;
      final absent = <int>{};
      for (var i = 0; i < nStarters; i++) {
        if (((stateIdx >> i) & 1) == 1) {
          prob *= (1.0 - starterPStarts[i]);
          absent.add(startingXi[i].fplId);
        } else {
          prob *= starterPStarts[i];
        }
      }
      if (prob > 1e-8) {
        activeStates.add((prob: prob, absent: absent));
      }
    }

    final starterIds = startingXi.map((p) => p.fplId).toSet();

    // 6 permutations of [0, 1, 2]
    const permutations = [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ];

    List<PlayerCandidate>? bestOrder;
    var bestScore = -double.infinity;

    for (final perm in permutations) {
      final fullBench = [
        benchGk,
        benchOutfield[perm[0]],
        benchOutfield[perm[1]],
        benchOutfield[perm[2]],
      ];

      var expectedPoints = 0.0;

      for (final state in activeStates) {
        final finalXi = applyFplAutoSubs(startingXi, fullBench, state.absent);

        var statePts = 0.0;
        for (final p in finalXi) {
          if (starterIds.contains(p.fplId)) {
            statePts += p.conditionalXpStart;
          } else {
            if (useSubstituteConditionalPoints) {
              statePts += p.conditionalXpSub;
            } else {
              statePts += p.xp;
            }
          }
        }

        expectedPoints += state.prob * statePts;
      }

      if (expectedPoints > bestScore) {
        bestScore = expectedPoints;
        bestOrder = fullBench;
      }
    }

    return (bestOrder!, bestScore);
  }

  /// Joint Starting XI, Captain, Vice-Captain, and Bench Order Optimiser (Spec §5.1, §5.2, §5.3).
  ///
  /// Performance budget: target under 1.0s on device (Spec §5.1).
  /// If budget exceeded or [forceFallback] requested:
  /// Evaluates bench search over top 20 candidate XIs and marks [isQuickModeFallback] = true.
  static LineupResult optimizeLineup(
    List<PlayerCandidate> squad, {
    Duration budget = const Duration(milliseconds: 1000),
    int quickModeThresholdXis = 1,
    bool forceFallback = false,
  }) {
    final stopwatch = Stopwatch()..start();

    if (squad.length != 15) {
      throw ArgumentError('Squad must contain exactly 15 players');
    }

    for (final p in squad) {
      if (p.xp < 0.0 && p.position != 'GK') {
        throw ArgumentError('Outfield player ${p.webName} has negative xP: ${p.xp}');
      }
    }

    final validXis = enumerateValidXis(squad);
    if (validXis.isEmpty) {
      throw StateError('No valid formation could be formed from the squad');
    }

    // Evaluate captain pairs for all valid XIs
    final candidates = <({List<PlayerCandidate> xi, PlayerCandidate c, PlayerCandidate v, double pairScore})>[];
    for (final xi in validXis) {
      final (c, v, pairScore) = evaluateCaptainPair(xi);
      candidates.add((xi: xi, c: c, v: v, pairScore: pairScore));
    }

    // Sort descending by Pair score
    candidates.sort((a, b) => b.pairScore.compareTo(a.pairScore));

    final isFallback = forceFallback || quickModeThresholdXis > 1;
    final topCandidates = forceFallback
        ? candidates.take(20).toList()
        : (quickModeThresholdXis > 1
            ? candidates.take(quickModeThresholdXis).toList()
            : candidates.take(1).toList());

    LineupResult? bestResult;
    var bestOverallScore = -double.infinity;

    for (final candidate in topCandidates) {
      // Check budget
      if (bestResult != null && stopwatch.elapsedMilliseconds > budget.inMilliseconds) {
        // Budget limit reached, return current best
        break;
      }

      final xiIds = candidate.xi.map((p) => p.fplId).toSet();
      final benchPlayers = squad.where((p) => !xiIds.contains(p.fplId)).toList();

      final benchGks = benchPlayers.where((p) => p.position == 'GK').toList();
      final benchOutfields = benchPlayers.where((p) => p.position != 'GK').toList();

      assert(benchGks.length == 1, 'Expected exactly 1 backup GK');
      assert(benchOutfields.length == 3, 'Expected exactly 3 outfield bench players');

      final (benchOrder, benchScore) = evaluateBenchOrders(
        startingXi: candidate.xi,
        benchGk: benchGks.first,
        benchOutfield: benchOutfields,
        useSubstituteConditionalPoints: true,
      );

      final qc = candidate.c.pApp;
      final captaincyBonus = candidate.c.xp + (1.0 - qc) * candidate.v.xp;
      final totalScore = benchScore + captaincyBonus;

      if (totalScore > bestOverallScore) {
        bestOverallScore = totalScore;
        final counts = formationCounts(candidate.xi);
        bestResult = LineupResult(
          startingXi: candidate.xi,
          captain: candidate.c,
          viceCaptain: candidate.v,
          bench: benchOrder,
          formation: [counts['GK']!, counts['DEF']!, counts['MID']!, counts['FWD']!],
          totalExpectedPoints: totalScore,
          captaincyScore: captaincyBonus,
          benchOrderScore: benchScore,
          isQuickModeFallback: isFallback,
        );
      }
    }

    return bestResult!;
  }
}
