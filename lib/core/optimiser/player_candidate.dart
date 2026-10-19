import 'dart:math' as math;

/// Pure Dart Player Model for Optimiser (Spec §5, §6).
/// Zero Flutter or I/O imports.
class PlayerCandidate {
  final int fplId;
  final String webName;
  final String position; // 'GK', 'DEF', 'MID', 'FWD'
  final int clubId;
  final int priceTenths;
  final int sellingPriceTenths;
  final double xp;
  final double pStart;
  final double pSub;
  final double? xpStart;
  final double? xpSub;

  const PlayerCandidate({
    required this.fplId,
    required this.webName,
    required this.position,
    required this.clubId,
    required this.priceTenths,
    required this.sellingPriceTenths,
    required this.xp,
    required this.pStart,
    required this.pSub,
    this.xpStart,
    this.xpSub,
  });

  /// Probability of appearance in gameweek: min(1.0, pStart + pSub)
  double get pApp {
    return math.min(1.0, math.max(0.0, pStart + pSub));
  }

  /// Expected points conditional on starting.
  double get conditionalXpStart {
    if (xpStart != null) return xpStart!;
    if (pStart > 0.001) {
      return xp / pStart;
    }
    return xp;
  }

  /// Expected points conditional on entering as a substitute (Spec §14 ledger).
  double get conditionalXpSub {
    if (xpSub != null) return xpSub!;
    if (pSub > 0.001) {
      return math.min(xp, 1.8);
    }
    return math.min(xp, 1.5);
  }

  factory PlayerCandidate.fromJson(Map<String, dynamic> json) {
    return PlayerCandidate(
      fplId: json['fpl_id'] as int,
      webName: json['web_name'] as String,
      position: json['position'] as String,
      clubId: (json['club_id'] as num?)?.toInt() ?? 1,
      priceTenths: (json['price_tenths'] as num?)?.toInt() ?? 50,
      sellingPriceTenths: (json['selling_price_tenths'] as num?)?.toInt() ?? 50,
      xp: (json['xp'] as num).toDouble(),
      pStart: (json['p_start'] as num).toDouble(),
      pSub: (json['p_sub'] as num).toDouble(),
      xpStart: (json['xp_start'] as num?)?.toDouble(),
      xpSub: (json['xp_sub'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fpl_id': fplId,
      'web_name': webName,
      'position': position,
      'club_id': clubId,
      'price_tenths': priceTenths,
      'selling_price_tenths': sellingPriceTenths,
      'xp': xp,
      'p_start': pStart,
      'p_sub': pSub,
      if (xpStart != null) 'xp_start': xpStart,
      if (xpSub != null) 'xp_sub': xpSub,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerCandidate &&
          runtimeType == other.runtimeType &&
          fplId == other.fplId;

  @override
  int get hashCode => fplId.hashCode;

  @override
  String toString() => '$webName ($position, $xp xP)';
}
