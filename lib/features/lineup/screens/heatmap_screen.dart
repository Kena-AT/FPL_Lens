import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/theme/app_colors.dart';
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

enum HeatmapSort {
  position,
  totalPoints,
  cost;

  String get label {
    switch (this) {
      case HeatmapSort.position:
        return 'Position';
      case HeatmapSort.totalPoints:
        return 'Total xP';
      case HeatmapSort.cost:
        return 'Price';
    }
  }
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
  HeatmapSort _selectedSort = HeatmapSort.position;
  String _positionFilter = 'ALL';
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

  double _calculatePlayerTotalXp(int fplId) {
    double total = 0.0;
    for (int offset = 0; offset < 5; offset++) {
      final gw = _startGw + offset;
      final bundle = _bundles[gw];
      final players = bundle?['players'] as List<dynamic>? ?? [];
      final pData = players
          .where((item) => item is Map && item['fpl_id'] == fplId)
          .firstOrNull as Map<String, dynamic>?;
      final fixtures = pData?['fixtures'] as List<dynamic>? ?? [];
      for (final f in fixtures) {
        total += (f['expected_points'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final squadState = ref.watch(squadNotifierProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final effectiveListView = _isListView || textScale > 1.3;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Heatmap',
          style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              effectiveListView ? Icons.grid_view : Icons.view_list,
              color: colors.textPrimary,
            ),
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

          // 3. Position Filters & Sorting bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'GK', 'DEF', 'MID', 'FWD'].map((pos) {
                        final isSelected = _positionFilter == pos;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(pos),
                            selected: isSelected,
                            selectedColor: colors.accentSoft,
                            backgroundColor: colors.bgSurface,
                            labelStyle: AppTextStyles.caption.copyWith(
                              color: isSelected ? colors.accent : colors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? colors.accent : colors.borderSubtle,
                            ),
                            onSelected: (_) => setState(() => _positionFilter = pos),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                PopupMenuButton<HeatmapSort>(
                  initialValue: _selectedSort,
                  tooltip: 'Sort by',
                  icon: Icon(Icons.sort_rounded, color: colors.textSecondary, size: 20),
                  onSelected: (sort) => setState(() => _selectedSort = sort),
                  itemBuilder: (context) => HeatmapSort.values
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // 4. Range selector row: GW n to n+4
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenGutter,
              vertical: AppTokens.space4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colors.textPrimary),
                  onPressed: _startGw > _currentGw ? () => _shiftWindow(-1) : null,
                ),
                Text(
                  'Gameweeks $_startGw to ${_startGw + 4}',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colors.textPrimary),
                  onPressed: () => _shiftWindow(1),
                ),
              ],
            ),
          ),

          // 5. Legend strip directly above the grid
          _buildLegendStrip(colors),

          Divider(height: 1, color: colors.borderSubtle),

          // 6. Grid or List View
          Expanded(
            child: _isLoading && _bundles.isEmpty
                ? Center(child: CircularProgressIndicator(color: colors.accent))
                : !squadState.hasSquad
                    ? EmptyState(
                        icon: Icons.shield_outlined,
                        title: 'No squad loaded',
                        body: 'Load your squad to inspect your 5-gameweek fixture run.',
                        actionLabel: 'Go Back',
                        onAction: () => context.pop(),
                      )
                    : effectiveListView
                        ? _buildListView(squadState, colors)
                        : _buildGridView(squadState, colors),
          ),

          // 7. Footer Note
          Container(
            padding: const EdgeInsets.all(AppTokens.space12),
            color: colors.bgSurface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Projections are estimates. Blank cells mean no fixture. Dashes mean no projection yet.',
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendStrip(AppColors colors) {
    final directionText =
        _selectedMetric.isHigherBetter ? 'Higher is better' : 'Lower is better (easier)';
    final ramp = HeatmapTokens.rampFor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space4,
      ),
      child: Row(
        children: [
          Text(
            directionText,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const Spacer(),
          Row(
            children: List.generate(5, (idx) {
              final stepIndex = _selectedMetric.isHigherBetter ? idx : 4 - idx;
              final color = ramp[stepIndex];
              return Container(
                width: 20,
                height: 12,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: colors.borderSubtle, width: 0.5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterAndSortPlayers(List<dynamic> players) {
    var filtered = players;
    if (_positionFilter != 'ALL') {
      filtered = filtered.where((p) => p.position == _positionFilter).toList();
    }

    final sorted = List<dynamic>.from(filtered);
    if (_selectedSort == HeatmapSort.totalPoints) {
      sorted.sort((a, b) => _calculatePlayerTotalXp(b.fplId).compareTo(_calculatePlayerTotalXp(a.fplId)));
    } else if (_selectedSort == HeatmapSort.cost) {
      sorted.sort((a, b) => (b.nowCostTenths as int).compareTo(a.nowCostTenths as int));
    }
    return sorted;
  }

  Widget _buildGridView(SquadState squadState, AppColors colors) {
    final players = _filterAndSortPlayers(squadState.squad);

    final gks = players.where((p) => p.position == 'GK').toList();
    final defs = players.where((p) => p.position == 'DEF').toList();
    final mids = players.where((p) => p.position == 'MID').toList();
    final fwds = players.where((p) => p.position == 'FWD').toList();

    final isGrouped = _selectedSort == HeatmapSort.position && _positionFilter == 'ALL';

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
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  border: Border(
                    bottom: BorderSide(color: colors.borderSubtle),
                    right: BorderSide(color: colors.borderSubtle),
                  ),
                ),
                child: Text(
                  'Player',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (isGrouped) ...[
                if (gks.isNotEmpty) _buildPositionGroupHeader('GOALKEEPERS', colors),
                ...gks.map((p) => _buildPlayerNameCell(p, colors)),
                if (defs.isNotEmpty) _buildPositionGroupHeader('DEFENDERS', colors),
                ...defs.map((p) => _buildPlayerNameCell(p, colors)),
                if (mids.isNotEmpty) _buildPositionGroupHeader('MIDFIELDERS', colors),
                ...mids.map((p) => _buildPlayerNameCell(p, colors)),
                if (fwds.isNotEmpty) _buildPositionGroupHeader('FORWARDS', colors),
                ...fwds.map((p) => _buildPlayerNameCell(p, colors)),
              ] else ...[
                ...players.map((p) => _buildPlayerNameCell(p, colors)),
              ],
            ],
          ),
        ),

        // Scrollable Gameweek Columns (5 columns × 64 dp) + Total xP Column (64 dp)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 6 * 64.0,
              child: ListView(
                children: [
                  // Gameweek column headers + Total xP hero column
                  Row(
                    children: [
                      ...List.generate(5, (offset) {
                        final gw = _startGw + offset;
                        final bundle = _bundles[gw];
                        final inputsAsOfStr = bundle?['inputs_as_of'] as String?;
                        final inputsAsOf =
                            inputsAsOfStr != null ? DateTime.tryParse(inputsAsOfStr) : null;

                        return Container(
                          width: 64,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.bgElevated,
                            border: Border(
                              bottom: BorderSide(color: colors.borderSubtle),
                              right: BorderSide(color: colors.borderSubtle),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'GW $gw',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
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
                      // Total xP Hero Column Header (§8.11)
                      Container(
                        width: 64,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.accentSoft.withValues(alpha: 0.3),
                          border: Border(
                            bottom: BorderSide(color: colors.borderSubtle),
                            right: BorderSide(color: colors.borderSubtle),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Total xP',
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Position Group spacer & Player rows
                  if (isGrouped) ...[
                    if (gks.isNotEmpty) _buildPositionGroupSpacer(colors),
                    ...gks.map((p) => _buildPlayerGameweeksRow(p.fplId, colors)),
                    if (defs.isNotEmpty) _buildPositionGroupSpacer(colors),
                    ...defs.map((p) => _buildPlayerGameweeksRow(p.fplId, colors)),
                    if (mids.isNotEmpty) _buildPositionGroupSpacer(colors),
                    ...mids.map((p) => _buildPlayerGameweeksRow(p.fplId, colors)),
                    if (fwds.isNotEmpty) _buildPositionGroupSpacer(colors),
                    ...fwds.map((p) => _buildPlayerGameweeksRow(p.fplId, colors)),
                  ] else ...[
                    ...players.map((p) => _buildPlayerGameweeksRow(p.fplId, colors)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionGroupHeader(String title, AppColors colors) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
      alignment: Alignment.centerLeft,
      color: colors.bgBase,
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPositionGroupSpacer(AppColors colors) {
    return Container(
      height: 28,
      color: colors.bgBase,
    );
  }

  Widget _buildPlayerNameCell(dynamic player, AppColors colors) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle),
          right: BorderSide(color: colors.borderSubtle),
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
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${player.teamShortName} · ${AppFormatters.formatMoneyTenths(player.nowCostTenths)}',
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGameweeksRow(int playerFplId, AppColors colors) {
    final totalXp = _calculatePlayerTotalXp(playerFplId);

    return Row(
      children: [
        ...List.generate(5, (offset) {
          final gw = _startGw + offset;
          return _buildHeatmapCell(playerFplId, gw, colors);
        }),
        // Hero Total xP Cell (§8.11: "the total column is the hero")
        Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: colors.bgElevated,
            border: Border(
              bottom: BorderSide(color: colors.borderSubtle),
              right: BorderSide(color: colors.borderSubtle),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            totalXp.toStringAsFixed(1),
            style: AppTextStyles.numeric.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCell(int playerFplId, int gw, AppColors colors) {
    final bundle = _bundles[gw];
    if (bundle == null) {
      return Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle),
            right: BorderSide(color: colors.borderSubtle),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '–',
          style: AppTextStyles.numeric.copyWith(color: colors.textDisabled),
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
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle),
            right: BorderSide(color: colors.borderSubtle),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Blank',
          style: AppTextStyles.caption.copyWith(color: colors.textDisabled),
        ),
      );
    }

    // Double gameweek check
    final isDouble = fixtures.length > 1;
    final primary = fixtures.first as Map<String, dynamic>;

    // Calculate metric value and ramp step
    final (valueStr, stepIndex) = _calculateMetricAndStep(fixtures);
    final ramp = HeatmapTokens.rampFor(context);
    final fillColour = ramp[stepIndex];
    final textColour = HeatmapTokens.textColorForStep(context, stepIndex);

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
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle),
            right: BorderSide(color: colors.borderSubtle),
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      oppCode,
                      style: AppTextStyles.caption.copyWith(
                        color: textColour.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isDouble)
                      Text(
                        ' ×2',
                        style: AppTextStyles.caption.copyWith(
                          color: colors.statusWarn,
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
        // §8.11: FDR shown as text (FDR 2)
        int step = (5 - diff).clamp(0, 4);
        return ('FDR $diff', step);

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

  Widget _buildListView(SquadState squadState, AppColors colors) {
    final players = _filterAndSortPlayers(squadState.squad);

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.screenGutter),
      itemCount: players.length,
      itemBuilder: (context, idx) {
        final p = players[idx];
        final totalXp = _calculatePlayerTotalXp(p.fplId);

        return Card(
          color: colors.bgSurface,
          margin: const EdgeInsets.only(bottom: AppTokens.space12),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${p.webName} (${p.position})',
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Total: ${totalXp.toStringAsFixed(1)} xP',
                      style: AppTextStyles.numeric.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${p.teamShortName} · ${AppFormatters.formatMoneyTenths(p.nowCostTenths)}',
                  style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                ),
                Divider(height: AppTokens.space16, color: colors.borderSubtle),
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
                        style: AppTextStyles.caption.copyWith(color: colors.textDisabled),
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
                          Text('GW $gw, vs $opp', style: AppTextStyles.body.copyWith(color: colors.textPrimary)),
                          const Spacer(),
                          Text(
                            '${_selectedMetric.label}: $valStr ($bucket)',
                            style: AppTextStyles.numeric.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.accent,
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
