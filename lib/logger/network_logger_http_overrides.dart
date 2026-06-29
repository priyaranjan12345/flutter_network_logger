import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'network_log_entry.dart';
import 'network_logger_service.dart';

class NetworkLoggerHttpOverrides extends HttpOverrides {
  final HttpOverrides? _previous;

  NetworkLoggerHttpOverrides() : _previous = HttpOverrides.current;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = _previous?.createHttpClient(context) ?? super.createHttpClient(context);
    return _LoggingHttpClient(client);
  }
}

class _LoggingHttpClient implements HttpClient {
  final HttpClient _inner;
  _LoggingHttpClient(this._inner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return _LoggingHttpClientRequest(request, method, url);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) =>
      openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open('GET', host, port, path);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open('POST', host, port, path);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open('PUT', host, port, path);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open('DELETE', host, port, path);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open('HEAD', host, port, path);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open('PATCH', host, port, path);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) => _inner.authenticate = f;
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) => _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) => _inner.badCertificateCallback = callback;
  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) => _inner.connectionFactory = f;
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) => _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) => _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  void close({bool force = false}) => _inner.close(force: force);
}

class _LoggingHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final String _method;
  final Uri _url;
  final StringBuffer _bodyBuffer = StringBuffer();

  _LoggingHttpClientRequest(this._inner, this._method, this._url);

  @override
  Future<HttpClientResponse> close() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final headers = <String, String>{};
    _inner.headers.forEach((name, values) => headers[name] = values.join(', '));

    final entry = NetworkLogEntry(
      id: id,
      method: _method,
      url: _url,
      requestHeaders: headers,
      requestBody: _bodyBuffer.toString().isEmpty ? null : _bodyBuffer.toString(),
      requestTime: DateTime.now(),
    );
    NetworkLoggerService.instance.addLog(entry);

    try {
      final response = await _inner.close();
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) => responseHeaders[name] = values.join(', '));

      final bytes = await response.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
      final body = utf8.decode(bytes, allowMalformed: true);

      NetworkLoggerService.instance.updateLog(id, (e) {
        e.statusCode = response.statusCode;
        e.responseHeaders = responseHeaders;
        e.responseBody = body;
        e.responseTime = DateTime.now();
      });

      return _BufferedHttpClientResponse(response, bytes);
    } catch (e) {
      NetworkLoggerService.instance.updateLog(id, (entry) {
        entry.error = e.toString();
        entry.responseTime = DateTime.now();
      });
      rethrow;
    }
  }

  @override
  void add(List<int> data) {
    _bodyBuffer.write(utf8.decode(data, allowMalformed: true));
    _inner.add(data);
  }

  @override
  void write(Object? object) {
    _bodyBuffer.write(object);
    _inner.write(object);
  }

  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  Uri get uri => _inner.uri;
  @override
  String get method => _inner.method;
  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);
  @override
  Future flush() => _inner.flush();
  @override
  Future<HttpClientResponse> get done => _inner.done;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  void writeAll(Iterable objects, [String separator = '']) {
    _bodyBuffer.writeAll(objects, separator);
    _inner.writeAll(objects, separator);
  }
  @override
  void writeCharCode(int charCode) {
    _bodyBuffer.writeCharCode(charCode);
    _inner.writeCharCode(charCode);
  }
  @override
  void writeln([Object? object = '']) {
    _bodyBuffer.writeln(object);
    _inner.writeln(object);
  }
  @override
  void abort([Object? exception, StackTrace? stackTrace]) => _inner.abort(exception, stackTrace);
}

/// Re-streams a buffered response so callers can still read the body.
class _BufferedHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final HttpClientResponse _inner;
  final List<int> _bytes;
  late final Stream<List<int>> _stream = Stream.value(_bytes);

  _BufferedHttpClientResponse(this._inner, this._bytes);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  int get statusCode => _inner.statusCode;
  @override
  String get reasonPhrase => _inner.reasonPhrase;
  @override
  int get contentLength => _inner.contentLength;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  X509Certificate? get certificate => _inner.certificate;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  bool get isRedirect => _inner.isRedirect;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  List<RedirectInfo> get redirects => _inner.redirects;
  @override
  HttpClientResponseCompressionState get compressionState => _inner.compressionState;
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) => _inner.redirect(method, url, followLoops);
  @override
  Future<Socket> detachSocket() => _inner.detachSocket();
}
