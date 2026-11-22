import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/core/widgets/app_loading_indicator.dart';
import 'package:fpl_lens/core/widgets/availability_badge.dart';
import 'package:fpl_lens/core/widgets/card_container.dart';
import 'package:fpl_lens/core/widgets/delta_chip.dart';
import 'package:fpl_lens/core/widgets/glass_container.dart';
import 'package:fpl_lens/core/widgets/stat_badge.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/auth/screens/register_screen.dart';
import 'package:fpl_lens/features/auth/screens/sign_in_screen.dart';
import 'package:fpl_lens/features/auth/screens/splash_screen.dart';
import 'package:fpl_lens/features/auth/screens/verify_email_screen.dart';
import 'package:fpl_lens/features/onboarding/screens/load_squad_screen.dart';
import 'package:fpl_lens/features/onboarding/screens/team_check_screen.dart';
import 'package:fpl_lens/features/settings/screens/settings_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockFplRepository extends FplRepository {
  MockFplRepository() : super(dio: null);

  @override
  Future<EntryModel> getEntry(int teamId) async {
    return const EntryModel(
      id: 12345,
      name: 'Redesign FC',
      playerFirstName: 'Alex',
      playerLastName: 'Ferguson',
      summaryOverallPoints: 1240,
      summaryOverallRank: 42000,
    );
  }
}

class MockSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  MockSquadNotifier([super.state = const SquadState(step: SquadLoadingStep.step2SquadPicks)]);

  @override
  Future<void> loadSquadSequence(int teamId, {bool force = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase inMemoryDb;

  setUp(() {
    inMemoryDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  Widget buildTestHost({
    required Widget screen,
    ThemeMode themeMode = ThemeMode.dark,
    double textScale = 2.0,
    bool disableAnimations = true,
    List<Override> overrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
        GoRoute(path: '/auth', builder: (_, __) => const Scaffold(body: Text('Route: /auth'))),
        GoRoute(path: '/auth/register', builder: (_, __) => const Scaffold(body: Text('Route: /auth/register'))),
        GoRoute(path: '/auth/verify', builder: (_, __) => const Scaffold(body: Text('Route: /auth/verify'))),
        GoRoute(path: '/onboarding/team', builder: (_, __) => const Scaffold(body: Text('Route: /onboarding/team'))),
        GoRoute(path: '/onboarding/load', builder: (_, __) => const Scaffold(body: Text('Route: /onboarding/load'))),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('Route: /home'))),
      ],
    );

    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(inMemoryDb),
        ...overrides,
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

  group('Section 3A Audit: 200% Text Scale & Reduced Motion on 360dp Viewport', () {
    const narrowViewport = Size(360, 800);

    // -------------------------------------------------------------------------
    // Sprint R2 Shared Components
    // -------------------------------------------------------------------------
    testWidgets('Sprint R2 Components render cleanly at 200% text scale with reduced motion', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestHost(
          screen: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const GlassContainer(
                    child: Text('Glass Card Content'),
                  ),
                  const StatBadge(label: 'DEADLINE', value: '2d 14h', size: StatBadgeSize.hero),
                  const StatBadge(label: 'SQUAD VALUE', value: '£102.4m', size: StatBadgeSize.large),
                  const AvailabilityBadge(variant: AvailabilityVariant.fit),
                  const AvailabilityBadge(variant: AvailabilityVariant.doubtful, chanceOfPlaying: 75),
                  const AvailabilityBadge(variant: AvailabilityVariant.injured),
                  DeltaChip.price(delta: 0.2),
                  DeltaChip.points(delta: 4.5),
                  DeltaChip.rank(rankDelta: 120),
                  const CardContainer(child: Text('Card Content')),
                  const AppLoadingIndicator.linear(value: 0.5),
                  const AppLoadingIndicator(value: 0.5),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // Sprint R1 Settings Screen
    // -------------------------------------------------------------------------
    testWidgets('SettingsScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      final notifier = AuthNotifier(
        repository: container.read(authRepositoryProvider),
        secureStore: container.read(secureStoreProvider),
      )..state = AuthState(
          status: AuthStatus.authenticatedVerified,
          user: UserModel(
            id: 'user-audit',
            email: 'audit@example.com',
            displayName: 'Audit Manager',
            fplTeamId: 999999,
            status: 'active',
            emailVerifiedAt: DateTime.now(),
          ),
        );

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const SettingsScreen(),
            themeMode: mode,
            overrides: [
              authNotifierProvider.overrideWith((ref) => notifier),
            ],
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });

    // -------------------------------------------------------------------------
    // Sprint R3 SplashScreen
    // -------------------------------------------------------------------------
    testWidgets('SplashScreen renders without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestHost(
          screen: const SplashScreen(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // Sprint R3 SignInScreen
    // -------------------------------------------------------------------------
    testWidgets('SignInScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const SignInScreen(),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });

    // -------------------------------------------------------------------------
    // Sprint R3 RegisterScreen
    // -------------------------------------------------------------------------
    testWidgets('RegisterScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const RegisterScreen(),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });

    // -------------------------------------------------------------------------
    // Sprint R3 VerifyEmailScreen
    // -------------------------------------------------------------------------
    testWidgets('VerifyEmailScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const VerifyEmailScreen(),
            themeMode: mode,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });

    // -------------------------------------------------------------------------
    // Sprint R3 TeamCheckScreen
    // -------------------------------------------------------------------------
    testWidgets('TeamCheckScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const TeamCheckScreen(),
            themeMode: mode,
            overrides: [
              fplRepositoryProvider.overrideWithValue(MockFplRepository()),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });

    // -------------------------------------------------------------------------
    // Sprint R3 LoadSquadScreen
    // -------------------------------------------------------------------------
    testWidgets('LoadSquadScreen renders without overflow at 200% text scale in dark and light modes', (tester) async {
      tester.view.physicalSize = narrowViewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          buildTestHost(
            screen: const LoadSquadScreen(teamId: 12345),
            themeMode: mode,
            overrides: [
              squadNotifierProvider.overrideWith(
                (ref) => MockSquadNotifier(
                  const SquadState(step: SquadLoadingStep.step2SquadPicks),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Failed in mode: $mode');
      }
    });
  });
}
