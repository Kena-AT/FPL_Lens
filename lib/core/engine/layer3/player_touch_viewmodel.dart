import 'dart:math' as math;

import '../../optimiser/player_candidate.dart';
import '../../optimiser/transfer_optimiser.dart';
import '../invariants/engine_invariants.dart';
import '../layer2/lineup_engine_v2.dart';
import '../layer3/transfer_engine_v2.dart';

/// Standardized Player Touch messages per Engine Design §10.5.
class PlayerTouchMessages {
  static const title = 'Transfer options';
  static const none = 'No swap clearly beats keeping this player.';
  static const noBudget = 'No player fits your budget for this swap.';
  static const benchNote = 'Shown as a swap into the starting XI.';
  static String stale(String timeAgo) =>
      'Last updated $timeAgo ago. Transfer options are paused until new data arrives.';
  static const approx = 'Approximate: this assumes no further transfers.';
  static const captainBenchBlocked = 'Bench players cannot be captain.';
  static const compareMore = 'Compare more options';
}

/// Single deterministic transfer option displayed in PlayerTouchSheet (§10.1, §10.2).
class PlayerTouchTransferOption {
  final PlayerCandidate incomingPlayer;
  final int priceDeltaTenths;
  final double rawGain;
  final double sigmaGain;
  final (double, double) interval80;
  final int hitCost;
  final String confidence;

  const PlayerTouchTransferOption({
    required this.incomingPlayer,
    required this.priceDeltaTenths,
    required this.rawGain,
    required this.sigmaGain,
    required this.interval80,
    required this.hitCost,
    required this.confidence,
  });

  String get formattedPriceDelta {
    if (priceDeltaTenths == 0) return 'Same price';
    final absM = (priceDeltaTenths.abs() / 10.0).toStringAsFixed(1);
    return priceDeltaTenths > 0 ? '£${absM}m more' : '£${absM}m less';
  }
}

/// Pure Dart ViewModel for Player Touch Sheet (§10.6). Zero Flutter imports.
class PlayerTouchViewModel {
  final PlayerCandidate outgoingPlayer;
  final bool isBenchPlayer;
  final bool isStale;
  final String? staleMessage;
  final String confidence;
  final List<PlayerTouchTransferOption> topOptions; // Top 3
  final List<PlayerTouchTransferOption> allOptions; // Full shortlist
  final String? emptyReason;

  const PlayerTouchViewModel({
    required this.outgoingPlayer,
    required this.isBenchPlayer,
    required this.isStale,
    this.staleMessage,
    required this.confidence,
    required this.topOptions,
    required this.allOptions,
    this.emptyReason,
  });
}

class PlayerTouchViewModelBuilder {
  static String _formatAge(Duration age) {
    if (age.inMinutes < 60) return '${math.max(1, age.inMinutes)}m';
    if (age.inHours < 24) return '${age.inHours}h';
    return '${age.inDays}d';
  }

  /// Builds [PlayerTouchViewModel] strictly from Layer 1-3 engine outputs (§10.2, §10.4).
  static PlayerTouchViewModel build({
    required PlayerCandidate outgoingPlayer,
    required List<PlayerCandidate> currentSquad,
    required List<PlayerCandidate> availablePool,
    required int bankTenths,
    required int freeTransfersAvailable,
    required bool isBenchPlayer,
    DateTime? snapshotFetchedAt,
    DateTime? now,
    double zThreshold = 1.0,
    String playerConfidence = 'MEDIUM',
  }) {
    final refNow = now ?? DateTime.now().toUtc();
    final stale = EngineInvariants.isSnapshotStale(snapshotFetchedAt, refNow);
    if (stale) {
      final ageStr = snapshotFetchedAt != null
          ? _formatAge(refNow.difference(snapshotFetchedAt))
          : 'unknown';
      return PlayerTouchViewModel(
        outgoingPlayer: outgoingPlayer,
        isBenchPlayer: isBenchPlayer,
        isStale: true,
        staleMessage: PlayerTouchMessages.stale(ageStr),
        confidence: 'LOW',
        topOptions: const [],
        allOptions: const [],
        emptyReason: PlayerTouchMessages.stale(ageStr),
      );
    }

    final validatedSquad = EngineInvariants.validateAndDeduplicatePool(currentSquad);
    final baseLineup = LineupEngineV2.optimize(validatedSquad);
    final shortlists = TransferEngineV2.generateShortlists(
      currentSquad: validatedSquad,
      availablePool: availablePool,
      bankTenths: bankTenths,
    );
    final shortlist = shortlists[outgoingPlayer.fplId] ?? const <PlayerCandidate>[];

    if (shortlist.isEmpty) {
      return PlayerTouchViewModel(
        outgoingPlayer: outgoingPlayer,
        isBenchPlayer: isBenchPlayer,
        isStale: false,
        confidence: playerConfidence,
        topOptions: const [],
        allOptions: const [],
        emptyReason: PlayerTouchMessages.noBudget,
      );
    }

    final hitCost = TransferOptimiser.computeHitCost(1, freeTransfersAvailable);
    final evaluated = <PlayerTouchTransferOption>[];

    for (final inP in shortlist) {
      final newSquad = validatedSquad
          .map((p) => p.fplId == outgoingPlayer.fplId ? inP : p)
          .toList();
      if (!TransferOptimiser.isValidSquad(newSquad)) continue;

      final newLineup = LineupEngineV2.optimize(newSquad);
      final netGain = (newLineup.expectedPoints - baseLineup.expectedPoints) - hitCost;
      final sigma = math.sqrt(
        math.pow(TransferEngineV2.playerSigma(inP), 2) +
            math.pow(TransferEngineV2.playerSigma(outgoingPlayer), 2),
      );
      final i80 = (netGain - 1.28 * sigma, netGain + 1.28 * sigma);
      final deltaPrice = inP.priceTenths - outgoingPlayer.sellingPriceTenths;

      evaluated.add(PlayerTouchTransferOption(
        incomingPlayer: inP,
        priceDeltaTenths: deltaPrice,
        rawGain: netGain,
        sigmaGain: sigma,
        interval80: i80,
        hitCost: hitCost,
        confidence: playerConfidence,
      ));
    }

    // §10.2 Deterministic ranking: net gain desc, lower price, lower fplId
    evaluated.sort((a, b) {
      final c1 = b.rawGain.compareTo(a.rawGain);
      if (c1 != 0) return c1;
      final c2 = a.incomingPlayer.priceTenths.compareTo(b.incomingPlayer.priceTenths);
      if (c2 != 0) return c2;
      return a.incomingPlayer.fplId.compareTo(b.incomingPlayer.fplId);
    });

    // §10.4: If player has pPlay near 1 and best candidate's gain is inside its noise, abstain
    final pPlay = 1.0 - LineupEngineV2.pZero(outgoingPlayer);
    final bestClearsNoise =
        evaluated.isNotEmpty && (evaluated.first.rawGain - zThreshold * evaluated.first.sigmaGain) > 0.0;
    if (pPlay >= 0.85 && !bestClearsNoise) {
      return PlayerTouchViewModel(
        outgoingPlayer: outgoingPlayer,
        isBenchPlayer: isBenchPlayer,
        isStale: false,
        confidence: playerConfidence,
        topOptions: const [],
        allOptions: evaluated,
        emptyReason: PlayerTouchMessages.none,
      );
    }

    return PlayerTouchViewModel(
      outgoingPlayer: outgoingPlayer,
      isBenchPlayer: isBenchPlayer,
      isStale: false,
      confidence: playerConfidence,
      topOptions: evaluated.take(3).toList(),
      allOptions: evaluated,
    );
  }
}
