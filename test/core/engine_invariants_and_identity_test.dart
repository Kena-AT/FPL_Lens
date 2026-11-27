import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/engine/invariants/engine_invariants.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/optimiser/transfer_optimiser.dart';
import 'package:fpl_lens/core/rules/rules_table.dart';

PlayerCandidate _p(
  int id,
  String name,
  String pos, {
  int clubId = 1,
  int price = 50,
  int sell = 50,
  double xp = 4.0,
  double pStart = 0.9,
  double pSub = 0.05,
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

List<PlayerCandidate> _build15Squad() {
  return [
    _p(1, 'Raya', 'GK', clubId: 1, xp: 4.5),
    _p(2, 'Fabianski', 'GK', clubId: 2, xp: 2.0),
    _p(3, 'Saliba', 'DEF', clubId: 1, xp: 4.8),
    _p(4, 'Gabriel', 'DEF', clubId: 3, xp: 4.7),
    _p(5, 'Gvardiol', 'DEF', clubId: 4, xp: 4.6),
    _p(6, 'Konsa', 'DEF', clubId: 5, xp: 3.5),
    _p(7, 'Greaves', 'DEF', clubId: 6, xp: 2.5),
    _p(8, 'Saka', 'MID', clubId: 7, xp: 7.2),
    _p(9, 'Palmer', 'MID', clubId: 8, xp: 7.0),
    _p(10, 'Salah', 'MID', clubId: 9, xp: 8.0),
    _p(11, 'Mbeumo', 'MID', clubId: 10, xp: 5.5),
    _p(12, 'Rogers', 'MID', clubId: 5, xp: 3.8),
    _p(355, 'Haaland', 'FWD', clubId: 13, price: 156, sell: 154, xp: 7.8),
    _p(14, 'Watkins', 'FWD', clubId: 5, xp: 6.0),
    _p(15, 'Wood', 'FWD', clubId: 11, xp: 5.0),
  ];
}

void main() {
  group('Sprint E1: RulesTable & EngineInvariants', () {
    test('RulesTable exposes verified and VERIFY rules cleanly', () {
      expect(RulesTable.version, '2026-27.1');
      expect(RulesTable.getInt('squad_size'), 15);
      expect(RulesTable.getInt('max_players_per_club'), 3);
      expect(
        RulesTable.verifyLabelsFor(['gw19_deadline_from_api', 'squad_size']),
        ['gw19_deadline_from_api [VERIFY]'],
      );
      expect(() => RulesTable.getRule('unknown_key'), throwsArgumentError);
    });

    test('Haaland F1-F4 regression: conflicting duplicate fplId fails closed with I10', () {
      final squad = _build15Squad();
      final conflictingHaaland = _p(355, 'Haaland', 'FWD', clubId: 13, price: 152, sell: 152, xp: 9.2);
      final otherFwd = _p(900, 'Isak', 'FWD', clubId: 14, price: 85, sell: 85, xp: 6.5);

      expect(
        () => TransferOptimiser.optimizeTransfersHorizon1(
          currentSquad: squad,
          availablePool: [conflictingHaaland, otherFwd],
          bankTenths: 10,
          freeTransfersAvailable: 1,
        ),
        throwsA(
          isA<InvariantViolationException>().having((e) => e.invariantId, 'invariantId', 'I10'),
        ),
      );
    });

    test('Haaland F1-F4 regression: same player in pool is never recommended as Out -> In', () {
      final squad = _build15Squad();
      final sameHaaland = _p(355, 'Haaland', 'FWD', clubId: 13, price: 156, sell: 154, xp: 7.8);
      final weakerFwd = _p(901, 'Calvert-Lewin', 'FWD', clubId: 15, price: 60, sell: 60, xp: 4.0);

      final move = TransferOptimiser.optimizeTransfersHorizon1(
        currentSquad: squad,
        availablePool: [sameHaaland, weakerFwd],
        bankTenths: 20,
        freeTransfersAvailable: 1,
      );

      for (var i = 0; i < move.transfersOut.length; i++) {
        expect(move.transfersOut[i].fplId, isNot(equals(move.transfersIn[i].fplId)));
      }
      expect(move.transfersIn.any((p) => p.fplId == 355), isFalse);
    });

    test('checkSingleSwap enforces I1, I2, I3, I5, I6 and isSnapshotStale enforces I16', () {
      final squad = _build15Squad();
      final haaland = squad.firstWhere((p) => p.fplId == 355);
      final watkins = squad.firstWhere((p) => p.fplId == 14);
      final mid = _p(902, 'Gordon', 'MID', clubId: 14, price: 75, sell: 75, xp: 6.0);
      final fourthVillaFwd = _p(903, 'Duran', 'FWD', clubId: 5, price: 60, sell: 60, xp: 5.5);
      final tooExpensiveFwd = _p(904, 'Mbappe', 'FWD', clubId: 16, price: 170, sell: 170, xp: 10.0);

      expect(EngineInvariants.checkSingleSwap(outPlayer: haaland, inPlayer: haaland, currentSquad: squad, bankTenths: 50), 'I1');
      expect(EngineInvariants.checkSingleSwap(outPlayer: haaland, inPlayer: watkins, currentSquad: squad, bankTenths: 50), 'I2');
      expect(EngineInvariants.checkSingleSwap(outPlayer: haaland, inPlayer: mid, currentSquad: squad, bankTenths: 50), 'I3');
      // Club 5 already has Konsa, Rogers, Watkins (3 players)
      expect(EngineInvariants.checkSingleSwap(outPlayer: haaland, inPlayer: fourthVillaFwd, currentSquad: squad, bankTenths: 50), 'I5');
      // Haaland sell=154 + bank=10 = 164 < 170
      expect(EngineInvariants.checkSingleSwap(outPlayer: haaland, inPlayer: tooExpensiveFwd, currentSquad: squad, bankTenths: 10), 'I6');

      final now = DateTime.utc(2026, 11, 27, 12, 0);
      expect(EngineInvariants.isSnapshotStale(now.subtract(const Duration(minutes: 31)), now), isTrue);
      expect(EngineInvariants.isSnapshotStale(now.subtract(const Duration(minutes: 10)), now), isFalse);
    });
  });
}
