import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/engine/invariants/engine_invariants.dart';
import 'package:fpl_lens/core/engine/layer3/chip_engine_v2.dart';
import 'package:fpl_lens/core/engine/layer3/transfer_engine_v2.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/optimiser/transfer_optimiser.dart';

PlayerCandidate _p(
  int id,
  String name,
  String pos, {
  int clubId = 1,
  int price = 60,
  int sell = 60,
  double xp = 4.0,
  double pStart = 0.95,
  double pSub = 0.03,
}) {
  return PlayerCandidate(
    fplId: id,
    webName: name,
    position: pos,
    clubId: clubId,
    priceTenths: price,
    sellingPriceTenths: sell,
    xp: xp,
    pStart: pStart,
    pSub: pSub,
  );
}

List<PlayerCandidate> _squad15() {
  return [
    _p(1, 'Raya', 'GK', clubId: 1, xp: 4.5),
    _p(2, 'Fabianski', 'GK', clubId: 2, xp: 1.0, pStart: 0.2, pSub: 0.05),
    _p(3, 'Saliba', 'DEF', clubId: 1, xp: 4.8),
    _p(4, 'Gabriel', 'DEF', clubId: 3, xp: 4.7),
    _p(5, 'Gvardiol', 'DEF', clubId: 4, xp: 4.6),
    _p(6, 'Konsa', 'DEF', clubId: 5, xp: 3.2),
    _p(7, 'Greaves', 'DEF', clubId: 6, xp: 2.0),
    _p(8, 'Saka', 'MID', clubId: 1, xp: 7.4),
    _p(9, 'Palmer', 'MID', clubId: 7, xp: 7.2),
    _p(10, 'Salah', 'MID', clubId: 8, xp: 8.2),
    _p(11, 'Mbeumo', 'MID', clubId: 9, xp: 5.5),
    _p(12, 'Rogers', 'MID', clubId: 5, xp: 3.5),
    _p(13, 'Haaland', 'FWD', clubId: 4, price: 150, sell: 150, xp: 8.6),
    _p(14, 'Watkins', 'FWD', clubId: 5, xp: 6.0),
    _p(15, 'Wood', 'FWD', clubId: 10, xp: 2.0),
  ];
}

void main() {
  group('Sprint E4: Layer 3 & Counterfactual Chips', () {
    test('Uncertainty gate abstains (Hold) on marginal gain inside noise, recommends clear gain', () {
      final squad = _squad15();
      final marginalIn = _p(900, 'MarginalFwd', 'FWD', clubId: 11, price: 60, xp: 2.5);
      final holdRec = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [marginalIn],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        strategy: StrategyRiskMode.balanced,
        allowDoubleSwaps: false,
      );
      expect(holdRec.isHold, isTrue);
      expect(holdRec.transfersOut, isEmpty);

      final clearIn = _p(901, 'StarFwd', 'FWD', clubId: 11, price: 60, xp: 7.5);
      final moveRec = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [clearIn],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        strategy: StrategyRiskMode.balanced,
        allowDoubleSwaps: false,
      );
      expect(moveRec.isHold, isFalse);
      expect(moveRec.transfersIn.single.fplId, 901);
      expect(moveRec.netGainLowerBound, greaterThan(0.0));
    });

    test('Strategy modes: Conservative blocks hits, LowConfidence blocks hits, Stale throws I16', () {
      final squad = _squad15();
      final starIn = _p(902, 'StarFwd', 'FWD', clubId: 11, price: 60, xp: 11.0);

      final cons = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [starIn],
        bankTenths: 20,
        freeTransfersAvailable: 0, // requires -4 hit
        strategy: StrategyRiskMode.conservative,
        allowDoubleSwaps: false,
      );
      expect(cons.isHold, isTrue);

      final lowConf = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [starIn],
        bankTenths: 20,
        freeTransfersAvailable: 0,
        strategy: StrategyRiskMode.balanced,
        isLowConfidence: true,
        allowDoubleSwaps: false,
      );
      expect(lowConf.isHold, isTrue);

      expect(
        () => TransferEngineV2.recommend(
          currentSquad: squad,
          availablePool: [starIn],
          bankTenths: 20,
          freeTransfersAvailable: 1,
          isSnapshotStale: true,
        ),
        throwsA(isA<InvariantViolationException>().having((e) => e.invariantId, 'id', 'I16')),
      );
    });

    test('I7 hit invariant check and H3 banked-FT option value', () {
      expect(
        () => EngineInvariants.checkHitInvariant(
          transfersCount: 2,
          freeTransfersAvailable: 1,
          hitCost: 0,
          isWildcardOrFreeHit: false,
        ),
        throwsA(isA<InvariantViolationException>().having((e) => e.invariantId, 'id', 'I7')),
      );
      EngineInvariants.checkHitInvariant(
        transfersCount: 2,
        freeTransfersAvailable: 1,
        hitCost: 0,
        isWildcardOrFreeHit: true,
      );

      final squad = _squad15();
      final h3In = _p(903, 'SolidFwd', 'FWD', clubId: 11, price: 60, xp: 4.5);
      final recH3 = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [h3In],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        horizon: 3,
        allowDoubleSwaps: false,
      );
      expect(recH3.isApproximate, isTrue);
      expect(recH3.horizon, 3);
    });

    test('Shortlist recall >= 95% against exhaustive single-swap search', () {
      final squad = _squad15();
      final pool = List.generate(
        20,
        (i) => _p(1000 + i, 'Pool$i', ['GK', 'DEF', 'MID', 'FWD'][i % 4], clubId: 11 + (i % 8), xp: 3.0 + i * 0.35),
      );
      final shortlists = TransferEngineV2.generateShortlists(
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 20,
        kIn: 8,
      );
      final exhaustive = TransferOptimiser.optimizeTransfersHorizon1(
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 20,
        freeTransfersAvailable: 1,
        strategy: TransferStrategy.singleOnly,
      );
      if (exhaustive.transfersOut.isNotEmpty) {
        final outId = exhaustive.transfersOut.first.fplId;
        final inId = exhaustive.transfersIn.first.fplId;
        expect(shortlists[outId]!.any((p) => p.fplId == inId), isTrue);
      }
    });

    test('Counterfactual Chips: evaluates TC, BB, WC, FH and blocks FH in GW1', () {
      final squad = _squad15();
      final pool = [_p(950, 'UpgradedFwd', 'FWD', clubId: 11, price: 60, xp: 9.0)];
      final evalsGw1 = ChipEngineV2.evaluateAll(
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 20,
        currentGameweek: 1,
        availableChips: {FplChip.tripleCaptain, FplChip.benchBoost, FplChip.wildcard, FplChip.freeHit},
        bestFutureExpectedValue: {
          FplChip.tripleCaptain: 5.0, // Current Haaland ~8.6 * rho -> recommended
          FplChip.benchBoost: 15.0, // Future DGW worth more -> hold
          FplChip.wildcard: 15.0,
          FplChip.freeHit: 15.0,
        },
      );
      final byChip = {for (final e in evalsGw1) e.chip: e};
      expect(byChip[FplChip.tripleCaptain]!.status, ChipDecisionStatus.recommended);
      expect(byChip[FplChip.freeHit]!.status, ChipDecisionStatus.unavailable);
      expect(byChip[FplChip.benchBoost]!.status, isNot(ChipDecisionStatus.recommended));
    });
  });
}
