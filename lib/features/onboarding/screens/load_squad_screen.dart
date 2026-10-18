import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/error_state.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(squadNotifierProvider.notifier).loadSquadSequence(widget.teamId);
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

    final currentStepIndex = _getStepIndex(squadState.step);
    final progressFraction = currentStepIndex / 4.0;

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        title: const Text('Loading your squad', style: AppTextStyles.title),
        automaticallyImplyLeading: false,
        actions: [
          if (_canCancel && squadState.isLoading)
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Cancel', style: TextStyle(color: AppTokens.textSecondary)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.space16),
              // Determinate progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 4,
                  backgroundColor: AppTokens.bgElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.neonPrimary),
                ),
              ),
              const SizedBox(height: AppTokens.space32),

              // 4 Step indicators
              _buildStepRow(
                index: 1,
                title: 'Team details',
                state: _getStepStatus(1, squadState),
              ),
              const SizedBox(height: AppTokens.space16),
              _buildStepRow(
                index: 2,
                title: 'Squad for this gameweek',
                state: _getStepStatus(2, squadState),
              ),
              const SizedBox(height: AppTokens.space16),
              _buildStepRow(
                index: 3,
                title: 'Transfer history',
                state: _getStepStatus(3, squadState),
              ),
              const SizedBox(height: AppTokens.space16),
              _buildStepRow(
                index: 4,
                title: 'Gameweek history',
                state: _getStepStatus(4, squadState),
              ),

              const SizedBox(height: AppTokens.space24),
              // Current step caption
              Text(
                _getStepCaption(squadState),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              if (squadState.step == SquadLoadingStep.failed) ...[
                ErrorState(
                  error: squadState.error ??
                      const AppError(
                        kind: AppErrorKind.unknown,
                        message: 'Could not load your squad from FPL.',
                        retryable: true,
                      ),
                  onRetry: () {
                    ref.read(squadNotifierProvider.notifier).retryFailedStep(widget.teamId);
                  },
                ),
                const SizedBox(height: AppTokens.space16),
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

  _StepVisualState _getStepStatus(int stepIndex, SquadState state) {
    if (state.step == SquadLoadingStep.failed && state.failedStep == stepIndex) {
      return _StepVisualState.failed;
    }

    final currentIndex = _getStepIndex(state.step);
    if (state.step == SquadLoadingStep.completed || currentIndex > stepIndex) {
      return _StepVisualState.done;
    } else if (currentIndex == stepIndex) {
      return _StepVisualState.active;
    } else {
      return _StepVisualState.pending;
    }
  }

  String _getStepCaption(SquadState state) {
    switch (state.step) {
      case SquadLoadingStep.idle:
      case SquadLoadingStep.step1TeamDetails:
        return 'Verifying team details...';
      case SquadLoadingStep.step2SquadPicks:
        return 'Fetching latest squad picks...';
      case SquadLoadingStep.step3Transfers:
        return 'Importing transfer history for price derivation...';
      case SquadLoadingStep.step4History:
        return 'Importing past gameweek ranks and scores...';
      case SquadLoadingStep.completed:
        return 'Squad loaded successfully!';
      case SquadLoadingStep.failed:
        return 'A network error occurred.';
    }
  }

  Widget _buildStepRow({
    required int index,
    required String title,
    required _StepVisualState state,
  }) {
    Widget iconWidget;
    Color textColor = AppTokens.textPrimary;

    switch (state) {
      case _StepVisualState.pending:
        iconWidget = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTokens.bgElevated,
          ),
          child: Text(
            '$index',
            style: AppTextStyles.caption.copyWith(color: AppTokens.textDisabled),
          ),
        );
        textColor = AppTokens.textDisabled;
        break;
      case _StepVisualState.active:
        iconWidget = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTokens.neonPrimary),
          ),
        );
        textColor = AppTokens.neonPrimary;
        break;
      case _StepVisualState.done:
        iconWidget = const Icon(
          Icons.check_circle_rounded,
          color: AppTokens.statusAvailable,
          size: 24,
        );
        textColor = AppTokens.textPrimary;
        break;
      case _StepVisualState.failed:
        iconWidget = const Icon(
          Icons.cancel_rounded,
          color: AppTokens.statusOut,
          size: 24,
        );
        textColor = AppTokens.statusOut;
        break;
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: AppTokens.space12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: textColor,
              fontWeight: state == _StepVisualState.active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

enum _StepVisualState {
  pending,
  active,
  done,
  failed,
}
