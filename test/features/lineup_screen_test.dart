import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/optimiser/lineup_optimiser.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/widgets/bench_strip.dart';
import 'package:fpl_lens/core/widgets/pitch_view.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/lineup/providers/lineup_provider.dart';
import 'package:fpl_lens/features/lineup/screens/lineup_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockLineupNotifier extends StateNotifier<LineupState> implements LineupNotifier {
  bool optimizeCalled = false;
  int? lastSelectedGw;

  MockLineupNotifier([super.state = const LineupState()]);

  @override
  Future<void> optimize({bool forceFallback = false}) async {
    optimizeCalled = true;
  }

  @override
  Future<void> selectGameweek(int gw) async {
    lastSelectedGw = gw;
    state = state.copyWith(selectedGameweek: gw);
  }

  @override
  void setRecommendedMode(bool isRecommended) {
    state = state.copyWith(isRecommendedMode: isRecommended);
  }

  @override
  void setManualCaptain(int fplId) {
    state = state.copyWith(manualCaptainId: fplId);
  }

  @override
  void setManualViceCaptain(int fplId) {
    state = state.copyWith(manualViceCaptainId: fplId);
  }

  @override
  void clearOverrides() {
    state = state.copyWith(manualCaptainId: null, manualViceCaptainId: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSquadLineupNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  MockSquadLineupNotifier([super.state = const SquadState()]);

  @override
  Future<String?> refreshSquad({bool force = false}) async => 'Synced';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  PlayerCandidate makeCandidate({
    required int fplId,
    required String name,
    required String pos,
    required double xp,
    int priceTenths = 60,
  }) {
    return PlayerCandidate(
      fplId: fplId,
      webName: name,
      position: pos,
      clubId: 1,
      priceTenths: priceTenths,
      sellingPriceTenths: priceTenths,
      xp: xp,
      pStart: 0.95,
      pSub: 0.05,
    );
  }

  LineupResult createSampleResult() {
    final gk = makeCandidate(fplId: 1, name: 'Raya', pos: 'GK', xp: 4.8);
    final defs = [
      makeCandidate(fplId: 2, name: 'Saliba', pos: 'DEF', xp: 5.2),
      makeCandidate(fplId: 3, name: 'Gabriel', pos: 'DEF', xp: 5.0),
      makeCandidate(fplId: 4, name: 'Gvardiol', pos: 'DEF', xp: 4.6),
    ];
    final mids = [
      makeCandidate(fplId: 5, name: 'Saka', pos: 'MID', xp: 7.4),
      makeCandidate(fplId: 6, name: 'Palmer', pos: 'MID', xp: 7.2),
      makeCandidate(fplId: 7, name: 'Salah', pos: 'MID', xp: 8.5),
      makeCandidate(fplId: 8, name: 'Mbeumo', pos: 'MID', xp: 5.8),
    ];
    final fwds = [
      makeCandidate(fplId: 9, name: 'Haaland', pos: 'FWD', xp: 9.1),
      makeCandidate(fplId: 10, name: 'Watkins', pos: 'FWD', xp: 6.3),
      makeCandidate(fplId: 11, name: 'Wood', pos: 'FWD', xp: 5.5),
    ];

    final bench = [
      makeCandidate(fplId: 12, name: 'Fabianski', pos: 'GK', xp: 1.5),
      makeCandidate(fplId: 13, name: 'Konsa', pos: 'DEF', xp: 3.2),
      makeCandidate(fplId: 14, name: 'Rogers', pos: 'MID', xp: 3.8),
      makeCandidate(fplId: 15, name: 'Greaves', pos: 'DEF', xp: 2.1),
    ];

    return LineupResult(
      startingXi: [gk, ...defs, ...mids, ...fwds],
      bench: bench,
      captain: fwds[0], // Haaland
      viceCaptain: mids[2], // Salah
      totalExpectedPoints: 69.4,
      formation: const [1, 3, 4, 3],
      captaincyScore: 18.2,
      benchOrderScore: 8.6,
      isQuickModeFallback: false,
    );
  }

  List<SquadPlayersTableData> create15DriftPlayers() {
    return List.generate(
      15,
      (i) => SquadPlayersTableData(
        id: i + 1,
        fplId: 100 + i,
        webName: 'Player ${i + 1}',
        position: i < 2 ? 'GK' : (i < 7 ? 'DEF' : (i < 12 ? 'MID' : 'FWD')),
        teamId: 1,
        teamShortName: 'ARS',
        purchasePriceTenths: 50,
        sellingPriceTenths: 50,
        nowCostTenths: 50,
        status: 'a',
        chanceOfPlayingNextRound: 100,
        isCaptain: i == 0,
        isViceCaptain: i == 1,
        multiplier: i == 0 ? 2 : 1,
        positionOrder: i + 1,
        priceSource: 'CONFIRMED_USER',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Widget buildLineupScreenHost({
    required LineupState lineupState,
    required SquadState squadState,
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    bool disableAnimations = false,
  }) {
    final router = GoRouter(
      initialLocation: '/lineup',
      routes: [
        GoRoute(path: '/lineup', builder: (_, __) => const LineupScreen()),
        GoRoute(path: '/heatmap', builder: (_, __) => const Scaffold(body: Text('Route: /heatmap'))),
      ],
    );

    return ProviderScope(
      overrides: [
        lineupNotifierProvider.overrideWith((ref) => MockLineupNotifier(lineupState)),
        squadNotifierProvider.overrideWith((ref) => MockSquadLineupNotifier(squadState)),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          );
        },
      ),
    );
  }

  group('Sprint R4: Lineup Screen Visual Redesign Tests', () {
    testWidgets('renders empty state when squad contains fewer than 15 players', (tester) async {
      await tester.pumpWidget(
        buildLineupScreenHost(
          lineupState: const LineupState(),
          squadState: const SquadState(squad: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No squad loaded'), findsOneWidget);
      expect(find.text('Sync Squad'), findsOneWidget);
    });

    testWidgets('renders starting XI pitch, bench strip, hero metrics and legend in dark mode', (tester) async {
      final sampleResult = createSampleResult();
      final squadPlayers = create15DriftPlayers();

      await tester.pumpWidget(
        buildLineupScreenHost(
          lineupState: LineupState(
            selectedGameweek: 9,
            result: sampleResult,
          ),
          squadState: SquadState(
            squad: squadPlayers,
            currentGameweek: const GameweekMetadata(id: 9, name: 'GW 9'),
          ),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Top Switcher
      expect(find.text('My Lineup'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);

      // Hero Metrics card
      expect(find.text('PROJECTED POINTS'), findsOneWidget);
      expect(find.text('69.4'), findsOneWidget);
      expect(find.text('xP'), findsWidgets);
      expect(find.text('3-4-3'), findsOneWidget);
      expect(find.text('Captain: Haaland (C)'), findsOneWidget);
      expect(find.text('Vice: Salah (V)'), findsOneWidget);

      // Pitch View & Legend
      expect(find.byType(PitchView), findsOneWidget);
      expect(find.text('Performance index (0–100). Dashed ring: start chance below 75 %.'), findsOneWidget);

      // Bench Strip
      expect(find.byType(BenchStrip), findsOneWidget);
      expect(find.text('BENCH (SUBSTITUTION ORDER)'), findsOneWidget);

      // Actions
      expect(find.text('Save lineup'), findsOneWidget);
    });

    testWidgets('tapping player on pitch opens player action sheet with xP attribution breakdown', (tester) async {
      final sampleResult = createSampleResult();
      final squadPlayers = create15DriftPlayers();

      await tester.pumpWidget(
        buildLineupScreenHost(
          lineupState: LineupState(
            selectedGameweek: 9,
            result: sampleResult,
          ),
          squadState: SquadState(
            squad: squadPlayers,
            currentGameweek: const GameweekMetadata(id: 9, name: 'GW 9'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Raya player chip on pitch
      await tester.tap(find.text('Raya'));
      await tester.pumpAndSettle();

      // Action sheet contents
      expect(find.text('xP CALCULATION EXPLANATION'), findsOneWidget);
      expect(find.text('View Fixture Heatmap'), findsOneWidget);
      expect(find.text('Make Captain'), findsOneWidget);
      expect(find.text('Make Vice-Captain'), findsOneWidget);
      expect(find.text('Clear Manual Overrides'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 200% text scale on 360dp narrow viewport in light and dark modes', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleResult = createSampleResult();
      final squadPlayers = create15DriftPlayers();

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildLineupScreenHost(
            lineupState: LineupState(
              selectedGameweek: 9,
              result: sampleResult,
            ),
            squadState: SquadState(
            squad: squadPlayers,
            currentGameweek: const GameweekMetadata(id: 9, name: 'GW 9'),
          ),
            themeMode: mode,
            textScale: 2.0,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed in $mode');
        expect(find.text('PROJECTED POINTS'), findsOneWidget);
        expect(find.text('Save lineup'), findsOneWidget);
      }
    });
  });
}
