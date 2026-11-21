import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'fpl_theme_mode';
const String _keyReduceMotion = 'fpl_reduce_motion';

/// State notifier for user-selected appearance mode per Visual Redesign §3.1.
/// Options: Dark, Light, System (default: System).
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? _prefs;

  ThemeNotifier([this._prefs]) : super(_initialMode(_prefs));

  static ThemeMode _initialMode(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.system;
    final saved = prefs.getString(_keyThemeMode);
    switch (saved) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString(_keyThemeMode, 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString(_keyThemeMode, 'light');
        break;
      case ThemeMode.system:
        await prefs.setString(_keyThemeMode, 'system');
        break;
    }
  }
}

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  // Can be overridden in tests or initialized in main
  return null;
});

/// Riverpod provider for ThemeMode.
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

/// State notifier for Reduce Motion setting per Visual Redesign §4.5.
class MotionPolicyNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  MotionPolicyNotifier([this._prefs]) : super(_initialReduceMotion(_prefs));

  static bool _initialReduceMotion(SharedPreferences? prefs) {
    if (prefs == null) return false;
    return prefs.getBool(_keyReduceMotion) ?? false;
  }

  Future<void> setReduceMotion(bool value) async {
    state = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyReduceMotion, value);
  }
}

/// Riverpod provider for Reduce Motion flag.
final motionPolicyProvider = StateNotifierProvider<MotionPolicyNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MotionPolicyNotifier(prefs);
});
