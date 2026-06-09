import 'package:flutter/foundation.dart';
import '../data/services/api_service.dart';
import './utils/device_utils.dart';

class AppLog {
  final String id; // Unique ID for deletion
  final DateTime timestamp;
  final String message;
  final String? type;
  final Map<String, dynamic>? details;

  AppLog({
    required this.id,
    required this.timestamp,
    required this.message,
    this.type,
    this.details,
  });
}

class AppLogger extends ChangeNotifier {
  static final AppLogger instance = AppLogger._();
  AppLogger._();

  final List<AppLog> _logs = [];
  List<AppLog> get logs => List.unmodifiable(_logs.reversed);

  void log(String message, {String? type, Map<String, dynamic>? details}) {
    final newLog = AppLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      message: message,
      type: type,
      details: details,
    );
    _logs.add(newLog);
    if (_logs.length > 50) {
      _logs.removeAt(0);
    }
    debugPrint('📝 [LOG]: $message');
    notifyListeners();
  }

  void removeLog(String logId) {
    _logs.removeWhere((l) => l.id == logId);
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  /// Sends a log to the server and removes it from local list upon success.
  Future<void> sendReport(AppLog log) async {
    final deviceContext = await DeviceUtils.GetDeviceContext();

    // Mapping log type to server-allowed error_type: bluetooth, audio, sync, permission, other
    String serverErrorType = 'other';
    final type = log.type?.toLowerCase() ?? '';
    final msg = log.message.toLowerCase();

    if (type.contains('network') ||
        type.contains('sync') ||
        type.contains('download')) {
      serverErrorType = 'sync';
    } else if (type.contains('playback') || type.contains('audio')) {
      serverErrorType = 'audio';
    } else if (type.contains('bluetooth') || msg.contains('bluetooth')) {
      serverErrorType = 'bluetooth';
    } else if (type.contains('permission')) {
      serverErrorType = 'permission';
    }

    try {
      await ApiService.instance.logError({
        'error_type': serverErrorType,
        'description': log.message,
        'sync_status': 'unknown',
        ...deviceContext,
        'log_details': log.details?.toString(),
      });

      // SUCCESS: Remove from local list
      removeLog(log.id);
    } catch (e) {
      // Keep in list if failed so user can try again
      rethrow;
    }
  }
}
