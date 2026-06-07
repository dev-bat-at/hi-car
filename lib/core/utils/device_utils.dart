import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  DeviceUtils._();

  static Future<Map<String, String>> GetDeviceContext() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = Platform.operatingSystemVersion;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (_) {}

    return {
      'device_id': deviceId,
      'device_name': Platform.localHostname,
      'device_model': deviceModel,
      'os_version': osVersion,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'app_version': '1.0.0',
    };
  }
}
