import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_logger/logger/flutter_network_logger_http_overrides.dart';
import 'package:flutter_network_logger/provider/flutter_network_logger_notifier.dart';

void main() {
  group('FlutterNetworkLoggerHttpOverrides', () {
    late HttpServer server;
    late Uri serverUri;
    HttpOverrides? previousGlobal;

    setUp(() async {
      previousGlobal = HttpOverrides.current;
      FlutterNetworkLoggerNotifier.instance.clear();
      server = await HttpServer.bind('127.0.0.1', 0);
      serverUri = Uri.parse('http://127.0.0.1:${server.port}');
    });

    tearDown(() async {
      HttpOverrides.global = previousGlobal;
      await server.close();
      FlutterNetworkLoggerNotifier.instance.clear();
    });

    test('logs successful HTTP request and response', () async {
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.headers.set('content-type', 'application/json');
        request.response.write('{"status":"ok"}');
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.getUrl(serverUri);
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      final logs = FlutterNetworkLoggerNotifier.instance.logs;
      expect(logs.length, 1);
      expect(logs[0].method, 'GET');
      expect(logs[0].url.toString(), serverUri.toString());
      expect(logs[0].statusCode, 200);
      expect(logs[0].responseHeaders, containsPair('content-type', 'application/json'));
      expect(logs[0].responseBody, '{"status":"ok"}');
      expect(logs[0].isComplete, isTrue);
      expect(logs[0].isError, isFalse);
      expect(logs[0].error, isNull);
    });

    test('logs HTTP error response (4xx)', () async {
      server.listen((request) {
        request.response.statusCode = 404;
        request.response.write('Not Found');
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.getUrl(serverUri);
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      final logs = FlutterNetworkLoggerNotifier.instance.logs;
      expect(logs.length, 1);
      expect(logs[0].statusCode, 404);
      expect(logs[0].isError, isTrue);
    });

    test('logs POST request with body', () async {
      server.listen((request) async {
        final body = await utf8.decodeStream(request);
        request.response.statusCode = 201;
        request.response.write('Created: $body');
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.postUrl(serverUri);
      request.write('hello');
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      final logs = FlutterNetworkLoggerNotifier.instance.logs;
      expect(logs.length, 1);
      expect(logs[0].method, 'POST');
      expect(logs[0].statusCode, 201);
      expect(logs[0].requestBody, 'hello');
    });

    test('response body can still be read after logging', () async {
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.write('readable body');
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.getUrl(serverUri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      expect(body, 'readable body');

      client.close(force: true);
    });

    test('logs request headers', () async {
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.getUrl(serverUri);
      request.headers.set('x-custom', 'test-value');
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      final logs = FlutterNetworkLoggerNotifier.instance.logs;
      expect(logs.length, 1);
      expect(logs[0].requestHeaders, containsPair('x-custom', 'test-value'));
    });

    test('timestamps are set on request and response', () async {
      server.listen((request) {
        request.response.statusCode = 200;
        request.response.close();
      });

      HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
      final client = HttpClient();
      final request = await client.getUrl(serverUri);
      final response = await request.close();
      await response.drain();
      client.close(force: true);

      final log = FlutterNetworkLoggerNotifier.instance.logs.first;
      expect(log.requestTime, isNotNull);
      expect(log.responseTime, isNotNull);
      expect(log.duration, isNotNull);
      expect(log.duration!.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });
}
