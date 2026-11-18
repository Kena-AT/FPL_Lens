import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/gameweek/screens/gameweek_screen.dart';

void main() {
  Widget createScreen({
    required CurrentGameweekResponse meta,
    required List<FixtureModel> fixtures,
  }) {
    return ProviderScope(
      overrides: [
        currentGameweekMetadataProvider.overrideWith((ref) => Future.value(meta)),
        gameweekFixturesProvider.overrideWith((ref, gw) => Future.value(fixtures)),
      ],
      child: const MaterialApp(
        home: GameweekScreen(),
      ),
    );
  }

  group('P14 GameweekScreen Tests', () {
    testWidgets('Renders Gameweek header, selector, summary card, and fixtures grouped by date', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final meta = CurrentGameweekResponse(
        current: GameweekMetadata(
          id: 9,
          name: 'Gameweek 9',
          deadlineTime: DateTime.utc(2026, 10, 24, 11, 0),
          isCurrent: true,
        ),
      );

      final fixtures = [
        FixtureModel(
          fplId: 101,
          gameweek: 9,
          kickoffTime: DateTime.utc(2026, 10, 24, 12, 30),
          homeTeamFplId: 1,
          homeTeamShortName: 'ARS',
          homeTeamName: 'Arsenal',
          awayTeamFplId: 2,
          awayTeamShortName: 'LIV',
          awayTeamName: 'Liverpool',
          finished: true,
          homeScore: 2,
          awayScore: 2,
        ),
        FixtureModel(
          fplId: 102,
          gameweek: 9,
          kickoffTime: DateTime.utc(2026, 10, 24, 15, 0),
          homeTeamFplId: 3,
          homeTeamShortName: 'MCI',
          homeTeamName: 'Manchester City',
          awayTeamFplId: 4,
          awayTeamShortName: 'SOU',
          awayTeamName: 'Southampton',
          finished: false,
          isDouble: true,
        ),
      ];

      await tester.pumpWidget(createScreen(meta: meta, fixtures: fixtures));
      await tester.pumpAndSettle();

      // Header & selector
      expect(find.text('Gameweek 9'), findsAtLeastNWidgets(1));
      expect(find.text('Current'), findsOneWidget);

      // Summary Card
      expect(find.text('Gameweek Summary'), findsOneWidget);
      expect(find.text('Average score'), findsOneWidget);
      expect(find.text('Highest score'), findsOneWidget);
      expect(find.text('Live rank'), findsOneWidget);

      // Fixtures
      expect(find.text('ARS'), findsOneWidget);
      expect(find.text('LIV'), findsOneWidget);
      expect(find.text('2 - 2'), findsOneWidget);

      expect(find.text('MCI'), findsOneWidget);
      expect(find.text('SOU'), findsOneWidget);
      expect(find.text('Double'), findsOneWidget);
    });

    testWidgets('Renders empty state when no fixtures are scheduled', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final meta = CurrentGameweekResponse(
        current: GameweekMetadata(
          id: 15,
          name: 'Gameweek 15',
          isCurrent: false,
        ),
      );

      await tester.pumpWidget(createScreen(meta: meta, fixtures: []));
      await tester.pumpAndSettle();

      expect(find.text('No fixtures scheduled yet.'), findsOneWidget);
    });

    testWidgets('P14 renders cleanly without overflow at 360 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final meta = CurrentGameweekResponse(
        current: GameweekMetadata(
          id: 10,
          name: 'Gameweek 10',
          deadlineTime: DateTime.utc(2026, 10, 31, 11, 0),
          isCurrent: true,
        ),
      );

      final fixtures = [
        FixtureModel(
          fplId: 201,
          gameweek: 10,
          kickoffTime: DateTime.utc(2026, 10, 31, 12, 30),
          homeTeamFplId: 1,
          homeTeamShortName: 'NEW',
          homeTeamName: 'Newcastle',
          awayTeamFplId: 2,
          awayTeamShortName: 'ARS',
          awayTeamName: 'Arsenal',
          finished: true,
          homeScore: 1,
          awayScore: 0,
        ),
      ];

      await tester.pumpWidget(createScreen(meta: meta, fixtures: fixtures));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('ARS'), findsOneWidget);
      expect(find.text('1 - 0'), findsOneWidget);
    });

    testWidgets('P14 renders cleanly without overflow at 430 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final meta = CurrentGameweekResponse(
        current: GameweekMetadata(
          id: 10,
          name: 'Gameweek 10',
          deadlineTime: DateTime.utc(2026, 10, 31, 11, 0),
          isCurrent: true,
        ),
      );

      final fixtures = [
        FixtureModel(
          fplId: 202,
          gameweek: 10,
          kickoffTime: DateTime.utc(2026, 10, 31, 15, 0),
          homeTeamFplId: 3,
          homeTeamShortName: 'LIV',
          homeTeamName: 'Liverpool',
          awayTeamFplId: 4,
          awayTeamShortName: 'BHA',
          awayTeamName: 'Brighton',
          finished: false,
          isDouble: true,
        ),
      ];

      await tester.pumpWidget(createScreen(meta: meta, fixtures: fixtures));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      if (exc != null) {
        if (exc is FlutterError) {
          for (final d in exc.diagnostics) {
            debugPrint('DIAG ${d.name}: ${d.toString(minLevel: DiagnosticLevel.fine)}');
          }
        }
      }
      expect(exc, isNull);
      expect(find.text('LIV'), findsOneWidget);
      expect(find.text('BHA'), findsOneWidget);
      expect(find.text('Double'), findsOneWidget);
    });
  });
}
