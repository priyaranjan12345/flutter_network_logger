import 'package:flutter/foundation.dart';
import 'network_log_entry.dart';

class NetworkLoggerService extends ChangeNotifier {
  NetworkLoggerService._();
  static final instance = NetworkLoggerService._();

  final List<NetworkLogEntry> _logs = [];
  List<NetworkLogEntry> get logs => List.unmodifiable(_logs);

  int _maxLogs = 200;
  set maxLogs(int value) => _maxLogs = value;

  void addLog(NetworkLogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > _maxLogs) _logs.removeLast();
    notifyListeners();
  }

  void updateLog(String id, void Function(NetworkLogEntry) update) {
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
