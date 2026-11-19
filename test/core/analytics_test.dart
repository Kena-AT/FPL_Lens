import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/analytics/analytics_service.dart';
import 'package:fpl_lens/core/analytics/events.dart';
import 'package:fpl_lens/core/storage/app_database.dart';

void main() {
  late AppDatabase db;
  late AnalyticsService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = AnalyticsService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Part F Analytics Tests', () {
    test('F1: Emits valid events with strictly typed properties', () {
      final event1 = AnalyticsEvent.signUpCompleted(method: 'email');
      service.logEvent(event1);

      final event2 = AnalyticsEvent.teamIdChecked(result: 'valid');
      service.logEvent(event2);

      final event3 = AnalyticsEvent.squadLoaded(source: 'fpl_proxy', durationMs: 420);
      service.logEvent(event3);

      final event4 = AnalyticsEvent.lineupCalculated(durationMs: 85, approximate: false);
      service.logEvent(event4);

      expect(service.recordedEvents.length, 4);
      expect(service.recordedEvents[0].name, AnalyticsEventName.signUpCompleted);
      expect(service.recordedEvents[0].properties['method'], 'email');
      expect(service.recordedEvents[3].properties['approximate'], false);
    });

    test('F2: Strictly forbids and rejects email addresses in event properties', () {
      expect(
        () => AnalyticsEvent.signUpCompleted(method: 'user@example.com'),
        isNot(throwsA(anything)), // event factory accepts string
      );

      final taintedEvent = AnalyticsEvent.signUpCompleted(method: 'leaked_email@test.com');
      expect(
        () => service.logEvent(taintedEvent),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('F2: Strictly forbids and rejects API keys in event properties', () {
      final keyEvent = AnalyticsEvent.aiKeyValidated(
        providerId: 'AIzaSyD-fake-google-api-key-test-value-35',
        result: 'valid',
      );
      expect(
        () => service.logEvent(keyEvent),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('F3: Opt-out prevents all events from being recorded', () async {
      await service.setEnabled(false);
      expect(service.isEnabled, isFalse);

      service.logEvent(AnalyticsEvent.squadLoaded(source: 'cache', durationMs: 12));
      service.logEvent(AnalyticsEvent.transferHorizonChanged(horizonGw: 3));

      expect(service.recordedEvents, isEmpty);
    });

    test('F3: Re-enabling analytics records analytics_opt_changed', () async {
      await service.setEnabled(false);
      expect(service.recordedEvents, isEmpty);

      await service.setEnabled(true);
      expect(service.isEnabled, isTrue);
      expect(service.recordedEvents.length, 1);
      expect(service.recordedEvents.first.name, AnalyticsEventName.analyticsOptChanged);
      expect(service.recordedEvents.first.properties['enabled'], true);
    });
  });
}
