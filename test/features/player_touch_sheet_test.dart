import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/engine/layer3/player_touch_viewmodel.dart';
import 'package:fpl_lens/core/engine/layer3/transfer_engine_v2.dart';
import 'package:fpl_lens/core/optimiser/player_candidate.dart';
import 'package:fpl_lens/features/lineup/player_touch_sheet.dart';

PlayerCandidate _p(
  int id,
  String name,
  String pos, {
  int clubId = 1,
  int price = 60,
  int sell = 60,
  double xp = 4.0,
  double pStart = 0.95,
  double pSub = 0.03,
}) {
  return PlayerCandidate(
    fplId: id,
    webName: name,
    position: pos,
    clubId: clubId,
    priceTenths: price,
    sellingPriceTenths: sell,
    xp: xp,
    pStart: pStart,
    pSub: pSub,
  );
}

List<PlayerCandidate> _squad15() {
  return [
    _p(1, 'Raya', 'GK', clubId: 1, xp: 4.5),
    _p(2, 'Fabianski', 'GK', clubId: 2, xp: 1.0, pStart: 0.2, pSub: 0.05),
    _p(3, 'Saliba', 'DEF', clubId: 1, xp: 4.8),
    _p(4, 'Gabriel', 'DEF', clubId: 3, xp: 4.7),
    _p(5, 'Gvardiol', 'DEF', clubId: 4, xp: 4.6),
    _p(6, 'Konsa', 'DEF', clubId: 5, xp: 3.2),
    _p(7, 'Greaves', 'DEF', clubId: 6, xp: 2.0),
    _p(8, 'Saka', 'MID', clubId: 1, xp: 7.4),
    _p(9, 'Palmer', 'MID', clubId: 7, xp: 7.2),
    _p(10, 'Salah', 'MID', clubId: 8, xp: 8.2),
    _p(11, 'Mbeumo', 'MID', clubId: 9, xp: 5.5),
    _p(12, 'Rogers', 'MID', clubId: 5, xp: 3.5),
    _p(13, 'Haaland', 'FWD', clubId: 4, price: 150, sell: 150, xp: 8.6),
    _p(14, 'Watkins', 'FWD', clubId: 5, xp: 6.0),
    _p(15, 'Wood', 'FWD', clubId: 10, price: 60, sell: 60, xp: 2.0),
  ];
}

void main() {
  group('Sprint E5: PlayerTouchSheet & G-UI Consistency', () {
    test('G-UI: PlayerTouchViewModel matches TransferEngineV2 net gain and hit cost', () {
      final squad = _squad15();
      final wood = squad.last;
      final starIn = _p(901, 'Isak', 'FWD', clubId: 11, price: 75, sell: 75, xp: 8.0);
      final now = DateTime.utc(2026, 11, 28, 12, 0);

      final vm = PlayerTouchViewModelBuilder.build(
        outgoingPlayer: wood,
        currentSquad: squad,
        availablePool: [starIn],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        isBenchPlayer: false,
        snapshotFetchedAt: now.subtract(const Duration(minutes: 5)),
        now: now,
      );

      final engineRec = TransferEngineV2.recommend(
        currentSquad: squad,
        availablePool: [starIn],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        allowDoubleSwaps: false,
      );

      expect(vm.topOptions, isNotEmpty);
      expect(vm.topOptions.first.incomingPlayer.fplId, engineRec.transfersIn.single.fplId);
      expect(vm.topOptions.first.rawGain, closeTo(engineRec.rawGain, 1e-9));
      expect(vm.topOptions.first.hitCost, engineRec.hitCost);
      expect(vm.topOptions.first.formattedPriceDelta, '£1.5m more');
    });

    test('Stale snapshot pauses transfer options (§10.4, I16)', () {
      final squad = _squad15();
      final wood = squad.last;
      final now = DateTime.utc(2026, 11, 28, 12, 0);

      final vm = PlayerTouchViewModelBuilder.build(
        outgoingPlayer: wood,
        currentSquad: squad,
        availablePool: [_p(901, 'Isak', 'FWD', clubId: 11, price: 75, xp: 8.0)],
        bankTenths: 20,
        freeTransfersAvailable: 1,
        isBenchPlayer: false,
        snapshotFetchedAt: now.subtract(const Duration(minutes: 45)),
        now: now,
      );

      expect(vm.isStale, isTrue);
      expect(vm.topOptions, isEmpty);
      expect(vm.emptyReason, contains('Transfer options are paused until new data arrives'));
    });

    testWidgets('Renders all §10.1 sections without overflow at 200% text scale on 360dp', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final squad = _squad15();
      final wood = squad.last;
      final pool = List.generate(
        5,
        (i) => _p(910 + i, 'Target$i', 'FWD', clubId: 11 + i, price: 65, xp: 7.5 - i * 0.3),
      );
      final now = DateTime.utc(2026, 11, 28, 12, 0);
      final vm = PlayerTouchViewModelBuilder.build(
        outgoingPlayer: wood,
        currentSquad: squad,
        availablePool: pool,
        bankTenths: 20,
        freeTransfersAvailable: 1,
        isBenchPlayer: false,
        snapshotFetchedAt: now,
        now: now,
      );

      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(
          MaterialApp(
            themeMode: mode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: PlayerTouchSheet(
                  viewModel: vm,
                  gameweek: 13,
                  onMakeCaptain: () {},
                  onMakeViceCaptain: () {},
                  onClearOverrides: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow or error in $mode');
        expect(find.text('TRANSFER OPTIONS'), findsOneWidget);
        expect(find.text('Compare more options'), findsOneWidget);
        expect(find.text('Make Captain'), findsOneWidget);
        expect(find.text('xP CALCULATION EXPLANATION'), findsOneWidget);
        expect(find.text('View Fixture Heatmap'), findsOneWidget);
        expect(find.text('View Player Details'), findsOneWidget);
      }
    });

    testWidgets('Bench player blocks captaincy with standardized message', (tester) async {
      final squad = _squad15();
      final vm = PlayerTouchViewModel(
        outgoingPlayer: squad[6],
        isBenchPlayer: true,
        isStale: false,
        confidence: 'MEDIUM',
        topOptions: const [],
        allOptions: const [],
        emptyReason: PlayerTouchMessages.noBudget,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerTouchSheet(
              viewModel: vm,
              gameweek: 13,
              onMakeCaptain: () {},
              onMakeViceCaptain: () {},
              onClearOverrides: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(PlayerTouchMessages.benchNote), findsOneWidget);
      expect(find.text(PlayerTouchMessages.noBudget), findsOneWidget);
      expect(find.text(PlayerTouchMessages.captainBenchBlocked), findsOneWidget);
      expect(find.text('Make Captain'), findsNothing);
    });
  });
}
