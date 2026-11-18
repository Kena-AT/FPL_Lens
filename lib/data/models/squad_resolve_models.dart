class CandidateMatch {
  final int fplId;
  final String webName;
  final String fullName;
  final int teamFplId;
  final String teamShortName;
  final String position;
  final int nowCostTenths;
  final double confidence;
  final String matchTier; // 'strong', 'possible', 'weak'

  const CandidateMatch({
    required this.fplId,
    required this.webName,
    required this.fullName,
    required this.teamFplId,
    required this.teamShortName,
    required this.position,
    required this.nowCostTenths,
    required this.confidence,
    required this.matchTier,
  });

  factory CandidateMatch.fromJson(Map<String, dynamic> json) {
    return CandidateMatch(
      fplId: json['fpl_id'] as int,
      webName: json['web_name'] as String,
      fullName: json['full_name'] as String,
      teamFplId: json['team_fpl_id'] as int,
      teamShortName: json['team_short_name'] as String,
      position: json['position'] as String,
      nowCostTenths: json['now_cost_tenths'] as int? ?? 60,
      confidence: (json['confidence'] as num).toDouble(),
      matchTier: json['match_tier'] as String? ?? 'weak',
    );
  }
}

class ResolvedPlayerResult {
  final String rawName;
  final String? slot;
  final bool exactMatch;
  final int? bestMatchFplId;
  final double bestConfidence;
  final List<CandidateMatch> candidates;

  const ResolvedPlayerResult({
    required this.rawName,
    this.slot,
    required this.exactMatch,
    this.bestMatchFplId,
    required this.bestConfidence,
    required this.candidates,
  });

  factory ResolvedPlayerResult.fromJson(Map<String, dynamic> json) {
    return ResolvedPlayerResult(
      rawName: json['raw_name'] as String,
      slot: json['slot'] as String?,
      exactMatch: json['exact_match'] as bool? ?? false,
      bestMatchFplId: json['best_match_fpl_id'] as int?,
      bestConfidence: (json['best_confidence'] as num? ?? 0.0).toDouble(),
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((c) => CandidateMatch.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isStrongMatch => exactMatch || bestConfidence >= 0.85;
}

class SquadResolveResponse {
  final bool allResolved;
  final int totalSubmitted;
  final int resolvedCount;
  final int unresolvedCount;
  final List<ResolvedPlayerResult> results;

  const SquadResolveResponse({
    required this.allResolved,
    required this.totalSubmitted,
    required this.resolvedCount,
    required this.unresolvedCount,
    required this.results,
  });

  factory SquadResolveResponse.fromJson(Map<String, dynamic> json) {
    return SquadResolveResponse(
      allResolved: json['all_resolved'] as bool? ?? false,
      totalSubmitted: json['total_submitted'] as int? ?? 0,
      resolvedCount: json['resolved_count'] as int? ?? 0,
      unresolvedCount: json['unresolved_count'] as int? ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((r) => ResolvedPlayerResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
