import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late FplRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = FplRepository(dio: mockDio);
  });

  group('FplRepository - Selling Price Mathematics (Spec §12.2)', () {
    test('computeSellingPriceTenths applies 50% profit rise rounded down', () {
      // Rise by 0.5m (5 tenths): 100 + floor(5/2) = 102 (10.2m)
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 100, nowCostTenths: 105), 102);

      // Rise by 0.4m (4 tenths): 100 + floor(4/2) = 102 (10.2m)
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 100, nowCostTenths: 104), 102);

      // Rise by 0.1m (1 tenth): 100 + floor(1/2) = 100 (10.0m)
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 100, nowCostTenths: 101), 100);

      // No price change
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 100, nowCostTenths: 100), 100);

      // Fall rule: selling price equals current cost
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 100, nowCostTenths: 95), 95);
      expect(repository.computeSellingPriceTenths(purchasePriceTenths: 140, nowCostTenths: 138), 138);
    });
  });

  group('FplRepository - Price Derivation (Spec §0, §12.2)', () {
    final transfer1 = TransferItemModel(
      elementIn: 101,
      elementInCost: 75,
      elementOut: 202,
      elementOutCost: 70,
      event: 2,
      time: DateTime(2026, 9, 1),
    );

    final transfer2 = TransferItemModel(
      elementIn: 101,
      elementInCost: 80,
      elementOut: 303,
      elementOutCost: 82,
      event: 5,
      time: DateTime(2026, 10, 1), // Newer transfer
    );

    test('derives FROM_TRANSFER for player with transfer record taking newest in_cost', () {
      final derived = repository.derivePlayerPrice(
        playerFplId: 101,
        nowCostTenths: 85,
        transferHistory: [transfer1, transfer2],
      );

      expect(derived.priceSource, 'FROM_TRANSFER');
      expect(derived.purchasePriceTenths, 80);
      expect(derived.isConfirmed, isTrue);
      // Rise: 80 -> 85 = +5, half floor = +2 -> 82
      expect(derived.sellingPriceTenths, 82);
    });

    test('derives CONFIRM and defaults to nowCost when player not in transfer records', () {
      final derived = repository.derivePlayerPrice(
        playerFplId: 999,
        nowCostTenths: 140,
        transferHistory: [transfer1, transfer2],
      );

      expect(derived.priceSource, 'CONFIRM');
      expect(derived.purchasePriceTenths, 140);
      expect(derived.isConfirmed, isFalse);
      expect(derived.sellingPriceTenths, 140);
    });

    test('respects user-confirmed price as CONFIRMED_USER', () {
      final derived = repository.derivePlayerPrice(
        playerFplId: 999,
        nowCostTenths: 144,
        transferHistory: [],
        savedPurchasePriceTenths: 140,
        isUserConfirmed: true,
      );

      expect(derived.priceSource, 'CONFIRMED_USER');
      expect(derived.purchasePriceTenths, 140);
      expect(derived.isConfirmed, isTrue);
      // 140 -> 144 = +4, half is +2 -> 142
      expect(derived.sellingPriceTenths, 142);
    });
  });

  group('FplRepository - API Endpoint Deserialization', () {
    test('getEntry returns deserialized EntryModel', () async {
      when(() => mockDio.get('/api/v1/fpl/entry/12345')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/fpl/entry/12345'),
          statusCode: 200,
          data: {
            'id': 12345,
            'name': 'Kena FC',
            'player_first_name': 'Kena',
            'player_last_name': 'At',
            'summary_overall_points': 542,
            'summary_overall_rank': 124532,
          },
        ),
      );

      final entry = await repository.getEntry(12345);
      expect(entry.id, 12345);
      expect(entry.name, 'Kena FC');
      expect(entry.playerFirstName, 'Kena');
      expect(entry.playerLastName, 'At');
      expect(entry.summaryOverallPoints, 542);
      expect(entry.summaryOverallRank, 124532);
    });

    test('getSquad returns deserialized SquadPicksResponse', () async {
      when(() => mockDio.get('/api/v1/fpl/entry/12345/squad', queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/fpl/entry/12345/squad'),
          statusCode: 200,
          data: {
            'picks': [
              {
                'element': 355,
                'position': 9,
                'multiplier': 2,
                'is_captain': true,
                'is_vice_captain': false,
              },
            ],
            'chips': [],
          },
        ),
      );

      final squad = await repository.getSquad(12345);
      expect(squad.picks.length, 1);
      expect(squad.picks.first.element, 355);
      expect(squad.picks.first.isCaptain, isTrue);
      expect(squad.picks.first.multiplier, 2);
    });

    test('getHistory returns deserialized HistoryResponse', () async {
      when(() => mockDio.get('/api/v1/fpl/entry/12345/history')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/fpl/entry/12345/history'),
          statusCode: 200,
          data: {
            'current': [
              {
                'event': 1,
                'points': 65,
                'total_points': 65,
                'overall_rank': 500000,
                'event_transfers': 0,
                'event_transfers_cost': 0,
                'points_on_bench': 4,
                'bank': 15,
                'value': 1000,
              },
            ],
          },
        ),
      );

      final history = await repository.getHistory(12345);
      expect(history.current.length, 1);
      expect(history.current.first.event, 1);
      expect(history.current.first.points, 65);
    });

    test('getTransfers returns deserialized TransferItemModel list', () async {
      when(() => mockDio.get('/api/v1/fpl/entry/12345/transfers')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/fpl/entry/12345/transfers'),
          statusCode: 200,
          data: [
            {
              'element_in': 101,
              'element_in_cost': 75,
              'element_out': 202,
              'element_out_cost': 70,
              'event': 2,
              'time': '2026-09-01T12:00:00Z',
            },
          ],
        ),
      );

      final transfers = await repository.getTransfers(12345);
      expect(transfers.length, 1);
      expect(transfers.first.elementIn, 101);
      expect(transfers.first.elementInCost, 75);
    });

    test('getCurrentGameweek returns GameweekMetadata', () async {
      when(() => mockDio.get('/api/v1/gameweeks/current')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/gameweeks/current'),
          statusCode: 200,
          data: {
            'current': {
              'id': 7,
              'name': 'Gameweek 7',
              'deadline_time': '2026-10-19T10:00:00Z',
              'finished': false,
              'is_current': true,
              'is_next': false,
            },
            'next': {
              'id': 8,
              'name': 'Gameweek 8',
              'deadline_time': '2026-10-26T10:00:00Z',
              'finished': false,
              'is_current': false,
              'is_next': true,
            },
          },
        ),
      );

      final gwResp = await repository.getCurrentGameweek();
      expect(gwResp.current, isNotNull);
      expect(gwResp.current!.id, 7);
      expect(gwResp.next!.id, 8);
    });
  });
}
