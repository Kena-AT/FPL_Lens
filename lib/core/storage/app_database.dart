import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// 1. Squad players stored on the device (Part K). Replaced on each squad sync.
class SquadPlayersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fplId => integer()();
  TextColumn get webName => text()();
  TextColumn get position => text()(); // GKP, DEF, MID, FWD
  IntColumn get teamId => integer()();
  TextColumn get teamShortName => text()();
  IntColumn get purchasePriceTenths => integer()();
  IntColumn get sellingPriceTenths => integer()();
  IntColumn get nowCostTenths => integer()();
  TextColumn get status => text()(); // available, doubtful, out
  TextColumn get news => text().nullable()();
  IntColumn get chanceOfPlayingNextRound => integer().nullable()();
  BoolColumn get isCaptain => boolean().withDefault(const Constant(false))();
  BoolColumn get isViceCaptain => boolean().withDefault(const Constant(false))();
  IntColumn get multiplier => integer().withDefault(const Constant(1))();
  IntColumn get positionOrder => integer()(); // 1 to 15 (1-11 XI, 12-15 bench)
  TextColumn get priceSource => text()(); // FROM_TRANSFER, CONFIRM, CONFIRMED_USER, DEFAULTED_CURRENT
  DateTimeColumn get updatedAt => dateTime()();
}

/// 2. Purchase prices per player (Part K). Source label per player.
class PurchasePricesTable extends Table {
  IntColumn get playerFplId => integer()();
  IntColumn get purchasePriceTenths => integer()();
  TextColumn get source => text()(); // FROM_TRANSFER, CONFIRM, CONFIRMED_USER
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playerFplId};
}

/// 3. Lineup results (Part K). Last 20 with projection run ID.
class LineupResultsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameweek => integer()();
  TextColumn get starting11FplIds => text()(); // comma-separated IDs
  TextColumn get benchFplIds => text()(); // comma-separated IDs in priority order
  IntColumn get captainFplId => integer()();
  IntColumn get viceCaptainFplId => integer()();
  RealColumn get projectedTotalPoints => real()();
  TextColumn get modelVersion => text()();
  TextColumn get projectionRunId => text()();
  DateTimeColumn get computedAt => dateTime()();
}

/// 4. Transfer history (Part K). Rebuilt on sync.
class TransferHistoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get elementInFplId => integer()();
  IntColumn get elementInCostTenths => integer()();
  TextColumn get elementInName => text()();
  IntColumn get elementOutFplId => integer()();
  IntColumn get elementOutCostTenths => integer()();
  TextColumn get elementOutName => text()();
  IntColumn get gameweek => integer()();
  DateTimeColumn get transferTime => dateTime()();
}

/// 5. Gameweek history (Part K). Rebuilt on sync.
class GameweekHistoryTable extends Table {
  IntColumn get gameweek => integer()();
  IntColumn get points => integer()();
  IntColumn get totalPoints => integer()();
  IntColumn get overallRank => integer()();
  RealColumn get percentileRank => real().nullable()();
  IntColumn get eventTransfers => integer()();
  IntColumn get eventTransfersCost => integer()();
  IntColumn get pointsOnBench => integer()();
  IntColumn get bankTenths => integer()();
  IntColumn get valueTenths => integer()();

  @override
  Set<Column> get primaryKey => {gameweek};
}

/// 6. Projection bundles per gameweek (Part K). For offline read-only.
class ProjectionBundlesTable extends Table {
  IntColumn get gameweek => integer()();
  TextColumn get bundleJson => text()();
  TextColumn get modelVersion => text()();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {gameweek};
}

/// 7. Preferences (Part K). Reminder timing, analytics opt-out, etc.
class UserPreferencesTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  SquadPlayersTable,
  PurchasePricesTable,
  LineupResultsTable,
  TransferHistoryTable,
  GameweekHistoryTable,
  ProjectionBundlesTable,
  UserPreferencesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fpl_lens_local.db');
  }

  // --- Squad operations ---

  Future<void> replaceSquad(List<SquadPlayersTableCompanion> players) async {
    await transaction(() async {
      await delete(squadPlayersTable).go();
      for (final p in players) {
        await into(squadPlayersTable).insert(p);
      }
    });
  }

  Future<List<SquadPlayersTableData>> getAllSquadPlayers() {
    return (select(squadPlayersTable)..orderBy([(t) => OrderingTerm(expression: t.positionOrder)])).get();
  }

  Stream<List<SquadPlayersTableData>> watchSquadPlayers() {
    return (select(squadPlayersTable)..orderBy([(t) => OrderingTerm(expression: t.positionOrder)])).watch();
  }

  Future<bool> hasSquad() async {
    final count = await select(squadPlayersTable).get();
    return count.isNotEmpty;
  }

  // --- Purchase prices operations ---

  Future<void> upsertPurchasePrice({
    required int playerFplId,
    required int purchasePriceTenths,
    required String source,
    required bool isConfirmed,
  }) async {
    await into(purchasePricesTable).insertOnConflictUpdate(
      PurchasePricesTableCompanion(
        playerFplId: Value(playerFplId),
        purchasePriceTenths: Value(purchasePriceTenths),
        source: Value(source),
        isConfirmed: Value(isConfirmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<PurchasePricesTableData>> getAllPurchasePrices() {
    return select(purchasePricesTable).get();
  }

  Future<int> getUnconfirmedPricesCount() async {
    final query = select(purchasePricesTable)..where((t) => t.isConfirmed.equals(false));
    final rows = await query.get();
    return rows.length;
  }

  Stream<int> watchUnconfirmedPricesCount() {
    final query = select(purchasePricesTable)..where((t) => t.isConfirmed.equals(false));
    return query.watch().map((rows) => rows.length);
  }

  // --- History operations ---

  Future<void> replaceGameweekHistory(List<GameweekHistoryTableCompanion> history) async {
    await transaction(() async {
      await delete(gameweekHistoryTable).go();
      for (final h in history) {
        await into(gameweekHistoryTable).insert(h);
      }
    });
  }

  Future<List<GameweekHistoryTableData>> getGameweekHistory() {
    return (select(gameweekHistoryTable)..orderBy([(t) => OrderingTerm.desc(t.gameweek)])).get();
  }

  Future<void> replaceTransferHistory(List<TransferHistoryTableCompanion> transfers) async {
    await transaction(() async {
      await delete(transferHistoryTable).go();
      for (final t in transfers) {
        await into(transferHistoryTable).insert(t);
      }
    });
  }

  Future<List<TransferHistoryTableData>> getTransferHistory() {
    return (select(transferHistoryTable)..orderBy([(t) => OrderingTerm.desc(t.transferTime)])).get();
  }

  // --- Lineup operations ---

  Future<void> insertLineupResult(LineupResultsTableCompanion result) async {
    await into(lineupResultsTable).insert(result);
    // Keep only last 20 lineup results per Part K
    final all = await (select(lineupResultsTable)..orderBy([(t) => OrderingTerm.desc(t.computedAt)])).get();
    if (all.length > 20) {
      final toDelete = all.sublist(20);
      for (final item in toDelete) {
        await (delete(lineupResultsTable)..where((t) => t.id.equals(item.id))).go();
      }
    }
  }

  Future<LineupResultsTableData?> getLatestLineupResult() async {
    final results = await (select(lineupResultsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  // --- Preferences operations ---

  Future<void> setPreference(String key, String value) async {
    await into(userPreferencesTable).insertOnConflictUpdate(
      UserPreferencesTableCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<String?> getPreference(String key) async {
    final row = await (select(userPreferencesTable)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  // --- Clear user data (sign out per Part K) ---

  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(squadPlayersTable).go();
      await delete(purchasePricesTable).go();
      await delete(lineupResultsTable).go();
      await delete(transferHistoryTable).go();
      await delete(gameweekHistoryTable).go();
      await delete(projectionBundlesTable).go();
      await delete(userPreferencesTable).go();
    });
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
