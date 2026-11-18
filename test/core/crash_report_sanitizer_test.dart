import 'package:flutter_test/flutter_test.dart';
import 'package:fpl_lens/core/services/crash_report_service.dart';

void main() {
  group('CrashReportSanitizer & Service Tests', () {
    test('Sanitizes sensitive headers including Authorization, X-Job-Token, and Cookie', () {
      final rawHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0In0',
        'X-Job-Token': 'super-secret-internal-cron-job-token',
        'Cookie': 'session=abc123xyz',
        'User-Agent': 'FPLLens/0.1',
      };

      final sanitized = CrashReportSanitizer.sanitizeHeaders(rawHeaders);

      expect(sanitized['Content-Type'], 'application/json');
      expect(sanitized['Authorization'], '[REDACTED]');
      expect(sanitized['X-Job-Token'], '[REDACTED]');
      expect(sanitized['Cookie'], '[REDACTED]');
      expect(sanitized['User-Agent'], 'FPLLens/0.1');
    });

    test('Strips query strings from request URLs', () {
      const sensitiveUrl = 'https://api.fpl-lens.app/api/v1/players/search?q=haaland&token=secret123';
      final cleanUrl = CrashReportSanitizer.sanitizeUrl(sensitiveUrl);

      expect(cleanUrl, 'https://api.fpl-lens.app/api/v1/players/search');
      expect(cleanUrl.contains('token'), isFalse);
    });

    test('Scrubs sensitive keys (password, access_token, api_key, squad) from bodies', () {
      final rawBody = {
        'email': 'manager@example.com',
        'password': 'SuperSecretPassword123!',
        'api_key': 'AIzaSyD-fake-google-api-key-test-value-35',
        'squad': [
          {'name': 'Haaland', 'fpl_id': 355},
        ],
        'gameweek': 10,
      };

      final sanitized = CrashReportSanitizer.sanitizeData(rawBody) as Map<String, dynamic>;

      expect(sanitized['password'], '[REDACTED]');
      expect(sanitized['api_key'], '[REDACTED]');
      expect(sanitized['squad'], '[REDACTED]');
      expect(sanitized['email'], '[REDACTED_EMAIL]');
      expect(sanitized['gameweek'], 10);
    });

    test('CrashReportService records sanitized crash payloads', () {
      final service = CrashReportService();

      service.recordCrash(
        error: Exception('Test exception with email user@domain.com and key sk-1234567890123456789012345678'),
        stackTrace: StackTrace.fromString('line 1 in file.dart\nBearer token123456789'),
        headers: {'Authorization': 'Bearer test-token'},
        requestUrl: 'https://example.com/api?secret=abc',
        requestBody: {'password': 'pass', 'metric': 'xP'},
      );

      expect(service.reportedCrashes.length, 1);
      final crash = service.reportedCrashes.first;

      expect(crash['error'].contains('[REDACTED_EMAIL]'), isTrue);
      expect(crash['error'].contains('[REDACTED_KEY]'), isTrue);
      expect(crash['stackTrace'].contains('Bearer [REDACTED]'), isTrue);
      expect(crash['headers']['Authorization'], '[REDACTED]');
      expect(crash['url'], 'https://example.com/api');
      expect(crash['body']['password'], '[REDACTED]');
      expect(crash['body']['metric'], 'xP');
    });
  });
}
