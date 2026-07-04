# flutter_network_logger

A Flutter package that intercepts and logs all HTTP network requests made via `dart:io`. It captures request/response details and provides an in-app overlay and full-screen log viewer for inspection.

## Features

- Logs every HTTP request: method, URL, headers, body
- Captures response: status code, headers, body, duration
- Pretty-printed JSON formatting for request/response bodies
- Draggable floating overlay button with request count badge
- Full-screen log viewer with Overview, Request, and Response tabs
- Configurable max log count (default 200)

## Usage

### 1. Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_network_logger:
    path: path/to/flutter_network_logger
```

### 2. Initialize

Set the HTTP overrides globally before `runApp`:

```dart
import 'dart:io';
import 'package:flutter_network_logger/flutter_network_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = FlutterNetworkLoggerHttpOverrides();
  runApp(const MyApp());
}
```

### 3. View logs

**Option A — Floating overlay button (recommended):**

Wrap your app's root widget with `FlutterNetworkLoggerOverlay`:

```dart
return FlutterNetworkLoggerOverlay(
  child: MaterialApp(
    home: MyHomePage(),
  ),
);
```

A draggable FAB will appear on screen showing the current request count. Tap it to open the log viewer.

**Option B — Manual navigation:**

Use `FlutterNetworkLoggerScreen.show()` from any context:

```dart
FloatingActionButton(
  onPressed: () => FlutterNetworkLoggerScreen.show(context),
  child: const Icon(Icons.wifi),
),
```

## API

| Class | Description |
|---|---|
| `FlutterNetworkLoggerHttpOverrides` | `HttpOverrides` subclass that intercepts all HTTP traffic |
| `NetworkLoggerNotifier` | Singleton notifier holding the log entries |
| `FlutterNetworkLoggerScreen` | Full-screen log viewer |
| `FlutterNetworkLoggerOverlay` | Widget that wraps your app and adds a floating log button |
| `LogEntry` | Data model for a single request/response pair |
