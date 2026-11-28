import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/engine/invariants/engine_invariants.dart';
import 'package:fpl_lens/core/engine/layer2/lineup_engine_v2.dart';
import 'package:fpl_lens/core/engine/layer3/chip_engine_v2.dart';
import 'package:fpl_lens/core/engine/layer3/transfer_engine_v2.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/optimiser/transfer_optimiser.dart';

PlayerCandidate _make(int id, String pos, int clubId, int price, double xp, double pStart) {
  return PlayerCandidate(
    fplId: id,
    webName: 'P$id',
    position: pos,
    clubId: clubId,
    priceTenths: price,
    sellingPriceTenths: price,
    xp: xp,
    pStart: pStart,
    pSub: 0.02,
  );
}

void main() {
  test('G-Inv: Invariants I1-I16 hold across 20 deterministic gameweek snapshots', () {
    for (var gw = 1; gw <= 20; gw++) {
      final squad = [
        _make(1, 'GK', 1, 50, 4.2 + (gw % 3) * 0.2, 0.96),
        _make(2, 'GK', 2, 40, 1.2, 0.25),
        _make(3, 'DEF', 1, 55, 4.6, 0.95),
        _make(4, 'DEF', 3, 55, 4.4, 0.95),
        _make(5, 'DEF', 4, 50, 4.2, 0.92),
        _make(6, 'DEF', 5, 45, 3.3, 0.88),
        _make(7, 'DEF', 6, 40, 2.1, 0.70),
        _make(8, 'MID', 1, 90, 7.2 + (gw % 4) * 0.3, 0.95),
        _make(9, 'MID', 7, 85, 6.8, 0.94),
        _make(10, 'MID', 8, 120, 8.1, 0.96),
        _make(11, 'MID', 9, 70, 5.4, 0.92),
        _make(12, 'MID', 5, 50, 3.6, 0.85),
        _make(13, 'FWD', 4, 150, 8.5, 0.96),
        _make(14, 'FWD', 5, 85, 6.0, 0.92),
        _make(15, 'FWD', 10, 60, 2.2, 0.80),
      ];
      final pool = [
        _make(501, 'FWD', 11, 70, 7.8 + (gw % 2) * 0.4, 0.95),
        _make(502, 'MID', 12, 65, 6.9, 0.92),
      ];

      final lineup = LineupEngineV2.optimize(squad);
      EngineInvariants.checkLineupInvariants(
        startingXi: lineup.startingXi,
        captain: lineup.captain,
        viceCaptain: lineup.viceCaptain,
      );

      final rec = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 15,
        freeTransfersAvailable: (gw % 2) + 1,
        allowDoubleSwaps: false,
      );
      if (!rec.isHold) {
        EngineInvariants.checkHitInvariant(
          transfersCount: rec.transferCount,
          freeTransfersAvailable: (gw % 2) + 1,
          hitCost: rec.hitCost,
        );
        for (var i = 0; i < rec.transferCount; i++) {
          expect(rec.transfersOut[i].fplId, isNot(rec.transfersIn[i].fplId));
        }
      }

      final chips = ChipEngineV2.evaluateAll(
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 15,
        currentGameweek: gw,
        availableChips: {FplChip.tripleCaptain, FplChip.benchBoost, FplChip.freeHit},
      );
      expect(chips.length, 3);
    }
  });
}
