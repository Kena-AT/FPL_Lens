import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/core/theme/app_theme.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';
import 'package:fpl_lens/features/squad/screens/purchase_prices_screen.dart';

class FakePurchasePriceSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakePurchasePriceSquadNotifier(super.state);

  int? lastConfirmedId;
  int? lastConfirmedPrice;

  @override
  Future<void> confirmPurchasePrice(int fplId, int purchasePriceTenths) async {
    lastConfirmedId = fplId;
    lastConfirmedPrice = purchasePriceTenths;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleSquad = [
    SquadPlayersTableData(
      id: 1,
      fplId: 101,
      webName: 'Saka',
      position: 'MID',
      teamId: 1,
      teamShortName: 'ARS',
      nowCostTenths: 102,
      purchasePriceTenths: 100,
      sellingPriceTenths: 101,
      priceSource: 'CONFIRM',
      status: 'a',
      chanceOfPlayingNextRound: 100,
      isCaptain: false,
      isViceCaptain: false,
      multiplier: 1,
      positionOrder: 1,
      updatedAt: DateTime(2026, 10, 20),
    ),
  ];

  Widget buildScreen({
    ThemeMode mode = ThemeMode.dark,
    double textScale = 1.0,
    FakePurchasePriceSquadNotifier? notifier,
  }) {
    final fakeNotifier = notifier ??
        FakePurchasePriceSquadNotifier(
          SquadState(
            squad: sampleSquad,
            bankTenths: 15,
          ),
        );

    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => fakeNotifier),
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
          child: const PurchasePricesScreen(),
        ),
      ),
    );
  }

  group('PurchasePricesScreen Redesign Tests', () {
    testWidgets('Renders bank hero, formula note, and price steppers', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Purchase Prices'), findsOneWidget);
      expect(find.text('In The Bank'), findsOneWidget);
      expect(find.text('£1.5m'), findsWidgets);
      expect(find.text('Estimated'), findsOneWidget);
      expect(
        find.text(
          'Selling price is estimated as: purchase price, plus half of any rise since you bought (rounded down). This rule is not yet verified against official FPL rules.',
        ),
        findsOneWidget,
      );

      expect(find.text('Saka'), findsOneWidget);
      expect(find.text('£10.0m'), findsOneWidget);
      expect(find.text('Confirm & Save Prices'), findsOneWidget);
    });

    testWidgets('Steppers adjust price and recalculate selling price', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap + button to increase price by 0.1m
      final plusButton = find.byTooltip('Increase purchase price by £0.1m');
      expect(plusButton, findsOneWidget);
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      expect(find.text('£10.1m'), findsWidgets);
    });

    testWidgets('Renders in light mode at 200% text scale without overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScreen(mode: ThemeMode.light, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(find.text('Purchase Prices'), findsOneWidget);
      expect(find.text('Confirm & Save Prices'), findsOneWidget);
    });
  });
}
