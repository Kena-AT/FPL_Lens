/// Formatting utilities adhering to Frontend Implementation Plan §B8.
///
/// English only, tabular figures for numbers, exact rounding rules:
/// - Money: `£` + one decimal from tenths (e.g. 105 -> `£10.5m`, 15 -> `£1.5m`)
/// - Bank: `£` + one decimal from tenths (e.g. 15 -> `£1.5m`)
/// - Points: Integer (e.g. 64 -> `64`)
/// - Expected Points (xP): One decimal (e.g. 8.4 -> `8.4`)
/// - Percentage: Integer, no decimal (e.g. 0.94 -> `94%`, 94 -> `94%`)
/// - Rank: Comma-formatted integer (e.g. 124532 -> `124,532`)
/// - Countdown: `Xd Xh` (>24h), `Xh Xm` (1h - 24h), `Xm` (<1h)
/// - Relative Time: `Updated 12 min ago`, `Updated 2 h ago`, `Updated yesterday`, `Offline`
class AppFormatters {
  const AppFormatters._();

  /// Formats tenths of millions into money string (e.g. 105 -> "£10.5m").
  static String formatMoneyTenths(int tenths) {
    final value = tenths / 10.0;
    return '£${value.toStringAsFixed(1)}m';
  }

  /// Formats raw double amount in millions into money string (e.g. 10.5 -> "£10.5m").
  static String formatMoneyMillions(double millions) {
    return '£${millions.toStringAsFixed(1)}m';
  }

  /// Converts a money string (e.g. "10.5" or "£10.5m") into tenths integer, or null if invalid.
  static int? parseMoneyToTenths(String input) {
    final clean = input.replaceAll('£', '').replaceAll('m', '').trim();
    final value = double.tryParse(clean);
    if (value == null || value < 0) return null;
    return (value * 10).round();
  }

  /// Formats integer points.
  static String formatPoints(int points) {
    return points.toString();
  }

  /// Formats expected points (xP) to one decimal place.
  static String formatXp(double xp) {
    return xp.toStringAsFixed(1);
  }

  /// Formats rank integer with commas (e.g. 1234567 -> "1,234,567").
  static String formatRank(int rank) {
    final str = rank.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Formats percentage (e.g. 0.85 -> "85%" or 85 -> "85%").
  static String formatPercentage(num value) {
    final intVal = value <= 1.0 && value >= 0.0 ? (value * 100).round() : value.round();
    return '$intVal%';
  }

  /// Formats duration remaining into countdown string:
  /// - > 24 hours: `Xd Xh` (e.g. "2d 14h")
  /// - 1 hour - 24 hours: `Xh Xm` (e.g. "2h 14m")
  /// - < 1 hour: `Xm` (e.g. "45m")
  /// - Past: `Passed` or `0m`
  static String formatCountdown(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Passed';
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${minutes}m';
    } else {
      return '${minutes > 0 ? minutes : 1}m';
    }
  }

  /// Formats relative time since [dateTime] compared to [now].
  ///
  /// Examples:
  /// - "Updated just now" (< 1 min)
  /// - "Updated 12 min ago" (< 60 min)
  /// - "Updated 2 h ago" (< 24 hours)
  /// - "Updated yesterday" (1-2 days)
  /// - "Updated on {date}" (> 2 days)
  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(dateTime);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Updated just now';
    } else if (diff.inMinutes < 60) {
      return 'Updated ${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return 'Updated ${diff.inHours} h ago';
    } else if (diff.inDays == 1) {
      return 'Updated yesterday';
    } else if (diff.inDays < 7) {
      return 'Updated ${diff.inDays} days ago';
    } else {
      return 'Updated ${dateTime.day} ${_monthName(dateTime.month)}';
    }
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
