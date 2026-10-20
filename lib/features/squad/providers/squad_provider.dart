import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/secure_store.dart';
import '../../../data/models/fpl_models.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../auth/providers/auth_provider.dart';

enum SquadLoadingStep {
  idle,
  step1TeamDetails,
  step2SquadPicks,
  step3Transfers,
  step4History,
  completed,
  failed,
}

class SquadState {
  final SquadLoadingStep step;
  final EntryModel? entry;
  final List<SquadPlayersTableData> squad;
  final List<TransferHistoryTableData> transfers;
  final List<GameweekHistoryTableData> gameweekHistory;
  final int unconfirmedCount;
  final GameweekMetadata? currentGameweek;
  final GameweekMetadata? nextGameweek;
  final int bankTenths;
  final int squadValueTenths;
  final int freeTransfers;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final AppError? error;
  final int? failedStep;
  final bool isPartialFailure;

  const SquadState({
    this.step = SquadLoadingStep.idle,
    this.entry,
    this.squad = const [],
    this.transfers = const [],
    this.gameweekHistory = const [],
    this.unconfirmedCount = 0,
    this.currentGameweek,
    this.nextGameweek,
    this.bankTenths = 0,
    this.squadValueTenths = 1000,
    this.freeTransfers = 1,
    this.lastSyncTime,
    this.errorMessage,
    this.error,
    this.failedStep,
    this.isPartialFailure = false,
  });

  bool get hasSquad => squad.isNotEmpty;
  bool get isLoading =>
      step == SquadLoadingStep.step1TeamDetails ||
      step == SquadLoadingStep.step2SquadPicks ||
      step == SquadLoadingStep.step3Transfers ||
      step == SquadLoadingStep.step4History;

  SquadState copyWith({
    SquadLoadingStep? step,
    EntryModel? entry,
    List<SquadPlayersTableData>? squad,
    List<TransferHistoryTableData>? transfers,
    List<GameweekHistoryTableData>? gameweekHistory,
    int? unconfirmedCount,
    GameweekMetadata? currentGameweek,
    GameweekMetadata? nextGameweek,
    int? bankTenths,
    int? squadValueTenths,
    int? freeTransfers,
    DateTime? lastSyncTime,
    String? errorMessage,
    AppError? error,
    int? failedStep,
    bool? isPartialFailure,
  }) {
    return SquadState(
      step: step ?? this.step,
      entry: entry ?? this.entry,
      squad: squad ?? this.squad,
      transfers: transfers ?? this.transfers,
      gameweekHistory: gameweekHistory ?? this.gameweekHistory,
      unconfirmedCount: unconfirmedCount ?? this.unconfirmedCount,
      currentGameweek: currentGameweek ?? this.currentGameweek,
      nextGameweek: nextGameweek ?? this.nextGameweek,
      bankTenths: bankTenths ?? this.bankTenths,
      squadValueTenths: squadValueTenths ?? this.squadValueTenths,
      freeTransfers: freeTransfers ?? this.freeTransfers,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
      error: error,
      failedStep: failedStep,
      isPartialFailure: isPartialFailure ?? this.isPartialFailure,
    );
  }
}

class SquadNotifier extends StateNotifier<SquadState> {
  final FplRepository _fplRepo;
  final AppDatabase _db;
  final SecureStore _secureStore;
  StreamSubscription? _squadSub;

  SquadNotifier({
    required FplRepository fplRepo,
    required AppDatabase db,
    required SecureStore secureStore,
  })  : _fplRepo = fplRepo,
        _db = db,
        _secureStore = secureStore,
        super(const SquadState()) {
    _init();
  }

  @override
  void dispose() {
    _squadSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Watch squad players stream from Drift
    _squadSub = _db.watchSquadPlayers().listen((players) async {
      if (!mounted) return;
      final unconfirmed = await _db.getUnconfirmedPricesCount();
      if (!mounted) return;
      final transfers = await _db.getTransferHistory();
      if (!mounted) return;
      final gwHistory = await _db.getGameweekHistory();
      if (!mounted) return;

      state = state.copyWith(
        squad: players,
        unconfirmedCount: unconfirmed,
        transfers: transfers,
        gameweekHistory: gwHistory,
        step: players.isNotEmpty ? SquadLoadingStep.completed : state.step,
      );
    });
  }

  /// 4-step sequence per Frontend Plan P6:
  /// 1. Team details
  /// 2. Squad for this gameweek
  /// 3. Transfer history
  /// 4. Gameweek history
  Future<void> loadSquadSequence(int teamId, {bool force = false}) async {
    state = state.copyWith(
      step: SquadLoadingStep.step1TeamDetails,
      errorMessage: null,
      error: null,
      failedStep: null,
      isPartialFailure: false,
    );

    // --- STEP 1: Team details ---
    EntryModel? entry;
    try {
      entry = await _fplRepo.getEntry(teamId);
      state = state.copyWith(
        entry: entry,
        step: SquadLoadingStep.step2SquadPicks,
      );
    } catch (e) {
      final appError = ErrorMapper.fromException(e);
      state = state.copyWith(
        step: SquadLoadingStep.failed,
        failedStep: 1,
        error: appError,
        errorMessage: appError.message,
      );
      return;
    }

    // --- STEP 2: Squad for current gameweek ---
    SquadPicksResponse? squadResp;
    CurrentGameweekResponse? currentGwResp;
    List<TransferItemModel> rawTransfers = [];
    try {
      currentGwResp = await _fplRepo.getCurrentGameweek();
      squadResp = await _fplRepo.getSquad(teamId, gw: currentGwResp.current?.id, force: force);

      // Also fetch transfers for price derivation
      rawTransfers = await _fplRepo.getTransfers(teamId);

      // Search players to get names and positions if available
      final playersSearch = await _fplRepo.searchPlayers('', limit: 50);
      final playerInfoMap = {
        for (final p in playersSearch) (p['fpl_id'] as int): p,
      };

      // Query saved prices from Drift
      final savedPrices = await _db.select(_db.purchasePricesTable).get();
      final savedPricesMap = {
        for (final sp in savedPrices) sp.playerFplId: sp,
      };

      final companionList = <SquadPlayersTableCompanion>[];

      for (int i = 0; i < squadResp.picks.length; i++) {
        final pick = squadResp.picks[i];
        final info = playerInfoMap[pick.element];

        final webName = pick.webName ?? (info?['web_name'] as String?) ?? 'Player ${pick.element}';
        final position = pick.playerPosition ?? (info?['position'] as String?) ?? _defaultPosition(pick.position);
        final teamShortName = pick.teamShortName ?? (info?['team_short_name'] as String?) ?? 'PL';
        final nowCost = pick.nowCost ?? (info?['now_cost'] as int?) ?? 60;
        final status = pick.status ?? (info?['status'] as String?) ?? 'a';
        final chance = pick.chanceOfPlayingNextRound ?? (info?['chance_of_playing_next_round'] as int?);

        final saved = savedPricesMap[pick.element];
        final derived = _fplRepo.derivePlayerPrice(
          playerFplId: pick.element,
          nowCostTenths: nowCost,
          transferHistory: rawTransfers,
          savedPurchasePriceTenths: saved?.purchasePriceTenths,
          isUserConfirmed: saved?.isConfirmed,
        );

        // Upsert purchase price record
        await _db.upsertPurchasePrice(
          playerFplId: pick.element,
          purchasePriceTenths: derived.purchasePriceTenths,
          source: derived.priceSource,
          isConfirmed: derived.isConfirmed,
        );

        companionList.add(
          SquadPlayersTableCompanion(
            fplId: drift.Value(pick.element),
            webName: drift.Value(webName),
            position: drift.Value(position),
            teamId: drift.Value(pick.teamFplId ?? (info?['team_fpl_id'] as int?) ?? 1),
            teamShortName: drift.Value(teamShortName),
            purchasePriceTenths: drift.Value(derived.purchasePriceTenths),
            sellingPriceTenths: drift.Value(derived.sellingPriceTenths),
            nowCostTenths: drift.Value(nowCost),
            status: drift.Value(status),
            chanceOfPlayingNextRound: drift.Value(chance),
            isCaptain: drift.Value(pick.isCaptain),
            isViceCaptain: drift.Value(pick.isViceCaptain),
            multiplier: drift.Value(pick.multiplier),
            positionOrder: drift.Value(pick.position),
            priceSource: drift.Value(derived.priceSource),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      // Commit squad to Drift
      await _db.replaceSquad(companionList);

      final bank = (squadResp.entryHistory?['bank'] as int?) ?? 0;
      final value = (squadResp.entryHistory?['value'] as int?) ?? 1000;

      state = state.copyWith(
        currentGameweek: currentGwResp.current,
        nextGameweek: currentGwResp.next,
        bankTenths: bank,
        squadValueTenths: value,
        step: SquadLoadingStep.step3Transfers,
      );
    } catch (e) {
      // Squad step failure: the whole load stops per P6
      final appError = ErrorMapper.fromException(e);
      state = state.copyWith(
        step: SquadLoadingStep.failed,
        failedStep: 2,
        error: appError,
        errorMessage: appError.message,
      );
      return;
    }

    // --- STEP 3: Transfer history ---
    try {
      final transferCompanions = rawTransfers.map((t) {
        return TransferHistoryTableCompanion(
          elementInFplId: drift.Value(t.elementIn),
          elementInCostTenths: drift.Value(t.elementInCost),
          elementInName: drift.Value(t.elementInName ?? 'Player #${t.elementIn}'),
          elementOutFplId: drift.Value(t.elementOut),
          elementOutCostTenths: drift.Value(t.elementOutCost),
          elementOutName: drift.Value(t.elementOutName ?? 'Player #${t.elementOut}'),
          gameweek: drift.Value(t.event),
          transferTime: drift.Value(t.time),
        );
      }).toList();

      await _db.replaceTransferHistory(transferCompanions);
      state = state.copyWith(step: SquadLoadingStep.step4History);
    } catch (e) {
      // History/transfer failure after squad step: load completes with partial warning per P6
      state = state.copyWith(
        isPartialFailure: true,
        step: SquadLoadingStep.completed,
        lastSyncTime: DateTime.now(),
      );
      return;
    }

    // --- STEP 4: Gameweek history ---
    try {
      final historyResp = await _fplRepo.getHistory(teamId);
      final gwCompanions = historyResp.current.map((gw) {
        return GameweekHistoryTableCompanion(
          gameweek: drift.Value(gw.event),
          points: drift.Value(gw.points),
          totalPoints: drift.Value(gw.totalPoints),
          overallRank: drift.Value(gw.overallRank),
          percentileRank: drift.Value(gw.percentileRank),
          eventTransfers: drift.Value(gw.eventTransfers),
          eventTransfersCost: drift.Value(gw.eventTransfersCost),
          pointsOnBench: drift.Value(gw.pointsOnBench),
          bankTenths: drift.Value(gw.bank),
          valueTenths: drift.Value(gw.value),
        );
      }).toList();

      await _db.replaceGameweekHistory(gwCompanions);
      await _secureStore.saveFplTeamId(teamId);

      state = state.copyWith(
        step: SquadLoadingStep.completed,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      // History failure after squad step: load completes with partial warning per P6
      state = state.copyWith(
        isPartialFailure: true,
        step: SquadLoadingStep.completed,
        lastSyncTime: DateTime.now(),
      );
    }
  }

  /// Re-runs only the failed step per P6
  Future<void> retryFailedStep(int teamId) async {
    final failed = state.failedStep;
    if (failed == 1 || failed == null) {
      await loadSquadSequence(teamId);
    } else if (failed == 2) {
      state = state.copyWith(step: SquadLoadingStep.step2SquadPicks);
      await loadSquadSequence(teamId);
    }
  }

  /// Rate-limited pull-to-refresh (once per 15 min per P8 & P9)
  Future<String?> refreshSquad({bool force = false}) async {
    if (!force && state.lastSyncTime != null) {
      final elapsed = DateTime.now().difference(state.lastSyncTime!);
      if (elapsed < const Duration(minutes: 15)) {
        return 'Already up to date';
      }
    }

    final teamId = await _secureStore.getFplTeamId();
    if (teamId != null) {
      await loadSquadSequence(teamId, force: force);
    }
    return null;
  }

  /// Updates a player's purchase price and recomputes selling price per Spec §12.2
  Future<void> confirmPurchasePrice(int playerFplId, int purchasePriceTenths) async {
    await _db.upsertPurchasePrice(
      playerFplId: playerFplId,
      purchasePriceTenths: purchasePriceTenths,
      source: 'CONFIRMED_USER',
      isConfirmed: true,
    );

    // Find player in current squad
    final currentPlayers = await _db.getAllSquadPlayers();
    final updatedList = currentPlayers.map((p) {
      if (p.fplId == playerFplId) {
        final newSelling = _fplRepo.computeSellingPriceTenths(
          purchasePriceTenths: purchasePriceTenths,
          nowCostTenths: p.nowCostTenths,
        );
        return SquadPlayersTableCompanion(
          id: drift.Value(p.id),
          fplId: drift.Value(p.fplId),
          webName: drift.Value(p.webName),
          position: drift.Value(p.position),
          teamId: drift.Value(p.teamId),
          teamShortName: drift.Value(p.teamShortName),
          purchasePriceTenths: drift.Value(purchasePriceTenths),
          sellingPriceTenths: drift.Value(newSelling),
          nowCostTenths: drift.Value(p.nowCostTenths),
          status: drift.Value(p.status),
          chanceOfPlayingNextRound: drift.Value(p.chanceOfPlayingNextRound),
          isCaptain: drift.Value(p.isCaptain),
          isViceCaptain: drift.Value(p.isViceCaptain),
          multiplier: drift.Value(p.multiplier),
          positionOrder: drift.Value(p.positionOrder),
          priceSource: const drift.Value('CONFIRMED_USER'),
          updatedAt: drift.Value(DateTime.now()),
        );
      }
      return SquadPlayersTableCompanion(
        id: drift.Value(p.id),
        fplId: drift.Value(p.fplId),
        webName: drift.Value(p.webName),
        position: drift.Value(p.position),
        teamId: drift.Value(p.teamId),
        teamShortName: drift.Value(p.teamShortName),
        purchasePriceTenths: drift.Value(p.purchasePriceTenths),
        sellingPriceTenths: drift.Value(p.sellingPriceTenths),
        nowCostTenths: drift.Value(p.nowCostTenths),
        status: drift.Value(p.status),
        chanceOfPlayingNextRound: drift.Value(p.chanceOfPlayingNextRound),
        isCaptain: drift.Value(p.isCaptain),
        isViceCaptain: drift.Value(p.isViceCaptain),
        multiplier: drift.Value(p.multiplier),
        positionOrder: drift.Value(p.positionOrder),
        priceSource: drift.Value(p.priceSource),
        updatedAt: drift.Value(p.updatedAt),
      );
    }).toList();

    await _db.replaceSquad(updatedList);
  }

  static String _defaultPosition(int positionOrder) {
    if (positionOrder == 1 || positionOrder == 12) return 'GK';
    if (positionOrder >= 2 && positionOrder <= 5) return 'DEF';
    if (positionOrder >= 6 && positionOrder <= 9) return 'MID';
    return 'FWD';
  }
}

final squadNotifierProvider = StateNotifierProvider<SquadNotifier, SquadState>((ref) {
  final fplRepo = ref.watch(fplRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  final secureStore = ref.watch(secureStoreProvider);

  return SquadNotifier(
    fplRepo: fplRepo,
    db: db,
    secureStore: secureStore,
  );
});
