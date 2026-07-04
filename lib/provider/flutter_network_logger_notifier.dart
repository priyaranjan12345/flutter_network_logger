import 'package:flutter/foundation.dart';
import '../entity/log_entry.dart';

class FlutterNetworkLoggerNotifier extends ChangeNotifier {
  FlutterNetworkLoggerNotifier._();
  static final instance = FlutterNetworkLoggerNotifier._();

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  int _maxLogs = 200;
  int get maxLogs => _maxLogs;
  set maxLogs(int value) => _maxLogs = value;

  void addLog(LogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > _maxLogs) _logs.removeLast();
    notifyListeners();
  }

  void updateLog(String id, void Function(LogEntry) update) {
    final entry = _logs.firstWhere(
      (e) => e.id == id,
      orElse: () => throw StateError('Log not found'),
    );
    update(entry);
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
