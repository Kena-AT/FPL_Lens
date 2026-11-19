// Type-safe Analytics Events per Frontend Plan Part F (F1).
// Unknown properties and forbidden PII (F2) are strictly prohibited.

enum AnalyticsEventName {
  signUpCompleted('sign_up_completed'),
  teamIdChecked('team_id_checked'),
  squadLoaded('squad_loaded'),
  squadLoadFailed('squad_load_failed'),
  lineupCalculated('lineup_calculated'),
  screenshotFallbackUsed('screenshot_fallback_used'),
  aiKeyValidated('ai_key_validated'),
  transferHorizonChanged('transfer_horizon_changed'),
  notificationOpened('notification_opened'),
  errorShown('error_shown'),
  analyticsOptChanged('analytics_opt_changed'),
  heatmapViewed('heatmap_viewed'),
  heatmapMetricChanged('heatmap_metric_changed');

  final String eventName;
  const AnalyticsEventName(this.eventName);
}

class AnalyticsEvent {
  final AnalyticsEventName name;
  final Map<String, Object> properties;

  const AnalyticsEvent._(this.name, this.properties);

  factory AnalyticsEvent.signUpCompleted({required String method}) {
    return AnalyticsEvent._(
      AnalyticsEventName.signUpCompleted,
      {'method': method},
    );
  }

  factory AnalyticsEvent.teamIdChecked({required String result}) {
    return AnalyticsEvent._(
      AnalyticsEventName.teamIdChecked,
      {'result': result},
    );
  }

  factory AnalyticsEvent.squadLoaded({
    required String source,
    required int durationMs,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.squadLoaded,
      {'source': source, 'duration_ms': durationMs},
    );
  }

  factory AnalyticsEvent.squadLoadFailed({
    required String step,
    required String errorKind,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.squadLoadFailed,
      {'step': step, 'error_kind': errorKind},
    );
  }

  factory AnalyticsEvent.lineupCalculated({
    required int durationMs,
    required bool approximate,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.lineupCalculated,
      {'duration_ms': durationMs, 'approximate': approximate},
    );
  }

  factory AnalyticsEvent.screenshotFallbackUsed({required String providerId}) {
    return AnalyticsEvent._(
      AnalyticsEventName.screenshotFallbackUsed,
      {'provider_id': providerId},
    );
  }

  factory AnalyticsEvent.aiKeyValidated({
    required String providerId,
    required String result,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.aiKeyValidated,
      {'provider_id': providerId, 'result': result},
    );
  }

  factory AnalyticsEvent.transferHorizonChanged({required int horizonGw}) {
    return AnalyticsEvent._(
      AnalyticsEventName.transferHorizonChanged,
      {'horizon_gw': horizonGw},
    );
  }

  factory AnalyticsEvent.notificationOpened({required String channel}) {
    return AnalyticsEvent._(
      AnalyticsEventName.notificationOpened,
      {'channel': channel},
    );
  }

  factory AnalyticsEvent.errorShown({
    required String errorKind,
    required String screen,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.errorShown,
      {'error_kind': errorKind, 'screen': screen},
    );
  }

  factory AnalyticsEvent.analyticsOptChanged({required bool enabled}) {
    return AnalyticsEvent._(
      AnalyticsEventName.analyticsOptChanged,
      {'enabled': enabled},
    );
  }

  factory AnalyticsEvent.heatmapViewed({
    required String view,
    required String metric,
  }) {
    return AnalyticsEvent._(
      AnalyticsEventName.heatmapViewed,
      {'view': view, 'metric': metric},
    );
  }

  factory AnalyticsEvent.heatmapMetricChanged({required String metric}) {
    return AnalyticsEvent._(
      AnalyticsEventName.heatmapMetricChanged,
      {'metric': metric},
    );
  }
}
