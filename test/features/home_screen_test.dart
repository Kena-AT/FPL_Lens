import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/widgets/glass_container.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/home/screens/home_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockHomeSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  bool refreshCalled = false;
  bool refreshForceArg = false;

  MockHomeSquadNotifier([super.state = const SquadState()]);

  @override
  Future<String?> refreshSquad({bool force = false}) async {
    refreshCalled = true;
    refreshForceArg = force;
    return 'Synced successfully';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildHomeScreenHost({
    required SquadState squadState,
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 1.0,
    bool disableAnimations = false,
    MockHomeSquadNotifier? notifier,
  }) {
    final effectiveNotifier = notifier ?? MockHomeSquadNotifier(squadState);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/history', builder: (_, __) => const Scaffold(body: Text('Route: /history'))),
        GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('Route: /settings'))),
        GoRoute(path: '/squad', builder: (_, __) => const Scaffold(body: Text('Route: /squad'))),
        GoRoute(path: '/squad/prices', builder: (_, __) => const Scaffold(body: Text('Route: /squad/prices'))),
        GoRoute(path: '/lineup', builder: (_, __) => const Scaffold(body: Text('Route: /lineup'))),
        GoRoute(path: '/transfers', builder: (_, __) => const Scaffold(body: Text('Route: /transfers'))),
      ],
    );

    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => effectiveNotifier),
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

  group('Sprint R4: Home Screen Visual Redesign & Bento Grid Tests', () {
    final sampleGw = GameweekMetadata(
      id: 9,
      name: 'Gameweek 9',
      deadlineTime: DateTime.now().add(const Duration(days: 2, hours: 14, minutes: 32)),
      isCurrent: true,
      isNext: false,
      finished: false,
    );

    final sampleSquadState = SquadState(
      currentGameweek: sampleGw,
      nextGameweek: sampleGw,
      squadValueTenths: 1024,
      bankTenths: 15,
      freeTransfers: 2,
      lastSyncTime: DateTime.now().subtract(const Duration(minutes: 4)),
      unconfirmedCount: 0,
    );

    testWidgets('renders Bento Grid layout in dark mode with Glass Hero deadline card', (tester) async {
      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: sampleSquadState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // App bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('History'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      // Hero Gameweek Card
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(find.text('Gameweek 9'), findsOneWidget);
      expect(find.text('DEADLINE COUNTDOWN'), findsOneWidget);

      // 3 Bento Metric Tiles
      expect(find.text('SQUAD VALUE'), findsOneWidget);
      expect(find.text('£102.4m'), findsOneWidget);
      expect(find.text('IN BANK'), findsOneWidget);
      expect(find.text('£1.5m'), findsOneWidget);
      expect(find.text('TRANSFERS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // 2x1 Projection Tile
      expect(find.text('PROJECTED TOTAL'), findsOneWidget);
      expect(find.text('View Lineup'), findsOneWidget);

      // Quick action chips (scroll down to ensure visible)
      await tester.scrollUntilVisible(find.text('Squad'), 200);
      expect(find.text('Squad'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Prices'), findsOneWidget);
      expect(find.text('Transfer Lab'), findsOneWidget);
    });

    testWidgets('renders cleanly in light mode with correct theme colors', (tester) async {
      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: sampleSquadState,
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Gameweek 9'), findsOneWidget);
      expect(find.text('£102.4m'), findsOneWidget);
    });

    testWidgets('renders unconfirmed purchase prices warning banner when count > 0 and navigates', (tester) async {
      final warningSquadState = sampleSquadState.copyWith(unconfirmedCount: 3);

      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: warningSquadState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 player purchase prices need confirmation.'), findsOneWidget);

      await tester.tap(find.text('3 player purchase prices need confirmation.'));
      await tester.pumpAndSettle();

      expect(find.text('Route: /squad/prices'), findsOneWidget);
    });

    testWidgets('renders without overflow at 200% text scale on 360dp narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: sampleSquadState.copyWith(unconfirmedCount: 2),
          themeMode: ThemeMode.dark,
          textScale: 2.0,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('SQUAD VALUE'), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers force sync on squad notifier', (tester) async {
      final mockNotifier = MockHomeSquadNotifier(sampleSquadState);

      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: sampleSquadState,
          themeMode: ThemeMode.dark,
          notifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger pull to refresh gesture on scrollable ListView
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(mockNotifier.refreshCalled, isTrue);
      expect(mockNotifier.refreshForceArg, isTrue);
    });

    testWidgets('quick actions navigate to correct routes', (tester) async {
      await tester.pumpWidget(
        buildHomeScreenHost(
          squadState: sampleSquadState,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Tap View Lineup button
      await tester.tap(find.text('View Lineup'));
      await tester.pumpAndSettle();
      expect(find.text('Route: /lineup'), findsOneWidget);
    });
  });
}
