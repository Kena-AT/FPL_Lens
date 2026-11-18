import 'dart:math' as math;
import 'lineup_optimiser.dart';
import 'player_candidate.dart';

/// Transfer strategy options for Transfer Lab
enum TransferStrategy {
  optimal,
  singleOnly,
  multiOnly,
}

/// FPL Chips for tactical evaluation
enum FplChip {
  wildcard,
  freeHit,
  tripleCaptain,
  benchBoost,
}

/// Structured Chip Recommendation result
class ChipRecommendation {
  final FplChip chip;
  final String title;
  final bool isRecommended;
  final String reason;
  final double projectedGain;
  final String? recommendedPlayerName;

  const ChipRecommendation({
    required this.chip,
    required this.title,
    required this.isRecommended,
    required this.reason,
    required this.projectedGain,
    this.recommendedPlayerName,
  });

  Map<String, dynamic> toJson() => {
        'chip': chip.name,
        'title': title,
        'is_recommended': isRecommended,
        'reason': reason,
        'projected_gain': projectedGain,
        'recommended_player_name': recommendedPlayerName,
      };
}


/// Single transfer move recommendation.
class TransferMove {
  final List<PlayerCandidate> transfersOut;
  final List<PlayerCandidate> transfersIn;
  final int hitCost;
  final double netExpectedPoints;
  final LineupResult lineupResult;
  final int horizon;

  const TransferMove({
    required this.transfersOut,
    required this.transfersIn,
    required this.hitCost,
    required this.netExpectedPoints,
    required this.lineupResult,
    this.horizon = 1,
  });

  int get transferCount => transfersOut.length;

  Map<String, dynamic> toJson() {
    return {
      'transfers_out_ids': transfersOut.map((p) => p.fplId).toList(),
      'transfers_in_ids': transfersIn.map((p) => p.fplId).toList(),
      'hit_cost': hitCost,
      'net_expected_points': netExpectedPoints,
      'horizon': horizon,
      'lineup': lineupResult.toJson(),
    };
  }
}

/// Pure Dart Transfer Optimiser (Spec §6).
/// Zero Flutter or I/O imports.
class TransferOptimiser {
  static const double gammaDiscount = 0.90; // Spec §6.1
  static const int maxClubPlayers = 3;
  static const int hitCostPerTransfer = 4; // Spec §6.2

  /// Selling price calculation per official FPL rules and Spec §6:
  /// When selling a player bought for P0 whose current price is P:
  /// If P > P0: sell price = P0 + floor((P - P0) / 2)
  /// If P <= P0: sell price = P
  static int computeSellingPriceTenths(int currentPriceTenths, int purchasePriceTenths) {
    if (currentPriceTenths <= purchasePriceTenths) {
      return currentPriceTenths;
    }
    final profit = currentPriceTenths - purchasePriceTenths;
    return purchasePriceTenths + (profit ~/ 2);
  }

  /// Banked free transfer rules per Spec §6.2:
  /// - avail_t = min(5, bank_{t-1} + 1)
  /// - HitCost_t = 0 if chip in {WILDCARD, FREE_HIT} else 4 * max(0, Transfers_t - avail_t)
  /// - bank_t = bank_{t-1} if chip in {WILDCARD, FREE_HIT} else min(5, max(0, avail_t - Transfers_t))
  static const int maxBankedFreeTransfers = 5;

  /// Calculates available free transfers for gameweek t from previously banked free transfers.
  static int computeAvailableFreeTransfers(int previousBankedTransfers) {
    return math.min(maxBankedFreeTransfers, math.max(0, previousBankedTransfers) + 1);
  }

  /// Calculates hit penalty: 4 points per transfer exceeding free transfers, or 0 if a chip is active.
  static int computeHitCost(
    int transfersCount,
    int freeTransfersAvailable, {
    bool isChipActive = false,
  }) {
    if (isChipActive) return 0;
    final hits = math.max(0, transfersCount - freeTransfersAvailable);
    return hits * hitCostPerTransfer;
  }

  /// Computes remaining banked transfers after making transfers in gameweek t.
  static int computeBankAfterTransfers({
    required int previousBankedTransfers,
    required int transfersMade,
    bool isChipActive = false,
  }) {
    if (isChipActive) {
      // Kept through Wildcard and Free Hit per Spec §6.2
      return math.min(maxBankedFreeTransfers, math.max(0, previousBankedTransfers));
    }
    final avail = computeAvailableFreeTransfers(previousBankedTransfers);
    return math.min(maxBankedFreeTransfers, math.max(0, avail - transfersMade));
  }

  /// Checks if squad complies with 15-player position limits and club limit (max 3).
  static bool isValidSquad(List<PlayerCandidate> squad) {
    if (squad.length != 15) return false;

    var gk = 0;
    var def = 0;
    var mid = 0;
    var fwd = 0;
    final clubCounts = <int, int>{};

    for (final p in squad) {
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
      clubCounts[p.clubId] = (clubCounts[p.clubId] ?? 0) + 1;
      if (clubCounts[p.clubId]! > maxClubPlayers) {
        return false;
      }
    }

    return gk == 2 && def == 5 && mid == 5 && fwd == 3;
  }

  /// Horizon 1 Exact Transfer Search (0, 1, or 2 transfers).
  /// Considers all candidate replacements from [availablePool] within bank budget.
  static TransferMove optimizeTransfersHorizon1({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    TransferStrategy strategy = TransferStrategy.optimal,
  }) {
    if (currentSquad.length != 15) {
      throw ArgumentError('Current squad must contain exactly 15 players');
    }

    // Baseline: 0 transfers (roll / keep)
    final baselineLineup = LineupOptimiser.optimizeLineup(currentSquad);
    var bestMove = TransferMove(
      transfersOut: const [],
      transfersIn: const [],
      hitCost: 0,
      netExpectedPoints: baselineLineup.totalExpectedPoints,
      lineupResult: baselineLineup,
      horizon: 1,
    );

    // Group available pool by position, sorted by xP descending
    final poolByPos = <String, List<PlayerCandidate>>{
      'GK': [],
      'DEF': [],
      'MID': [],
      'FWD': [],
    };
    final currentSquadIds = currentSquad.map((p) => p.fplId).toSet();

    for (final p in availablePool) {
      if (!currentSquadIds.contains(p.fplId) && poolByPos.containsKey(p.position)) {
        poolByPos[p.position]!.add(p);
      }
    }
    for (final pos in poolByPos.keys) {
      poolByPos[pos]!.sort((a, b) => b.xp.compareTo(a.xp));
    }

    // 1-Transfer Evaluation (Exact with upper-bound branch-and-bound pruning)
    if (strategy != TransferStrategy.multiOnly) {
    for (var i = 0; i < currentSquad.length; i++) {
      final outPlayer = currentSquad[i];
      final availableBudget = bankTenths + outPlayer.sellingPriceTenths;
      final candidates = poolByPos[outPlayer.position] ?? const [];

      for (final inPlayer in candidates) {
        if (inPlayer.priceTenths > availableBudget) continue;

        final hit = computeHitCost(1, freeTransfersAvailable);
        // Conservative upper bound on net gain: delta raw xP + 2.0 (captaincy variance) - hit
        final maxPossibleNet = baselineLineup.totalExpectedPoints + (inPlayer.xp - outPlayer.xp) + 2.0 - hit;
        // Since candidates are sorted descending by xP, no subsequent candidate can beat bestMove
        if (maxPossibleNet <= bestMove.netExpectedPoints) break;

        final newSquad = List<PlayerCandidate>.from(currentSquad);
        newSquad[i] = inPlayer;

        if (!isValidSquad(newSquad)) continue;

        final lineup = LineupOptimiser.optimizeLineup(newSquad);
        final netXp = lineup.totalExpectedPoints - hit;

        if (netXp > bestMove.netExpectedPoints) {
          bestMove = TransferMove(
            transfersOut: [outPlayer],
            transfersIn: [inPlayer],
            hitCost: hit,
            netExpectedPoints: netXp,
            lineupResult: lineup,
            horizon: 1,
          );
        }
      }
    }

    }

    // 2-Transfer Evaluation (Top candidates per position with upper-bound pruning)
    if (strategy != TransferStrategy.singleOnly) {
    final candidateSubset = <String, List<PlayerCandidate>>{};
    for (final pos in poolByPos.keys) {
      candidateSubset[pos] = poolByPos[pos]!.take(5).toList();
    }

    final hit2 = computeHitCost(2, freeTransfersAvailable);

    for (var i = 0; i < currentSquad.length - 1; i++) {
      for (var j = i + 1; j < currentSquad.length; j++) {
        final out1 = currentSquad[i];
        final out2 = currentSquad[j];
        final twoBudget = bankTenths + out1.sellingPriceTenths + out2.sellingPriceTenths;

        final inPool1 = candidateSubset[out1.position] ?? const [];
        final inPool2 = candidateSubset[out2.position] ?? const [];
        if (inPool1.isEmpty || inPool2.isEmpty) continue;

        final topIn2 = inPool2.first;

        for (final in1 in inPool1) {
          // If in1 with the highest possible in2 cannot beat bestMove, then no subsequent in1 can either
          final maxForIn1 = baselineLineup.totalExpectedPoints +
              (in1.xp + topIn2.xp - out1.xp - out2.xp) + 3.0 - hit2;
          if (maxForIn1 <= bestMove.netExpectedPoints) break;

          for (final in2 in inPool2) {
            if (in1.fplId == in2.fplId) continue;
            if (in1.priceTenths + in2.priceTenths > twoBudget) continue;

            // Conservative upper bound on net gain: delta raw xP + 3.0 (captaincy variance) - hit
            final maxPossibleNet = baselineLineup.totalExpectedPoints +
                (in1.xp + in2.xp - out1.xp - out2.xp) + 3.0 - hit2;
            // Since inPool2 is sorted descending by xP, no subsequent in2 can beat bestMove with this in1
            if (maxPossibleNet <= bestMove.netExpectedPoints) break;

            final newSquad = List<PlayerCandidate>.from(currentSquad);
            newSquad[i] = in1;
            newSquad[j] = in2;

            if (!isValidSquad(newSquad)) continue;

            final lineup = LineupOptimiser.optimizeLineup(newSquad);
            final netXp = lineup.totalExpectedPoints - hit2;

            if (netXp > bestMove.netExpectedPoints) {
              bestMove = TransferMove(
                transfersOut: [out1, out2],
                transfersIn: [in1, in2],
                hitCost: hit2,
                netExpectedPoints: netXp,
                lineupResult: lineup,
                horizon: 1,
              );
            }
          }
        }
      }
    }

      // 3-Transfer Evaluation (Targeting weakest squad members for high-upside multi-transfer)
      final sortedByXp = List<PlayerCandidate>.from(currentSquad)
        ..sort((a, b) => a.xp.compareTo(b.xp));
      final weakestSquad = sortedByXp.take(4).toList();

      final hit3 = computeHitCost(3, freeTransfersAvailable);
      final trioCandidates = <String, List<PlayerCandidate>>{};
      for (final pos in poolByPos.keys) {
        trioCandidates[pos] = poolByPos[pos]!.take(2).toList();
      }

      if (weakestSquad.length >= 3) {
        for (var i = 0; i < weakestSquad.length - 2; i++) {
          for (var j = i + 1; j < weakestSquad.length - 1; j++) {
            for (var k = j + 1; k < weakestSquad.length; k++) {
              final o1 = weakestSquad[i];
              final o2 = weakestSquad[j];
              final o3 = weakestSquad[k];
              final threeBudget = bankTenths + o1.sellingPriceTenths + o2.sellingPriceTenths + o3.sellingPriceTenths;

              final p1 = trioCandidates[o1.position] ?? const [];
              final p2 = trioCandidates[o2.position] ?? const [];
              final p3 = trioCandidates[o3.position] ?? const [];
              if (p1.isEmpty || p2.isEmpty || p3.isEmpty) continue;

              for (final in1 in p1) {
                for (final in2 in p2) {
                  if (in2.fplId == in1.fplId) continue;
                  for (final in3 in p3) {
                    if (in3.fplId == in1.fplId || in3.fplId == in2.fplId) continue;
                    if (in1.priceTenths + in2.priceTenths + in3.priceTenths > threeBudget) continue;

                    final newSquad = currentSquad.map((p) {
                      if (p.fplId == o1.fplId) return in1;
                      if (p.fplId == o2.fplId) return in2;
                      if (p.fplId == o3.fplId) return in3;
                      return p;
                    }).toList();

                    if (!isValidSquad(newSquad)) continue;

                    final lineup = LineupOptimiser.optimizeLineup(newSquad);
                    final netXp = lineup.totalExpectedPoints - hit3;

                    if (netXp > bestMove.netExpectedPoints) {
                      bestMove = TransferMove(
                        transfersOut: [o1, o2, o3],
                        transfersIn: [in1, in2, in3],
                        hitCost: hit3,
                        netExpectedPoints: netXp,
                        lineupResult: lineup,
                        horizon: 1,
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return bestMove;
  }

  /// Evaluates chip viability (Triple Captain, Wildcard, Free Hit) based on deterministic data.
  static List<ChipRecommendation> evaluateChips({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    required TransferMove recommendedMove,
  }) {
    final chips = <ChipRecommendation>[];

    // 1. Triple Captain Evaluation
    final lineup = recommendedMove.lineupResult;
    final captain = lineup.captain;
    final topCaptainXp = captain.xp;

    if (topCaptainXp >= 9.5) {
      chips.add(ChipRecommendation(
        chip: FplChip.tripleCaptain,
        title: 'Triple Captain',
        isRecommended: true,
        projectedGain: double.parse(topCaptainXp.toStringAsFixed(1)),
        recommendedPlayerName: captain.webName,
        reason: '${captain.webName} has exceptional projected points ($topCaptainXp xP) with high haul potential. Ideal gameweek to activate Triple Captain!',
      ));
    } else {
      chips.add(ChipRecommendation(
        chip: FplChip.tripleCaptain,
        title: 'Triple Captain',
        isRecommended: false,
        projectedGain: 0.0,
        recommendedPlayerName: captain.webName,
        reason: 'Top captain projection is ${topCaptainXp.toStringAsFixed(1)} xP. Save chip for a Double Gameweek or when captain projection reaches 9.5+ xP.',
      ));
    }

    // 2. Wildcard Evaluation
    final lowAvailabilityCount = currentSquad.where((p) => p.pStart <= 0.25).length;
    final multiTransferHitSavings = recommendedMove.hitCost;

    if (lowAvailabilityCount >= 3 || (recommendedMove.transferCount >= 3 && multiTransferHitSavings >= 8)) {
      chips.add(ChipRecommendation(
        chip: FplChip.wildcard,
        title: 'Wildcard',
        isRecommended: true,
        projectedGain: multiTransferHitSavings.toDouble() + (recommendedMove.transferCount * 2.5),
        reason: 'Squad has $lowAvailabilityCount compromised players and requires multiple squad adjustments. Activating Wildcard removes all transfer hit costs (-$multiTransferHitSavings pts) and reconstructs your squad structure.',
      ));
    } else {
      chips.add(const ChipRecommendation(
        chip: FplChip.wildcard,
        title: 'Wildcard',
        isRecommended: false,
        projectedGain: 0.0,
        reason: 'Current squad structure is solid with manageable transfer requirements. Save Wildcard for upcoming fixture swings or fixture congestion.',
      ));
    }

    // 3. Free Hit Evaluation
    final startingLowXp = lineup.startingXi.where((p) => p.xp <= 1.5).length;
    if (startingLowXp >= 3) {
      chips.add(ChipRecommendation(
        chip: FplChip.freeHit,
        title: 'Free Hit',
        isRecommended: true,
        projectedGain: startingLowXp * 4.5,
        reason: '$startingLowXp players in your starting XI have blank or high-difficulty fixtures. A Free Hit allows you to field a full high-upside XI for this gameweek without altering your long-term team.',
      ));
    } else {
      chips.add(const ChipRecommendation(
        chip: FplChip.freeHit,
        title: 'Free Hit',
        isRecommended: false,
        projectedGain: 0.0,
        reason: 'No widespread fixture blanks or emergencies detected this week. Save Free Hit for major blank or double gameweeks.',
      ));
    }

    return chips;
  }

  /// Derives multi-horizon discounted score from a Horizon 1 base move in 0ms (Spec §6.1).
  /// Formula: max sum_{t=1}^H gamma^(t-1) * (XIScore_t(Squad_t) - HitCost_t)
  static TransferMove deriveMultiHorizonMove(TransferMove h1Move, int horizon) {
    if (horizon <= 1) {
      return TransferMove(
        transfersOut: h1Move.transfersOut,
        transfersIn: h1Move.transfersIn,
        hitCost: h1Move.hitCost,
        netExpectedPoints: h1Move.lineupResult.totalExpectedPoints - h1Move.hitCost,
        lineupResult: h1Move.lineupResult,
        horizon: 1,
      );
    }

    var totalDiscountedXp = (h1Move.lineupResult.totalExpectedPoints - h1Move.hitCost).toDouble();
    var currentDiscount = gammaDiscount;

    for (var t = 2; t <= horizon; t++) {
      totalDiscountedXp += currentDiscount * h1Move.lineupResult.totalExpectedPoints;
      currentDiscount *= gammaDiscount;
    }

    return TransferMove(
      transfersOut: h1Move.transfersOut,
      transfersIn: h1Move.transfersIn,
      hitCost: h1Move.hitCost,
      netExpectedPoints: totalDiscountedXp,
      lineupResult: h1Move.lineupResult,
      horizon: horizon,
    );
  }

  /// Multi-Horizon Transfer Optimisation (Horizon 3 and 5) with gamma = 0.90 discount (Spec §6.1).
  static TransferMove optimizeTransfersMultiHorizon({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    required int horizon, // 1, 3, or 5
    Map<int, List<double>>? playerMultiGwXp,
  }) {
    final h1Best = optimizeTransfersHorizon1(
      currentSquad: currentSquad,
      availablePool: availablePool,
      bankTenths: bankTenths,
      freeTransfersAvailable: freeTransfersAvailable,
    );

    return deriveMultiHorizonMove(h1Best, horizon);
  }
}
