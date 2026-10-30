import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/squad_resolve_models.dart';
import '../../squad/providers/squad_provider.dart';

/// Screen P16: Resolve Players (/scan/resolve)
/// Paged cards for ambiguous or low-confidence player names extracted from a screenshot.
class ResolvePlayersScreen extends ConsumerStatefulWidget {
  final SquadResolveResponse resolveResponse;

  const ResolvePlayersScreen({
    super.key,
    required this.resolveResponse,
  });

  @override
  ConsumerState<ResolvePlayersScreen> createState() => _ResolvePlayersScreenState();
}

class _ResolvePlayersScreenState extends ConsumerState<ResolvePlayersScreen> {
  late final List<ResolvedPlayerResult> _unclearPlayers;
  late final List<ResolvedPlayerResult> _allPlayers;
  int _currentIndex = 0;

  // Selected candidate per unclear player index (null means 'None of these' selected, absent means pending)
  final Map<int, CandidateMatch?> _selections = {};

  @override
  void initState() {
    super.initState();
    _allPlayers = widget.resolveResponse.results;
    // Filter down to players that are not strong matches (confidence < 0.85 or not exact match)
    _unclearPlayers = _allPlayers.where((p) => !p.isStrongMatch).toList();

    // Pre-select best candidate if available with reasonable confidence
    for (int i = 0; i < _unclearPlayers.length; i++) {
      final p = _unclearPlayers[i];
      if (p.candidates.isNotEmpty) {
        _selections[i] = p.candidates.first;
      }
    }
  }

  bool get _isAllResolvedOrMarked {
    return _selections.length == _unclearPlayers.length;
  }

  Future<void> _handleConfirmAndContinue() async {
    final companions = <SquadPlayersTableCompanion>[];

    int playerOrder = 1;

    for (final player in _allPlayers) {
      if (player.isStrongMatch) {
        final c = player.candidates.isNotEmpty ? player.candidates.first : null;
        final fplId = player.bestMatchFplId ?? c?.fplId ?? (9000 + playerOrder);
        final webName = c?.webName ?? player.rawName;
        final pos = c?.position ?? (player.slot ?? 'MID');
        final team = c?.teamShortName ?? 'PL';
        final nowCost = c?.nowCostTenths ?? 60;

        companions.add(
          SquadPlayersTableCompanion(
            fplId: drift.Value(fplId),
            webName: drift.Value(webName),
            position: drift.Value(pos),
            teamId: drift.Value(c?.teamFplId ?? 1),
            teamShortName: drift.Value(team),
            purchasePriceTenths: drift.Value(nowCost),
            sellingPriceTenths: drift.Value(nowCost),
            nowCostTenths: drift.Value(nowCost),
            status: const drift.Value('a'),
            chanceOfPlayingNextRound: const drift.Value(100),
            isCaptain: drift.Value(playerOrder == 1),
            isViceCaptain: drift.Value(playerOrder == 2),
            multiplier: drift.Value(playerOrder == 1 ? 2 : 1),
            positionOrder: drift.Value(playerOrder),
            priceSource: const drift.Value('CONFIRM'),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      } else {
        final unclearIdx = _unclearPlayers.indexOf(player);
        final chosen = _selections[unclearIdx];

        final fplId = chosen?.fplId ?? (9000 + playerOrder);
        final webName = chosen?.webName ?? player.rawName;
        final pos = chosen?.position ?? (player.slot ?? 'MID');
        final team = chosen?.teamShortName ?? 'PL';
        final nowCost = chosen?.nowCostTenths ?? 60;

        companions.add(
          SquadPlayersTableCompanion(
            fplId: drift.Value(fplId),
            webName: drift.Value(webName),
            position: drift.Value(pos),
            teamId: drift.Value(chosen?.teamFplId ?? 1),
            teamShortName: drift.Value(team),
            purchasePriceTenths: drift.Value(nowCost),
            sellingPriceTenths: drift.Value(nowCost),
            nowCostTenths: drift.Value(nowCost),
            status: const drift.Value('a'),
            chanceOfPlayingNextRound: const drift.Value(100),
            isCaptain: drift.Value(playerOrder == 1),
            isViceCaptain: drift.Value(playerOrder == 2),
            multiplier: drift.Value(playerOrder == 1 ? 2 : 1),
            positionOrder: drift.Value(playerOrder),
            priceSource: const drift.Value('CONFIRM'),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }
      playerOrder++;
    }

    await ref.read(squadNotifierProvider.notifier).saveScanResolvedSquad(companions);

    if (mounted) {
      context.go('/squad/prices');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unclearPlayers.isEmpty) {
      // Nothing unclear, proceed directly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleConfirmAndContinue();
      });
      return const Scaffold(
        backgroundColor: AppTokens.bgBase,
        body: Center(
          child: CircularProgressIndicator(color: AppTokens.goldPrimary),
        ),
      );
    }

    final current = _unclearPlayers[_currentIndex];
    final selectedCandidate = _selections[_currentIndex];
    final isNoneOfThese = _selections.containsKey(_currentIndex) && selectedCandidate == null;

    final totalCount = _unclearPlayers.length;
    final positionLabel = current.slot != null ? 'Slot: ${current.slot}' : 'Unassigned slot';

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        backgroundColor: AppTokens.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
          onPressed: () {
            if (_currentIndex > 0) {
              setState(() => _currentIndex--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Confirm players',
          style: AppTextStyles.headline.copyWith(fontSize: 18.0),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.screenGutter),
            child: Center(
              child: Text(
                '${_currentIndex + 1} of $totalCount',
                style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenGutter,
            vertical: AppTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card with OCR text and slot
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: AppTokens.bgSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppTokens.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READ FROM SCREENSHOT',
                      style: AppTextStyles.label.copyWith(
                        color: AppTokens.textDisabled,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      current.rawName,
                      style: AppTextStyles.headline.copyWith(
                        color: AppTokens.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      positionLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTokens.neonPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space24),

              Text(
                'SELECT MATCHING PLAYER',
                style: AppTextStyles.label.copyWith(
                  color: AppTokens.textDisabled,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppTokens.space8),

              // Candidates list
              Expanded(
                child: ListView(
                  children: [
                    if (current.candidates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppTokens.space16),
                        decoration: BoxDecoration(
                          color: AppTokens.bgSurface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                          border: Border.all(color: AppTokens.borderSubtle),
                        ),
                        child: Text(
                          "We couldn't match this name. Choose 'None of these'.",
                          style: AppTextStyles.body.copyWith(
                            color: AppTokens.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...current.candidates.map((candidate) {
                        final isSelected = selectedCandidate?.fplId == candidate.fplId;
                        return _buildCandidateRow(candidate, isSelected);
                      }),
                    const SizedBox(height: AppTokens.space12),

                    // "None of these" tertiary option
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selections[_currentIndex] = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space16,
                            vertical: AppTokens.space12,
                          ),
                          decoration: BoxDecoration(
                            color: isNoneOfThese ? AppTokens.bgElevated : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                            border: Border.all(
                              color: isNoneOfThese ? AppTokens.neonPrimary : AppTokens.borderSubtle,
                              width: isNoneOfThese ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isNoneOfThese
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: isNoneOfThese ? AppTokens.neonPrimary : AppTokens.textDisabled,
                              ),
                              const SizedBox(width: AppTokens.space12),
                              Text(
                                'None of these (manual entry later)',
                                style: AppTextStyles.body.copyWith(
                                  color: isNoneOfThese ? AppTokens.neonPrimary : AppTokens.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Paging buttons
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: AppButton(
                        label: 'Previous',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _currentIndex--);
                        },
                      ),
                    ),
                  if (_currentIndex > 0 && _currentIndex < totalCount - 1)
                    const SizedBox(width: AppTokens.space12),
                  if (_currentIndex < totalCount - 1)
                    Expanded(
                      child: AppButton(
                        label: 'Next',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {
                          setState(() => _currentIndex++);
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),

              // Confirm and continue
              AppButton(
                label: 'Confirm and continue',
                onPressed: _isAllResolvedOrMarked ? _handleConfirmAndContinue : null,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateRow(CandidateMatch candidate, bool isSelected) {
    Color confidenceColor = AppTokens.statusAvailable;
    String matchLabel = 'Strong match';

    if (candidate.confidence < 0.60) {
      confidenceColor = AppTokens.statusOut;
      matchLabel = 'Weak match';
    } else if (candidate.confidence < 0.85) {
      confidenceColor = AppTokens.statusDoubtful;
      matchLabel = 'Possible match';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selections[_currentIndex] = candidate;
            });
          },
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space12),
            decoration: BoxDecoration(
              color: AppTokens.bgSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: isSelected ? AppTokens.neonPrimary : AppTokens.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSelected ? AppTokens.neonPrimary : AppTokens.textDisabled,
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.webName,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 16,
                          color: AppTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${candidate.teamShortName} • ${candidate.position} • £${(candidate.nowCostTenths / 10).toStringAsFixed(1)}m',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Text(
                    matchLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: confidenceColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
