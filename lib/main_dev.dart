import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Handled if Google Play Services / Firebase is not available
  }

  const config = AppConfig(
    flavor: AppFlavor.dev,
    apiBaseUrl: 'https://fpl-lens-dev.onrender.com',
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const FplLensApp(),
    ),
  );
}
