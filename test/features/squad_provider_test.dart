import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockFplRepository extends Mock implements FplRepository {}
class MockSecureStore extends Mock implements SecureStore {}

void main() {
  late MockFplRepository mockFplRepo;
  late MockSecureStore mockSecureStore;
  late AppDatabase db;
  late SquadNotifier notifier;

  setUp(() {
    mockFplRepo = MockFplRepository();
    mockSecureStore = MockSecureStore();
    db = AppDatabase(NativeDatabase.memory());

    when(() => mockSecureStore.getFplTeamId()).thenAnswer((_) async => 12345);
    when(() => mockSecureStore.saveFplTeamId(any())).thenAnswer((_) async {});

    notifier = SquadNotifier(
      fplRepo: mockFplRepo,
      db: db,
      secureStore: mockSecureStore,
    );
  });

  tearDown(() async {
    notifier.dispose();
    await db.close();
  });

  final dummyEntry = const EntryModel(
    id: 12345,
    name: 'Kena FC',
    playerFirstName: 'Kena',
    playerLastName: 'At',
    summaryOverallPoints: 500,
    summaryOverallRank: 100000,
  );

  final dummyGw = const CurrentGameweekResponse(
    current: GameweekMetadata(id: 7, name: 'Gameweek 7', isCurrent: true),
    next: GameweekMetadata(id: 8, name: 'Gameweek 8', isNext: true),
  );

  final dummySquad = const SquadPicksResponse(
    picks: [
      PickModel(element: 101, position: 1, multiplier: 1, isCaptain: false, isViceCaptain: false),
      PickModel(element: 202, position: 2, multiplier: 2, isCaptain: true, isViceCaptain: false),
    ],
    entryHistory: {
      'bank': 15,
      'value': 1020,
    },
  );

  final dummyTransfers = [
    TransferItemModel(
      elementIn: 101,
      elementInCost: 75,
      elementOut: 303,
      elementOutCost: 70,
      event: 2,
      time: DateTime(2026, 9, 1),
    ),
  ];

  final dummyHistory = const HistoryResponse(
    current: [
      GameweekHistoryItemModel(
        event: 1,
        points: 60,
        totalPoints: 60,
        overallRank: 50000,
        eventTransfers: 0,
        eventTransfersCost: 0,
        pointsOnBench: 4,
        bank: 10,
        value: 1000,
      ),
    ],
  );

  group('SquadNotifier - 4-step sequence execution (Spec P6)', () {
    test('successful 4-step sequence loads entry, picks, transfers, history into Drift', () async {
      when(() => mockFplRepo.getEntry(12345)).thenAnswer((_) async => dummyEntry);
      when(() => mockFplRepo.getCurrentGameweek()).thenAnswer((_) async => dummyGw);
      when(() => mockFplRepo.getSquad(12345, gw: 7)).thenAnswer((_) async => dummySquad);
      when(() => mockFplRepo.getTransfers(12345)).thenAnswer((_) async => dummyTransfers);
      when(() => mockFplRepo.getHistory(12345)).thenAnswer((_) async => dummyHistory);
      when(() => mockFplRepo.searchPlayers('', limit: 50)).thenAnswer((_) async => [
            {
              'fpl_id': 101,
              'web_name': 'Raya',
              'position': 'GK',
              'team_short_name': 'ARS',
              'now_cost': 56,
              'status': 'a',
            },
            {
              'fpl_id': 202,
              'web_name': 'Haaland',
              'position': 'FWD',
              'team_short_name': 'MCI',
              'now_cost': 153,
              'status': 'a',
            },
          ]);

      when(() => mockFplRepo.derivePlayerPrice(
            playerFplId: any(named: 'playerFplId'),
            nowCostTenths: any(named: 'nowCostTenths'),
            transferHistory: any(named: 'transferHistory'),
            savedPurchasePriceTenths: any(named: 'savedPurchasePriceTenths'),
            isUserConfirmed: any(named: 'isUserConfirmed'),
          )).thenReturn(
        const DerivedPlayerPrice(
          purchasePriceTenths: 75,
          sellingPriceTenths: 75,
          priceSource: 'FROM_TRANSFER',
          isConfirmed: true,
        ),
      );

      await notifier.loadSquadSequence(12345);

      expect(notifier.state.step, SquadLoadingStep.completed);
      expect(notifier.state.entry?.name, 'Kena FC');
      expect(notifier.state.bankTenths, 15);
      expect(notifier.state.squadValueTenths, 1020);
      expect(notifier.state.isPartialFailure, isFalse);

      // Verify stored in Drift database
      final storedPlayers = await db.getAllSquadPlayers();
      expect(storedPlayers.length, 2);
      expect(storedPlayers.first.fplId, 101);
      expect(storedPlayers.first.webName, 'Raya');
      expect(storedPlayers[1].isCaptain, isTrue);

      final storedTransfers = await db.getTransferHistory();
      expect(storedTransfers.length, 1);
      expect(storedTransfers.first.elementInFplId, 101);

      final storedHistory = await db.getGameweekHistory();
      expect(storedHistory.length, 1);
      expect(storedHistory.first.points, 60);
    });

    test('step 1 failure aborts sequence with failedStep = 1', () async {
      when(() => mockFplRepo.getEntry(12345)).thenThrow(Exception('Upstream failure'));

      await notifier.loadSquadSequence(12345);

      expect(notifier.state.step, SquadLoadingStep.failed);
      expect(notifier.state.failedStep, 1);
      expect(notifier.state.squad, isEmpty);
    });

    test('step 2 failure aborts sequence with failedStep = 2 and discards partial squad', () async {
      when(() => mockFplRepo.getEntry(12345)).thenAnswer((_) async => dummyEntry);
      when(() => mockFplRepo.getCurrentGameweek()).thenAnswer((_) async => dummyGw);
      when(() => mockFplRepo.getSquad(12345, gw: 7)).thenThrow(Exception('Squad 404'));

      await notifier.loadSquadSequence(12345);

      expect(notifier.state.step, SquadLoadingStep.failed);
      expect(notifier.state.failedStep, 2);
      expect(notifier.state.squad, isEmpty);
    });

    test('step 4 history failure preserves squad and marks isPartialFailure = true per P6', () async {
      when(() => mockFplRepo.getEntry(12345)).thenAnswer((_) async => dummyEntry);
      when(() => mockFplRepo.getCurrentGameweek()).thenAnswer((_) async => dummyGw);
      when(() => mockFplRepo.getSquad(12345, gw: 7)).thenAnswer((_) async => dummySquad);
      when(() => mockFplRepo.getTransfers(12345)).thenAnswer((_) async => dummyTransfers);
      when(() => mockFplRepo.getHistory(12345)).thenThrow(Exception('History timeout'));
      when(() => mockFplRepo.searchPlayers('', limit: 50)).thenAnswer((_) async => []);
      when(() => mockFplRepo.derivePlayerPrice(
            playerFplId: any(named: 'playerFplId'),
            nowCostTenths: any(named: 'nowCostTenths'),
            transferHistory: any(named: 'transferHistory'),
            savedPurchasePriceTenths: any(named: 'savedPurchasePriceTenths'),
            isUserConfirmed: any(named: 'isUserConfirmed'),
          )).thenReturn(
        const DerivedPlayerPrice(
          purchasePriceTenths: 60,
          sellingPriceTenths: 60,
          priceSource: 'CONFIRM',
          isConfirmed: false,
        ),
      );

      await notifier.loadSquadSequence(12345);

      expect(notifier.state.step, SquadLoadingStep.completed);
      expect(notifier.state.isPartialFailure, isTrue);

      final storedPlayers = await db.getAllSquadPlayers();
      expect(storedPlayers.length, 2);
    });
  });

  group('SquadNotifier - Price Confirmation & Selling Math (Spec §12.2)', () {
    test('confirmPurchasePrice updates Drift purchase price and recalculated selling price', () async {
      when(() => mockFplRepo.getEntry(12345)).thenAnswer((_) async => dummyEntry);
      when(() => mockFplRepo.getCurrentGameweek()).thenAnswer((_) async => dummyGw);
      when(() => mockFplRepo.getSquad(12345, gw: 7)).thenAnswer((_) async => dummySquad);
      when(() => mockFplRepo.getTransfers(12345)).thenAnswer((_) async => []);
      when(() => mockFplRepo.getHistory(12345)).thenAnswer((_) async => dummyHistory);
      when(() => mockFplRepo.searchPlayers('', limit: 50)).thenAnswer((_) async => [
            {
              'fpl_id': 202,
              'web_name': 'Haaland',
              'position': 'FWD',
              'team_short_name': 'MCI',
              'now_cost': 154,
            },
          ]);
      when(() => mockFplRepo.derivePlayerPrice(
            playerFplId: any(named: 'playerFplId'),
            nowCostTenths: any(named: 'nowCostTenths'),
            transferHistory: any(named: 'transferHistory'),
          )).thenReturn(
        const DerivedPlayerPrice(
          purchasePriceTenths: 154,
          sellingPriceTenths: 154,
          priceSource: 'CONFIRM',
          isConfirmed: false,
        ),
      );

      when(() => mockFplRepo.computeSellingPriceTenths(
            purchasePriceTenths: 150,
            nowCostTenths: 154,
          )).thenReturn(152); // 150 + floor(4/2) = 152

      await notifier.loadSquadSequence(12345);

      // Confirm purchase price of 150 (15.0m) for Haaland (current: 15.4m)
      await notifier.confirmPurchasePrice(202, 150);

      final storedPlayers = await db.getAllSquadPlayers();
      final haaland = storedPlayers.firstWhere((p) => p.fplId == 202);
      expect(haaland.purchasePriceTenths, 150);
      expect(haaland.sellingPriceTenths, 152);
      expect(haaland.priceSource, 'CONFIRMED_USER');
    });
  });

  group('SquadNotifier - 15-Minute Refresh Throttle (Spec §7, Frontend Plan P8 & P9)', () {
    test('refreshSquad returns notice if called within 15 minutes without force', () async {
      when(() => mockFplRepo.getEntry(12345)).thenAnswer((_) async => dummyEntry);
      when(() => mockFplRepo.getCurrentGameweek()).thenAnswer((_) async => dummyGw);
      when(() => mockFplRepo.getSquad(12345, gw: 7)).thenAnswer((_) async => dummySquad);
      when(() => mockFplRepo.getTransfers(12345)).thenAnswer((_) async => dummyTransfers);
      when(() => mockFplRepo.getHistory(12345)).thenAnswer((_) async => dummyHistory);
      when(() => mockFplRepo.searchPlayers('', limit: 50)).thenAnswer((_) async => []);
      when(() => mockFplRepo.derivePlayerPrice(
            playerFplId: any(named: 'playerFplId'),
            nowCostTenths: any(named: 'nowCostTenths'),
            transferHistory: any(named: 'transferHistory'),
          )).thenReturn(
        const DerivedPlayerPrice(
          purchasePriceTenths: 60,
          sellingPriceTenths: 60,
          priceSource: 'CONFIRM',
          isConfirmed: false,
        ),
      );

      await notifier.loadSquadSequence(12345);

      // Second refresh immediately without force
      final notice = await notifier.refreshSquad(force: false);
      expect(notice, 'Already up to date');
    });
  });
}
