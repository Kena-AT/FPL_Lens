import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase - Squad Operations', () {
    test('replaceSquad and getAllSquadPlayers store and retrieve players ordered by positionOrder', () async {
      expect(await db.hasSquad(), isFalse);

      final now = DateTime.now();
      final p1 = SquadPlayersTableCompanion.insert(
        fplId: 355,
        webName: 'Haaland',
        position: 'FWD',
        teamId: 11,
        teamShortName: 'MCI',
        purchasePriceTenths: 140,
        sellingPriceTenths: 142,
        nowCostTenths: 144,
        status: 'available',
        positionOrder: 9,
        priceSource: 'FROM_TRANSFER',
        updatedAt: now,
      );

      final p2 = SquadPlayersTableCompanion.insert(
        fplId: 19,
        webName: 'Raya',
        position: 'GKP',
        teamId: 1,
        teamShortName: 'ARS',
        purchasePriceTenths: 55,
        sellingPriceTenths: 55,
        nowCostTenths: 56,
        status: 'available',
        positionOrder: 1,
        priceSource: 'CONFIRM',
        updatedAt: now,
      );

      await db.replaceSquad([p1, p2]);

      expect(await db.hasSquad(), isTrue);
      final players = await db.getAllSquadPlayers();
      expect(players.length, 2);
      // Ordered by positionOrder ascending: Raya (1), Haaland (9)
      expect(players.first.webName, 'Raya');
      expect(players.last.webName, 'Haaland');
    });

    test('watchSquadPlayers emits updates on changes', () async {
      final now = DateTime.now();
      final stream = db.watchSquadPlayers();

      final expectation = expectLater(
        stream,
        emits(hasLength(1)),
      );

      final p1 = SquadPlayersTableCompanion.insert(
        fplId: 355,
        webName: 'Haaland',
        position: 'FWD',
        teamId: 11,
        teamShortName: 'MCI',
        purchasePriceTenths: 140,
        sellingPriceTenths: 142,
        nowCostTenths: 144,
        status: 'available',
        positionOrder: 1,
        priceSource: 'FROM_TRANSFER',
        updatedAt: now,
      );

      await db.replaceSquad([p1]);
      await expectation;
    });
  });

  group('AppDatabase - Purchase Prices Operations', () {
    test('upsertPurchasePrice and unconfirmed count tracking', () async {
      expect(await db.getUnconfirmedPricesCount(), 0);

      await db.upsertPurchasePrice(
        playerFplId: 101,
        purchasePriceTenths: 85,
        source: 'CONFIRM',
        isConfirmed: false,
      );

      await db.upsertPurchasePrice(
        playerFplId: 102,
        purchasePriceTenths: 60,
        source: 'FROM_TRANSFER',
        isConfirmed: true,
      );

      expect(await db.getUnconfirmedPricesCount(), 1);

      // Confirm player 101
      await db.upsertPurchasePrice(
        playerFplId: 101,
        purchasePriceTenths: 87,
        source: 'CONFIRMED_USER',
        isConfirmed: true,
      );

      expect(await db.getUnconfirmedPricesCount(), 0);
    });
  });

  group('AppDatabase - History Operations', () {
    test('replaceGameweekHistory and getGameweekHistory returns newest gameweeks first', () async {
      final gw1 = GameweekHistoryTableCompanion.insert(
        gameweek: const Value(1),
        points: 65,
        totalPoints: 65,
        overallRank: 500000,
        eventTransfers: 0,
        eventTransfersCost: 0,
        pointsOnBench: 4,
        bankTenths: 15,
        valueTenths: 1000,
      );

      final gw2 = GameweekHistoryTableCompanion.insert(
        gameweek: const Value(2),
        points: 72,
        totalPoints: 137,
        overallRank: 350000,
        eventTransfers: 1,
        eventTransfersCost: 0,
        pointsOnBench: 2,
        bankTenths: 10,
        valueTenths: 1005,
      );

      await db.replaceGameweekHistory([gw1, gw2]);

      final history = await db.getGameweekHistory();
      expect(history.length, 2);
      expect(history.first.gameweek, 2);
      expect(history.last.gameweek, 1);
    });

    test('replaceTransferHistory and getTransferHistory returns transfers', () async {
      final now = DateTime.now();
      final t1 = TransferHistoryTableCompanion.insert(
        elementInFplId: 201,
        elementInCostTenths: 75,
        elementInName: 'Palmer',
        elementOutFplId: 301,
        elementOutCostTenths: 70,
        elementOutName: 'Foden',
        gameweek: 3,
        transferTime: now,
      );

      await db.replaceTransferHistory([t1]);

      final transfers = await db.getTransferHistory();
      expect(transfers.length, 1);
      expect(transfers.first.elementInName, 'Palmer');
      expect(transfers.first.elementOutName, 'Foden');
    });
  });

  group('AppDatabase - Lineup Results', () {
    test('insertLineupResult retains maximum 20 latest results', () async {
      final baseTime = DateTime(2026, 10, 18, 10, 0);

      for (int i = 1; i <= 25; i++) {
        await db.insertLineupResult(
          LineupResultsTableCompanion.insert(
            gameweek: i,
            starting11FplIds: '1,2,3,4,5,6,7,8,9,10,11',
            benchFplIds: '12,13,14,15',
            captainFplId: 9,
            viceCaptainFplId: 10,
            projectedTotalPoints: 60.5 + i,
            modelVersion: 'v1.4',
            projectionRunId: 'run-$i',
            computedAt: baseTime.add(Duration(minutes: i)),
          ),
        );
      }

      final allResults = await db.select(db.lineupResultsTable).get();
      expect(allResults.length, 20);

      final latest = await db.getLatestLineupResult();
      expect(latest, isNotNull);
      expect(latest!.gameweek, 25);
    });
  });

  group('AppDatabase - User Preferences & Clear All', () {
    test('setPreference and getPreference stores key-value pairs', () async {
      await db.setPreference('analytics_opt_out', 'true');
      expect(await db.getPreference('analytics_opt_out'), 'true');
      expect(await db.getPreference('non_existent'), isNull);
    });

    test('clearAllUserData clears all tables on sign-out', () async {
      await db.setPreference('test_key', 'val');
      await db.upsertPurchasePrice(
        playerFplId: 1,
        purchasePriceTenths: 50,
        source: 'CONFIRM',
        isConfirmed: false,
      );

      await db.clearAllUserData();

      expect(await db.getPreference('test_key'), isNull);
      expect(await db.getUnconfirmedPricesCount(), 0);
      expect(await db.hasSquad(), isFalse);
    });
  });
}
