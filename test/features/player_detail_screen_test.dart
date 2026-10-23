import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/player/screens/player_detail_screen.dart';

class MockFplRepository implements FplRepository {
  final Map<String, dynamic>? playerProjectionResponse;
  final bool shouldThrowNotFound;

  MockFplRepository({
    this.playerProjectionResponse,
    this.shouldThrowNotFound = false,
  });

  @override
  Future<Map<String, dynamic>> getPlayerProjection(int gw, int fplId) async {
    if (shouldThrowNotFound) {
      throw Exception('404 NOT_FOUND');
    }
    return playerProjectionResponse ??
        {
          'gameweek': gw,
          'fpl_id': fplId,
          'player': {
            'fpl_id': fplId,
            'web_name': 'Haaland',
            'position': 'FWD',
            'team_short_name': 'MCI',
            'now_cost': 152,
            'status': 'a',
            'chance_of_playing_next_round': 100,
            'news': '',
          },
          'inputs_as_of': '2026-10-20T12:00:00Z',
          'fixtures': [
            {
              'fixture_fpl_id': 101,
              'expected_points': 8.4,
              'availability': 1.0,
              'p_start': 0.95,
              'expected_minutes': 85.0,
              'exp_goals': 0.85,
              'exp_assists': 0.25,
              'exp_clean_sheet': 0.45,
              'exp_goals_conceded': -0.40,
              'exp_dc': 0.20,
              'exp_bonus': 0.95,
              'exp_card_penalty': -0.05,
              'is_home': true,
              'opponent_short_name': 'ARS',
              'kickoff_time': '2026-10-24T12:30:00Z',
              'opponent_attack_strength': 1200,
              'opponent_defence_strength': 1150,
            }
          ],
        };
  }

  @override
  Future<CurrentGameweekResponse> getCurrentGameweek() async {
    return const CurrentGameweekResponse(
      next: GameweekMetadata(id: 9, name: 'Gameweek 9'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildScreen(FplRepository repo, {int fplId = 355}) {
    return ProviderScope(
      overrides: [
        fplRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: PlayerDetailScreen(fplId: fplId, gameweek: 9),
      ),
    );
  }

  group('P11 PlayerDetailScreen Tests', () {
    testWidgets('Renders full player projection with all attribution rows', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockFplRepository();
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Top bar & Header
      expect(find.text('Haaland'), findsWidgets);
      expect(find.text('FWD'), findsOneWidget);
      expect(find.text('MCI'), findsOneWidget);
      expect(find.text('£15.2m'), findsOneWidget);
      expect(find.text('Fit'), findsOneWidget);

      // Projection summary
      expect(find.text('8.4'), findsOneWidget);
      expect(find.text('vs ARS (H), 24 Oct 12:30'), findsOneWidget);

      // Attribution rows
      expect(find.text('Availability (α)'), findsOneWidget);
      expect(find.text('100%'), findsWidgets);
      expect(find.text('Start probability'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('Expected minutes'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Expected goals (xG)'), findsOneWidget);
      expect(find.text('0.85'), findsOneWidget);
      expect(find.text('Expected assists (xA)'), findsOneWidget);
      expect(find.text('0.25'), findsOneWidget);
      expect(find.text('Clean sheet probability'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('Goals-conceded penalty'), findsOneWidget);
      expect(find.text('-0.40'), findsOneWidget);
      expect(find.text('Defensive contributions'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Expected bonus'), findsOneWidget);
      expect(find.text('0.95'), findsOneWidget);
      expect(find.text('Card penalty'), findsOneWidget);
      expect(find.text('-0.05'), findsOneWidget);

      // Opponent intensity
      expect(find.text('Opponent Attack'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('Opponent Defence'), findsOneWidget);
      expect(find.text('1150'), findsOneWidget);
    });

    testWidgets('Omit attribution row when a field is missing (never invented)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final partialData = {
        'gameweek': 9,
        'fpl_id': 355,
        'player': {
          'fpl_id': 355,
          'web_name': 'Saka',
          'position': 'MID',
          'team_short_name': 'ARS',
          'now_cost': 100,
          'status': 'd',
          'chance_of_playing_next_round': 75,
          'news': 'Knock - 75% chance of playing',
        },
        'inputs_as_of': '2026-10-20T12:00:00Z',
        'fixtures': [
          {
            'fixture_fpl_id': 102,
            'expected_points': 6.2,
            'availability': 0.75,
            'p_start': 0.80,
            'expected_minutes': 75.0,
            'exp_goals': 0.40,
            // Missing: exp_assists, exp_clean_sheet, exp_goals_conceded, exp_dc, exp_bonus, exp_card_penalty
          }
        ],
      };

      final repo = MockFplRepository(playerProjectionResponse: partialData);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Saka'), findsWidgets);
      expect(find.text('Doubtful, 75%'), findsOneWidget);
      expect(find.text('Knock - 75% chance of playing'), findsOneWidget);

      // Present rows
      expect(find.text('Availability (α)'), findsOneWidget);
      expect(find.text('75%'), findsWidgets);
      expect(find.text('Start probability'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Expected minutes'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('Expected goals (xG)'), findsOneWidget);
      expect(find.text('0.40'), findsOneWidget);

      // Missing rows must not be displayed or invented
      expect(find.text('Expected assists (xA)'), findsNothing);
      expect(find.text('Clean sheet probability'), findsNothing);
      expect(find.text('Goals-conceded penalty'), findsNothing);
      expect(find.text('Defensive contributions'), findsNothing);
    });

    testWidgets('Renders not found state when player is unknown', (tester) async {
      final repo = MockFplRepository(shouldThrowNotFound: true);
      await tester.pumpWidget(buildScreen(repo, fplId: 99999));
      await tester.pumpAndSettle();

      expect(find.text('Player not found'), findsOneWidget);
      expect(find.text('We could not find player #99999 in our records.'), findsOneWidget);
    });

    testWidgets('Renders no projection state when player has no fixtures', (tester) async {
      final noFixturesData = {
        'gameweek': 9,
        'fpl_id': 400,
        'player': {
          'fpl_id': 400,
          'web_name': 'BenchPlayer',
          'position': 'DEF',
          'team_short_name': 'EVE',
          'now_cost': 40,
          'status': 'a',
        },
        'fixtures': [],
      };

      final repo = MockFplRepository(playerProjectionResponse: noFixturesData);
      await tester.pumpWidget(buildScreen(repo, fplId: 400));
      await tester.pumpAndSettle();

      expect(find.text('No projection for BenchPlayer in this gameweek.'), findsOneWidget);
    });
  });
}
