## 0.0.1

* Initial release.
* Intercept HTTP requests via `HttpOverrides` with `FlutterNetworkLoggerHttpOverrides`.
* Log request/response details: URL, method, headers, body, status code, duration, errors.
* View logs in-app via a draggable floating overlay button.
* Full-screen log viewer with Overview, Request, and Response tabs.
* Pretty-printed JSON formatting for request and response bodies.
* Singleton `NetworkLoggerNotifier` with configurable max log count (default 200).
