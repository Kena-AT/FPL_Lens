import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/availability_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../data/repositories/fpl_repository.dart';

class PlayerDetailScreen extends ConsumerStatefulWidget {
  final int fplId;
  final int? gameweek;

  const PlayerDetailScreen({
    super.key,
    required this.fplId,
    this.gameweek,
  });

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  bool _isLoading = true;
  AppError? _error;
  bool _isNotFound = false;
  Map<String, dynamic>? _data;
  late int _selectedGw;

  @override
  void initState() {
    super.initState();
    _selectedGw = widget.gameweek ?? 1;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isNotFound = false;
    });

    try {
      final repo = ref.read(fplRepositoryProvider);
      int targetGw = _selectedGw;

      if (widget.gameweek == null && targetGw == 1) {
        try {
          final gwMeta = await repo.getCurrentGameweek();
          targetGw = gwMeta.next?.id ?? gwMeta.current?.id ?? 1;
          _selectedGw = targetGw;
        } catch (_) {
          targetGw = 1;
        }
      }

      final res = await repo.getPlayerProjection(targetGw, widget.fplId);
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (e is AppError) {
        if (e.kind == AppErrorKind.notFound || e.message.contains('404')) {
          setState(() {
            _isNotFound = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = e;
            _isLoading = false;
          });
        }
      } else {
        final msg = e.toString();
        if (msg.contains('NOT_FOUND') || msg.contains('404')) {
          setState(() {
            _isNotFound = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = const AppError(
              kind: AppErrorKind.unknown,
              message: 'Failed to load player details. Please check connection.',
              retryable: true,
            );
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onGameweekChanged(int newGw) {
    if (newGw == _selectedGw) return;
    setState(() => _selectedGw = newGw);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          backgroundColor: colors.bgSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Loading...', style: AppTextStyles.headline.copyWith(color: colors.textPrimary)),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.accent),
        ),
      );
    }

    if (_isNotFound) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          backgroundColor: colors.bgSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Player Detail', style: AppTextStyles.headline.copyWith(color: colors.textPrimary)),
        ),
        body: EmptyState(
          icon: Icons.person_off_rounded,
          title: 'Player not found',
          body: 'We could not find player #${widget.fplId} in our records.',
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          backgroundColor: colors.bgSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Player Detail', style: AppTextStyles.headline.copyWith(color: colors.textPrimary)),
        ),
        body: Center(
          child: ErrorState(
            error: _error!,
            onRetry: _loadData,
          ),
        ),
      );
    }

    final player = _data?['player'] as Map<String, dynamic>?;
    final fixtures = (_data?['fixtures'] as List<dynamic>?) ?? [];
    final webName = player?['web_name'] as String? ?? 'Player #${widget.fplId}';
    final position = player?['position'] as String? ?? '–';
    final teamShort = player?['team_short_name'] as String? ?? '–';
    final nowCost = player?['now_cost'] as int? ?? 0;
    final status = player?['status'] as String?;
    final chance = player?['chance_of_playing_next_round'] as int?;
    final news = player?['news'] as String?;
    final inputsAsOfStr = _data?['inputs_as_of'] as String?;
    final inputsAsOf = inputsAsOfStr != null ? DateTime.tryParse(inputsAsOfStr) : null;
    final modelVersion = (_data?['model_version'] as String?) ?? 'xp-v1.5.0';

    final hasFixtures = fixtures.isNotEmpty;
    final primaryFixture = hasFixtures ? fixtures.first as Map<String, dynamic> : null;
    final xp = (primaryFixture?['expected_points'] as num?)?.toDouble() ?? 0.0;
    final isHome = primaryFixture?['is_home'] as bool?;
    final oppShort = primaryFixture?['opponent_short_name'] as String?;
    final kickoff = primaryFixture?['kickoff_time'] as String?;

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
          webName,
          style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
        ),
        actions: [
          // Gameweek selector
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedGw,
                dropdownColor: colors.bgElevated,
                icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
                items: List.generate(38, (i) => i + 1).map((gw) {
                  return DropdownMenuItem<int>(
                    value: gw,
                    child: Text(
                      'GW $gw',
                      style: AppTextStyles.label.copyWith(
                        color: gw == _selectedGw ? colors.accent : colors.textPrimary,
                        fontWeight: gw == _selectedGw ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onGameweekChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          children: [
            // 1. Header card: Name, Club, Position, Price, Availability
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space8,
                          vertical: AppTokens.space2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentSoft.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                        ),
                        child: Text(
                          position,
                          style: AppTextStyles.label.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Text(
                        teamShort,
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppFormatters.formatMoneyTenths(nowCost),
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AvailabilityBadge.fromStatus(
                        status: status,
                        chanceOfPlaying: chance,
                      ),
                      if (inputsAsOf != null)
                        Flexible(
                          child: FreshnessLabel(
                            lastUpdated: inputsAsOf,
                            staleThreshold: const Duration(minutes: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),

            // 2. Hero Card (layered): projected points in Hero numeral (32 sp), model label xp-v1.5.0
            if (hasFixtures && primaryFixture != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next Gameweek Projection',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.bgElevated,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.borderSubtle, width: 0.5),
                          ),
                          child: Text(
                            modelVersion,
                            style: AppTextStyles.caption.copyWith(
                              color: colors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          AppFormatters.formatXp(xp),
                          style: AppTextStyles.numeric.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: AppTokens.space8),
                        Text(
                          'xP',
                          style: AppTextStyles.label.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      _formatFixtureLine(oppShort, isHome, kickoff),
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space16),

              // 3. Attribution List (positive terms in textPrimary/accent, negative in statusError with ▼)
              Text(
                'Projection Breakdown',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              _buildAttributionList(primaryFixture, colors),
              const SizedBox(height: AppTokens.space16),

              // 4. Opponent Intensity / Fixture Difficulty
              if (primaryFixture['opponent_attack_strength'] != null ||
                  primaryFixture['opponent_defence_strength'] != null) ...[
                Text(
                  'Opponent Intensity',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 18,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Container(
                  padding: const EdgeInsets.all(AppTokens.space16),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opponent Attack',
                              style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                            ),
                            const SizedBox(height: AppTokens.space4),
                            Text(
                              '${primaryFixture['opponent_attack_strength'] ?? '–'}',
                              style: AppTextStyles.numeric.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opponent Defence',
                              style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                            ),
                            const SizedBox(height: AppTokens.space4),
                            Text(
                              '${primaryFixture['opponent_defence_strength'] ?? '–'}',
                              style: AppTextStyles.numeric.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],

              // 5. Upcoming fixtures cards (§8.12: horizontal list with opponent, venue, and FDR as text)
              if (fixtures.length > 1) ...[
                Text(
                  'Upcoming Fixtures',
                  style: AppTextStyles.headline.copyWith(
                    fontSize: 18,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fixtures.length - 1,
                    separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space8),
                    itemBuilder: (context, index) {
                      final f = fixtures[index + 1] as Map<String, dynamic>;
                      final opp = f['opponent_short_name'] as String? ?? 'OPP';
                      final isH = f['is_home'] as bool?;
                      final venue = isH == true ? 'H' : (isH == false ? 'A' : '');
                      final diff = f['difficulty'] ?? 3;
                      final fXp = (f['expected_points'] as num?)?.toDouble();

                      return Container(
                        width: 110,
                        padding: const EdgeInsets.all(AppTokens.space8),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$opp ($venue)',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'FDR $diff',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (fXp != null)
                              Text(
                                '${fXp.toStringAsFixed(1)} xP',
                                style: AppTextStyles.numeric.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],
            ] else ...[
              // State: No projection for this player (§9.3: player.noProjection)
              Container(
                padding: const EdgeInsets.all(AppTokens.space24),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Center(
                  child: Text(
                    'No projection for $webName in this gameweek.',
                    style: AppTextStyles.body.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space16),
            ],

            // 6. Injury News (if any)
            if (news != null && news.trim().isNotEmpty) ...[
              Text(
                'Injury News',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              Container(
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    Text(
                      'Source: FPL',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space24),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFixtureLine(String? opp, bool? isHome, String? kickoff) {
    final venue = isHome == true ? 'H' : (isHome == false ? 'A' : '');
    final oppText = opp != null ? (venue.isNotEmpty ? 'vs $opp ($venue)' : 'vs $opp') : 'Upcoming Fixture';
    if (kickoff != null && kickoff.isNotEmpty) {
      final dt = DateTime.tryParse(kickoff);
      if (dt != null) {
        return '$oppText, ${dt.day} ${_monthName(dt.month)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    return oppText;
  }

  static String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? m[month - 1] : '';
  }

  Widget _buildAttributionList(Map<String, dynamic> f, AppColors colors) {
    final items = <_AttributionItem>[];

    // 1. Availability
    if (f['availability'] != null) {
      final val = (f['availability'] as num).toDouble();
      final pct = (val <= 1.0 ? val * 100 : val).round();
      items.add(_AttributionItem(
        label: 'Availability (α)',
        value: '$pct%',
        explanation: 'Share of expected availability.',
        accessibleText: 'Availability, $pct percent',
        isNegative: false,
      ));
    }

    // 2. Start probability
    if (f['p_start'] != null) {
      final val = (f['p_start'] as num).toDouble();
      final pct = (val <= 1.0 ? val * 100 : val).round();
      items.add(_AttributionItem(
        label: 'Start probability',
        value: '$pct%',
        explanation: 'Probability of starting in XI.',
        accessibleText: 'Start probability, $pct percent',
        isNegative: false,
      ));
    }

    // 3. Expected minutes
    if (f['expected_minutes'] != null) {
      final val = (f['expected_minutes'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Expected minutes',
        value: val.toStringAsFixed(0),
        explanation: 'Projected playing time.',
        accessibleText: 'Expected minutes, ${val.toStringAsFixed(0)}',
        isNegative: false,
      ));
    }

    // 4. Expected goals
    if (f['exp_goals'] != null) {
      final val = (f['exp_goals'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Expected goals (xG)',
        value: val.toStringAsFixed(2),
        explanation: 'Expected goal scoring returns.',
        accessibleText: 'Expected goals, ${val.toStringAsFixed(2)}',
        isNegative: false,
      ));
    }

    // 5. Expected assists
    if (f['exp_assists'] != null) {
      final val = (f['exp_assists'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Expected assists (xA)',
        value: val.toStringAsFixed(2),
        explanation: 'Expected goal creation returns.',
        accessibleText: 'Expected assists, ${val.toStringAsFixed(2)}',
        isNegative: false,
      ));
    }

    // 6. Clean sheet probability
    if (f['exp_clean_sheet'] != null) {
      final val = (f['exp_clean_sheet'] as num).toDouble();
      final pct = (val <= 1.0 ? val * 100 : val).round();
      items.add(_AttributionItem(
        label: 'Clean sheet probability',
        value: '$pct%',
        explanation: 'Clean sheet bonus probability.',
        accessibleText: 'Clean sheet probability, $pct percent',
        isNegative: false,
      ));
    }

    // 7. Goals conceded penalty
    if (f['exp_goals_conceded'] != null) {
      final val = (f['exp_goals_conceded'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Goals-conceded penalty',
        value: val.toStringAsFixed(2),
        explanation: 'Expected points deduction from goals conceded.',
        accessibleText: 'Goals conceded penalty, ${val.toStringAsFixed(2)}',
        isNegative: val < 0,
      ));
    }

    // 8. Defensive contributions
    if (f['exp_dc'] != null) {
      final val = (f['exp_dc'] as num).toDouble();
      final pct = (val <= 1.0 ? val * 100 : val).round();
      items.add(_AttributionItem(
        label: 'Defensive contributions',
        value: '$pct%',
        explanation: 'Chance of hitting defensive contribution threshold.',
        accessibleText: 'Defensive contributions, $pct percent',
        isNegative: false,
      ));
    }

    // 9. Expected bonus
    if (f['exp_bonus'] != null) {
      final val = (f['exp_bonus'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Expected bonus',
        value: val.toStringAsFixed(2),
        explanation: 'Estimated bonus points from BPS ranking.',
        accessibleText: 'Expected bonus, ${val.toStringAsFixed(2)}',
        isNegative: false,
      ));
    }

    // 10. Card penalty
    if (f['exp_card_penalty'] != null) {
      final val = (f['exp_card_penalty'] as num).toDouble();
      items.add(_AttributionItem(
        label: 'Card penalty',
        value: val.toStringAsFixed(2),
        explanation: 'Deductions for projected yellow/red cards.',
        accessibleText: 'Card penalty, ${val.toStringAsFixed(2)}',
        isNegative: val < 0,
      ));
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(
          'Component details not available.',
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colors.borderSubtle,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final valueColor = item.isNegative ? colors.statusError : colors.textPrimary;

          return Semantics(
            label: item.accessibleText,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space16,
                vertical: AppTokens.space12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          item.explanation,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isNegative) ...[
                        Icon(Icons.arrow_drop_down, color: colors.statusError, size: 18),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        item.value,
                        style: AppTextStyles.numeric.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttributionItem {
  final String label;
  final String value;
  final String explanation;
  final String accessibleText;
  final bool isNegative;

  const _AttributionItem({
    required this.label,
    required this.value,
    required this.explanation,
    required this.accessibleText,
    required this.isNegative,
  });
}
