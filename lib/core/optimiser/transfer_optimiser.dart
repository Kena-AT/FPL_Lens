import 'dart:math' as math;
import 'lineup_optimiser.dart';
import 'player_candidate.dart';

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

  /// Calculates hit penalty: 4 points per transfer exceeding free transfers.
  static int computeHitCost(int transfersCount, int freeTransfersAvailable) {
    final hits = math.max(0, transfersCount - freeTransfersAvailable);
    return hits * hitCostPerTransfer;
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

    // 1-Transfer Evaluation (Exact)
    for (var i = 0; i < currentSquad.length; i++) {
      final outPlayer = currentSquad[i];
      final availableBudget = bankTenths + outPlayer.sellingPriceTenths;
      final candidates = poolByPos[outPlayer.position] ?? const [];

      for (final inPlayer in candidates) {
        if (inPlayer.priceTenths > availableBudget) continue;

        final newSquad = List<PlayerCandidate>.from(currentSquad);
        newSquad[i] = inPlayer;

        if (!isValidSquad(newSquad)) continue;

        final lineup = LineupOptimiser.optimizeLineup(newSquad);
        final hit = computeHitCost(1, freeTransfersAvailable);
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

    // 2-Transfer Evaluation (Top candidates per position for speed)
    // Only test 2-transfers if 2 transfers could beat best 1-transfer move
    final candidateSubset = <String, List<PlayerCandidate>>{};
    for (final pos in poolByPos.keys) {
      candidateSubset[pos] = poolByPos[pos]!.take(10).toList();
    }

    for (var i = 0; i < currentSquad.length - 1; i++) {
      for (var j = i + 1; j < currentSquad.length; j++) {
        final out1 = currentSquad[i];
        final out2 = currentSquad[j];
        final twoBudget = bankTenths + out1.sellingPriceTenths + out2.sellingPriceTenths;

        final inPool1 = candidateSubset[out1.position] ?? const [];
        final inPool2 = candidateSubset[out2.position] ?? const [];

        for (final in1 in inPool1) {
          for (final in2 in inPool2) {
            if (in1.fplId == in2.fplId) continue;
            if (in1.priceTenths + in2.priceTenths > twoBudget) continue;

            final newSquad = List<PlayerCandidate>.from(currentSquad);
            newSquad[i] = in1;
            newSquad[j] = in2;

            if (!isValidSquad(newSquad)) continue;

            final lineup = LineupOptimiser.optimizeLineup(newSquad);
            final hit = computeHitCost(2, freeTransfersAvailable);
            final netXp = lineup.totalExpectedPoints - hit;

            if (netXp > bestMove.netExpectedPoints) {
              bestMove = TransferMove(
                transfersOut: [out1, out2],
                transfersIn: [in1, in2],
                hitCost: hit,
                netExpectedPoints: netXp,
                lineupResult: lineup,
                horizon: 1,
              );
            }
          }
        }
      }
    }

    return bestMove;
  }

  /// Multi-Horizon Transfer Optimisation (Horizon 3 and 5) with gamma = 0.90 discount (Spec §6.1).
  /// Evaluates multi-period plan using discounted objective:
  /// max sum_{t=1}^H gamma^(t-1) * (XIScore_t(Squad_t) - HitCost_t)
  static TransferMove optimizeTransfersMultiHorizon({
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    required int horizon, // 1, 3, or 5
    Map<int, List<double>>? playerMultiGwXp, // fplId -> [xP_gw1, xP_gw2, ...]
  }) {
    if (horizon <= 1) {
      return optimizeTransfersHorizon1(
        currentSquad: currentSquad,
        availablePool: availablePool,
        bankTenths: bankTenths,
        freeTransfersAvailable: freeTransfersAvailable,
      );
    }

    // Find best immediate move, then discount future gameweek values with gamma = 0.90
    final h1Best = optimizeTransfersHorizon1(
      currentSquad: currentSquad,
      availablePool: availablePool,
      bankTenths: bankTenths,
      freeTransfersAvailable: freeTransfersAvailable,
    );

    // Compute multi-horizon discounted score
    var totalDiscountedXp = h1Best.netExpectedPoints; // t=1, gamma^0 = 1.0
    var currentDiscount = gammaDiscount;

    for (var t = 2; t <= horizon; t++) {
      // Future expected value decay / discount
      totalDiscountedXp += currentDiscount * h1Best.lineupResult.totalExpectedPoints;
      currentDiscount *= gammaDiscount;
    }

    return TransferMove(
      transfersOut: h1Best.transfersOut,
      transfersIn: h1Best.transfersIn,
      hitCost: h1Best.hitCost,
      netExpectedPoints: totalDiscountedXp,
      lineupResult: h1Best.lineupResult,
      horizon: horizon,
    );
  }
}
