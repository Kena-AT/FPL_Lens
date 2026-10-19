class EntryModel {
  final int id;
  final String name;
  final String playerFirstName;
  final String playerLastName;
  final int summaryOverallPoints;
  final int? summaryOverallRank;

  const EntryModel({
    required this.id,
    required this.name,
    required this.playerFirstName,
    required this.playerLastName,
    required this.summaryOverallPoints,
    this.summaryOverallRank,
  });

  factory EntryModel.fromJson(Map<String, dynamic> json) {
    return EntryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      playerFirstName: (json['player_first_name'] as String?) ?? '',
      playerLastName: (json['player_last_name'] as String?) ?? '',
      summaryOverallPoints: (json['summary_overall_points'] as int?) ?? 0,
      summaryOverallRank: json['summary_overall_rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'player_first_name': playerFirstName,
        'player_last_name': playerLastName,
        'summary_overall_points': summaryOverallPoints,
        'summary_overall_rank': summaryOverallRank,
      };
}

class PickModel {
  final int element;
  final int position;
  final int multiplier;
  final bool isCaptain;
  final bool isViceCaptain;
  final String? webName;
  final String? playerPosition;
  final int? teamFplId;
  final String? teamShortName;
  final int? nowCost;
  final String? status;
  final int? chanceOfPlayingNextRound;

  const PickModel({
    required this.element,
    required this.position,
    required this.multiplier,
    required this.isCaptain,
    required this.isViceCaptain,
    this.webName,
    this.playerPosition,
    this.teamFplId,
    this.teamShortName,
    this.nowCost,
    this.status,
    this.chanceOfPlayingNextRound,
  });

  factory PickModel.fromJson(Map<String, dynamic> json) {
    final rawPos = json['position'];
    final int positionOrder = rawPos is int ? rawPos : (int.tryParse(rawPos?.toString() ?? '') ?? 1);

    return PickModel(
      element: json['element'] as int,
      position: positionOrder,
      multiplier: json['multiplier'] as int? ?? 1,
      isCaptain: json['is_captain'] as bool? ?? false,
      isViceCaptain: json['is_vice_captain'] as bool? ?? false,
      webName: json['web_name'] as String?,
      playerPosition: (json['player_position'] as String?) ?? (rawPos is String ? rawPos : null),
      teamFplId: json['team_fpl_id'] as int?,
      teamShortName: json['team_short_name'] as String?,
      nowCost: json['now_cost'] as int?,
      status: json['status'] as String?,
      chanceOfPlayingNextRound: json['chance_of_playing_next_round'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'element': element,
        'position': position,
        'multiplier': multiplier,
        'is_captain': isCaptain,
        'is_vice_captain': isViceCaptain,
        'web_name': webName,
        'team_fpl_id': teamFplId,
        'team_short_name': teamShortName,
        'now_cost': nowCost,
        'status': status,
        'chance_of_playing_next_round': chanceOfPlayingNextRound,
      };
}

class SquadPicksResponse {
  final List<PickModel> picks;
  final List<Map<String, dynamic>> chips;
  final Map<String, dynamic>? entryHistory;

  const SquadPicksResponse({
    required this.picks,
    this.chips = const [],
    this.entryHistory,
  });

  factory SquadPicksResponse.fromJson(Map<String, dynamic> json) {
    final rawPicks = json['picks'] as List<dynamic>? ?? [];
    final picks = rawPicks.map((e) => PickModel.fromJson(e as Map<String, dynamic>)).toList();
    final rawChips = json['chips'] as List<dynamic>? ?? [];
    final chips = rawChips.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final entryHistory = json['entry_history'] != null
        ? Map<String, dynamic>.from(json['entry_history'] as Map)
        : null;

    return SquadPicksResponse(
      picks: picks,
      chips: chips,
      entryHistory: entryHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'picks': picks.map((p) => p.toJson()).toList(),
        'chips': chips,
        'entry_history': entryHistory,
      };
}

class TransferItemModel {
  final int elementIn;
  final int elementInCost;
  final int elementOut;
  final int elementOutCost;
  final int? entry;
  final int event;
  final DateTime time;
  final String? elementInName;
  final String? elementOutName;

  const TransferItemModel({
    required this.elementIn,
    required this.elementInCost,
    required this.elementOut,
    required this.elementOutCost,
    this.entry,
    required this.event,
    required this.time,
    this.elementInName,
    this.elementOutName,
  });

  factory TransferItemModel.fromJson(Map<String, dynamic> json) {
    return TransferItemModel(
      elementIn: json['element_in'] as int,
      elementInCost: json['element_in_cost'] as int,
      elementOut: json['element_out'] as int,
      elementOutCost: json['element_out_cost'] as int,
      entry: json['entry'] as int?,
      event: json['event'] as int,
      time: DateTime.parse(json['time'] as String),
      elementInName: json['element_in_name'] as String?,
      elementOutName: json['element_out_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'element_in': elementIn,
        'element_in_cost': elementInCost,
        'element_out': elementOut,
        'element_out_cost': elementOutCost,
        'entry': entry,
        'event': event,
        'time': time.toIso8601String(),
        'element_in_name': elementInName,
        'element_out_name': elementOutName,
      };
}

class GameweekHistoryItemModel {
  final int event;
  final int points;
  final int totalPoints;
  final int overallRank;
  final double? percentileRank;
  final int eventTransfers;
  final int eventTransfersCost;
  final int pointsOnBench;
  final int bank;
  final int value;

  const GameweekHistoryItemModel({
    required this.event,
    required this.points,
    required this.totalPoints,
    required this.overallRank,
    this.percentileRank,
    required this.eventTransfers,
    required this.eventTransfersCost,
    required this.pointsOnBench,
    required this.bank,
    required this.value,
  });

  factory GameweekHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return GameweekHistoryItemModel(
      event: json['event'] as int,
      points: json['points'] as int,
      totalPoints: json['total_points'] as int,
      overallRank: json['overall_rank'] as int,
      percentileRank: (json['percentile_rank'] as num?)?.toDouble(),
      eventTransfers: json['event_transfers'] as int,
      eventTransfersCost: json['event_transfers_cost'] as int,
      pointsOnBench: json['points_on_bench'] as int,
      bank: json['bank'] as int,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event,
        'points': points,
        'total_points': totalPoints,
        'overall_rank': overallRank,
        'percentile_rank': percentileRank,
        'event_transfers': eventTransfers,
        'event_transfers_cost': eventTransfersCost,
        'points_on_bench': pointsOnBench,
        'bank': bank,
        'value': value,
      };
}

class HistoryResponse {
  final List<GameweekHistoryItemModel> current;
  final List<Map<String, dynamic>> past;
  final List<Map<String, dynamic>> chips;

  const HistoryResponse({
    this.current = const [],
    this.past = const [],
    this.chips = const [],
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawCurrent = json['current'] as List<dynamic>? ?? [];
    final current = rawCurrent
        .map((e) => GameweekHistoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawPast = json['past'] as List<dynamic>? ?? [];
    final past = rawPast.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final rawChips = json['chips'] as List<dynamic>? ?? [];
    final chips = rawChips.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return HistoryResponse(
      current: current,
      past: past,
      chips: chips,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current.map((c) => c.toJson()).toList(),
        'past': past,
        'chips': chips,
      };
}

class GameweekMetadata {
  final int id;
  final String name;
  final DateTime? deadlineTime;
  final bool finished;
  final bool isCurrent;
  final bool isNext;

  const GameweekMetadata({
    required this.id,
    required this.name,
    this.deadlineTime,
    this.finished = false,
    this.isCurrent = false,
    this.isNext = false,
  });

  factory GameweekMetadata.fromJson(Map<String, dynamic> json) {
    return GameweekMetadata(
      id: json['id'] as int,
      name: json['name'] as String,
      deadlineTime: json['deadline_time'] != null
          ? DateTime.tryParse(json['deadline_time'] as String)
          : null,
      finished: json['finished'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
      isNext: json['is_next'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deadline_time': deadlineTime?.toIso8601String(),
        'finished': finished,
        'is_current': isCurrent,
        'is_next': isNext,
      };
}

class CurrentGameweekResponse {
  final GameweekMetadata? current;
  final GameweekMetadata? next;

  const CurrentGameweekResponse({
    this.current,
    this.next,
  });

  factory CurrentGameweekResponse.fromJson(Map<String, dynamic> json) {
    return CurrentGameweekResponse(
      current: json['current'] != null
          ? GameweekMetadata.fromJson(json['current'] as Map<String, dynamic>)
          : null,
      next: json['next'] != null
          ? GameweekMetadata.fromJson(json['next'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current?.toJson(),
        'next': next?.toJson(),
      };
}
