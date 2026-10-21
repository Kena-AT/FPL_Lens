import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/storage/app_database.dart';
import 'package:fpl_lens/data/models/fpl_models.dart';
import 'package:fpl_lens/features/squad/providers/squad_provider.dart';
import 'package:fpl_lens/features/transfers/screens/transfer_lab_screen.dart';

class FakeSquadNotifier extends StateNotifier<SquadState> implements SquadNotifier {
  FakeSquadNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  List<SquadPlayersTableData> generate15Players() {
    final positions = [
      ('GK', 1), ('GK', 12),
      ('DEF', 2), ('DEF', 3), ('DEF', 4), ('DEF', 5), ('DEF', 13),
      ('MID', 6), ('MID', 7), ('MID', 8), ('MID', 9), ('MID', 14),
      ('FWD', 10), ('FWD', 11), ('FWD', 15),
    ];

    return positions.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final pos = entry.value.$1;
      final order = entry.value.$2;

      return SquadPlayersTableData(
        id: i,
        fplId: 200 + i,
        webName: 'Player $i',
        position: pos,
        teamId: (i % 6) + 1,
        teamShortName: 'T${(i % 6) + 1}',
        nowCostTenths: 60,
        purchasePriceTenths: 60,
        sellingPriceTenths: 60,
        priceSource: 'CONFIRM',
        status: 'a',
        chanceOfPlayingNextRound: 100,
        isCaptain: i == 10,
        isViceCaptain: i == 11,
        multiplier: i == 10 ? 2 : 1,
        positionOrder: order,
        updatedAt: DateTime(2026, 10, 20),
      );
    }).toList();
  }

  Widget buildScreen(SquadState squadState) {
    return ProviderScope(
      overrides: [
        squadNotifierProvider.overrideWith((ref) => FakeSquadNotifier(squadState)),
      ],
      child: const MaterialApp(
        home: TransferLabScreen(runInBackground: false),
      ),
    );
  }

  testWidgets('TransferLabScreen renders empty state when no squad loaded', (tester) async {
    await tester.pumpWidget(buildScreen(const SquadState(squad: [])));
    await tester.pumpAndSettle();

    expect(find.text('No squad loaded'), findsOneWidget);
  });

  testWidgets('TransferLabScreen renders incomplete squad message when squad has fewer than 15 players', (tester) async {
    final incompleteSquad = generate15Players().take(12).toList();
    final state = SquadState(
      squad: incompleteSquad,
      bankTenths: 15,
      freeTransfers: 1,
    );

    await tester.pumpWidget(buildScreen(state));
    await tester.pumpAndSettle();

    expect(find.text('Incomplete squad (12/15)'), findsOneWidget);
    expect(find.textContaining('Your squad must contain exactly 15 players'), findsOneWidget);
  });

  testWidgets('TransferLabScreen renders with 15 player squad and runs optimiser', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final squad = generate15Players();
    final state = SquadState(
      squad: squad,
      bankTenths: 15,
      freeTransfers: 1,
      currentGameweek: const GameweekMetadata(id: 8, name: 'Gameweek 8'),
      nextGameweek: const GameweekMetadata(id: 9, name: 'Gameweek 9'),
    );

    await tester.pumpWidget(buildScreen(state));
    await tester.pumpAndSettle();

    expect(find.text('Transfer Lab'), findsOneWidget);
    expect(find.text('Find Optimal Transfers'), findsOneWidget);

    // Tap Find Optimal Transfers
    await tester.tap(find.text('Find Optimal Transfers'));
    await tester.pump();
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('PROJECTED LINEUP').evaluate().isNotEmpty) break;
    }

    expect(find.text('PROJECTED LINEUP'), findsOneWidget);

    // Switch to Horizon 3
    await tester.tap(find.text('H3'));
    await tester.pump();
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('PROJECTED LINEUP').evaluate().isNotEmpty) break;
    }
    expect(find.text('PROJECTED LINEUP'), findsOneWidget);

    // Switch to Horizon 5
    await tester.tap(find.text('H5'));
    await tester.pump();
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('PROJECTED LINEUP').evaluate().isNotEmpty) break;
    }
    expect(find.text('PROJECTED LINEUP'), findsOneWidget);

    // Tap on a player chip in pitch view to open candidate picker
    final playerFinder = find.text('Player 1').first;
    await tester.tap(playerFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Select Player'), findsOneWidget);
  });
}
