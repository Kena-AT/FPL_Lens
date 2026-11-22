import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/availability_badge.dart';
import '../../../core/widgets/delta_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/freshness_label.dart';
import '../../../core/widgets/stat_badge.dart';
import '../providers/squad_provider.dart';

enum SquadViewMode {
  list,
  pitch,
}

/// Squad screen (/squad) per Visual Redesign Design Document §8.8 & Sprint R4.
///
/// Features:
/// - Segmented control switcher: List | Pitch
/// - List View: Position group headers (modular tiles), AvailabilityBadge (6dp dot + icon + label),
///   player details, CP/SP prices, and DeltaChip price variance
/// - Pitch View: Full 15-player 2-5-5-3 tactical pitch canvas
/// - Sticky bottom summary dock: Total value, bank, and Edit Prices CTA
/// - Full 200% text scale and dual-theme accessibility compliance
class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key});

  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends ConsumerState<SquadScreen> {
  SquadViewMode _viewMode = SquadViewMode.list;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final squadState = ref.watch(squadNotifierProvider);
    final players = squadState.squad;

    final totalSquadValueTenths = players.fold<int>(
      0,
      (sum, p) => sum + p.nowCostTenths,
    );
    final effectiveSquadValue = squadState.squadValueTenths > 0
        ? squadState.squadValueTenths
        : (totalSquadValueTenths > 0 ? totalSquadValueTenths : 1000);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 68.0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppTokens.screenGutter,
        title: Text(
          'Squad',
          style: AppTextStyles.title.copyWith(
            fontSize: 24.0,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            tooltip: 'Refresh squad',
            onPressed: () async {
              final notice = await ref.read(squadNotifierProvider.notifier).refreshSquad(force: true);
              if (notice != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(notice),
                    duration: const Duration(seconds: 2),
                    backgroundColor: colors.bgElevated,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: players.isEmpty
          ? EmptyState(
              icon: Icons.group_off_outlined,
              title: 'No squad loaded',
              body: 'Enter your FPL Team ID to load your squad.',
              actionLabel: 'Enter Team ID',
              onAction: () => context.go('/onboarding/team'),
            )
          : Column(
              children: [
                // 1. View Switcher (List | Pitch) & Freshness Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenGutter,
                    vertical: AppTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    border: Border(bottom: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: [
                      SegmentedButton<SquadViewMode>(
                        segments: const [
                          ButtonSegment(
                            value: SquadViewMode.list,
                            label: Text('List'),
                            icon: Icon(Icons.list_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: SquadViewMode.pitch,
                            label: Text('Pitch'),
                            icon: Icon(Icons.sports_soccer_rounded, size: 16),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (val) {
                          setState(() {
                            _viewMode = val.first;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return colors.accent.withValues(alpha: 0.18);
                            }
                            return colors.bgSurface;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return colors.accent;
                            }
                            return colors.textSecondary;
                          }),
                        ),
                      ),
                      FreshnessLabel(
                        lastUpdated: squadState.lastSyncTime ?? DateTime.now(),
                      ),
                    ],
                  ),
                ),

                // 2. Main View Content (List or Pitch)
                Expanded(
                  child: _viewMode == SquadViewMode.list
                      ? _buildListView(players, colors)
                      : _buildPitchView(players, colors),
                ),

                // 3. Fixed Bottom Summary Dock (§8.8)
                _buildSummaryDock(effectiveSquadValue, squadState.bankTenths, colors),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // List View (§8.8)
  // ---------------------------------------------------------------------------
  Widget _buildListView(List<SquadPlayersTableData> players, AppColors colors) {
    final gks = players.where((p) => p.position == 'GK' || p.position == 'GKP').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final defs = players.where((p) => p.position == 'DEF').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final mids = players.where((p) => p.position == 'MID').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));
    final fwds = players.where((p) => p.position == 'FWD').toList()
      ..sort((a, b) => b.nowCostTenths.compareTo(a.nowCostTenths));

    return ListView(
      padding: const EdgeInsets.only(bottom: AppTokens.space16),
      children: [
        if (gks.isNotEmpty) ...[
          _buildGroupHeader('Goalkeepers', gks.length, colors),
          ...gks.map((p) => _buildPlayerRow(p, colors)),
        ],
        if (defs.isNotEmpty) ...[
          _buildGroupHeader('Defenders', defs.length, colors),
          ...defs.map((p) => _buildPlayerRow(p, colors)),
        ],
        if (mids.isNotEmpty) ...[
          _buildGroupHeader('Midfielders', mids.length, colors),
          ...mids.map((p) => _buildPlayerRow(p, colors)),
        ],
        if (fwds.isNotEmpty) ...[
          _buildGroupHeader('Forwards', fwds.length, colors),
          ...fwds.map((p) => _buildPlayerRow(p, colors)),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String title, int count, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space12,
      ),
      color: colors.bgBase,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: colors.textDisabled,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(SquadPlayersTableData player, AppColors colors) {
    final profitLossTenths = player.sellingPriceTenths - player.purchasePriceTenths;
    final profitLossDelta = profitLossTenths / 10.0;

    final availabilityVariant = _mapAvailability(player.status);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final isAccessibilityScale = textScale > 1.3;

    if (isAccessibilityScale) {
      return InkWell(
        onTap: () => context.push('/player/${player.fplId}'),
        onLongPress: () => _showPriceInfoSheet(player, colors),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space12,
          ),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border(bottom: BorderSide(color: colors.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppTokens.space8,
                runSpacing: AppTokens.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AvailabilityBadge(
                    variant: availabilityVariant,
                    chanceOfPlaying: player.chanceOfPlayingNextRound,
                    compact: true,
                  ),
                  Text(
                    player.webName,
                    style: AppTextStyles.body.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (player.isCaptain)
                    _buildCaptainBadge('C', colors.accent, colors.bgBase)
                  else if (player.isViceCaptain)
                    _buildCaptainBadge('V', colors.textSecondary, colors.bgBase),
                ],
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                '${player.teamShortName} • ${player.position}',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTokens.space8),
              Wrap(
                spacing: AppTokens.space12,
                runSpacing: AppTokens.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'CP: ${AppFormatters.formatMoneyTenths(player.nowCostTenths)}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'SP: ${AppFormatters.formatMoneyTenths(player.sellingPriceTenths)}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DeltaChip.price(
                    delta: profitLossDelta,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/player/${player.fplId}'),
      onLongPress: () => _showPriceInfoSheet(player, colors),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.screenGutter,
          vertical: AppTokens.space12,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
        child: Row(
          children: [
            // Availability badge (§6.1: 6dp dot + icon + label)
            AvailabilityBadge(
              variant: availabilityVariant,
              chanceOfPlaying: player.chanceOfPlayingNextRound,
              compact: true,
            ),
            const SizedBox(width: AppTokens.space12),

            // Player name and team short code
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.webName,
                          style: AppTextStyles.body.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.isCaptain) ...[
                        const SizedBox(width: AppTokens.space4),
                        _buildCaptainBadge('C', colors.accent, colors.bgBase),
                      ] else if (player.isViceCaptain) ...[
                        const SizedBox(width: AppTokens.space4),
                        _buildCaptainBadge('V', colors.textSecondary, colors.bgBase),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    '${player.teamShortName} • ${player.position}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space8),

            // Price figures (CP, SP) and profit/loss DeltaChip
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CP: ${AppFormatters.formatMoneyTenths(player.nowCostTenths)}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Text(
                      'SP: ${AppFormatters.formatMoneyTenths(player.sellingPriceTenths)}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                DeltaChip.price(
                  delta: profitLossDelta,
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptainBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pitch View (2-5-5-3 Tactical Canvas per §8.8 & §8.9)
  // ---------------------------------------------------------------------------
  Widget _buildPitchView(List<SquadPlayersTableData> players, AppColors colors) {
    final gks = players.where((p) => p.position == 'GK' || p.position == 'GKP').toList();
    final defs = players.where((p) => p.position == 'DEF').toList();
    final mids = players.where((p) => p.position == 'MID').toList();
    final fwds = players.where((p) => p.position == 'FWD').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space12,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: colors.borderSubtle, width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: CustomPaint(
            painter: _SquadPitchPainter(colors: colors),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space24, horizontal: AppTokens.space8),
              child: Column(
                children: [
                  // Row 1: Goalkeepers (2)
                  _buildPitchPlayerRow(gks, colors),
                  const SizedBox(height: AppTokens.space24),

                  // Row 2: Defenders (5)
                  _buildPitchPlayerRow(defs, colors),
                  const SizedBox(height: AppTokens.space24),

                  // Row 3: Midfielders (5)
                  _buildPitchPlayerRow(mids, colors),
                  const SizedBox(height: AppTokens.space24),

                  // Row 4: Forwards (3)
                  _buildPitchPlayerRow(fwds, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPitchPlayerRow(List<SquadPlayersTableData> rowPlayers, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rowPlayers.map((player) {
        return Flexible(
          child: GestureDetector(
            onTap: () => context.push('/player/${player.fplId}'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: colors.bgSurface.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(AppTokens.radiusBase),
                border: Border.all(
                  color: player.isCaptain
                      ? colors.accent
                      : colors.borderSubtle,
                  width: player.isCaptain ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shirt icon & captain indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.sports_soccer_rounded,
                        size: 20.0,
                        color: colors.accent,
                      ),
                      if (player.isCaptain)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: _buildCaptainBadge('C', colors.accent, colors.bgBase),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    player.webName,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    AppFormatters.formatMoneyTenths(player.sellingPriceTenths),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky Bottom Summary Dock (§8.8)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryDock(int squadValueTenths, int bankTenths, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenGutter,
        vertical: AppTokens.space12,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTokens.space16,
          runSpacing: AppTokens.space8,
          children: [
            Wrap(
              spacing: AppTokens.space16,
              runSpacing: AppTokens.space4,
              children: [
                StatBadge(
                  label: 'SQUAD VALUE',
                  value: AppFormatters.formatMoneyTenths(squadValueTenths),
                  size: StatBadgeSize.medium,
                ),
                StatBadge(
                  label: 'BANK',
                  value: AppFormatters.formatMoneyTenths(bankTenths),
                  size: StatBadgeSize.medium,
                ),
              ],
            ),
            AppButton(
              label: 'Edit Prices',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.push('/squad/prices'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceInfoSheet(SquadPlayersTableData player, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusModal)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  player.webName,
                  style: AppTextStyles.headline.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Current Cost: ${AppFormatters.formatMoneyTenths(player.nowCostTenths)} • Purchase: ${AppFormatters.formatMoneyTenths(player.purchasePriceTenths)}',
                  style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Selling Price: ${AppFormatters.formatMoneyTenths(player.sellingPriceTenths)} (${player.priceSource})',
                  style: AppTextStyles.body.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTokens.space24),
                AppButton(
                  label: 'Edit Purchase Price',
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/squad/prices');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AvailabilityVariant _mapAvailability(String status) {
    switch (status.toLowerCase()) {
      case 'i':
      case 'injured':
        return AvailabilityVariant.injured;
      case 'd':
      case 'doubtful':
        return AvailabilityVariant.doubtful;
      case 's':
      case 'suspended':
        return AvailabilityVariant.suspended;
      case 'u':
      case 'unavailable':
        return AvailabilityVariant.unknown;
      case 'a':
      case 'available':
      default:
        return AvailabilityVariant.fit;
    }
  }
}

class _SquadPitchPainter extends CustomPainter {
  final AppColors colors;

  _SquadPitchPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.pitchTop, colors.pitchBottom],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const inset = 10.0;
    final pitchRect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);
    canvas.drawRect(pitchRect, linePaint);

    final midY = size.height / 2.0;
    canvas.drawLine(Offset(inset, midY), Offset(size.width - inset, midY), linePaint);

    final center = Offset(size.width / 2.0, midY);
    canvas.drawCircle(center, 36.0, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SquadPitchPainter oldDelegate) => false;
}
