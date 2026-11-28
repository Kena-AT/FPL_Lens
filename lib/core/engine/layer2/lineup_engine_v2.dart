import 'dart:math' as math;

import '../../optimiser/lineup_optimiser.dart';
import '../../optimiser/player_candidate.dart';
import '../invariants/engine_invariants.dart';

/// Captain alternative with expected score gap (§6.4).
class CaptainAlternative {
  final PlayerCandidate player;
  final double expectedTeamPoints;
  final double gapFromBest;
  final bool isCloseCall;

  const CaptainAlternative({
    required this.player,
    required this.expectedTeamPoints,
    required this.gapFromBest,
    required this.isCloseCall,
  });
}

/// Output of Layer 2 v2 exact lineup optimiser (§6.4).
class LineupV2Result {
  final List<PlayerCandidate> startingXi;
  final PlayerCandidate captain;
  final PlayerCandidate viceCaptain;
  final List<PlayerCandidate> bench; // [0] = bench GK, [1..3] = outfield bench
  final List<int> formation;
  final double expectedPoints; // V(XI, c, v, omega)
  final double neglectedMass;
  final List<CaptainAlternative> captainAlternatives;
  final bool usedApproximation;

  const LineupV2Result({
    required this.startingXi,
    required this.captain,
    required this.viceCaptain,
    required this.bench,
    required this.formation,
    required this.expectedPoints,
    required this.neglectedMass,
    required this.captainAlternatives,
    required this.usedApproximation,
  });

  Map<String, dynamic> toJson() => {
        'starting_xi_ids': startingXi.map((p) => p.fplId).toList(),
        'captain_id': captain.fplId,
        'vice_captain_id': viceCaptain.fplId,
        'bench_ids': bench.map((p) => p.fplId).toList(),
        'formation': formation,
        'expected_points': double.parse(expectedPoints.toStringAsFixed(6)),
        'neglected_mass': neglectedMass,
        'used_approximation': usedApproximation,
      };
}

/// Pure Dart Layer 2 v2 Exact Lineup, Captain & Bench Optimiser (§6).
/// Zero Flutter or I/O imports.
class LineupEngineV2 {
  static const double defaultEpsilon = 1e-4; // §6.2 uncertainty pruning threshold
  static const int defaultTopK = 20; // §6.2 two-stage selection K

  /// Probability of zero minutes: P(S_A) = max(0, 1 - P(Start) - P(Sub)) (fixes Gap G3).
  static double pZero(PlayerCandidate p) {
    final play = math.min(1.0, math.max(0.0, p.pStart + p.pSub));
    return math.max(0.0, 1.0 - play);
  }

  /// Expected points conditional on playing at least 1 minute: xp_given_play (fixes Gap G8).
  static double xpGivenPlay(PlayerCandidate p) {
    final pPlay = 1.0 - pZero(p);
    if (pPlay <= 1e-6) return 0.0;
    return p.xp / pPlay;
  }

  /// Enumerates absence patterns A subset of S (all 15 players) with uncertainty pruning.
  /// Players with P(S_A) < epsilon are fixed present; P(S_A) > 1 - epsilon are fixed absent.
  /// Caps active uncertain players at [maxUncertain] (highest entropy) for mobile speed.
  static ({List<({double prob, Set<int> absent})> patterns, double neglectedMass})
      enumerateAbsencePatterns(
    List<PlayerCandidate> squad, {
    double epsilon = defaultEpsilon,
    int maxUncertain = 10,
  }) {
    final fixedAbsent = <int>{};
    final uncertain = <({int id, double pz})>[];
    var baseProb = 1.0;

    for (final p in squad) {
      final pz = pZero(p);
      if (pz < epsilon) {
        baseProb *= (1.0 - pz);
      } else if (pz > 1.0 - epsilon) {
        fixedAbsent.add(p.fplId);
        baseProb *= pz;
      } else {
        uncertain.add((id: p.fplId, pz: pz));
      }
    }

    // If more than maxUncertain players are uncertain, fix the most-likely-present ones
    if (uncertain.length > maxUncertain) {
      uncertain.sort((a, b) => (b.pz * (1.0 - b.pz)).compareTo(a.pz * (1.0 - a.pz)));
      final overflow = uncertain.sublist(maxUncertain);
      uncertain.removeRange(maxUncertain, uncertain.length);
      for (final o in overflow) {
        if (o.pz >= 0.5) {
          fixedAbsent.add(o.id);
          baseProb *= o.pz;
        } else {
          baseProb *= (1.0 - o.pz);
        }
      }
    }

    final m = uncertain.length;
    final totalStates = 1 << m;
    final patterns = <({double prob, Set<int> absent})>[];
    var coveredMass = 0.0;

    for (var mask = 0; mask < totalStates; mask++) {
      var prob = baseProb;
      final absent = Set<int>.from(fixedAbsent);
      for (var i = 0; i < m; i++) {
        if (((mask >> i) & 1) == 1) {
          prob *= uncertain[i].pz;
          absent.add(uncertain[i].id);
        } else {
          prob *= (1.0 - uncertain[i].pz);
        }
      }
      coveredMass += prob;
      if (prob >= 1e-7) {
        patterns.add((prob: prob, absent: absent));
      }
    }

    if (coveredMass > 0.0 && (1.0 - coveredMass).abs() > 1e-12) {
      final scale = 1.0 / coveredMass;
      for (var i = 0; i < patterns.length; i++) {
        patterns[i] = (prob: patterns[i].prob * scale, absent: patterns[i].absent);
      }
    }

    return (
      patterns: patterns,
      neglectedMass: math.max(0.0, 1.0 - coveredMass),
    );
  }

  /// Exact expected points V(XI, c, v, omega) over enumerated patterns (§6.1).
  static double evaluateExactV({
    required List<PlayerCandidate> startingXi,
    required List<PlayerCandidate> bench,
    required PlayerCandidate captain,
    required PlayerCandidate viceCaptain,
    required List<({double prob, Set<int> absent})> patterns,
    required Map<int, double> xpPlayById,
    int captainMultiplier = 2, // 3 for Triple Captain
    bool benchBoost = false,
  }) {
    var totalV = 0.0;
    final extraMult = (captainMultiplier - 1).toDouble();

    for (final pat in patterns) {
      final absent = pat.absent;
      var pts = 0.0;

      if (benchBoost) {
        for (final p in startingXi) {
          if (!absent.contains(p.fplId)) pts += xpPlayById[p.fplId] ?? 0.0;
        }
        for (final p in bench) {
          if (!absent.contains(p.fplId)) pts += xpPlayById[p.fplId] ?? 0.0;
        }
      } else {
        final finalXi = LineupOptimiser.applyFplAutoSubs(startingXi, bench, absent);
        for (final p in finalXi) {
          pts += xpPlayById[p.fplId] ?? 0.0;
        }
      }

      // Captain / Vice-captain multiplier (§3.3)
      if (!absent.contains(captain.fplId)) {
        pts += extraMult * (xpPlayById[captain.fplId] ?? 0.0);
      } else if (!absent.contains(viceCaptain.fplId)) {
        pts += extraMult * (xpPlayById[viceCaptain.fplId] ?? 0.0);
      }

      totalV += pat.prob * pts;
    }

    return totalV;
  }

  static int _idSum(List<PlayerCandidate> xi) => xi.fold(0, (s, p) => s + p.fplId);

  /// Optimizes XI, captain, vice-captain, and bench order deterministically (§6.2, §6.3).
  static LineupV2Result optimize(
    List<PlayerCandidate> squad, {
    int topK = defaultTopK,
    double epsilon = defaultEpsilon,
    int captainMultiplier = 2,
    bool benchBoost = false,
    bool exhaustive = false,
    double closeCallNoiseMargin = 0.5,
  }) {
    final validated = EngineInvariants.validateAndDeduplicatePool(squad);
    if (validated.length != 15) {
      throw const InvariantViolationException('I4', 'Squad must contain 15 unique players');
    }

    // Sort deterministically by fplId (§13.3)
    final orderedSquad = List<PlayerCandidate>.from(validated)
      ..sort((a, b) => a.fplId.compareTo(b.fplId));

    final xpPlayById = {for (final p in orderedSquad) p.fplId: xpGivenPlay(p)};
    final patRes = enumerateAbsencePatterns(orderedSquad, epsilon: exhaustive ? 0.0 : epsilon);
    final validXis = LineupOptimiser.enumerateValidXis(orderedSquad);

    // Stage 1: Cheap score sum(xp) + best captain term
    final stage1 = <({List<PlayerCandidate> xi, double cheapScore, double xpSum})>[];
    for (final xi in validXis) {
      final (c, v, pairScore) = LineupOptimiser.evaluateCaptainPair(xi);
      final xpSum = xi.fold(0.0, (s, p) => s + p.xp);
      final adjScore = captainMultiplier == 3 ? pairScore + c.xp : pairScore;
      // Touch v so it's clear both c and v come from stage 1
      if (v.fplId != c.fplId) {
        stage1.add((xi: xi, cheapScore: adjScore, xpSum: xpSum));
      }
    }

    stage1.sort((a, b) {
      final c1 = b.cheapScore.compareTo(a.cheapScore);
      if (c1 != 0) return c1;
      final c2 = b.xpSum.compareTo(a.xpSum);
      if (c2 != 0) return c2;
      return _idSum(a.xi).compareTo(_idSum(b.xi));
    });

    final candidates = exhaustive ? stage1 : stage1.take(math.min(topK, stage1.length)).toList();

    const perms = [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ];

    double bestV = -double.infinity;
    double bestXpSum = -double.infinity;
    int bestIdSum = 1 << 30;
    List<PlayerCandidate>? bestXi;
    PlayerCandidate? bestC;
    PlayerCandidate? bestVPlayer;
    List<PlayerCandidate>? bestBench;
    final bestCapScoresForBestXi = <int, double>{};

    for (final cand in candidates) {
      final xi = cand.xi;
      final xiIds = xi.map((p) => p.fplId).toSet();
      final benchPlayers = orderedSquad.where((p) => !xiIds.contains(p.fplId)).toList();
      final benchGk = benchPlayers.firstWhere((p) => p.position == 'GK');
      final benchOut = benchPlayers.where((p) => p.position != 'GK').toList()
        ..sort((a, b) {
          final c = b.xp.compareTo(a.xp);
          return c != 0 ? c : a.fplId.compareTo(b.fplId);
        });

      // Captain bonus depends only on absence patterns A (independent of bench order omega)
      final xiByXp = List<PlayerCandidate>.from(xi)
        ..sort((a, b) {
          final c = b.xp.compareTo(a.xp);
          return c != 0 ? c : a.fplId.compareTo(b.fplId);
        });
      final capPool = exhaustive ? xiByXp : xiByXp.take(4).toList();
      final extraMult = (captainMultiplier - 1).toDouble();

      var bestCapBonus = -double.infinity;
      PlayerCandidate? xiBestC;
      PlayerCandidate? xiBestV;
      for (final c in capPool) {
        for (final v in capPool) {
          if (c.fplId == v.fplId) continue;
          var capBonus = 0.0;
          final cXp = xpPlayById[c.fplId] ?? 0.0;
          final vXp = xpPlayById[v.fplId] ?? 0.0;
          for (final pat in patRes.patterns) {
            if (!pat.absent.contains(c.fplId)) {
              capBonus += pat.prob * extraMult * cXp;
            } else if (!pat.absent.contains(v.fplId)) {
              capBonus += pat.prob * extraMult * vXp;
            }
          }
          if (capBonus > bestCapBonus + 1e-12) {
            bestCapBonus = capBonus;
            xiBestC = c;
            xiBestV = v;
          }
        }
      }

      // Evaluate each of the 6 bench orders once (starting from xp-descending order)
      for (final perm in perms) {
        final fullBench = [benchGk, benchOut[perm[0]], benchOut[perm[1]], benchOut[perm[2]]];
        var baseScore = 0.0;
        for (final pat in patRes.patterns) {
          if (benchBoost) {
            for (final p in xi) {
              if (!pat.absent.contains(p.fplId)) baseScore += pat.prob * (xpPlayById[p.fplId] ?? 0.0);
            }
            for (final p in fullBench) {
              if (!pat.absent.contains(p.fplId)) baseScore += pat.prob * (xpPlayById[p.fplId] ?? 0.0);
            }
          } else {
            final finalXi = LineupOptimiser.applyFplAutoSubs(xi, fullBench, pat.absent);
            for (final p in finalXi) {
              baseScore += pat.prob * (xpPlayById[p.fplId] ?? 0.0);
            }
          }
        }
        final val = baseScore + bestCapBonus;
        final idSum = _idSum(xi);
        final better = val > bestV + 1e-12 ||
            ((val - bestV).abs() <= 1e-12 && cand.xpSum > bestXpSum + 1e-12) ||
            ((val - bestV).abs() <= 1e-12 &&
                (cand.xpSum - bestXpSum).abs() <= 1e-12 &&
                idSum < bestIdSum);
        if (better) {
          bestV = val;
          bestXpSum = cand.xpSum;
          bestIdSum = idSum;
          bestXi = xi;
          bestC = xiBestC;
          bestVPlayer = xiBestV;
          bestBench = fullBench;
        }
      }
    }

    // Compute captain alternatives on the winning XI + bench (§6.4)
    for (final c in bestXi!) {
      final val = evaluateExactV(
        startingXi: bestXi,
        bench: bestBench!,
        captain: c,
        viceCaptain: c.fplId == bestVPlayer!.fplId ? bestC! : bestVPlayer,
        patterns: patRes.patterns,
        xpPlayById: xpPlayById,
        captainMultiplier: captainMultiplier,
        benchBoost: benchBoost,
      );
      bestCapScoresForBestXi[c.fplId] = val;
    }

    final sortedCaps = List<PlayerCandidate>.from(bestXi)
      ..sort((a, b) {
        final cmp = (bestCapScoresForBestXi[b.fplId] ?? 0.0)
            .compareTo(bestCapScoresForBestXi[a.fplId] ?? 0.0);
        return cmp != 0 ? cmp : a.fplId.compareTo(b.fplId);
      });

    final alts = sortedCaps.take(3).map((p) {
      final score = bestCapScoresForBestXi[p.fplId] ?? bestV;
      final gap = bestV - score;
      return CaptainAlternative(
        player: p,
        expectedTeamPoints: score,
        gapFromBest: gap,
        isCloseCall: p.fplId != bestC!.fplId && gap <= closeCallNoiseMargin,
      );
    }).toList();

    EngineInvariants.checkLineupInvariants(
      startingXi: bestXi,
      captain: bestC!,
      viceCaptain: bestVPlayer!,
    );

    final counts = LineupOptimiser.formationCounts(bestXi);
    return LineupV2Result(
      startingXi: bestXi,
      captain: bestC,
      viceCaptain: bestVPlayer,
      bench: bestBench!,
      formation: [counts['GK']!, counts['DEF']!, counts['MID']!, counts['FWD']!],
      expectedPoints: bestV,
      neglectedMass: patRes.neglectedMass,
      captainAlternatives: alts,
      usedApproximation: !exhaustive && stage1.length > topK,
    );
  }
}
