import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_database.dart';
import 'events.dart';

class AnalyticsService {
  final AppDatabase _db;
  bool _isEnabled = true;
  final List<AnalyticsEvent> _recordedEvents = [];

  static const String prefKey = 'analytics_enabled';

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final RegExp _keyRegex = RegExp(
    r'(AIza[0-9A-Za-z-_]{35}|sk-[a-zA-Z0-9]{20,}|ant-[a-zA-Z0-9]{20,})',
  );

  AnalyticsService(this._db) {
    _loadPreference();
  }

  bool get isEnabled => _isEnabled;
  List<AnalyticsEvent> get recordedEvents => List.unmodifiable(_recordedEvents);

  Future<void> _loadPreference() async {
    final val = await _db.getPreference(prefKey);
    if (val != null) {
      _isEnabled = val.toLowerCase() == 'true';
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _db.setPreference(prefKey, enabled.toString());
    if (enabled) {
      logEvent(AnalyticsEvent.analyticsOptChanged(enabled: true));
    }
  }

  void logEvent(AnalyticsEvent event) {
    if (!_isEnabled) return;

    // F2 Redaction enforcement: Verify no properties violate data privacy
    for (final entry in event.properties.entries) {
      final valStr = entry.value.toString();
      if (_emailRegex.hasMatch(valStr)) {
        throw ArgumentError(
          'F2 Violation: Analytics property "${entry.key}" contains an email address: $valStr',
        );
      }
      if (_keyRegex.hasMatch(valStr)) {
        throw ArgumentError(
          'F2 Violation: Analytics property "${entry.key}" contains an API key: $valStr',
        );
      }
    }

    _recordedEvents.add(event);
  }

  void clearRecordedEvents() {
    _recordedEvents.clear();
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AnalyticsService(db);
});
