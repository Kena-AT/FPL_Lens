import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/widgets/app_button.dart';
import 'package:fpl_lens/data/models/squad_resolve_models.dart';
import 'package:fpl_lens/features/scan/screens/resolve_players_screen.dart';

void main() {
  SquadResolveResponse createTestResponse() {
    return const SquadResolveResponse(
      allResolved: false,
      totalSubmitted: 2,
      resolvedCount: 0,
      unresolvedCount: 2,
      results: [
        ResolvedPlayerResult(
          rawName: 'Haland',
          slot: 'FWD',
          exactMatch: false,
          bestConfidence: 0.82,
          candidates: [
            CandidateMatch(
              fplId: 101,
              webName: 'Haaland',
              fullName: 'Erling Haaland',
              teamFplId: 1,
              teamShortName: 'MCI',
              position: 'FWD',
              nowCostTenths: 152,
              confidence: 0.82,
              matchTier: 'possible',
            ),
          ],
        ),
        ResolvedPlayerResult(
          rawName: 'UnknownPlayer',
          slot: 'MID',
          exactMatch: false,
          bestConfidence: 0.45,
          candidates: [
            CandidateMatch(
              fplId: 102,
              webName: 'Palmer',
              fullName: 'Cole Palmer',
              teamFplId: 5,
              teamShortName: 'CHE',
              position: 'MID',
              nowCostTenths: 110,
              confidence: 0.45,
              matchTier: 'weak',
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTestable(Widget child, {double width = 360.0}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: child,
        ),
      ),
    );
  }

  group('P16 ResolvePlayersScreen Widget Tests', () {
    testWidgets('renders paged unclear names and candidate matches at 360 dp', (tester) async {
      final resp = createTestResponse();

      await tester.pumpWidget(
        buildTestable(
          ResolvePlayersScreen(resolveResponse: resp),
          width: 360.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm players'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);

      // Card 1
      expect(find.text('Haland'), findsOneWidget);
      expect(find.text('Slot: FWD'), findsOneWidget);
      expect(find.text('Haaland'), findsWidgets);
      expect(find.text('MCI • FWD • £15.2m'), findsOneWidget);
      expect(find.text('Possible match'), findsOneWidget);

      expect(find.text('None of these (manual entry later)'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Confirm and continue'), findsOneWidget);
    });

    testWidgets('paging works with Next and Previous buttons', (tester) async {
      final resp = createTestResponse();

      await tester.pumpWidget(
        buildTestable(
          ResolvePlayersScreen(resolveResponse: resp),
          width: 360.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Haland'), findsWidgets);

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Card 2
      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('UnknownPlayer'), findsOneWidget);
      expect(find.text('Palmer'), findsOneWidget);
      expect(find.text('Weak match'), findsOneWidget);

      // Tap Previous
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Haland'), findsWidgets);
    });

    testWidgets('allows selecting None of these', (tester) async {
      final resp = createTestResponse();

      await tester.pumpWidget(
        buildTestable(
          ResolvePlayersScreen(resolveResponse: resp),
          width: 360.0,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('None of these (manual entry later)'));
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap None of these on card 2
      await tester.tap(find.text('None of these (manual entry later)'));
      await tester.pumpAndSettle();

      // Both resolved/marked => Confirm and continue is enabled
      final btnFinder = find.widgetWithText(AppButton, 'Confirm and continue');
      final AppButton btn = tester.widget(btnFinder);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('renders properly at 430 dp width', (tester) async {
      final resp = createTestResponse();

      await tester.pumpWidget(
        buildTestable(
          ResolvePlayersScreen(resolveResponse: resp),
          width: 430.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm players'), findsOneWidget);
      expect(find.text('Haland'), findsWidgets);
    });
  });
}
