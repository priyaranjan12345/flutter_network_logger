import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_logger/entity/log_entry.dart';
import 'package:flutter_network_logger/provider/flutter_network_logger_notifier.dart';

void main() {
  late LogEntry entry1;
  late LogEntry entry2;
  late LogEntry entry3;

  setUp(() {
    entry1 = LogEntry(
      id: '1',
      method: 'GET',
      url: Uri.parse('https://example.com/a'),
      requestHeaders: {},
      requestTime: DateTime(2024, 1, 1),
    );
    entry2 = LogEntry(
      id: '2',
      method: 'POST',
      url: Uri.parse('https://example.com/b'),
      requestHeaders: {},
      requestTime: DateTime(2024, 1, 2),
    );
    entry3 = LogEntry(
      id: '3',
      method: 'PUT',
      url: Uri.parse('https://example.com/c'),
      requestHeaders: {},
      requestTime: DateTime(2024, 1, 3),
    );
    FlutterNetworkLoggerNotifier.instance.maxLogs = 200;
  });

  tearDown(() {
    FlutterNetworkLoggerNotifier.instance.clear();
  });

  group('NetworkLoggerNotifier', () {
    test('is a singleton', () {
      final instance1 = FlutterNetworkLoggerNotifier.instance;
      final instance2 = FlutterNetworkLoggerNotifier.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('starts with empty logs', () {
      expect(FlutterNetworkLoggerNotifier.instance.logs, isEmpty);
    });

    group('addLog', () {
      test('adds entry to logs', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        expect(FlutterNetworkLoggerNotifier.instance.logs.length, 1);
        expect(FlutterNetworkLoggerNotifier.instance.logs.first.id, '1');
      });

      test('inserts new entries at index 0 (newest first)', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        FlutterNetworkLoggerNotifier.instance.addLog(entry2);

        final logs = FlutterNetworkLoggerNotifier.instance.logs;
        expect(logs.length, 2);
        expect(logs[0].id, '2');
        expect(logs[1].id, '1');
      });

      test('trims logs beyond maxLogs', () {
        FlutterNetworkLoggerNotifier.instance.maxLogs = 2;
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        FlutterNetworkLoggerNotifier.instance.addLog(entry2);
        FlutterNetworkLoggerNotifier.instance.addLog(entry3);

        final logs = FlutterNetworkLoggerNotifier.instance.logs;
        expect(logs.length, 2);
        expect(logs[0].id, '3');
        expect(logs[1].id, '2');
      });

      test('notifies listeners', () {
        var notified = false;
        FlutterNetworkLoggerNotifier.instance.addListener(() {
          notified = true;
        });
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        expect(notified, isTrue);
      });
    });

    group('updateLog', () {
      test('updates an existing entry by id', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);

        FlutterNetworkLoggerNotifier.instance.updateLog('1', (e) {
          e.statusCode = 200;
          e.responseBody = '{"ok":true}';
        });

        final log = FlutterNetworkLoggerNotifier.instance.logs.first;
        expect(log.statusCode, 200);
        expect(log.responseBody, '{"ok":true}');
      });

      test('throws StateError when id is not found', () {
        expect(
          () => FlutterNetworkLoggerNotifier.instance.updateLog('nonexistent', (e) {}),
          throwsA(isA<StateError>()),
        );
      });

      test('notifies listeners', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);

        var notified = false;
        FlutterNetworkLoggerNotifier.instance.addListener(() {
          notified = true;
        });

        FlutterNetworkLoggerNotifier.instance.updateLog('1', (e) {
          e.statusCode = 200;
        });
        expect(notified, isTrue);
      });
    });

    group('clear', () {
      test('removes all logs', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        FlutterNetworkLoggerNotifier.instance.addLog(entry2);
        expect(FlutterNetworkLoggerNotifier.instance.logs.length, 2);

        FlutterNetworkLoggerNotifier.instance.clear();
        expect(FlutterNetworkLoggerNotifier.instance.logs, isEmpty);
      });

      test('notifies listeners', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);

        var notified = false;
        FlutterNetworkLoggerNotifier.instance.addListener(() {
          notified = true;
        });

        FlutterNetworkLoggerNotifier.instance.clear();
        expect(notified, isTrue);
      });
    });

    group('logs getter', () {
      test('returns an unmodifiable list', () {
        FlutterNetworkLoggerNotifier.instance.addLog(entry1);
        final logs = FlutterNetworkLoggerNotifier.instance.logs;
        expect(
          () => logs.add(entry2),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('maxLogs', () {
      test('defaults to 200', () {
        expect(FlutterNetworkLoggerNotifier.instance.maxLogs, 200);
      });

      test('can be changed', () {
        FlutterNetworkLoggerNotifier.instance.maxLogs = 50;
        expect(FlutterNetworkLoggerNotifier.instance.maxLogs, 50);
      });
    });
  });
}
