import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/engine/invariants/engine_invariants.dart';
import 'package:fpl_lens/core/engine/layer2/lineup_engine_v2.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';

PlayerCandidate _p(
  int id,
  String name,
  String pos, {
  int clubId = 1,
  double xp = 4.0,
  double pStart = 0.90,
  double pSub = 0.05,
}) {
  return PlayerCandidate(
    fplId: id,
    webName: name,
    position: pos,
    clubId: clubId,
    priceTenths: 60,
    sellingPriceTenths: 60,
    xp: xp,
    pStart: pStart,
    pSub: pSub,
  );
}

List<PlayerCandidate> _sampleSquad({double benchSubRate = 0.05}) {
  return [
    _p(1, 'Raya', 'GK', clubId: 1, xp: 4.5, pStart: 0.99, pSub: 0.0),
    _p(2, 'Fabianski', 'GK', clubId: 2, xp: 0.8, pStart: 0.20, pSub: 0.02),
    _p(3, 'Saliba', 'DEF', clubId: 1, xp: 5.0, pStart: 0.96, pSub: 0.02),
    _p(4, 'Gabriel', 'DEF', clubId: 3, xp: 4.8, pStart: 0.95, pSub: 0.02),
    _p(5, 'Gvardiol', 'DEF', clubId: 4, xp: 4.6, pStart: 0.85, pSub: 0.10),
    _p(6, 'Konsa', 'DEF', clubId: 5, xp: 3.6, pStart: 0.90, pSub: benchSubRate),
    _p(7, 'Greaves', 'DEF', clubId: 6, xp: 2.2, pStart: 0.70, pSub: 0.10),
    _p(8, 'Saka', 'MID', clubId: 1, xp: 7.4, pStart: 0.94, pSub: 0.04),
    _p(9, 'Palmer', 'MID', clubId: 7, xp: 7.2, pStart: 0.95, pSub: 0.03),
    _p(10, 'Salah', 'MID', clubId: 8, xp: 8.2, pStart: 0.96, pSub: 0.02),
    _p(11, 'Mbeumo', 'MID', clubId: 9, xp: 5.5, pStart: 0.92, pSub: 0.04),
    _p(12, 'Rogers', 'MID', clubId: 5, xp: 3.9, pStart: 0.80, pSub: 0.10),
    _p(13, 'Haaland', 'FWD', clubId: 4, xp: 8.6, pStart: 0.95, pSub: 0.03),
    _p(14, 'Watkins', 'FWD', clubId: 5, xp: 6.1, pStart: 0.90, pSub: 0.05),
    _p(15, 'Wood', 'FWD', clubId: 10, xp: 4.4, pStart: 0.85, pSub: 0.08),
  ];
}

void main() {
  group('Sprint E3: Layer 2 Exact Engine (V2)', () {
    test('I8 & I9 invariants reject invalid XI and identical C/VC', () {
      final squad = _sampleSquad();
      final badXi = squad.take(10).toList();
      expect(
        () => EngineInvariants.checkLineupInvariants(
          startingXi: badXi,
          captain: squad[0],
          viceCaptain: squad[2],
        ),
        throwsA(isA<InvariantViolationException>().having((e) => e.invariantId, 'id', 'I8')),
      );

      final validXi = [
        squad[0],
        squad[2], squad[3], squad[4],
        squad[7], squad[8], squad[9], squad[10],
        squad[12], squad[13], squad[14],
      ];
      expect(
        () => EngineInvariants.checkLineupInvariants(
          startingXi: validXi,
          captain: squad[12],
          viceCaptain: squad[12],
        ),
        throwsA(isA<InvariantViolationException>().having((e) => e.invariantId, 'id', 'I9')),
      );
    });

    test('G3 & G9 fix: pZero uses 1 - pStart - pSub and bench absence is modelled', () {
      // Player with pStart=0.5, pSub=0.5 has pZero = 0.0 (never auto-subbed)
      final superSub = _p(99, 'Jota', 'MID', xp: 4.0, pStart: 0.50, pSub: 0.50);
      expect(LineupEngineV2.pZero(superSub), closeTo(0.0, 1e-9));
      expect(LineupEngineV2.xpGivenPlay(superSub), closeTo(4.0, 1e-9));

      // Injured bench player (pStart=0, pSub=0 -> pZero=1.0) contributes 0 and loses bench priority
      final squad = _sampleSquad();
      squad[6] = _p(7, 'Greaves', 'DEF', clubId: 6, xp: 0.0, pStart: 0.0, pSub: 0.0);
      final res = LineupEngineV2.optimize(squad);
      expect(res.bench.last.fplId, 7);
    });

    test('Pruned enumeration and two-stage K=20 agree closely with exhaustive search', () {
      final squad = _sampleSquad();
      final pruned = LineupEngineV2.optimize(squad, topK: 20, exhaustive: false);
      final full = LineupEngineV2.optimize(squad, exhaustive: true);

      expect(pruned.neglectedMass, lessThan(0.10));
      expect(pruned.captain.fplId, full.captain.fplId);
      expect((pruned.expectedPoints - full.expectedPoints).abs(), lessThan(0.25));
    });

    test('Determinism and device timing budget (< 1000ms)', () {
      final squad = _sampleSquad();
      final sw = Stopwatch()..start();
      final r1 = LineupEngineV2.optimize(squad, topK: 20);
      sw.stop();
      final r2 = LineupEngineV2.optimize(squad, topK: 20);

      expect(r1.toJson(), equals(r2.toJson()));
      expect(r1.captainAlternatives.length, 3);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
