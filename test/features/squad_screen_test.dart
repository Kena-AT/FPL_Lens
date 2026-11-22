import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/widgets/availability_badge.dart';
import 'package:fpl_lens/core/widgets/delta_chip.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';
import 'package:fpl_lens/features/squad/screens/squad_screen.dart';

class MockSquadScreenNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  bool refreshCalled = false;

  MockSquadScreenNotifier([super.state = const SquadState()]);

  @override
  Future<String?> refreshSquad({bool force = false}) async {
    refreshCalled = true;
    return 'Synced';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  List<SquadPlayersTableData> create15Players() {
    return [
      // 2 GKs
      SquadPlayersTableData(
        id: 1,
        fplId: 101,
        webName: 'Raya',
        position: 'GK',
        teamId: 1,
        teamShortName: 'ARS',
        purchasePriceTenths: 55,
        sellingPriceTenths: 56,
        nowCostTenths: 56,
        status: 'a',
        chanceOfPlayingNextRound: 100,
        isCaptain: true,
        isViceCaptain: false,
        multiplier: 2,
        positionOrder: 1,
        priceSource: 'CONFIRMED_USER',
        updatedAt: DateTime.now(),
      ),
      SquadPlayersTableData(
        id: 2,
        fplId: 102,
        webName: 'Fabianski',
        position: 'GK',
        teamId: 20,
        teamShortName: 'WHU',
        purchasePriceTenths: 40,
        sellingPriceTenths: 40,
        nowCostTenths: 40,
        status: 'd',
        chanceOfPlayingNextRound: 75,
        isCaptain: false,
        isViceCaptain: true,
        multiplier: 1,
        positionOrder: 12,
        priceSource: 'DEFAULTED_CURRENT',
        updatedAt: DateTime.now(),
      ),
      // 5 DEFs
      for (int i = 1; i <= 5; i++)
        SquadPlayersTableData(
          id: 2 + i,
          fplId: 200 + i,
          webName: 'Defender $i',
          position: 'DEF',
          teamId: i,
          teamShortName: 'TM$i',
          purchasePriceTenths: 50 + i,
          sellingPriceTenths: 50 + i,
          nowCostTenths: 50 + i,
          status: 'a',
          chanceOfPlayingNextRound: 100,
          isCaptain: false,
          isViceCaptain: false,
          multiplier: 1,
          positionOrder: i + 1,
          priceSource: 'FROM_TRANSFER',
          updatedAt: DateTime.now(),
        ),
      // 5 MIDs
      for (int i = 1; i <= 5; i++)
        SquadPlayersTableData(
          id: 7 + i,
          fplId: 300 + i,
          webName: 'Midfielder $i',
          position: 'MID',
          teamId: i + 5,
          teamShortName: 'MD$i',
          purchasePriceTenths: 70 + i,
          sellingPriceTenths: 72 + i,
          nowCostTenths: 74 + i,
          status: i == 1 ? 'i' : 'a',
          chanceOfPlayingNextRound: i == 1 ? 0 : 100,
          isCaptain: false,
          isViceCaptain: false,
          multiplier: 1,
          positionOrder: i + 6,
          priceSource: 'FROM_TRANSFER',
          updatedAt: DateTime.now(),
        ),
      // 3 FWDs
      for (int i = 1; i <= 3; i++)
        SquadPlayersTableData(
          id: 12 + i,
          fplId: 400 + i,
          webName: 'Forward $i',
          position: 'FWD',
          teamId: i + 10,
          teamShortName: 'FW$i',
          purchasePriceTenths: 80 + i,
          sellingPriceTenths: 82 + i,
          nowCostTenths: 84 + i,
          status: 'a',
          chanceOfPlayingNextRound: 100,
          isCaptain: false,
          isViceCaptain: false,
          multiplier: 1,
          positionOrder: i + 11,
          priceSource: 'CONFIRMED_USER',
          updatedAt: DateTime.now(),
        ),
    ];
  }

  Widget buildSquadScreenHost({
    required SquadState squadState,
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    bool disableAnimations = false,
  }) {
    final router = GoRouter(
      initialLocation: '/squad',
      routes: [
        GoRoute(path: '/squad', builder: (_, __) => const SquadScreen()),
        GoRoute(path: '/squad/prices', builder: (_, __) => const Scaffold(body: Text('Route: /squad/prices'))),
        GoRoute(path: '/player/:id', builder: (_, state) => Scaffold(body: Text('Route: /player/${state.pathParameters['id']}'))),
        GoRoute(path: '/onboarding/team', builder: (_, __) => const Scaffold(body: Text('Route: /onboarding/team'))),
      ],
    );

    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => MockSquadScreenNotifier(squadState)),
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

  group('Sprint R4: Squad Screen Visual Redesign Tests', () {
    testWidgets('renders EmptyState when squad is empty', (tester) async {
      await tester.pumpWidget(
        buildSquadScreenHost(
          squadState: const SquadState(squad: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No squad loaded'), findsOneWidget);
      expect(find.text('Enter Team ID'), findsOneWidget);
    });

    testWidgets('renders 15 players list view with position groups, badges and delta chips', (tester) async {
      final players = create15Players();
      final squadState = SquadState(
        squad: players,
        squadValueTenths: 1015,
        bankTenths: 12,
        currentGameweek: const GameweekMetadata(id: 9, name: 'GW 9'),
      );

      await tester.pumpWidget(
        buildSquadScreenHost(
          squadState: squadState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // View switcher
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Pitch'), findsOneWidget);

      // Group headers
      expect(find.text('GOALKEEPERS'), findsOneWidget);
      expect(find.text('DEFENDERS'), findsOneWidget);

      // Players and badges
      expect(find.text('Raya'), findsOneWidget);
      expect(find.text('Fabianski'), findsOneWidget);
      expect(find.byType(AvailabilityBadge), findsWidgets);
      expect(find.byType(DeltaChip), findsWidgets);

      // Captain badge
      expect(find.text('C'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);

      // Bottom dock
      expect(find.text('SQUAD VALUE'), findsOneWidget);
      expect(find.text('£101.5m'), findsOneWidget);
      expect(find.text('BANK'), findsOneWidget);
      expect(find.text('£1.2m'), findsOneWidget);
      expect(find.text('Edit Prices'), findsOneWidget);
    });

    testWidgets('switches to Pitch view and renders 15 players on 2-5-5-3 tactical canvas', (tester) async {
      final players = create15Players();
      final squadState = SquadState(
        squad: players,
        squadValueTenths: 1015,
        bankTenths: 12,
      );

      await tester.pumpWidget(
        buildSquadScreenHost(
          squadState: squadState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pitch button segment
      await tester.tap(find.text('Pitch'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Raya'), findsOneWidget);
      expect(find.text('Fabianski'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow at 200% text scale on 360dp narrow viewport in light and dark modes', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final players = create15Players();
      final squadState = SquadState(
        squad: players,
        squadValueTenths: 1015,
        bankTenths: 12,
      );

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildSquadScreenHost(
            squadState: squadState,
            themeMode: mode,
            textScale: 2.0,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed in $mode');
        expect(find.text('Squad'), findsOneWidget);
        expect(find.text('Edit Prices'), findsOneWidget);
      }
    });

    testWidgets('tapping player navigates to player detail route', (tester) async {
      final players = create15Players();
      final squadState = SquadState(squad: players);

      await tester.pumpWidget(
        buildSquadScreenHost(squadState: squadState),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raya'));
      await tester.pumpAndSettle();

      expect(find.text('Route: /player/101'), findsOneWidget);
    });

    testWidgets('tapping Edit Prices navigates to /squad/prices', (tester) async {
      final players = create15Players();
      final squadState = SquadState(squad: players);

      await tester.pumpWidget(
        buildSquadScreenHost(squadState: squadState),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Prices'));
      await tester.pumpAndSettle();

      expect(find.text('Route: /squad/prices'), findsOneWidget);
    });
  });
}
