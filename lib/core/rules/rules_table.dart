/// Pure Dart Versioned Rules Table per Engine Design §3 & §13.2.
/// Zero Flutter or I/O imports.
class RuleRow {
  final String key;
  final Object value;
  final String season;
  final String source;
  final String state; // VERIFIED-OFFICIAL | VERIFIED-2ND | VERIFY | DECIDED
  final String dateChecked;

  const RuleRow({
    required this.key,
    required this.value,
    required this.season,
    required this.source,
    required this.state,
    required this.dateChecked,
  });

  bool get isVerify => state == 'VERIFY';
}

class RulesTable {
  static const String version = '2026-27.1';

  static const List<RuleRow> rows = [
    RuleRow(key: 'squad_size', value: 15, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_size', value: 11, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_min_gk', value: 1, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_max_gk', value: 1, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_min_def', value: 3, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_min_mid', value: 2, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'xi_min_fwd', value: 1, season: '2026/27', source: 'PL basics', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'squad_gk_count', value: 2, season: '2026/27', source: 'Frontend & Core App docs', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'squad_def_count', value: 5, season: '2026/27', source: 'Frontend & Core App docs', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'squad_mid_count', value: 5, season: '2026/27', source: 'Frontend & Core App docs', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'squad_fwd_count', value: 3, season: '2026/27', source: 'Frontend & Core App docs', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'max_players_per_club', value: 3, season: '2026/27', source: 'onsidearena.com 2026/27', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'initial_budget_tenths', value: 1000, season: '2026/27', source: 'onsidearena.com 2026/27', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'free_transfers_per_gw', value: 1, season: '2026/27', source: 'onsidearena', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'max_banked_free_transfers', value: 5, season: '2026/27', source: 'PL 4679873', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'extra_transfer_hit_cost', value: 4, season: '2026/27', source: 'onsidearena; FFS', state: 'VERIFIED-2ND', dateChecked: '2026-11-22'),
    RuleRow(key: 'one_chip_per_gw', value: true, season: '2026/27', source: 'PL 4679879', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'free_hit_allowed_gw1', value: false, season: '2026/27', source: 'PL 4679879', state: 'VERIFIED-OFFICIAL', dateChecked: '2026-11-22'),
    RuleRow(key: 'hit_waived_during_wc_fh', value: true, season: '2026/27', source: 'Pending official rules check', state: 'VERIFY', dateChecked: '2026-11-22'),
    RuleRow(key: 'wildcard_available_gw1', value: true, season: '2026/27', source: 'Conflicting PL vs onsidearena', state: 'VERIFY', dateChecked: '2026-11-22'),
    RuleRow(key: 'gw19_deadline_from_api', value: true, season: '2026/27', source: 'Read deadline_time from API', state: 'VERIFY', dateChecked: '2026-11-22'),
    RuleRow(key: 'vice_captain_sub_activation', value: true, season: '2026/27', source: 'Pending past-GW test', state: 'VERIFY', dateChecked: '2026-11-22'),
    RuleRow(key: 'dgw_chip_captain_handling', value: 'both_fixtures', season: '2026/27', source: 'Pending live DGW observation', state: 'VERIFY', dateChecked: '2026-11-22'),
  ];

  static final Map<String, RuleRow> _byKey = {
    for (final r in rows) r.key: r,
  };

  static RuleRow getRule(String key) {
    final row = _byKey[key];
    if (row == null) {
      throw ArgumentError('Unknown rule key "$key" in RulesTable $version');
    }
    return row;
  }

  static int getInt(String key) => getRule(key).value as int;
  static bool getBool(String key) => getRule(key).value as bool;

  static List<String> verifyLabelsFor(Iterable<String> keys) {
    return keys
        .map((k) => _byKey[k])
        .where((r) => r != null && r.isVerify)
        .map((r) => '${r!.key} [VERIFY]')
        .toList();
  }
}
