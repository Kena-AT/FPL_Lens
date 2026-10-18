import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatting/app_formatters.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/team_id_field.dart';
import '../../../data/models/fpl_models.dart';
import '../../../data/repositories/fpl_repository.dart';
import '../../auth/providers/auth_provider.dart';

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
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Your team', style: AppTextStyles.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/auth');
            }
          },
        ),
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
                        _buildSkeletonTeamCard(),
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
                        _buildTeamCard(_entry!),
                        const SizedBox(height: AppTokens.space24),
                        const Text(
                          'Is this your team?',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildTeamCard(EntryModel entry) {
    final managerName = '${entry.playerFirstName} ${entry.playerLastName}'.trim();
    final rankText = entry.summaryOverallRank != null
        ? 'Rank ${AppFormatters.formatRank(entry.summaryOverallRank!)}'
        : 'Unranked';

    final semantics =
        'Team ${entry.name}, managed by $managerName, ${entry.summaryOverallPoints} points, $rankText';

    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: AppTokens.bgSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: AppTokens.goldPrimary, size: 28),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: AppTextStyles.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (managerName.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          managerName,
                          style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space16),
            const Divider(color: AppTokens.borderSubtle, height: 1),
            const SizedBox(height: AppTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total points', style: AppTextStyles.label),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      '${entry.summaryOverallPoints} pts',
                      style: AppTextStyles.numeric.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Overall rank', style: AppTextStyles.label),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      rankText,
                      style: AppTextStyles.numeric.copyWith(fontSize: 18),
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

  Widget _buildSkeletonTeamCard() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.bgSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(width: 200, height: 24),
          SizedBox(height: AppTokens.space8),
          SkeletonLoader(width: 140, height: 16),
          SizedBox(height: AppTokens.space24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 80, height: 32),
              SkeletonLoader(width: 100, height: 32),
            ],
          ),
        ],
      ),
    );
  }
}
