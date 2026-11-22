import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/features/history/screens/history_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class FakeHistorySquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakeHistorySquadNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleGameweeks = [
    GameweekHistoryTableData(
      gameweek: 8,
      points: 74,
      totalPoints: 540,
      overallRank: 124512,
      percentileRank: 1.2,
      bankTenths: 15,
      valueTenths: 1025,
      eventTransfers: 1,
      eventTransfersCost: 4,
      pointsOnBench: 6,
    ),
    GameweekHistoryTableData(
      gameweek: 7,
      points: 62,
      totalPoints: 466,
      overallRank: 180200,
      percentileRank: 1.8,
      bankTenths: 20,
      valueTenths: 1020,
      eventTransfers: 0,
      eventTransfersCost: 0,
      pointsOnBench: 2,
    ),
  ];

  final sampleTransfers = [
    TransferHistoryTableData(
      id: 1,
      elementInFplId: 101,
      elementInName: 'Palmer',
      elementInCostTenths: 108,
      elementOutFplId: 102,
      elementOutName: 'Saka',
      elementOutCostTenths: 101,
      gameweek: 8,
      transferTime: DateTime(2026, 10, 15, 14, 30),
    ),
  ];

  Widget buildScreen({ThemeMode mode = ThemeMode.dark, double textScale = 1.0}) {
    final notifier = FakeHistorySquadNotifier(
      SquadState(
        gameweekHistory: sampleGameweeks,
        transfers: sampleTransfers,
      ),
    );

    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
            size: const Size(360, 800),
          ),
          child: const HistoryScreen(),
        ),
      ),
    );
  }

  group('HistoryScreen Redesign Tests', () {
    testWidgets('Renders hero rank, season chips, and gameweek table in dark mode', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Overall Rank'), findsWidgets);
      expect(find.text('124,512'), findsOneWidget);
      expect(find.text('540'), findsOneWidget);
      expect(find.text('Season Chips'), findsOneWidget);
      expect(find.text('Wildcard 1 AVAILABLE'), findsOneWidget);

      // Check gameweek rows
      expect(find.text('GW 8'), findsOneWidget);
      expect(find.text('74 pts'), findsOneWidget);
      expect(find.text('-4'), findsOneWidget); // Hit cost
      expect(find.text('GW 7'), findsOneWidget);
      expect(find.text('62 pts'), findsOneWidget);
    });

    testWidgets('Renders properly in light mode at 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(mode: ThemeMode.light, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('124,512'), findsOneWidget);

      // Switch to transfers tab
      await tester.tap(find.text('Transfers'));
      await tester.pumpAndSettle();

      expect(find.text('Palmer'), findsOneWidget);
      expect(find.text('Saka'), findsOneWidget);
    });
  });
}
