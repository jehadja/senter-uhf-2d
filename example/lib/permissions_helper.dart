import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request all permissions needed for UHF reader
  static Future<bool> requestUhfPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print('Some permissions were denied:');
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          print('$permission: $status');
        }
      });
    }

    return allGranted;
  }

  /// Check if all UHF permissions are granted
  static Future<bool> checkUhfPermissions() async {
    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.location.isGranted;
  }
}
