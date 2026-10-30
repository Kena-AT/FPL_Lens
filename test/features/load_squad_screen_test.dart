import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/storage/secure_store.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/data/models/user_model.dart';
import 'package:fpl_lens/data/repositories/auth_repository.dart';
import 'package:fpl_lens/data/repositories/fpl_repository.dart';
import 'package:fpl_lens/features/auth/providers/auth_provider.dart';
import 'package:fpl_lens/features/onboarding/screens/load_squad_screen.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFplRepository extends Mock implements FplRepository {}
class MockSecureStore extends Mock implements SecureStore {}
class MockAppDatabase extends Mock implements AppDatabase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockFplRepository mockFplRepo;
  late MockSecureStore mockSecureStore;
  late MockAppDatabase mockDb;

  setUp(() {
    mockFplRepo = MockFplRepository();
    mockSecureStore = MockSecureStore();
    mockDb = MockAppDatabase();

    when(() => mockSecureStore.getFplTeamId()).thenAnswer((_) async => 2354349);
    when(() => mockSecureStore.saveFplTeamId(any())).thenAnswer((_) async {});
    when(() => mockDb.watchSquadPlayers()).thenAnswer((_) => const Stream.empty());
    when(() => mockDb.getUnconfirmedPricesCount()).thenAnswer((_) async => 0);
    when(() => mockDb.getTransferHistory()).thenAnswer((_) async => []);
    when(() => mockDb.getGameweekHistory()).thenAnswer((_) async => []);
  });

  Widget buildTestApp({
    int teamId = 2354349,
  }) {
    final router = GoRouter(
      initialLocation: '/onboarding/load',
      routes: [
        GoRoute(
          path: '/onboarding/load',
          builder: (_, __) => LoadSquadScreen(teamId: teamId),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Screen: Home')),
        ),
        GoRoute(
          path: '/onboarding/team',
          builder: (_, __) => const Scaffold(body: Text('Screen: TeamCheck')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => SquadNotifier(
              fplRepo: mockFplRepo,
              db: mockDb,
              secureStore: mockSecureStore,
            )),
        authNotifierProvider.overrideWith((ref) => AuthNotifier(
              repository: MockAuthRepository(),
              secureStore: mockSecureStore,
            )..setInitialState(const AuthState(
                status: AuthStatus.authenticatedVerified,
                user: UserModel(
                  id: 'u1',
                  email: 'test@example.com',
                  displayName: 'Test',
                  status: 'active',
                  fplTeamId: 2354349,
                ),
              ))),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('LoadSquadScreen displays 4 loading steps and progress bar', (tester) async {
    when(() => mockFplRepo.getEntry(any())).thenAnswer((_) async => Completer<EntryModel>().future);

    await tester.pumpWidget(
      buildTestApp(),
    );
    await tester.pump();

    expect(find.text('Loading your squad'), findsOneWidget);
    expect(find.text('Team details'), findsOneWidget);
    expect(find.text('Squad for this gameweek'), findsOneWidget);
    expect(find.text('Transfer history'), findsOneWidget);
    expect(find.text('Gameweek history'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

extension on AuthNotifier {
  void setInitialState(AuthState authState) {
    state = authState;
  }
}
