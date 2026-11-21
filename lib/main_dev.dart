import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Handled if Google Play Services / Firebase is not available
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}

  final config = AppConfig.fromEnvironment(
    defaultFlavor: AppFlavor.dev,
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FplLensApp(),
    ),
  );
}
