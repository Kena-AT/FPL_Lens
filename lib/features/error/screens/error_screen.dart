import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/events.dart';
import '../../../core/network/error_mapper.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../squad/providers/squad_provider.dart';

class ErrorScreenArgs {
  final AppError error;
  final VoidCallback? onRetry;
  final String? fromScreen;
  final DateTime? lastUpdated;

  const ErrorScreenArgs({
    required this.error,
    this.onRetry,
    this.fromScreen,
    this.lastUpdated,
  });
}

/// Screen P20: Error and offline (`/error`) per Frontend Implementation Plan Part E.
/// Dedicated full-screen recovery shell for unrecoverable errors and complete network loss.
class ErrorScreen extends ConsumerStatefulWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final String fromScreen;
  final DateTime? lastUpdated;

  const ErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
    this.fromScreen = 'unknown',
    this.lastUpdated,
  });

  @override
  ConsumerState<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends ConsumerState<ErrorScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
            AnalyticsEvent.errorShown(
              errorKind: widget.error.kind.name,
              screen: widget.fromScreen,
            ),
          );
    });
  }

  bool _canPop(BuildContext context) {
    try {
      return Navigator.of(context).canPop();
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      if (widget.onRetry != null) {
        widget.onRetry!();
      } else {
        try {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        } catch (_) {
          Navigator.of(context).maybePop();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  void _handleGoToSavedData() {
    try {
      context.go('/home');
    } catch (_) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      try {
        context.go('/auth');
      } catch (_) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  IconData _getIcon() {
    switch (widget.error.kind) {
      case AppErrorKind.offline:
        return Icons.wifi_off_rounded;
      case AppErrorKind.server:
        return Icons.dns_rounded;
      case AppErrorKind.timeout:
      case AppErrorKind.projectionsUnavailable:
      case AppErrorKind.fplUnavailable:
        return Icons.cloud_off_rounded;
      case AppErrorKind.rateLimited:
        return Icons.timer_outlined;
      default:
        return Icons.error_outline_rounded;
    }
  }

  String _getTitle() {
    switch (widget.error.kind) {
      case AppErrorKind.offline:
        return 'No connection';
      case AppErrorKind.server:
        return 'Server error';
      case AppErrorKind.timeout:
        return 'Connection timed out';
      case AppErrorKind.fplUnavailable:
        return 'FPL unavailable';
      case AppErrorKind.projectionsUnavailable:
        return 'Projections unavailable';
      case AppErrorKind.rateLimited:
        return 'Too many attempts';
      default:
        return 'Something went wrong';
    }
  }

  String _getBody() {
    switch (widget.error.kind) {
      case AppErrorKind.offline:
        return "You're offline. Check your internet connection.";
      case AppErrorKind.server:
        return 'Something went wrong on our side. Try again.';
      case AppErrorKind.timeout:
        return 'The request took too long. Try again.';
      case AppErrorKind.fplUnavailable:
        return 'Fantasy Premier League servers are currently unavailable. Try again shortly.';
      case AppErrorKind.projectionsUnavailable:
        return 'Projections are currently unavailable. Try again shortly.';
      case AppErrorKind.rateLimited:
        final mins = widget.error.retryAfterMinutes ?? 15;
        return 'Too many attempts. Try again in $mins minutes.';
      default:
        return widget.error.message.isNotEmpty
            ? widget.error.message
            : 'Something went wrong. Try again.';
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final squadState = ref.watch(squadNotifierProvider);
    final hasStoredData = squadState.hasSquad;
    final canGoBack = _canPop(context);

    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTokens.textPrimary),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenGutter),
          child: Column(
            children: [
              const Spacer(),
              // 64 dp illustration
              Icon(
                _getIcon(),
                size: 64.0,
                color: AppTokens.statusOut,
              ),
              const SizedBox(height: AppTokens.space24),

              // Title (Heading)
              Semantics(
                header: true,
                child: Text(
                  _getTitle(),
                  style: AppTextStyles.headline.copyWith(fontSize: 22.0),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTokens.space12),

              // Body
              Text(
                _getBody(),
                style: AppTextStyles.body.copyWith(color: AppTokens.textSecondary),
                textAlign: TextAlign.center,
              ),

              // Stored data timestamp (if present)
              if (hasStoredData && widget.lastUpdated != null) ...[
                const SizedBox(height: AppTokens.space16),
                Text(
                  'Last updated ${_formatTime(widget.lastUpdated!)}',
                  style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary),
                ),
              ],

              const Spacer(),

              // Primary Action: Try again
              AppButton(
                label: 'Try again',
                isLoading: _isRetrying,
                onPressed: _handleRetry,
                size: AppButtonSize.large,
              ),
              const SizedBox(height: AppTokens.space12),

              // Secondary / Tertiary Action
              if (hasStoredData)
                AppButton(
                  label: 'Go to saved data',
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleGoToSavedData,
                  size: AppButtonSize.large,
                )
              else
                AppButton(
                  label: 'Sign out',
                  variant: AppButtonVariant.tertiary,
                  onPressed: _handleSignOut,
                  size: AppButtonSize.large,
                ),

              const SizedBox(height: AppTokens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
