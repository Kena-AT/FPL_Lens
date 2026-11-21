import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/team_id_field.dart';
import '../../../data/models/fpl_models.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Team Check screen (/onboarding/team) per Visual Redesign Design Document §8.5 & Sprint R3.
///
/// Features large Team ID field, info card ("FPL Lens never asks for your FPL account password"),
/// confirmation card with manager name and rank, and continue button.
class TeamCheckScreen extends ConsumerStatefulWidget {
  const TeamCheckScreen({super.key});

  @override
  ConsumerState<TeamCheckScreen> createState() => _TeamCheckScreenState();
}

class _TeamCheckScreenState extends ConsumerState<TeamCheckScreen> {
  final TextEditingController _teamIdController = TextEditingController();
  bool _isLoading = false;
  bool _isEditingId = false;
  EntryModel? _entry;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTeamId();
    });
  }

  @override
  void dispose() {
    _teamIdController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialTeamId() async {
    final secureStore = ref.read(secureStoreProvider);
    final user = ref.read(authNotifierProvider).user;
    final teamId = user?.fplTeamId ?? await secureStore.getFplTeamId();

    if (teamId != null && teamId > 0) {
      _teamIdController.text = teamId.toString();
      _lookupTeam(teamId);
    } else {
      setState(() {
        _isEditingId = true;
      });
    }
  }

  Future<void> _lookupTeam(int teamId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fplRepo = ref.read(fplRepositoryProvider);
      final entry = await fplRepo.getEntry(teamId);
      setState(() {
        _entry = entry;
        _isLoading = false;
        _isEditingId = false;
      });
    } catch (e) {
      final appError = ErrorMapper.fromException(e);
      setState(() {
        _error = appError;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        title: Text('Your team', style: AppTextStyles.title.copyWith(color: colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/auth');
            }
          },
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEditingId) ...[
                        const SizedBox(height: AppTokens.space16),
                        TeamIdField(
                          controller: _teamIdController,
                          onResolved: (teamId) {
                            if (teamId != null) _lookupTeam(teamId);
                          },
                        ),
                        const SizedBox(height: AppTokens.space16),
                        AppButton(
                          label: 'Find team',
                          onPressed: _isLoading
                              ? null
                              : () {
                                  final id = int.tryParse(_teamIdController.text.trim());
                                  if (id != null) _lookupTeam(id);
                                },
                        ),
                        const SizedBox(height: AppTokens.space24),
                      ],
                      if (_isLoading) ...[
                        _buildSkeletonTeamCard(colors),
                      ] else if (_error != null) ...[
                        ErrorState(
                          error: _error!,
                          onRetry: () {
                            final id = int.tryParse(_teamIdController.text.trim());
                            if (id != null) _lookupTeam(id);
                          },
                          customActionLabel: 'Enter ID again',
                          onCustomAction: () {
                            setState(() {
                              _isEditingId = true;
                              _error = null;
                            });
                          },
                        ),
                      ] else if (_entry != null) ...[
                        _buildTeamCard(_entry!, colors),
                        const SizedBox(height: AppTokens.space24),
                        Text(
                          'Is this your team?',
                          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: AppTokens.space24),

                      // Privacy Info Card per §8.5 & §9.1 (team.info)
                      CardContainer(
                        variant: CardVariant.elevated,
                        padding: const EdgeInsets.all(AppTokens.space16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: colors.accent,
                              size: 20.0,
                            ),
                            const SizedBox(width: AppTokens.space12),
                            Expanded(
                              child: Text(
                                'FPL Lens never asks for your FPL account password.',
                                style: AppTextStyles.label.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_entry != null && !_isLoading && _error == null) ...[
                AppButton(
                  label: 'Confirm and load squad',
                  onPressed: () {
                    context.push('/onboarding/load', extra: _entry!.id);
                  },
                ),
                const SizedBox(height: AppTokens.space8),
                AppButton(
                  label: 'Not my team? Edit ID',
                  variant: AppButtonVariant.tertiary,
                  onPressed: () {
                    setState(() {
                      _isEditingId = true;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(EntryModel entry, AppColors colors) {
    final managerName = '${entry.playerFirstName} ${entry.playerLastName}'.trim();
    final rankText = entry.summaryOverallRank != null
        ? 'Rank ${AppFormatters.formatRank(entry.summaryOverallRank!)}'
        : 'Unranked';

    final semantics =
        'Team ${entry.name}, managed by $managerName, ${entry.summaryOverallPoints} points, $rankText';

    return Semantics(
      label: semantics,
      child: CardContainer(
        variant: CardVariant.surface,
        accentRing: true,
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.name,
                    style: AppTextStyles.title.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: colors.accentSoft.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTokens.radiusBase),
                  ),
                  child: Text(
                    'ID ${entry.id}',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              'Manager: $managerName',
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppTokens.space16),
            Divider(color: colors.borderSubtle, height: 1.0),
            const SizedBox(height: AppTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points',
                      style: AppTextStyles.label.copyWith(color: colors.textDisabled),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      AppFormatters.formatPoints(entry.summaryOverallPoints),
                      style: AppTextStyles.figure.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Overall Rank',
                      style: AppTextStyles.label.copyWith(color: colors.textDisabled),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      rankText,
                      style: AppTextStyles.figure.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTeamCard(AppColors colors) {
    return CardContainer(
      variant: CardVariant.surface,
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(width: 180, height: 24),
          SizedBox(height: AppTokens.space8),
          SkeletonLoader(width: 120, height: 16),
          SizedBox(height: AppTokens.space16),
          SkeletonLoader(width: double.infinity, height: 1),
          SizedBox(height: AppTokens.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 80, height: 32),
              SkeletonLoader(width: 80, height: 32),
            ],
          ),
        ],
      ),
    );
  }
}
