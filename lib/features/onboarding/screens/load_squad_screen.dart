import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../squad/providers/squad_provider.dart';

class LoadSquadScreen extends ConsumerStatefulWidget {
  final int teamId;

  const LoadSquadScreen({super.key, required this.teamId});

  @override
  ConsumerState<LoadSquadScreen> createState() => _LoadSquadScreenState();
}

class _LoadSquadScreenState extends ConsumerState<LoadSquadScreen> {
  Timer? _cancelTimer;
  bool _canCancel = false;

  @override
  void initState() {
    super.initState();
    // 15-second timer before Cancel button appears per P6
    _cancelTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _canCancel = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int id = widget.teamId;
      if (id <= 0) {
        final secureStore = ref.read(secureStoreProvider);
        final user = ref.read(authNotifierProvider).user;
        id = user?.fplTeamId ?? (await secureStore.getFplTeamId()) ?? 0;
      }
      if (id > 0) {
        ref.read(squadNotifierProvider.notifier).loadSquadSequence(id, force: true);
      } else if (mounted) {
        context.go('/onboarding/team');
      }
    });
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);

    // Auto-navigate after 400ms when completed per P6
    ref.listen<SquadState>(squadNotifierProvider, (_, next) {
      if (next.step == SquadLoadingStep.completed) {
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          if (next.unconfirmedCount > 0) {
            router.go('/squad/prices');
          } else {
            router.go('/home');
          }
        });
      }
    });

    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final currentStepIndex = _getStepIndex(squadState.step);
    final progressFraction = (squadState.step == SquadLoadingStep.completed)
        ? 1.0
        : (currentStepIndex / 4.0).clamp(0.08, 1.0);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        title: Text('Loading your squad', style: AppTextStyles.title.copyWith(color: colors.textPrimary)),
        automaticallyImplyLeading: false,
        actions: [
          if (_canCancel && squadState.isLoading)
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (squadState.step != SquadLoadingStep.failed) ...[
                const Spacer(flex: 2),
                // Smooth loading line filling up
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: TweenAnimationBuilder<double>(
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0.08, end: progressFraction),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: colors.bgElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ] else ...[
                Builder(
                  builder: (context) {
                    final err = squadState.error ??
                        const AppError(
                          kind: AppErrorKind.unknown,
                          message: 'Could not load your squad from FPL.',
                          retryable: true,
                        );
                    final canUseScreenshot = err.kind == AppErrorKind.fplUnavailable ||
                        err.kind == AppErrorKind.timeout;
                    return ErrorState(
                      error: err,
                      onRetry: () {
                        ref.read(squadNotifierProvider.notifier).retryFailedStep(widget.teamId);
                      },
                      customActionLabel: canUseScreenshot ? 'Use screenshot instead' : null,
                      onCustomAction: canUseScreenshot ? () => context.push('/scan') : null,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _getStepIndex(SquadLoadingStep step) {
    switch (step) {
      case SquadLoadingStep.idle:
        return 0;
      case SquadLoadingStep.step1TeamDetails:
        return 1;
      case SquadLoadingStep.step2SquadPicks:
        return 2;
      case SquadLoadingStep.step3Transfers:
        return 3;
      case SquadLoadingStep.step4History:
        return 4;
      case SquadLoadingStep.completed:
        return 4;
      case SquadLoadingStep.failed:
        return 2;
    }
  }
}
