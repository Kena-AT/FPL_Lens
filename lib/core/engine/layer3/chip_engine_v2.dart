import '../../optimiser/player_candidate.dart';
import '../../optimiser/transfer_optimiser.dart';
import '../../rules/rules_table.dart';
import '../invariants/engine_invariants.dart';
import '../layer2/lineup_engine_v2.dart';

enum ChipDecisionStatus {
  recommended,
  hold,
  noClearRecommendation,
  unavailable,
}

class ChipV2Evaluation {
  final FplChip chip;
  final ChipDecisionStatus status;
  final double counterfactualGain; // Best_t(k) - Best_t(none)
  final double opportunityCost;
  final double sigma;
  final double bestFutureExpectedGain;
  final String? targetPlayerName;
  final String reason;

  const ChipV2Evaluation({
    required this.chip,
    required this.status,
    required this.counterfactualGain,
    required this.opportunityCost,
    required this.sigma,
    required this.bestFutureExpectedGain,
    this.targetPlayerName,
    required this.reason,
  });
}

/// Pure Dart Counterfactual Chip Engine per Engine Design §9.
/// Replaces hard-coded thresholds (Gap G4) with counterfactual value & timing rules.
class ChipEngineV2 {
  static const double defaultFutureDiscountRho = 0.85; // §9.2 [TUNE]
  static const double defaultWcFhReshuffleCost = 2.0; // §9.2 opportunity cost

  /// Evaluates all 4 chips (Triple Captain, Bench Boost, Wildcard, Free Hit) counterfactually.
  static List<ChipV2Evaluation> evaluateAll({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int currentGameweek,
    required Set<FplChip> availableChips,
    Map<FplChip, double>? bestFutureExpectedValue,
    double zThreshold = 1.0,
    double rho = defaultFutureDiscountRho,
  }) {
    final validatedSquad = EngineInvariants.validateAndDeduplicatePool(currentSquad);
    final baseLineup = LineupEngineV2.optimize(validatedSquad);
    final baseV = baseLineup.expectedPoints;
    final results = <ChipV2Evaluation>[];

    // 1. Triple Captain (§9.1)
    if (availableChips.contains(FplChip.tripleCaptain)) {
      final tcLineup = LineupEngineV2.optimize(validatedSquad, captainMultiplier: 3);
      final gain = tcLineup.expectedPoints - baseV;
      final sigma = 1.8; // Captaincy haul noise
      final futureBest = bestFutureExpectedValue?[FplChip.tripleCaptain] ?? 6.5;
      results.add(_decide(
        chip: FplChip.tripleCaptain,
        gain: gain,
        cost: 0.0,
        sigma: sigma,
        futureBest: futureBest,
        rho: rho,
        zThreshold: zThreshold,
        targetName: tcLineup.captain.webName,
      ));
    }

    // 2. Bench Boost (§9.1, §9.4: uses all 15 players with their own P(S_A))
    if (availableChips.contains(FplChip.benchBoost)) {
      final bbLineup = LineupEngineV2.optimize(validatedSquad, benchBoost: true);
      final gain = bbLineup.expectedPoints - baseV;
      final sigma = 2.5;
      final futureBest = bestFutureExpectedValue?[FplChip.benchBoost] ?? 10.0;
      results.add(_decide(
        chip: FplChip.benchBoost,
        gain: gain,
        cost: 0.0,
        sigma: sigma,
        futureBest: futureBest,
        rho: rho,
        zThreshold: zThreshold,
      ));
    }

    // 3. Wildcard & Free Hit (§9.1, §9.4)
    final greedyBestSquad = _buildBestGreedySquad(
      currentSquad: validatedSquad,
      availablePool: availablePool,
      bankTenths: bankTenths,
    );
    final chipSqLineup = LineupEngineV2.optimize(greedyBestSquad);
    final squadUpgradeGain = chipSqLineup.expectedPoints - baseV;

    if (availableChips.contains(FplChip.wildcard)) {
      final futureBest = bestFutureExpectedValue?[FplChip.wildcard] ?? 12.0;
      results.add(_decide(
        chip: FplChip.wildcard,
        gain: squadUpgradeGain,
        cost: defaultWcFhReshuffleCost,
        sigma: 3.5,
        futureBest: futureBest,
        rho: rho,
        zThreshold: zThreshold,
      ));
    }

    if (availableChips.contains(FplChip.freeHit)) {
      final fhAllowedGw1 = RulesTable.getBool('free_hit_allowed_gw1');
      if (currentGameweek == 1 && !fhAllowedGw1) {
        results.add(const ChipV2Evaluation(
          chip: FplChip.freeHit,
          status: ChipDecisionStatus.unavailable,
          counterfactualGain: 0.0,
          opportunityCost: 0.0,
          sigma: 0.0,
          bestFutureExpectedGain: 0.0,
          reason: 'Free Hit is not playable in Gameweek 1.',
        ));
      } else {
        final futureBest = bestFutureExpectedValue?[FplChip.freeHit] ?? 14.0;
        results.add(_decide(
          chip: FplChip.freeHit,
          gain: squadUpgradeGain,
          cost: defaultWcFhReshuffleCost,
          sigma: 3.5,
          futureBest: futureBest,
          rho: rho,
          zThreshold: zThreshold,
        ));
      }
    }

    return results;
  }

  static ChipV2Evaluation _decide({
    required FplChip chip,
    required double gain,
    required double cost,
    required double sigma,
    required double futureBest,
    required double rho,
    required double zThreshold,
    String? targetName,
  }) {
    final netNow = gain - cost;
    final clearsNoise = netNow - zThreshold * sigma > 0.0;
    final beatsFuture = netNow >= futureBest * rho;

    if (netNow <= 0.0 || !clearsNoise) {
      return ChipV2Evaluation(
        chip: chip,
        status: ChipDecisionStatus.noClearRecommendation,
        counterfactualGain: gain,
        opportunityCost: cost,
        sigma: sigma,
        bestFutureExpectedGain: futureBest,
        targetPlayerName: targetName,
        reason: 'No clear recommendation: counterfactual gain (+${gain.toStringAsFixed(1)} xP) is within noise.',
      );
    }

    if (!beatsFuture) {
      return ChipV2Evaluation(
        chip: chip,
        status: ChipDecisionStatus.hold,
        counterfactualGain: gain,
        opportunityCost: cost,
        sigma: sigma,
        bestFutureExpectedGain: futureBest,
        targetPlayerName: targetName,
        reason: 'Hold: a future gameweek is expected to yield higher value (${futureBest.toStringAsFixed(1)} xP).',
      );
    }

    return ChipV2Evaluation(
      chip: chip,
      status: ChipDecisionStatus.recommended,
      counterfactualGain: gain,
      opportunityCost: cost,
      sigma: sigma,
      bestFutureExpectedGain: futureBest,
      targetPlayerName: targetName,
      reason: 'Recommended: counterfactual gain +${gain.toStringAsFixed(1)} xP beats future weeks.',
    );
  }

  /// Builds a legal 15-man squad within total selling-value + ITB budget for WC/FH counterfactual.
  static List<PlayerCandidate> _buildBestGreedySquad({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
  }) {
    final totalBudget = bankTenths + currentSquad.fold<int>(0, (s, p) => s + p.sellingPriceTenths);
    final all = EngineInvariants.validateAndDeduplicatePool([...currentSquad, ...availablePool]);

    // Start from currentSquad and greedily upgrade highest-gain valid swaps within remaining budget
    var best = List<PlayerCandidate>.from(currentSquad);
    var remaining = bankTenths;

    final byPos = <String, List<PlayerCandidate>>{'GK': [], 'DEF': [], 'MID': [], 'FWD': []};
    for (final p in all) {
      byPos[p.position]?.add(p);
    }
    for (final list in byPos.values) {
      list.sort((a, b) => b.xp.compareTo(a.xp));
    }

    for (var i = 0; i < best.length; i++) {
      final outP = best[i];
      for (final inP in byPos[outP.position] ?? const <PlayerCandidate>[]) {
        if (inP.xp <= outP.xp) break;
        if (best.any((p) => p.fplId == inP.fplId)) continue;
        final deltaCost = inP.priceTenths - outP.sellingPriceTenths;
        if (deltaCost > remaining) continue;
        final trial = List<PlayerCandidate>.from(best)..[i] = inP;
        if (TransferOptimiser.isValidSquad(trial)) {
          best = trial;
          remaining -= deltaCost;
          break;
        }
      }
    }
    assert(best.fold<int>(0, (s, p) => s + p.priceTenths) <= totalBudget + 1000);
    return best;
  }
}
