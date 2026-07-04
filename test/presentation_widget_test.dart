import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_logger/entity/log_entry.dart';
import 'package:flutter_network_logger/presentation/flutter_network_logger_overlay.dart';
import 'package:flutter_network_logger/presentation/flutter_network_logger_screen.dart';
import 'package:flutter_network_logger/provider/flutter_network_logger_notifier.dart';

Widget buildApp({Widget? home}) {
  return MaterialApp(
    home: home ?? const Scaffold(body: Center(child: Text('Home'))),
  );
}

void main() {
  setUp(() {
    FlutterNetworkLoggerNotifier.instance.clear();
  });

  tearDown(() {
    FlutterNetworkLoggerNotifier.instance.clear();
  });

  group('FlutterNetworkLoggerOverlay', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const FlutterNetworkLoggerOverlay(child: Text('App Content')),
      );

      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('shows FAB with badge count 0', (tester) async {
      await tester.pumpWidget(
        const FlutterNetworkLoggerOverlay(child: SizedBox()),
      );

      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows badge count when logs are added', (tester) async {
      await tester.pumpWidget(
        const FlutterNetworkLoggerOverlay(child: SizedBox()),
      );

      FlutterNetworkLoggerNotifier.instance.addLog(
        LogEntry(
          id: '1',
          method: 'GET',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestTime: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('FAB navigates to logger screen on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const FlutterNetworkLoggerOverlay(
              child: Center(child: Text('Home')),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Network Logger'), findsOneWidget);
    });
  });

  group('FlutterNetworkLoggerScreen', () {
    testWidgets('shows empty state when no logs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );

      expect(find.text('No network requests yet'), findsOneWidget);
    });

    testWidgets('shows logs in list', (tester) async {
      FlutterNetworkLoggerNotifier.instance.addLog(
        LogEntry(
          id: '1',
          method: 'GET',
          url: Uri.parse('https://example.com/api'),
          requestHeaders: {},
          requestTime: DateTime.now(),
        )..statusCode = 200,
      );

      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );

      expect(find.text('/api'), findsOneWidget);
      expect(find.textContaining('example.com'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('clear button removes all logs', (tester) async {
      FlutterNetworkLoggerNotifier.instance.addLog(
        LogEntry(
          id: '1',
          method: 'GET',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestTime: DateTime.now(),
        )..statusCode = 200,
      );

      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.text('No network requests yet'), findsOneWidget);
    });

    testWidgets('shows error status in log tile', (tester) async {
      final entry = LogEntry(
        id: '1',
        method: 'GET',
        url: Uri.parse('https://example.com'),
        requestHeaders: {},
        requestTime: DateTime.now(),
      );
      entry.error = 'timeout';
      FlutterNetworkLoggerNotifier.instance.addLog(entry);

      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );

      expect(find.text('ERR'), findsOneWidget);
    });

    testWidgets('shows pending status for incomplete request', (tester) async {
      FlutterNetworkLoggerNotifier.instance.addLog(
        LogEntry(
          id: '1',
          method: 'GET',
          url: Uri.parse('https://example.com'),
          requestHeaders: {},
          requestTime: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );

      expect(find.text('\u2022\u2022\u2022'), findsOneWidget);
    });

    testWidgets('navigates to detail screen on tile tap', (tester) async {
      FlutterNetworkLoggerNotifier.instance.addLog(
        LogEntry(
          id: '1',
          method: 'GET',
          url: Uri.parse('https://example.com/test'),
          requestHeaders: {},
          requestTime: DateTime.now(),
        )..statusCode = 200,
      );

      await tester.pumpWidget(
        const MaterialApp(home: FlutterNetworkLoggerScreen()),
      );

      await tester.tap(find.text('/test'));
      await tester.pumpAndSettle();

      expect(find.text('GET /test'), findsOneWidget);
    });
  });
}
