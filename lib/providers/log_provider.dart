import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;

  LogEntry(
      {required this.timestamp, required this.level, required this.message});
}

class LogProvider extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  final List<String> _terminalOutput = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<String> get terminalOutput => List.unmodifiable(_terminalOutput);

  void addLog(String level, String message) {
    _logs.add(LogEntry(
      timestamp: DateTime.now(),
      level: level.toUpperCase(),
      message: message,
    ));
    if (_logs.length > 500) _logs.removeAt(0);
    notifyListeners();
  }

  void addTerminalOutput(String line) {
    _terminalOutput.add(line);
    if (_terminalOutput.length > 200) _terminalOutput.removeAt(0);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void clearTerminal() {
    _terminalOutput.clear();
    notifyListeners();
  }
}
