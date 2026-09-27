import 'package:emam_admin_web_app/features/devices/utils/device_label.dart';

/// This browser's own admin sign-in session. There is no backend endpoint
/// (yet) to list sign-ins from *other* devices/browsers, so this always
/// describes exactly the session you're viewing it from.
class DeviceSessionInfo {
  const DeviceSessionInfo({
    required this.label,
    required this.ipAddress,
    required this.startedAt,
    required this.expiresAt,
    required this.lastAccessedAt,
  });

  final DeviceLabel label;
  final String? ipAddress;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime lastAccessedAt;
}
