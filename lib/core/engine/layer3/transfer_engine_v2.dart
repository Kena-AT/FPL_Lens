import 'dart:math' as math;

import '../../optimiser/player_candidate.dart';
import '../../optimiser/transfer_optimiser.dart';
import '../../rules/rules_table.dart';
import '../invariants/engine_invariants.dart';
import '../layer2/lineup_engine_v2.dart';

/// Strategy risk modes per Engine Design §8.4.
enum StrategyRiskMode {
  conservative,
  balanced,
  aggressive,
}

class StrategyConfig {
  final bool hitsAllowed;
  final double zThreshold;

  const StrategyConfig({
    required this.hitsAllowed,
    required this.zThreshold,
  });

  static const Map<StrategyRiskMode, StrategyConfig> defaults = {
    StrategyRiskMode.conservative: StrategyConfig(hitsAllowed: false, zThreshold: 1.5),
    StrategyRiskMode.balanced: StrategyConfig(hitsAllowed: true, zThreshold: 1.0),
    StrategyRiskMode.aggressive: StrategyConfig(hitsAllowed: true, zThreshold: 0.5),
  };
}

/// Output of Layer 3 v2 Transfer Engine (§8.6).
class TransferV2Recommendation {
  final List<PlayerCandidate> transfersOut;
  final List<PlayerCandidate> transfersIn;
  final int hitCost;
  final double rawGain; // V(Q) - V(Q0) - Hit + BankedFTBonus
  final double sigmaGain;
  final double netGainLowerBound; // rawGain - z * sigmaGain
  final bool isHold;
  final bool isApproximate;
  final int horizon;
  final StrategyRiskMode strategy;
  final LineupV2Result lineupResult;
  final String reason;

  const TransferV2Recommendation({
    required this.transfersOut,
    required this.transfersIn,
    required this.hitCost,
    required this.rawGain,
    required this.sigmaGain,
    required this.netGainLowerBound,
    required this.isHold,
    required this.isApproximate,
    required this.horizon,
    required this.strategy,
    required this.lineupResult,
    required this.reason,
  });

  int get transferCount => transfersOut.length;
}

/// Pure Dart Layer 3 v2 Transfer Engine per Engine Design §8.
/// Zero Flutter or I/O imports.
class TransferEngineV2 {
  static const int defaultKIn = 8; // §8.3 shortlist per outgoing player
  static const int defaultKPair = 15; // §8.3 top single swaps for double/triple builds
  static const double defaultGamma = 0.90; // §8.1 multi-GW discount
  static const double defaultPPlayFloor = 0.50; // §8.3 minimum pPlay for H1
  static const double defaultBankedFtOptionValue = 1.2; // §8.2 Gap G5 fix

  /// Estimates per-player 1-GW standard deviation from interval80 or xP fallback.
  static double playerSigma(PlayerCandidate p, {Map<int, double>? sigmaById}) {
    if (sigmaById != null && sigmaById.containsKey(p.fplId)) {
      return math.max(0.25, sigmaById[p.fplId]!);
    }
    return math.max(0.8, 0.45 * math.sqrt(math.max(1.0, p.xp)));
  }

  /// Generates shortlist of up to [kIn] eligible incoming candidates per outgoing player (§8.3).
  static Map<int, List<PlayerCandidate>> generateShortlists({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    int kIn = defaultKIn,
    double pPlayFloor = defaultPPlayFloor,
  }) {
    final validatedSquad = EngineInvariants.validateAndDeduplicatePool(currentSquad);
    final validatedPool = EngineInvariants.validateAndDeduplicatePool(availablePool);
    final squadIds = validatedSquad.map((p) => p.fplId).toSet();

    final shortlists = <int, List<PlayerCandidate>>{};
    for (final outP in validatedSquad) {
      final eligible = <PlayerCandidate>[];
      for (final inP in validatedPool) {
        if (squadIds.contains(inP.fplId)) continue;
        final pPlay = 1.0 - LineupEngineV2.pZero(inP);
        if (pPlay < pPlayFloor) continue;
        final violation = EngineInvariants.checkSingleSwap(
          outPlayer: outP,
          inPlayer: inP,
          currentSquad: validatedSquad,
          bankTenths: bankTenths,
        );
        if (violation != null) continue;
        eligible.add(inP);
      }

      eligible.sort((a, b) {
        final gainA = a.xp - outP.xp;
        final gainB = b.xp - outP.xp;
        final c1 = gainB.compareTo(gainA);
        if (c1 != 0) return c1;
        final c2 = a.priceTenths.compareTo(b.priceTenths);
        if (c2 != 0) return c2;
        return a.fplId.compareTo(b.fplId);
      });

      shortlists[outP.fplId] = eligible.take(kIn).toList();
    }
    return shortlists;
  }

  /// Evaluates a candidate squad Q across horizon H with rollout & banked FT option value (§8.1, §8.2).
  static double _evaluateHorizonGain({
    required List<PlayerCandidate> newSquad,
    required LineupV2Result baseLineup,
    required LineupV2Result newLineup,
    required int transfersMade,
    required int freeTransfersAvailable,
    required int hitCost,
    required int horizon,
    required double gamma,
    required double bankedFtOptionValue,
    Map<int, List<double>>? playerMultiGwXp,
  }) {
    final ftBefore = freeTransfersAvailable;
    final ftAfter = math.min(
      RulesTable.getInt('max_banked_free_transfers'),
      math.max(0, ftBefore - transfersMade),
    );
    final ftDiff = ftAfter - ftBefore;

    if (horizon <= 1) {
      return (newLineup.expectedPoints - baseLineup.expectedPoints) - hitCost;
    }

    var totalGain = (newLineup.expectedPoints - baseLineup.expectedPoints) - hitCost;
    var disc = gamma;
    for (var t = 2; t <= horizon; t++) {
      if (playerMultiGwXp != null) {
        // Use future-GW projected xP differences for the swapped players
        var newSum = 0.0;
        var baseSum = 0.0;
        for (final p in newLineup.startingXi) {
          final arr = playerMultiGwXp[p.fplId];
          newSum += (arr != null && t - 1 < arr.length) ? arr[t - 1] : p.xp;
        }
        for (final p in baseLineup.startingXi) {
          final arr = playerMultiGwXp[p.fplId];
          baseSum += (arr != null && t - 1 < arr.length) ? arr[t - 1] : p.xp;
        }
        totalGain += disc * (newSum - baseSum);
      } else {
        totalGain += disc * (newLineup.expectedPoints - baseLineup.expectedPoints);
      }
      disc *= gamma;
    }

    // Gap G5 fix: account for option value of banking/spending free transfers
    totalGain += bankedFtOptionValue * ftDiff;
    return totalGain;
  }

  /// Finds the best transfer move or abstains (Hold) if uncertainty/cost is not cleared (§8.1, §8.3).
  static TransferV2Recommendation recommend({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    StrategyRiskMode strategy = StrategyRiskMode.balanced,
    int horizon = 1,
    int kIn = defaultKIn,
    int kPair = defaultKPair,
    double gamma = defaultGamma,
    double bankedFtOptionValue = defaultBankedFtOptionValue,
    Map<int, double>? sigmaById,
    Map<int, List<double>>? playerMultiGwXp,
    bool isLowConfidence = false,
    bool isSnapshotStale = false,
    bool allowDoubleSwaps = true,
  }) {
    if (isSnapshotStale) {
      throw const InvariantViolationException(
        'I16',
        'Snapshot is stale; transfer recommendations are disabled.',
      );
    }

    final cfg = StrategyConfig.defaults[strategy]!;
    final validatedSquad = EngineInvariants.validateAndDeduplicatePool(currentSquad);
    if (validatedSquad.length != 15) {
      throw const InvariantViolationException('I4', 'Squad must contain 15 unique players');
    }
    EngineInvariants.validateAndDeduplicatePool([...validatedSquad, ...availablePool]);

    final baseLineup = LineupEngineV2.optimize(validatedSquad);
    final shortlists = generateShortlists(
      currentSquad: validatedSquad,
      availablePool: availablePool,
      bankTenths: bankTenths,
      kIn: kIn,
    );

    final candidateMoves = <({
      List<PlayerCandidate> outList,
      List<PlayerCandidate> inList,
      int hit,
      double gain,
      double sigma,
      double lcb,
      LineupV2Result lineup,
    })>[];

    // 1. Single swaps
    final singleSwaps = <({PlayerCandidate outP, PlayerCandidate inP, double gain})>[];
    for (final outP in validatedSquad) {
      final list = shortlists[outP.fplId] ?? const [];
      for (final inP in list) {
        final hit = TransferOptimiser.computeHitCost(1, freeTransfersAvailable);
        if (hit > 0 && (!cfg.hitsAllowed || isLowConfidence)) continue;

        final newSquad = validatedSquad.map((p) => p.fplId == outP.fplId ? inP : p).toList();
        if (!TransferOptimiser.isValidSquad(newSquad)) continue;

        final newLineup = LineupEngineV2.optimize(newSquad);
        final gain = _evaluateHorizonGain(
          newSquad: newSquad,
          baseLineup: baseLineup,
          newLineup: newLineup,
          transfersMade: 1,
          freeTransfersAvailable: freeTransfersAvailable,
          hitCost: hit,
          horizon: horizon,
          gamma: gamma,
          bankedFtOptionValue: bankedFtOptionValue,
          playerMultiGwXp: playerMultiGwXp,
        );
        final sigma = math.sqrt(
          math.pow(playerSigma(inP, sigmaById: sigmaById), 2) +
              math.pow(playerSigma(outP, sigmaById: sigmaById), 2),
        ) * math.sqrt(horizon.toDouble());
        final lcb = gain - cfg.zThreshold * sigma;

        singleSwaps.add((outP: outP, inP: inP, gain: gain));
        candidateMoves.add((
          outList: [outP],
          inList: [inP],
          hit: hit,
          gain: gain,
          sigma: sigma,
          lcb: lcb,
          lineup: newLineup,
        ));
      }
    }

    // 2. Double swaps from top kPair single swaps (§8.3)
    if (allowDoubleSwaps) {
      singleSwaps.sort((a, b) => b.gain.compareTo(a.gain));
      final topSingles = singleSwaps.take(kPair).toList();
      final hit2 = TransferOptimiser.computeHitCost(2, freeTransfersAvailable);
      if (hit2 == 0 || (cfg.hitsAllowed && !isLowConfidence)) {
        for (var i = 0; i < topSingles.length - 1; i++) {
          for (var j = i + 1; j < topSingles.length; j++) {
            final s1 = topSingles[i];
            final s2 = topSingles[j];
            if (s1.outP.fplId == s2.outP.fplId || s1.inP.fplId == s2.inP.fplId) continue;

            final budgetAfter = bankTenths +
                s1.outP.sellingPriceTenths +
                s2.outP.sellingPriceTenths -
                s1.inP.priceTenths -
                s2.inP.priceTenths;
            if (budgetAfter < 0) continue;

            final newSquad = validatedSquad.map((p) {
              if (p.fplId == s1.outP.fplId) return s1.inP;
              if (p.fplId == s2.outP.fplId) return s2.inP;
              return p;
            }).toList();
            if (!TransferOptimiser.isValidSquad(newSquad)) continue;

            final newLineup = LineupEngineV2.optimize(newSquad);
            final gain = _evaluateHorizonGain(
              newSquad: newSquad,
              baseLineup: baseLineup,
              newLineup: newLineup,
              transfersMade: 2,
              freeTransfersAvailable: freeTransfersAvailable,
              hitCost: hit2,
              horizon: horizon,
              gamma: gamma,
              bankedFtOptionValue: bankedFtOptionValue,
              playerMultiGwXp: playerMultiGwXp,
            );
            final sigma = math.sqrt(
              math.pow(playerSigma(s1.inP, sigmaById: sigmaById), 2) +
                  math.pow(playerSigma(s2.inP, sigmaById: sigmaById), 2) +
                  math.pow(playerSigma(s1.outP, sigmaById: sigmaById), 2) +
                  math.pow(playerSigma(s2.outP, sigmaById: sigmaById), 2),
            ) * math.sqrt(horizon.toDouble());
            final lcb = gain - cfg.zThreshold * sigma;

            candidateMoves.add((
              outList: [s1.outP, s2.outP],
              inList: [s1.inP, s2.inP],
              hit: hit2,
              gain: gain,
              sigma: sigma,
              lcb: lcb,
              lineup: newLineup,
            ));
          }
        }
      }
    }

    // Filter to moves clearing uncertainty gate: Gain - z * sigma > 0 (§8.1)
    final qualifying = candidateMoves.where((m) => m.lcb > 0.0).toList();
    if (qualifying.isEmpty) {
      return TransferV2Recommendation(
        transfersOut: const [],
        transfersIn: const [],
        hitCost: 0,
        rawGain: 0.0,
        sigmaGain: 0.0,
        netGainLowerBound: 0.0,
        isHold: true,
        isApproximate: horizon > 1,
        horizon: horizon,
        strategy: strategy,
        lineupResult: baseLineup,
        reason: 'No transfer beats keeping your squad by enough to be worth a hit.',
      );
    }

    qualifying.sort((a, b) {
      final c1 = b.gain.compareTo(a.gain);
      if (c1 != 0) return c1;
      return a.inList.first.fplId.compareTo(b.inList.first.fplId);
    });

    final best = qualifying.first;
    EngineInvariants.checkHitInvariant(
      transfersCount: best.outList.length,
      freeTransfersAvailable: freeTransfersAvailable,
      hitCost: best.hit,
    );

    return TransferV2Recommendation(
      transfersOut: best.outList,
      transfersIn: best.inList,
      hitCost: best.hit,
      rawGain: best.gain,
      sigmaGain: best.sigma,
      netGainLowerBound: best.lcb,
      isHold: false,
      isApproximate: horizon > 1,
      horizon: horizon,
      strategy: strategy,
      lineupResult: best.lineup,
      reason: 'Expected gain +${best.gain.toStringAsFixed(1)} xP clears uncertainty (±${best.sigma.toStringAsFixed(1)}).',
    );
  }
}
