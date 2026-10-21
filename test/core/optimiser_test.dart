import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/optimiser/formation_validator.dart';
import 'package:fpl_lens/core/optimiser/lineup_optimiser.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/optimiser/transfer_optimiser.dart';

void main() {
  group('Architectural constraints', () {
    test('core/optimiser files must have zero Flutter or I/O imports', () {
      final dir = Directory('lib/core/optimiser');
      expect(dir.existsSync(), isTrue);

      final files = dir.listSync(recursive: true).whereType<File>();
      expect(files, isNotEmpty);

      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        expect(
          content.contains('package:flutter'),
          isFalse,
          reason: '${file.path} must not import package:flutter',
        );
        expect(
          content.contains("import 'dart:io'"),
          isFalse,
          reason: '${file.path} must not import dart:io',
        );
        expect(
          content.contains('import "dart:io"'),
          isFalse,
          reason: '${file.path} must not import dart:io',
        );
      }
    });
  });

  group('FormationValidator (Spec §5.2)', () {
    test('accepts all 8 legal formations', () {
      const legal = [
        [1, 3, 5, 2],
        [1, 3, 4, 3],
        [1, 4, 4, 2],
        [1, 4, 3, 3],
        [1, 4, 5, 1],
        [1, 5, 3, 2],
        [1, 5, 2, 3],
        [1, 5, 4, 1],
      ];

      for (final f in legal) {
        expect(
          FormationValidator.isValidCounts(f[0], f[1], f[2], f[3]),
          isTrue,
          reason: 'Formation 1-${f[1]}-${f[2]}-${f[3]} must be valid',
        );
      }
    });

    test('rejects illegal formations', () {
      const illegal = [
        [1, 2, 5, 3], // Only 2 defenders (min is 3)
        [1, 6, 3, 1], // 6 defenders (max is 5)
        [1, 4, 6, 0], // 0 forwards (min is 1)
        [2, 4, 4, 1], // 2 goalkeepers
        [1, 4, 4, 3], // 12 players
        [1, 3, 3, 3], // 10 players
      ];

      for (final f in illegal) {
        expect(
          FormationValidator.isValidCounts(f[0], f[1], f[2], f[3]),
          isFalse,
          reason: 'Formation 1-${f[1]}-${f[2]}-${f[3]} must be illegal',
        );
      }
    });
  });

  group('LineupOptimiser and Auto-Subs (Spec §5.1, §5.2, §5.3)', () {
    List<PlayerCandidate> makeStandardSquad() {
      return [
        const PlayerCandidate(fplId: 1, webName: 'Raya', position: 'GK', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 4.8, pStart: 0.98, pSub: 0.05),
        const PlayerCandidate(fplId: 2, webName: 'Turner', position: 'GK', clubId: 2, priceTenths: 40, sellingPriceTenths: 40, xp: 1.2, pStart: 0.05, pSub: 0.05),
        const PlayerCandidate(fplId: 3, webName: 'Gabriel', position: 'DEF', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 5.0, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 4, webName: 'Saliba', position: 'DEF', clubId: 1, priceTenths: 60, sellingPriceTenths: 60, xp: 4.9, pStart: 0.96, pSub: 0.05),
        const PlayerCandidate(fplId: 5, webName: 'Alexander-Arnold', position: 'DEF', clubId: 3, priceTenths: 70, sellingPriceTenths: 70, xp: 6.2, pStart: 0.92, pSub: 0.05),
        const PlayerCandidate(fplId: 6, webName: 'Gvardiol', position: 'DEF', clubId: 4, priceTenths: 60, sellingPriceTenths: 60, xp: 5.1, pStart: 0.88, pSub: 0.05),
        const PlayerCandidate(fplId: 7, webName: 'Burn', position: 'DEF', clubId: 5, priceTenths: 45, sellingPriceTenths: 45, xp: 3.5, pStart: 0.90, pSub: 0.05),
        const PlayerCandidate(fplId: 8, webName: 'Salah', position: 'MID', clubId: 3, priceTenths: 125, sellingPriceTenths: 125, xp: 8.5, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 9, webName: 'Saka', position: 'MID', clubId: 1, priceTenths: 100, sellingPriceTenths: 100, xp: 7.8, pStart: 0.94, pSub: 0.05),
        const PlayerCandidate(fplId: 10, webName: 'Palmer', position: 'MID', clubId: 6, priceTenths: 105, sellingPriceTenths: 105, xp: 8.0, pStart: 0.92, pSub: 0.05),
        const PlayerCandidate(fplId: 11, webName: 'Gordon', position: 'MID', clubId: 5, priceTenths: 75, sellingPriceTenths: 75, xp: 5.5, pStart: 0.89, pSub: 0.05),
        const PlayerCandidate(fplId: 12, webName: 'Rogers', position: 'MID', clubId: 7, priceTenths: 50, sellingPriceTenths: 50, xp: 4.5, pStart: 0.85, pSub: 0.10),
        const PlayerCandidate(fplId: 13, webName: 'Haaland', position: 'FWD', clubId: 4, priceTenths: 150, sellingPriceTenths: 150, xp: 9.0, pStart: 0.95, pSub: 0.05),
        const PlayerCandidate(fplId: 14, webName: 'Watkins', position: 'FWD', clubId: 7, priceTenths: 90, sellingPriceTenths: 90, xp: 6.8, pStart: 0.90, pSub: 0.05),
        const PlayerCandidate(fplId: 15, webName: 'Wood', position: 'FWD', clubId: 2, priceTenths: 60, sellingPriceTenths: 60, xp: 5.2, pStart: 0.82, pSub: 0.15),
      ];
    }

    test('enumerates exactly 550 valid starting XIs for standard squad', () {
      final squad = makeStandardSquad();
      final validXis = LineupOptimiser.enumerateValidXis(squad);
      expect(validXis.length, equals(550));
      for (final xi in validXis) {
        expect(LineupOptimiser.isValidXi(xi), isTrue);
      }
    });

    test('joint captaincy evaluates all 110 pairs and assigns distinct C and V', () {
      final squad = makeStandardSquad();
      final xi = LineupOptimiser.enumerateValidXis(squad).first;
      final (c, v, pairScore) = LineupOptimiser.evaluateCaptainPair(xi);

      expect(c.fplId, isNot(equals(v.fplId)));
      expect(pairScore, greaterThan(xi.fold<double>(0.0, (acc, p) => acc + p.xp)));
    });

    test('auto-subs replaces absent goalkeeper with backup goalkeeper', () {
      final squad = makeStandardSquad();
      final startingXi = squad.where((p) => p.fplId != 2 && p.fplId != 7 && p.fplId != 12 && p.fplId != 15).toList();
      final bench = [
        squad.firstWhere((p) => p.fplId == 2),
        squad.firstWhere((p) => p.fplId == 7),
        squad.firstWhere((p) => p.fplId == 12),
        squad.firstWhere((p) => p.fplId == 15),
      ];

      // Absent Raya (id 1)
      final finalXi = LineupOptimiser.applyFplAutoSubs(startingXi, bench, {1});
      expect(finalXi.any((p) => p.webName == 'Turner'), isTrue);
      expect(finalXi.any((p) => p.webName == 'Raya'), isFalse);
      expect(LineupOptimiser.isValidXi(finalXi), isTrue);
    });

    test('bench search produces exact bench order over 2048 states', () {
      final squad = makeStandardSquad();
      final startingXi = LineupOptimiser.enumerateValidXis(squad).first;
      final bench = squad.where((p) => !startingXi.contains(p)).toList();
      final benchGk = bench.firstWhere((p) => p.position == 'GK');
      final benchOutfield = bench.where((p) => p.position != 'GK').toList();

      final (order, score) = LineupOptimiser.evaluateBenchOrders(
        startingXi: startingXi,
        benchGk: benchGk,
        benchOutfield: benchOutfield,
        useSubstituteConditionalPoints: true,
      );

      expect(order.length, equals(4));
      expect(order.first.position, equals('GK'));
      expect(score, greaterThan(0.0));
    });
  });

  group('Golden Cases Assertion (Pure Dart vs Python Oracle)', () {
    test('all 25 golden cases match Python reference optimiser identically', () {
      final fixtureFile = File('test/fixtures/optimiser_golden_cases.json');
      expect(fixtureFile.existsSync(), isTrue, reason: 'Golden fixture file must exist');

      final jsonString = fixtureFile.readAsStringSync();
      final List<dynamic> cases = jsonDecode(jsonString);
      expect(cases.length, greaterThanOrEqualTo(20));

      for (final caseData in cases) {
        final caseId = caseData['case_id'] as int;
        final isFallback = caseData['is_quick_mode_fallback'] as bool;
        final squadJson = caseData['squad'] as List<dynamic>;
        final squad = squadJson.map((j) => PlayerCandidate.fromJson(j)).toList();

        final result = LineupOptimiser.optimizeLineup(
          squad,
          forceFallback: isFallback,
        );

        final expectedXiIds = (caseData['expected_starting_xi_ids'] as List<dynamic>).cast<int>();
        final actualXiIds = result.startingXi.map((p) => p.fplId).toList()..sort();
        expect(actualXiIds, equals(expectedXiIds), reason: 'Case $caseId XI mismatch');

        final expectedCaptainId = caseData['expected_captain_id'] as int;
        expect(result.captain.fplId, equals(expectedCaptainId), reason: 'Case $caseId Captain mismatch');

        final expectedViceCaptainId = caseData['expected_vice_captain_id'] as int;
        expect(result.viceCaptain.fplId, equals(expectedViceCaptainId), reason: 'Case $caseId VC mismatch');

        final expectedBenchIds = (caseData['expected_bench_ids'] as List<dynamic>).cast<int>();
        final actualBenchIds = result.bench.map((p) => p.fplId).toList();
        expect(actualBenchIds, equals(expectedBenchIds), reason: 'Case $caseId Bench mismatch');

        final expectedTotalXp = (caseData['expected_total_xp'] as num).toDouble();
        expect(result.totalExpectedPoints, closeTo(expectedTotalXp, 1e-2), reason: 'Case $caseId total xP mismatch');
      }
    });
  });

  group('TransferOptimiser (Spec §6)', () {
    test('selling price math: 50% profit rounded down to 0.1m, no loss on sale', () {
      // Current 6.5m, bought at 6.0m -> profit 0.5m -> sell 6.2m (62 tenths)
      expect(TransferOptimiser.computeSellingPriceTenths(65, 60), equals(62));

      // Current 6.6m, bought at 6.0m -> profit 0.6m -> sell 6.3m (63 tenths)
      expect(TransferOptimiser.computeSellingPriceTenths(66, 60), equals(63));

      // Current 5.8m, bought at 6.0m -> loss -> sell 5.8m (58 tenths)
      expect(TransferOptimiser.computeSellingPriceTenths(58, 60), equals(58));

      // Current 6.0m, bought at 6.0m -> sell 6.0m (60 tenths)
      expect(TransferOptimiser.computeSellingPriceTenths(60, 60), equals(60));
    });

    test('hit cost calculation: 4 points per transfer exceeding free allowance', () {
      expect(TransferOptimiser.computeHitCost(1, 1), equals(0));
      expect(TransferOptimiser.computeHitCost(0, 1), equals(0));
      expect(TransferOptimiser.computeHitCost(2, 1), equals(4));
      expect(TransferOptimiser.computeHitCost(3, 1), equals(8));
      expect(TransferOptimiser.computeHitCost(3, 2), equals(4));
    });

    test('squad validation enforces 15 players and max 3 per club', () {
      final squad = [
        const PlayerCandidate(fplId: 1, webName: 'P1', position: 'GK', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 2, webName: 'P2', position: 'GK', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 3, webName: 'P3', position: 'DEF', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 4, webName: 'P4', position: 'DEF', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 5, webName: 'P5', position: 'DEF', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05), // 4 from club 1!
        const PlayerCandidate(fplId: 6, webName: 'P6', position: 'DEF', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 7, webName: 'P7', position: 'DEF', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 8, webName: 'P8', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 9, webName: 'P9', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 10, webName: 'P10', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 11, webName: 'P11', position: 'MID', clubId: 4, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 12, webName: 'P12', position: 'MID', clubId: 4, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 13, webName: 'P13', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 14, webName: 'P14', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 15, webName: 'P15', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
      ];

      // Club 1 has 4 players -> invalid
      expect(TransferOptimiser.isValidSquad(squad), isFalse);
    });

    test('multi-horizon optimization applies gamma discount of 0.90', () {
      final squad = [
        const PlayerCandidate(fplId: 1, webName: 'P1', position: 'GK', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 2, webName: 'P2', position: 'GK', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 3, webName: 'P3', position: 'DEF', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 4, webName: 'P4', position: 'DEF', clubId: 1, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 5, webName: 'P5', position: 'DEF', clubId: 6, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 6, webName: 'P6', position: 'DEF', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 7, webName: 'P7', position: 'DEF', clubId: 2, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 8, webName: 'P8', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 9, webName: 'P9', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 10, webName: 'P10', position: 'MID', clubId: 3, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 11, webName: 'P11', position: 'MID', clubId: 4, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 12, webName: 'P12', position: 'MID', clubId: 4, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 13, webName: 'P13', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 14, webName: 'P14', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
        const PlayerCandidate(fplId: 15, webName: 'P15', position: 'FWD', clubId: 5, priceTenths: 50, sellingPriceTenths: 50, xp: 4.0, pStart: 0.9, pSub: 0.05),
      ];

      final h1 = TransferOptimiser.optimizeTransfersMultiHorizon(
        currentSquad: squad,
        availablePool: const [],
        bankTenths: 10,
        freeTransfersAvailable: 1,
        horizon: 1,
      );

      final h3 = TransferOptimiser.optimizeTransfersMultiHorizon(
        currentSquad: squad,
        availablePool: const [],
        bankTenths: 10,
        freeTransfersAvailable: 1,
        horizon: 3,
      );

      expect(h3.horizon, equals(3));
      // For horizon 3: score = h1 + 0.9 * h1 + 0.9^2 * h1 = (1 + 0.9 + 0.81) * h1 = 2.71 * h1
      expect(h3.netExpectedPoints, closeTo(h1.netExpectedPoints * (1.0 + 0.90 + 0.81), 0.5));
    });

    group('Free Transfer Banking and Hit Rules (Spec §6.2)', () {
      test('bank accumulation caps at 5 free transfers', () {
        // avail_t = min(5, bank_{t-1} + 1)
        expect(TransferOptimiser.computeAvailableFreeTransfers(0), equals(1));
        expect(TransferOptimiser.computeAvailableFreeTransfers(1), equals(2));
        expect(TransferOptimiser.computeAvailableFreeTransfers(2), equals(3));
        expect(TransferOptimiser.computeAvailableFreeTransfers(3), equals(4));
        expect(TransferOptimiser.computeAvailableFreeTransfers(4), equals(5));
        expect(TransferOptimiser.computeAvailableFreeTransfers(5), equals(5));
        expect(TransferOptimiser.computeAvailableFreeTransfers(10), equals(5));
      });

      test('hit calculation matches worked examples across scenarios', () {
        // Scenario 1: 1 transfer with 1 FT -> 0 hits
        expect(TransferOptimiser.computeHitCost(1, 1), equals(0));

        // Scenario 2: 2 transfers with 1 FT -> 1 hit = 4 points
        expect(TransferOptimiser.computeHitCost(2, 1), equals(4));

        // Scenario 3: 4 transfers with 2 FT -> 2 hits = 8 points
        expect(TransferOptimiser.computeHitCost(4, 2), equals(8));

        // Scenario 4: 5 transfers with 1 FT -> 4 hits = 16 points
        expect(TransferOptimiser.computeHitCost(5, 1), equals(16));

        // Scenario 5: Wildcard or Free Hit active -> 0 hit penalty
        expect(TransferOptimiser.computeHitCost(5, 1, isChipActive: true), equals(0));
      });

      test('bank state transition timeline with transfers and chips', () {
        // GW8: Start with 0 banked -> receive 1 FT -> make 0 transfers -> bank 1
        var bank = TransferOptimiser.computeBankAfterTransfers(
          previousBankedTransfers: 0,
          transfersMade: 0,
        );
        expect(bank, equals(1));

        // GW9: Have 1 banked -> avail is 2 -> make 2 transfers -> bank 0
        bank = TransferOptimiser.computeBankAfterTransfers(
          previousBankedTransfers: bank,
          transfersMade: 2,
        );
        expect(bank, equals(0));

        // GW10: Have 0 banked -> avail is 1 -> make 0 transfers -> bank 1
        bank = TransferOptimiser.computeBankAfterTransfers(
          previousBankedTransfers: bank,
          transfersMade: 0,
        );
        expect(bank, equals(1));

        // GW11: Chip gameweek (Wildcard) -> bank carried unchanged across chip gameweek
        bank = TransferOptimiser.computeBankAfterTransfers(
          previousBankedTransfers: bank,
          transfersMade: 10,
          isChipActive: true,
        );
        expect(bank, equals(1));

        // GW12: Bank 1 + 1 = 2 FT available -> 3 transfers made -> bank 0 (1 hit incurred)
        bank = TransferOptimiser.computeBankAfterTransfers(
          previousBankedTransfers: bank,
          transfersMade: 3,
        );
        expect(bank, equals(0));
      });
    });
  });
}
