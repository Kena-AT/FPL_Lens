import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/analytics/analytics_service.dart';
import 'package:fpl_lens/core/network/error_mapper.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/features/auth/screens/register_screen.dart';
import 'package:fpl_lens/features/auth/screens/sign_in_screen.dart';
import 'package:fpl_lens/features/auth/screens/verify_email_screen.dart';
import 'package:fpl_lens/features/error/screens/error_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late AnalyticsService analytics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    analytics = AnalyticsService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildWithScale(Widget child, {double textScale = 2.0, Size size = const Size(360, 800)}) {
    return ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        squadNotifierProvider.overrideWith(
          (ref) => FakeSquadNotifier(
            const SquadState(squad: []),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Part H Responsive Layout & 200% Text Scaling Tests', () {
    testWidgets('P2 SignInScreen renders cleanly at 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWithScale(const SignInScreen(), textScale: 2.0));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('P3 RegisterScreen renders cleanly at 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWithScale(const RegisterScreen(), textScale: 2.0));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Create account'), findsWidgets);
    });

    testWidgets('P4 VerifyEmailScreen renders cleanly at 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWithScale(const VerifyEmailScreen(), textScale: 2.0));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Check your email'), findsOneWidget);
    });

    testWidgets('P20 ErrorScreen renders cleanly at 200% text scale at 360 dp', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const error = AppError(
        kind: AppErrorKind.offline,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(buildWithScale(
        const ErrorScreen(error: error),
        textScale: 2.0,
      ));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('P20 ErrorScreen renders cleanly at 430 dp width in dark theme', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const error = AppError(
        kind: AppErrorKind.server,
        message: '',
        retryable: true,
      );

      await tester.pumpWidget(buildWithScale(
        const ErrorScreen(error: error),
        textScale: 1.0,
        size: const Size(430, 932),
      ));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);
      expect(find.text('Server error'), findsOneWidget);
    });
  });
}

class FakeSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakeSquadNotifier(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
