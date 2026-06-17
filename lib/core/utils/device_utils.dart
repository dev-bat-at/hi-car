import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtils {
  DeviceUtils._();

  /// Device metadata for error reports and login (API field names).
  static Future<Map<String, String>> getDeviceContext() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

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
        final manufacturer = androidInfo.manufacturer;
        if (manufacturer.isNotEmpty) {
          final label = manufacturer[0].toUpperCase() +
              (manufacturer.length > 1 ? manufacturer.substring(1) : '');
          deviceName = '$label ${androidInfo.model}';
        } else {
          deviceName = androidInfo.model;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceName = iosInfo.name;
      }
    } catch (_) {}

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': 'v${packageInfo.version}',
    };
  }

  @Deprecated('Use getDeviceContext')
  static Future<Map<String, String>> GetDeviceContext() => getDeviceContext();
}
