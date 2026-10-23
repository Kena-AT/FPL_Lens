import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/heatmap_tokens.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../squad/providers/squad_provider.dart';

enum HeatmapMetric {
  expectedPoints,
  difficulty,
  startChance,
  availability;

  String get label {
    switch (this) {
      case HeatmapMetric.expectedPoints:
        return 'Expected points';
      case HeatmapMetric.difficulty:
        return 'Difficulty';
      case HeatmapMetric.startChance:
        return 'Start chance';
      case HeatmapMetric.availability:
        return 'Availability';
    }
  }

  bool get isHigherBetter => this != HeatmapMetric.difficulty;
}

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  int _startGw = 1;
  int _currentGw = 1;
  HeatmapMetric _selectedMetric = HeatmapMetric.expectedPoints;
  bool _isAllPlayersMode = false;
  bool _isListView = false;
  bool _isLoading = true;

  // Bundles keyed by gameweek
  final Map<int, Map<String, dynamic>> _bundles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGameweek());
  }

  Future<void> _initGameweek() async {
    final squadState = ref.read(squadNotifierProvider);
    final nextGw = squadState.nextGameweek?.id ?? squadState.currentGameweek?.id ?? 1;
    setState(() {
      _currentGw = nextGw;
      _startGw = nextGw;
    });
    await _loadBundlesForWindow(_startGw);
  }

  Future<void> _loadBundlesForWindow(int startGw) async {
    setState(() => _isLoading = true);
    final repo = ref.read(fplRepositoryProvider);

    for (int gw = startGw; gw < startGw + 5; gw++) {
      if (!_bundles.containsKey(gw)) {
        try {
          final bundle = await repo.getProjectionBundle(gw);
          _bundles[gw] = bundle;
        } catch (_) {
          // Some future gameweeks may not have published projections yet
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _shiftWindow(int delta) {
    final newStart = _startGw + delta;
    if (newStart < _currentGw) return;
    setState(() => _startGw = newStart);
    _loadBundlesForWindow(newStart);
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final effectiveListView = _isListView || textScale > 1.3;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Heatmap', style: AppTextStyles.headline),
        actions: [
          IconButton(
            icon: Icon(effectiveListView ? Icons.grid_view : Icons.view_list),
            tooltip: effectiveListView ? 'Switch to Grid View' : 'Switch to List View',
            onPressed: () => setState(() => _isListView = !_isListView),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Row set selector: Squad | All players
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space4,
            ),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Squad'),
                  icon: Icon(Icons.groups_rounded, size: 16),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('All players'),
                  icon: Icon(Icons.person_search_rounded, size: 16),
                ),
              ],
              selected: {_isAllPlayersMode},
              onSelectionChanged: (val) {
                setState(() => _isAllPlayersMode = val.first);
              },
            ),
          ),

          // 2. Metric selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space4,
            ),
            child: SegmentedButton<HeatmapMetric>(
              segments: HeatmapMetric.values
                  .map((m) => ButtonSegment<HeatmapMetric>(
                        value: m,
                        label: Text(m.label),
                      ))
                  .toList(),
              selected: {_selectedMetric},
              onSelectionChanged: (val) {
                setState(() => _selectedMetric = val.first);
              },
            ),
          ),

          // 3. Range selector row: GW n to n+4
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _startGw > _currentGw ? () => _shiftWindow(-1) : null,
                ),
                Text(
                  'Gameweeks $_startGw to ${_startGw + 4}',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTokens.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftWindow(1),
                ),
              ],
            ),
          ),

          // 4. Legend strip directly above the grid
          _buildLegendStrip(),

          const Divider(height: 1, color: AppTokens.borderSubtle),

          // 5. Grid or List View
          Expanded(
            child: _isLoading && _bundles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : !squadState.hasSquad
                    ? EmptyState(
                        icon: Icons.shield_outlined,
                        title: 'No squad loaded',
                        body: 'Load your squad to inspect your 5-gameweek fixture run.',
                        actionLabel: 'Go Back',
                        onAction: () => context.pop(),
                      )
                    : effectiveListView
                        ? _buildListView(squadState)
                        : _buildGridView(squadState),
          ),

          // 6. Footer Note
          Container(
            padding: const EdgeInsets.all(AppTokens.space12),
            color: AppTokens.bgSurface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Projections are estimates. Blank cells mean no fixture. Dashes mean no projection yet.',
                    style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendStrip() {
    final directionText =
        _selectedMetric.isHigherBetter ? 'Higher is better' : 'Lower is better (easier)';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space4,
      ),
      child: Row(
        children: [
          Text(
            directionText,
            style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (idx) {
              final stepIndex = _selectedMetric.isHigherBetter ? idx : 4 - idx;
              final color = HeatmapTokens.ramp[stepIndex];
              return Container(
                width: 20,
                height: 12,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppTokens.borderSubtle, width: 0.5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(SquadState squadState) {
    final players = squadState.squad;

    // Group players by position: GK, DEF, MID, FWD
    final gks = players.where((p) => p.position == 'GK').toList();
    final defs = players.where((p) => p.position == 'DEF').toList();
    final mids = players.where((p) => p.position == 'MID').toList();
    final fwds = players.where((p) => p.position == 'FWD').toList();

    return Row(
      children: [
        // Frozen Player Name Column (112 dp wide)
        SizedBox(
          width: 112,
          child: ListView(
            children: [
              // Column Header placeholder
              Container(
                height: 56,
                padding: const EdgeInsets.all(AppTokens.space8),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: AppTokens.bgElevated,
                  border: Border(
                    bottom: BorderSide(color: AppTokens.borderSubtle),
                    right: BorderSide(color: AppTokens.borderSubtle),
                  ),
                ),
                child: Text(
                  'Player',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
              _buildPositionGroupHeader('GOALKEEPERS'),
              ...gks.map(_buildPlayerNameCell),
              _buildPositionGroupHeader('DEFENDERS'),
              ...defs.map(_buildPlayerNameCell),
              _buildPositionGroupHeader('MIDFIELDERS'),
              ...mids.map(_buildPlayerNameCell),
              _buildPositionGroupHeader('FORWARDS'),
              ...fwds.map(_buildPlayerNameCell),
            ],
          ),
        ),

        // Scrollable Gameweek Columns (5 columns × 64 dp)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 5 * 64.0,
              child: ListView(
                children: [
                  // Gameweek column headers
                  Row(
                    children: List.generate(5, (offset) {
                      final gw = _startGw + offset;
                      final bundle = _bundles[gw];
                      final inputsAsOfStr = bundle?['inputs_as_of'] as String?;
                      final inputsAsOf =
                          inputsAsOfStr != null ? DateTime.tryParse(inputsAsOfStr) : null;

                      return Container(
                        width: 64,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppTokens.bgElevated,
                          border: Border(
                            bottom: BorderSide(color: AppTokens.borderSubtle),
                            right: BorderSide(color: AppTokens.borderSubtle),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'GW $gw',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimary,
                              ),
                            ),
                            if (inputsAsOf != null)
                              FreshnessLabel(
                                lastUpdated: inputsAsOf,
                                staleThreshold: const Duration(minutes: 60),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),

                  // Position Group spacer
                  _buildPositionGroupSpacer(),
                  ...gks.map((p) => _buildPlayerGameweeksRow(p.fplId)),
                  _buildPositionGroupSpacer(),
                  ...defs.map((p) => _buildPlayerGameweeksRow(p.fplId)),
                  _buildPositionGroupSpacer(),
                  ...mids.map((p) => _buildPlayerGameweeksRow(p.fplId)),
                  _buildPositionGroupSpacer(),
                  ...fwds.map((p) => _buildPlayerGameweeksRow(p.fplId)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionGroupHeader(String title) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
      alignment: Alignment.centerLeft,
      color: AppTokens.bgBase,
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppTokens.goldPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPositionGroupSpacer() {
    return Container(
      height: 28,
      color: AppTokens.bgBase,
    );
  }

  Widget _buildPlayerNameCell(dynamic player) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
      decoration: const BoxDecoration(
        color: AppTokens.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderSubtle),
          right: BorderSide(color: AppTokens.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player.webName,
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${player.teamShortName} · ${AppFormatters.formatMoneyTenths(player.nowCostTenths)}',
            style: AppTextStyles.caption.copyWith(
              color: AppTokens.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGameweeksRow(int playerFplId) {
    return Row(
      children: List.generate(5, (offset) {
        final gw = _startGw + offset;
        return _buildHeatmapCell(playerFplId, gw);
      }),
    );
  }

  Widget _buildHeatmapCell(int playerFplId, int gw) {
    final bundle = _bundles[gw];
    if (bundle == null) {
      return Container(
        width: 64,
        height: 56,
        decoration: const BoxDecoration(
          color: AppTokens.bgSurface,
          border: Border(
            bottom: BorderSide(color: AppTokens.borderSubtle),
            right: BorderSide(color: AppTokens.borderSubtle),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '–',
          style: AppTextStyles.numeric.copyWith(color: AppTokens.textDisabled),
        ),
      );
    }

    final players = bundle['players'] as List<dynamic>? ?? [];
    final playerData = players
        .where((p) => p is Map && p['fpl_id'] == playerFplId)
        .firstOrNull as Map<String, dynamic>?;

    final fixtures = playerData?['fixtures'] as List<dynamic>? ?? [];
    if (fixtures.isEmpty) {
      // Blank gameweek
      return Container(
        width: 64,
        height: 56,
        decoration: const BoxDecoration(
          color: AppTokens.bgSurface,
          border: Border(
            bottom: BorderSide(color: AppTokens.borderSubtle),
            right: BorderSide(color: AppTokens.borderSubtle),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Blank',
          style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
        ),
      );
    }

    // Double gameweek check
    final isDouble = fixtures.length > 1;
    final primary = fixtures.first as Map<String, dynamic>;

    // Calculate metric value and ramp step
    final (valueStr, stepIndex) = _calculateMetricAndStep(fixtures);
    final fillColour = HeatmapTokens.ramp[stepIndex];
    final textColour = HeatmapTokens.textColorForStep(stepIndex);

    final oppShort = primary['opponent_short_name'] as String? ?? 'OPP';
    final isHome = primary['is_home'] as bool?;
    final oppCode = isHome == true ? '$oppShort (H)' : (isHome == false ? '$oppShort (A)' : oppShort);

    return InkWell(
      onTap: () => context.push('/player/$playerFplId?gw=$gw'),
      child: Container(
        width: 64,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: fillColour,
          border: const Border(
            bottom: BorderSide(color: AppTokens.borderSubtle),
            right: BorderSide(color: AppTokens.borderSubtle),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    oppCode,
                    style: AppTextStyles.caption.copyWith(
                      color: textColour.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDouble)
                  Text(
                    ' ×2',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTokens.statusDoubtful,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              valueStr,
              style: AppTextStyles.numeric.copyWith(
                color: textColour,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, int) _calculateMetricAndStep(List<dynamic> fixtures) {
    switch (_selectedMetric) {
      case HeatmapMetric.expectedPoints:
        double totalXp = 0.0;
        for (final f in fixtures) {
          totalXp += (f['expected_points'] as num?)?.toDouble() ?? 0.0;
        }
        int step = 0;
        if (totalXp >= 8.0) {
          step = 4;
        } else if (totalXp >= 6.0) {
          step = 3;
        } else if (totalXp >= 4.0) {
          step = 2;
        } else if (totalXp >= 2.0) {
          step = 1;
        }
        return (totalXp.toStringAsFixed(1), step);

      case HeatmapMetric.difficulty:
        final f = fixtures.first as Map<String, dynamic>;
        final diff = (f['difficulty'] as int?) ?? 3;
        // Inverted: difficulty 1-2 is best (step 4), difficulty 5 is worst (step 0)
        int step = (5 - diff).clamp(0, 4);
        return ('$diff', step);

      case HeatmapMetric.startChance:
        final f = fixtures.first as Map<String, dynamic>;
        final pStart = (f['p_start'] as num?)?.toDouble() ?? 1.0;
        final pct = (pStart <= 1.0 ? pStart * 100 : pStart).round();
        int step = 0;
        if (pct >= 95) {
          step = 4;
        } else if (pct >= 85) {
          step = 3;
        } else if (pct >= 70) {
          step = 2;
        } else if (pct >= 50) {
          step = 1;
        }
        return ('$pct%', step);

      case HeatmapMetric.availability:
        final f = fixtures.first as Map<String, dynamic>;
        final avail = (f['availability'] as num?)?.toDouble() ?? 1.0;
        final pct = (avail <= 1.0 ? avail * 100 : avail).round();
        int step = 0;
        if (pct >= 95) {
          step = 4;
        } else if (pct >= 75) {
          step = 3;
        } else if (pct >= 50) {
          step = 2;
        } else if (pct >= 25) {
          step = 1;
        }
        return ('$pct%', step);
    }
  }

  Widget _buildListView(SquadState squadState) {
    final players = squadState.squad;

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.screenGutter),
      itemCount: players.length,
      itemBuilder: (context, idx) {
        final p = players[idx];
        return Card(
          color: AppTokens.bgSurface,
          margin: const EdgeInsets.only(bottom: AppTokens.space12),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${p.webName} (${p.position})',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                    Text(
                      '${p.teamShortName} · ${AppFormatters.formatMoneyTenths(p.nowCostTenths)}',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: AppTokens.space16, color: AppTokens.borderSubtle),
                ...List.generate(5, (offset) {
                  final gw = _startGw + offset;
                  final bundle = _bundles[gw];
                  final playersList = bundle?['players'] as List<dynamic>? ?? [];
                  final pData = playersList
                      .where((item) => item is Map && item['fpl_id'] == p.fplId)
                      .firstOrNull as Map<String, dynamic>?;

                  final fixtures = pData?['fixtures'] as List<dynamic>? ?? [];
                  if (fixtures.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                      child: Text(
                        'GW $gw: Blank (No fixture)',
                        style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
                      ),
                    );
                  }

                  final (valStr, stepIndex) = _calculateMetricAndStep(fixtures);
                  final bucket = HeatmapTokens.bucketNames[stepIndex];
                  final primary = fixtures.first as Map<String, dynamic>;
                  final opp = primary['opponent_short_name'] ?? 'OPP';

                  return InkWell(
                    onTap: () => context.push('/player/${p.fplId}?gw=$gw'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                      child: Row(
                        children: [
                          Text('GW $gw, vs $opp', style: AppTextStyles.body),
                          const Spacer(),
                          Text(
                            '${_selectedMetric.label}: $valStr ($bucket)',
                            style: AppTextStyles.numeric.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTokens.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
