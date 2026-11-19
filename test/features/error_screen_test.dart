import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/analytics/analytics_service.dart';
import 'package:fpl_lens/core/analytics/events.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/features/error/screens/error_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

class MockAnalyticsService extends AnalyticsService {
  MockAnalyticsService() : super(AppDatabase(NativeDatabase.memory()));
}

class FakeSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakeSquadNotifier(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
  });

  Widget createScreen({
    required AppError error,
    VoidCallback? onRetry,
    bool hasSquad = false,
    DateTime? lastUpdated,
  }) {
    final squadData = hasSquad
        ? [
            SquadPlayersTableData(
              id: 1,
              fplId: 101,
              webName: 'Saka',
              position: 'MID',
              teamId: 1,
              teamShortName: 'ARS',
              purchasePriceTenths: 100,
              sellingPriceTenths: 100,
              nowCostTenths: 100,
              status: 'a',
              chanceOfPlayingNextRound: 100,
              isCaptain: false,
              isViceCaptain: false,
              multiplier: 1,
              positionOrder: 7,
              priceSource: 'INITIAL',
              updatedAt: DateTime.now(),
            )
          ]
        : const <SquadPlayersTableData>[];

    return ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
        squadNotifierProvider.overrideWith(
          (ref) => FakeSquadNotifier(
            SquadState(
              squad: squadData,
              lastSyncTime: lastUpdated,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: ErrorScreen(
          error: error,
          onRetry: onRetry,
          fromScreen: 'test_screen',
          lastUpdated: lastUpdated,
        ),
      ),
    );
  }

  group('P20 ErrorScreen Tests', () {
    testWidgets('Renders offline error copy from §B7', (tester) async {
      const error = AppError(
        kind: AppErrorKind.offline,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(createScreen(error: error));
      await tester.pumpAndSettle();

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text("You're offline. Check your internet connection."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      expect(mockAnalytics.recordedEvents.length, 1);
      expect(mockAnalytics.recordedEvents.first.name, AnalyticsEventName.errorShown);
      expect(mockAnalytics.recordedEvents.first.properties['error_kind'], 'offline');
    });

    testWidgets('Renders server error copy from §B7', (tester) async {
      const error = AppError(
        kind: AppErrorKind.server,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(createScreen(error: error));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('Something went wrong on our side. Try again.'), findsOneWidget);
    });

    testWidgets('Shows "Go to saved data" when stored data exists', (tester) async {
      const error = AppError(
        kind: AppErrorKind.timeout,
        message: '',
        retryable: true,
      );

      final dt = DateTime(2026, 11, 19, 14, 30);
      await tester.pumpWidget(createScreen(
        error: error,
        hasSquad: true,
        lastUpdated: dt,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Connection timed out'), findsOneWidget);
      expect(find.text('Go to saved data'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.textContaining('Last updated'), findsOneWidget);
    });

    testWidgets('Tapping Try again invokes onRetry callback', (tester) async {
      bool retried = false;
      const error = AppError(
        kind: AppErrorKind.offline,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(createScreen(
        error: error,
        onRetry: () => retried = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('P20 renders cleanly without overflow at 360 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const error = AppError(
        kind: AppErrorKind.projectionsUnavailable,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(createScreen(
        error: error,
        hasSquad: true,
        lastUpdated: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Projections unavailable'), findsOneWidget);
    });

    testWidgets('P20 renders cleanly without overflow at 430 dp in dark theme', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const error = AppError(
        kind: AppErrorKind.rateLimited,
        message: '',
        retryable: true,
        retryAfterMinutes: 10,
      );

      await tester.pumpWidget(createScreen(error: error));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Too many attempts'), findsOneWidget);
      expect(find.text('Too many attempts. Try again in 10 minutes.'), findsOneWidget);
    });
  });
}
