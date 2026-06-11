import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceUtils {
  DeviceUtils._();

  static Future<Map<String, String>> GetDeviceContext() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    String deviceModel = 'unknown';
    String deviceName = 'unknown';
    String osVersion = Platform.operatingSystemVersion;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
        // Better device name: "Samsung SM-G991B" instead of "localhost"
        final manufacturer = androidInfo.manufacturer[0].toUpperCase() +
            androidInfo.manufacturer.substring(1);
        final model = androidInfo.model;
        deviceName = '$manufacturer $model';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceName = iosInfo.name; // e.g. "iPhone 13"
      }
    } catch (_) {}

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_model': deviceModel,
      'os_version': osVersion,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'app_version': '1.0.0',
    };
  }
}
