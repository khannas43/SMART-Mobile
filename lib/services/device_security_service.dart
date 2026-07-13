import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

/// Rooted / emulator checks for release builds (VAPT warning closure).
class DeviceSecurityService {
  DeviceSecurityService._();

  static final DeviceSecurityService instance = DeviceSecurityService._();

  /// Returns a user-facing block reason, or `null` when the device is allowed.
  Future<String?> compromisedDeviceReason() async {
    if (!kReleaseMode) return null;

    try {
      final jailBroken = await SafeDevice.isJailBroken;
      if (jailBroken) {
        return 'This app cannot run on rooted or compromised devices.';
      }

      final realDevice = await SafeDevice.isRealDevice;
      if (!realDevice) {
        return 'This app must run on a physical device.';
      }
    } catch (_) {
      // If the check fails, allow login rather than bricking production users.
      return null;
    }

    return null;
  }
}
