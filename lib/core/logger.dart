import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import './utils/device_utils.dart';

class AppLog {
  final String id;
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

  static const errorTypes = {
    'native_error',
    'sync_error',
    'playback_error',
    'native_playback_error',
    'network_error',
  };

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

  List<AppLog> get errorLogs =>
      logs.where((l) => errorTypes.contains(l.type ?? '')).toList();

  String _mapErrorType(AppLog log) {
    final type = log.type?.toLowerCase() ?? '';
    final msg = log.message.toLowerCase();

    if (type.contains('network') ||
        type.contains('sync') ||
        type.contains('download')) {
      return 'sync';
    }
    if (type.contains('playback') || type.contains('audio')) {
      return 'audio';
    }
    if (type.contains('bluetooth') || msg.contains('bluetooth')) {
      return 'bluetooth';
    }
    if (type.contains('permission')) {
      return 'permission';
    }
    return 'other';
  }

  Future<String> _resolveSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_sync_time');
      if (lastSync != null && lastSync.isNotEmpty) return 'synced';
    } catch (_) {}
    return 'unknown';
  }

  String _buildDescription({
    required AppLog log,
    String? userNote,
    String? diagnosticLog,
  }) {
    final parts = <String>[];
    if (userNote != null && userNote.trim().isNotEmpty) {
      parts.add(userNote.trim());
    }
    parts.add(log.message);
    if (diagnosticLog != null && diagnosticLog.trim().isNotEmpty) {
      parts.add('\n--- HiCar adb log ---\n${diagnosticLog.trim()}');
    }
    return parts.join('\n\n');
  }

  /// Sends error report to server (API: POST /api/logs/error).
  Future<void> sendReport(
    AppLog log, {
    String? userNote,
    String? diagnosticLog,
  }) async {
    final deviceContext = await DeviceUtils.getDeviceContext();
    final syncStatus = await _resolveSyncStatus();
    final description = _buildDescription(
      log: log,
      userNote: userNote,
      diagnosticLog: diagnosticLog,
    );

    await ApiService.instance.logError({
      'error_type': _mapErrorType(log),
      'description': description,
      'device_id': deviceContext['device_id'],
      'device_name': deviceContext['device_name'],
      'device_model': deviceContext['device_model'],
      'os_version': deviceContext['os_version'],
      'app_version': deviceContext['app_version'],
      'sync_status': syncStatus,
    });

    removeLog(log.id);
  }
}
