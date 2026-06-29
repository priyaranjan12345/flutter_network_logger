import 'dart:convert';

class NetworkLogEntry {
  final String id;
  final String method;
  final Uri url;
  final Map<String, String> requestHeaders;
  final dynamic requestBody;
  final DateTime requestTime;

  int? statusCode;
  Map<String, String>? responseHeaders;
  dynamic responseBody;
  DateTime? responseTime;
  String? error;

  NetworkLogEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    required this.requestTime,
  });

  Duration? get duration => responseTime?.difference(requestTime);

  bool get isComplete => statusCode != null || error != null;
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);

  String get formattedRequestBody {
    if (requestBody == null) return '';
    try {
      final decoded = jsonDecode(requestBody.toString());
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return requestBody.toString();
    }
  }

  String get formattedResponseBody {
    if (responseBody == null) return '';
    try {
      final decoded = jsonDecode(responseBody.toString());
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return responseBody.toString();
    }
  }
}
