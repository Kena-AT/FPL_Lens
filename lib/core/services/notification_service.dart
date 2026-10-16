import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../theme/tokens.dart';
import '../theme/text_styles.dart';
import '../widgets/app_button.dart';

class NotificationService {
  final AuthRepository _authRepository;

  NotificationService({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Initialize listeners for token refresh and incoming messages.
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await _authRepository.registerDevice(token);
      });
    } catch (_) {
      // Firebase messaging not available (e.g. unit tests or missing Play Services)
    }
  }

  /// Syncs current FCM token to backend via POST /api/v1/devices.
  Future<void> syncDeviceToken() async {
    try {
      if (Firebase.apps.isEmpty) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _authRepository.registerDevice(token);
      }
    } catch (_) {
      // Ignored for environments without FCM
    }
  }

  /// Request Android 13 notification permission with rationale after sign-up / onboarding.
  /// Explains deadline reminders and injury alerts before requesting system permission.
  Future<bool> requestPermissionWithRationale(BuildContext context) async {
    if (!Platform.isAndroid) return false;

    // Show custom rationale dialog/bottom sheet first
    final userAccepted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusModal)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 48,
                  color: AppTokens.goldPrimary,
                ),
                const SizedBox(height: AppTokens.space16),
                const Text(
                  'Never Miss a Deadline',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space12),
                const Text(
                  'FPL Lens sends timely deadline reminders and urgent injury alerts for your squad so you can lock in optimal transfers and captaincy.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.space24),
                AppButton(
                  label: 'Enable notifications',
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                ),
                const SizedBox(height: AppTokens.space8),
                AppButton(
                  label: 'Not now',
                  variant: AppButtonVariant.tertiary,
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (userAccepted == true) {
      try {
        if (Firebase.apps.isNotEmpty) {
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
          if (granted) {
            await syncDeviceToken();
          }
          return granted;
        }
      } catch (_) {
        // Fallback
      }
    }

    return false;
  }
}
