import '../../optimiser/player_candidate.dart';
import '../../rules/rules_table.dart';

/// Thrown when an engine invariant (I1..I20) is violated.
/// Callers must fail closed rather than display invalid recommendations.
class InvariantViolationException implements Exception {
  final String invariantId;
  final String message;

  const InvariantViolationException(this.invariantId, this.message);

  @override
  String toString() => 'Invariant $invariantId violated: $message';
}

/// Pure Dart runtime invariant checks per Engine Design §12 (I1..I20).
/// Zero Flutter or I/O imports.
class EngineInvariants {
  /// I10: Every player has one price, one xp, and one set of probabilities per snapshot & GW.
  /// Rejects pools containing conflicting duplicate records for the same fplId.
  static List<PlayerCandidate> validateAndDeduplicatePool(
    List<PlayerCandidate> pool,
  ) {
    final seen = <int, PlayerCandidate>{};
    for (final p in pool) {
      if (!p.xp.isFinite || !p.pStart.isFinite || !p.pSub.isFinite) {
        throw InvariantViolationException(
          'I13',
          'Non-finite projection values for player ${p.fplId} (${p.webName})',
        );
      }
      if (p.pStart < 0.0 || p.pStart > 1.0 || p.pSub < 0.0 || p.pSub > 1.0) {
        throw InvariantViolationException(
          'I12',
          'Invalid probabilities for player ${p.fplId}: pStart=${p.pStart}, pSub=${p.pSub}',
        );
      }
      final existing = seen[p.fplId];
      if (existing != null) {
        final conflict = existing.priceTenths != p.priceTenths ||
            (existing.xp - p.xp).abs() > 1e-9 ||
            (existing.pStart - p.pStart).abs() > 1e-9 ||
            existing.clubId != p.clubId ||
            existing.position != p.position;
        if (conflict) {
          throw InvariantViolationException(
            'I10',
            'Conflicting records for fplId=${p.fplId} (${p.webName}): '
            'price=${existing.priceTenths} vs ${p.priceTenths}, xp=${existing.xp} vs ${p.xp}',
          );
        }
        continue; // Exact duplicate skipped safely
      }
      seen[p.fplId] = p;
    }
    return seen.values.toList();
  }

  /// I1..I6: Validates a single outgoing -> incoming transfer against the current squad.
  /// Returns null if valid, or the failed invariant code ('I1'..'I6') if invalid.
  static String? checkSingleSwap({
    required PlayerCandidate outPlayer,
    required PlayerCandidate inPlayer,
    required List<PlayerCandidate> currentSquad,
    required int bankTenths,
  }) {
    // I1: Outgoing and incoming players are different.
    if (outPlayer.fplId == inPlayer.fplId) return 'I1';

    // I2: Incoming player is not already in the squad.
    if (currentSquad.any((p) => p.fplId == inPlayer.fplId)) return 'I2';

    // I3: Same position for single swaps.
    if (outPlayer.position != inPlayer.position) return 'I3';

    // I4: Squad has 15 players with 2 GK, 5 DEF, 5 MID, 3 FWD.
    if (currentSquad.length != RulesTable.getInt('squad_size')) return 'I4';

    // I5: Max 3 players from any club after swap.
    final maxPerClub = RulesTable.getInt('max_players_per_club');
    final clubCounts = <int, int>{};
    for (final p in currentSquad) {
      if (p.fplId == outPlayer.fplId) continue;
      clubCounts[p.clubId] = (clubCounts[p.clubId] ?? 0) + 1;
    }
    final newClubCount = (clubCounts[inPlayer.clubId] ?? 0) + 1;
    if (newClubCount > maxPerClub) return 'I5';

    // I6: Integer budget in tenths using outgoing sellingPriceTenths.
    final remainingBudget = bankTenths + outPlayer.sellingPriceTenths - inPlayer.priceTenths;
    if (remainingBudget < 0) return 'I6';

    return null;
  }

  /// I12: Strict Layer 1 v2 probability partition check: pStart + pSub + pZero == 1.
  static void checkProbabilityPartition(double pStart, double pSub, double pZero) {
    if (pStart < 0.0 ||
        pStart > 1.0 ||
        pSub < 0.0 ||
        pSub > 1.0 ||
        pZero < 0.0 ||
        pZero > 1.0 ||
        (pStart + pSub + pZero - 1.0).abs() > 1e-9) {
      throw InvariantViolationException(
        'I12',
        'Probability partition must sum to 1: pStart=$pStart, pSub=$pSub, pZero=$pZero',
      );
    }
  }

  /// I16: Returns true if snapshot is missing or older than maxAgeMinutes (default 30 min).
  static bool isSnapshotStale(
    DateTime? fetchedAt,
    DateTime now, {
    int maxAgeMinutes = 30,
  }) {
    if (fetchedAt == null) return true;
    return now.difference(fetchedAt).inMinutes > maxAgeMinutes;
  }
}
