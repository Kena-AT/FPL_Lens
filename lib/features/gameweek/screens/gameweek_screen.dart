import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/fpl_models.dart';
import '../../../data/repositories/fpl_repository.dart';

final selectedGameweekProvider = StateProvider<int?>((ref) => null);

final currentGameweekMetadataProvider =
    FutureProvider<CurrentGameweekResponse>((ref) async {
  final repo = ref.watch(fplRepositoryProvider);
  return repo.getCurrentGameweek();
});

final gameweekFixturesProvider =
    FutureProvider.family<List<FixtureModel>, int>((ref, gw) async {
  final repo = ref.watch(fplRepositoryProvider);
  return repo.getFixtures(gw: gw);
});

class GameweekScreen extends ConsumerStatefulWidget {
  final int? initialGw;

  const GameweekScreen({super.key, this.initialGw});

  @override
  ConsumerState<GameweekScreen> createState() => _GameweekScreenState();
}

class _GameweekScreenState extends ConsumerState<GameweekScreen> {
  int? _selectedGw;

  @override
  void initState() {
    super.initState();
    _selectedGw = widget.initialGw;
  }

  void _changeGameweek(int currentActiveGw, int delta) {
    final newGw = (currentActiveGw + delta).clamp(1, 38);
    if (newGw != currentActiveGw) {
      setState(() {
        _selectedGw = newGw;
      });
    }
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final local = dt.toLocal();
    final dayName = days[local.weekday - 1];
    final monthName = months[local.month - 1];
    return '$dayName ${local.day} $monthName';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDeadline(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final local = dt.toLocal();
    final dayName = days[local.weekday - 1];
    final monthName = months[local.month - 1];
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$dayName ${local.day} $monthName, $h:$m';
  }

  Map<String, List<FixtureModel>> _groupByDate(List<FixtureModel> fixtures) {
    final groups = <String, List<FixtureModel>>{};
    for (final f in fixtures) {
      final dateKey = f.kickoffTime != null
          ? _formatDate(f.kickoffTime!)
          : 'To be announced';
      groups.putIfAbsent(dateKey, () => []).add(f);
    }
    return groups;
  }

  Widget _buildSummaryCard(GameweekMetadata? meta) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space8,
      ),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
        border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gameweek Summary',
                style: AppTextStyles.label.copyWith(color: AppTokens.accent),
              ),
              if (meta?.isCurrent == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space8,
                    vertical: AppTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.statusAvailable.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Text(
                    'LIVE',
                    style: AppTextStyles.caption.copyWith(
                      color: AppTokens.statusAvailable,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average score',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      '54 pts',
                      style: AppTextStyles.headline.copyWith(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Highest score',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      '112 pts',
                      style: AppTextStyles.headline.copyWith(fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live rank',
                      style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      'Top 5%',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 18.0,
                        color: AppTokens.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(FixtureModel fixture) {
    final hasScore = fixture.homeScore != null && fixture.awayScore != null;
    final timeStr = fixture.kickoffTime != null
        ? _formatTime(fixture.kickoffTime!)
        : 'TBD';

    final accessibilityLabel =
        '${fixture.homeTeamName.isNotEmpty ? fixture.homeTeamName : fixture.homeTeamShortName} versus ${fixture.awayTeamName.isNotEmpty ? fixture.awayTeamName : fixture.awayTeamShortName}, $timeStr';

    return Semantics(
      label: accessibilityLabel,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.screenGutter,
          vertical: AppTokens.space4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space12,
        ),
        decoration: BoxDecoration(
          color: AppTokens.bgSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          border: Border.all(color: AppTokens.borderSubtle, width: 1.0),
        ),
        child: Row(
          children: [
            // Home team
            Expanded(
              child: Text(
                fixture.homeTeamShortName,
                textAlign: TextAlign.end,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Score or kick-off time
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
              alignment: Alignment.center,
              child: hasScore
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space8,
                        vertical: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: fixture.finished
                            ? AppTokens.bgElevated
                            : AppTokens.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: Text(
                        '${fixture.homeScore} - ${fixture.awayScore}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: fixture.finished
                              ? AppTokens.textPrimary
                              : AppTokens.accent,
                        ),
                      ),
                    )
                  : Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            // Away team
            Expanded(
              child: Text(
                fixture.awayTeamShortName,
                textAlign: TextAlign.start,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Markers (Double / Blank / Bonus)
            if (fixture.isDouble)
              Container(
                margin: const EdgeInsets.only(left: AppTokens.space4),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.statusDoubtful.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                child: Text(
                  'Double',
                  style: AppTextStyles.caption.copyWith(
                    color: AppTokens.statusDoubtful,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metaAsync = ref.watch(currentGameweekMetadataProvider);
    final currentMeta = metaAsync.valueOrNull?.current;
    final activeGw = _selectedGw ?? currentMeta?.id ?? 1;
    final isCurrent = currentMeta?.id == activeGw;
    final fixturesAsync = ref.watch(gameweekFixturesProvider(activeGw));

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: Text('Gameweek $activeGw', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Gameweek selector bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.screenGutter,
                vertical: AppTokens.space8,
              ),
              color: AppTokens.bgSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppTokens.textPrimary),
                    onPressed: activeGw > 1 ? () => _changeGameweek(activeGw, -1) : null,
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Gameweek $activeGw',
                            style: AppTextStyles.headline.copyWith(fontSize: 16.0),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: AppTokens.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space8,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              ),
                              child: Text(
                                'Current',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppTokens.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTokens.textPrimary),
                    onPressed: activeGw < 38 ? () => _changeGameweek(activeGw, 1) : null,
                  ),
                ],
              ),
            ),

            // Deadline row
            if (currentMeta?.deadlineTime != null && isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.screenGutter,
                  vertical: AppTokens.space8,
                ),
                color: AppTokens.bgElevated,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16.0,
                      color: AppTokens.accent,
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Flexible(
                      child: Text(
                        'Deadline: ${_formatDeadline(currentMeta!.deadlineTime!)}',
                        style: AppTextStyles.caption.copyWith(color: AppTokens.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Summary Card
            _buildSummaryCard(currentMeta),

            // Fixtures content
            Expanded(
              child: fixturesAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(AppTokens.screenGutter),
                  children: List.generate(
                    6,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppTokens.space8),
                      child: SkeletonLoader(height: 52.0),
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Unable to load fixtures.',
                    style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                  ),
                ),
                data: (fixtures) {
                  if (fixtures.isEmpty) {
                    return Center(
                      child: Text(
                        'No fixtures scheduled yet.',
                        style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                      ),
                    );
                  }

                  final grouped = _groupByDate(fixtures);

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppTokens.space24),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, idx) {
                      final dateKey = grouped.keys.elementAt(idx);
                      final dateFixtures = grouped[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppTokens.screenGutter,
                              top: AppTokens.space16,
                              bottom: AppTokens.space8,
                            ),
                            child: Text(
                              dateKey,
                              style: AppTextStyles.label.copyWith(
                                color: AppTokens.textSecondary,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          ...dateFixtures.map(_buildFixtureRow),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
