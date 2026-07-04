import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_logger/entity/log_entry.dart';

void main() {
  group('LogEntry', () {
    late DateTime baseTime;
    late LogEntry entry;

    setUp(() {
      baseTime = DateTime(2024, 1, 1, 12, 0, 0);
      entry = LogEntry(
        id: '1',
        method: 'GET',
        url: Uri.parse('https://example.com/api/test'),
        requestHeaders: {'content-type': 'application/json'},
        requestBody: '{"key":"value"}',
        requestTime: baseTime,
      );
    });

    group('constructor', () {
      test('sets request fields correctly', () {
        expect(entry.id, '1');
        expect(entry.method, 'GET');
        expect(entry.url.toString(), 'https://example.com/api/test');
        expect(entry.requestHeaders, {'content-type': 'application/json'});
        expect(entry.requestBody, '{"key":"value"}');
        expect(entry.requestTime, baseTime);
      });

      test('initializes response fields to null', () {
        expect(entry.statusCode, isNull);
        expect(entry.responseHeaders, isNull);
        expect(entry.responseBody, isNull);
        expect(entry.responseTime, isNull);
        expect(entry.error, isNull);
      });

      test('allows null requestBody', () {
        final noBody = LogEntry(
          id: '2',
          method: 'POST',
          url: Uri.parse('https://example.com/api'),
          requestHeaders: {},
          requestTime: baseTime,
        );
        expect(noBody.requestBody, isNull);
      });
    });

    group('duration', () {
      test('returns null when responseTime is null', () {
        expect(entry.duration, isNull);
      });

      test('returns difference between request and response time', () {
        entry.responseTime = baseTime.add(const Duration(seconds: 2));
        expect(entry.duration, const Duration(seconds: 2));
      });
    });

    group('isComplete', () {
      test('returns false when no statusCode and no error', () {
        expect(entry.isComplete, isFalse);
      });

      test('returns true when statusCode is set', () {
        entry.statusCode = 200;
        expect(entry.isComplete, isTrue);
      });

      test('returns true when error is set', () {
        entry.error = 'Connection failed';
        expect(entry.isComplete, isTrue);
      });
    });

    group('isError', () {
      test('returns false for successful response', () {
        entry.statusCode = 200;
        expect(entry.isError, isFalse);
      });

      test('returns true for 4xx status', () {
        entry.statusCode = 404;
        expect(entry.isError, isTrue);
      });

      test('returns true for 5xx status', () {
        entry.statusCode = 500;
        expect(entry.isError, isTrue);
      });

      test('returns true when error is set', () {
        entry.error = 'Timeout';
        expect(entry.isError, isTrue);
      });

      test('returns false when statusCode is null and no error', () {
        expect(entry.isError, isFalse);
      });

      test('returns true when error is set even with 200 status', () {
        entry.statusCode = 200;
        entry.error = 'Something went wrong';
        expect(entry.isError, isTrue);
      });
    });

    group('formattedRequestBody', () {
      test('returns empty string when requestBody is null', () {
        final noBody = LogEntry(
          id: '2',
          method: 'GET',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestTime: baseTime,
        );
        expect(noBody.formattedRequestBody, '');
      });

      test('pretty-prints valid JSON', () {
        final formatted = entry.formattedRequestBody;
        expect(formatted, '{\n  "key": "value"\n}');
      });

      test('returns raw string for invalid JSON', () {
        final badJson = LogEntry(
          id: '3',
          method: 'POST',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestBody: 'not-json',
          requestTime: baseTime,
        );
        expect(badJson.formattedRequestBody, 'not-json');
      });

      test('handles non-string requestBody', () {
        final numBody = LogEntry(
          id: '4',
          method: 'POST',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestBody: 42,
          requestTime: baseTime,
        );
        expect(numBody.formattedRequestBody, '42');
      });
    });

    group('formattedResponseBody', () {
      test('returns empty string when responseBody is null', () {
        expect(entry.formattedResponseBody, '');
      });

      test('pretty-prints valid JSON', () {
        entry.responseBody = '{"status":"ok"}';
        final formatted = entry.formattedResponseBody;
        expect(formatted, '{\n  "status": "ok"\n}');
      });

      test('returns raw string for invalid JSON', () {
        entry.responseBody = 'plain text error';
        expect(entry.formattedResponseBody, 'plain text error');
      });

      test('handles empty string', () {
        entry.responseBody = '';
        expect(entry.formattedResponseBody, '');
      });
    });

    group('mutable response fields', () {
      test('can set and update statusCode', () {
        entry.statusCode = 201;
        expect(entry.statusCode, 201);
      });

      test('can set and update responseHeaders', () {
        entry.responseHeaders = {'content-type': 'text/plain'};
        expect(
          entry.responseHeaders,
          {'content-type': 'text/plain'},
        );
      });

      test('can set and update responseBody', () {
        entry.responseBody = 'response data';
        expect(entry.responseBody, 'response data');
      });

      test('can set and update responseTime', () {
        final respTime = baseTime.add(const Duration(seconds: 1));
        entry.responseTime = respTime;
        expect(entry.responseTime, respTime);
      });

      test('can set and update error', () {
        entry.error = 'connection refused';
        expect(entry.error, 'connection refused');
      });
    });
  });
}
