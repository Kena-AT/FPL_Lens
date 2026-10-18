import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/formatting/app_formatters.dart';

void main() {
  group('AppFormatters', () {
    test('formatMoneyTenths converts tenths of millions to £X.Xm format', () {
      expect(AppFormatters.formatMoneyTenths(105), '£10.5m');
      expect(AppFormatters.formatMoneyTenths(15), '£1.5m');
      expect(AppFormatters.formatMoneyTenths(0), '£0.0m');
      expect(AppFormatters.formatMoneyTenths(45), '£4.5m');
      expect(AppFormatters.formatMoneyTenths(140), '£14.0m');
    });

    test('parseMoneyToTenths parses string inputs correctly', () {
      expect(AppFormatters.parseMoneyToTenths('10.5'), 105);
      expect(AppFormatters.parseMoneyToTenths('£10.5m'), 105);
      expect(AppFormatters.parseMoneyToTenths('  4.5  '), 45);
      expect(AppFormatters.parseMoneyToTenths('invalid'), isNull);
      expect(AppFormatters.parseMoneyToTenths('-1.0'), isNull);
    });

    test('formatPoints formats integer points directly', () {
      expect(AppFormatters.formatPoints(64), '64');
      expect(AppFormatters.formatPoints(0), '0');
      expect(AppFormatters.formatPoints(-4), '-4');
    });

    test('formatXp formats expected points to one decimal', () {
      expect(AppFormatters.formatXp(8.43), '8.4');
      expect(AppFormatters.formatXp(6.0), '6.0');
      expect(AppFormatters.formatXp(0.0), '0.0');
    });

    test('formatRank applies comma separators', () {
      expect(AppFormatters.formatRank(124532), '124,532');
      expect(AppFormatters.formatRank(1234567), '1,234,567');
      expect(AppFormatters.formatRank(450), '450');
      expect(AppFormatters.formatRank(1), '1');
    });

    test('formatPercentage handles both normalized (0-1) and integer (0-100) values', () {
      expect(AppFormatters.formatPercentage(0.94), '94%');
      expect(AppFormatters.formatPercentage(94), '94%');
      expect(AppFormatters.formatPercentage(0.75), '75%');
      expect(AppFormatters.formatPercentage(100), '100%');
    });

    test('formatCountdown follows duration threshold rules', () {
      // > 24 hours
      expect(AppFormatters.formatCountdown(const Duration(days: 2, hours: 14)), '2d 14h');
      // 1h - 24h
      expect(AppFormatters.formatCountdown(const Duration(hours: 2, minutes: 14)), '2h 14m');
      // < 1h
      expect(AppFormatters.formatCountdown(const Duration(minutes: 45)), '45m');
      // Negative / zero
      expect(AppFormatters.formatCountdown(const Duration(seconds: -10)), 'Passed');
    });

    test('formatRelativeTime formats relative timestamps', () {
      final now = DateTime(2026, 10, 18, 12, 0);

      expect(AppFormatters.formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now), 'Updated just now');
      expect(AppFormatters.formatRelativeTime(now.subtract(const Duration(minutes: 12)), now: now), 'Updated 12 min ago');
      expect(AppFormatters.formatRelativeTime(now.subtract(const Duration(hours: 2)), now: now), 'Updated 2 h ago');
      expect(AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 1)), now: now), 'Updated yesterday');
      expect(AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 3)), now: now), 'Updated 3 days ago');
    });
  });
}
