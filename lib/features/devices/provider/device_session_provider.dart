import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/devices/models/device_session_info.dart';
import 'package:emam_admin_web_app/features/devices/provider/ip_lookup_repository_provider.dart';
import 'package:emam_admin_web_app/features/devices/utils/browser_user_agent.dart';
import 'package:emam_admin_web_app/features/devices/utils/device_label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceSessionProvider =
    AsyncNotifierProvider.autoDispose<DeviceSessionNotifier, DeviceSessionInfo>(
      DeviceSessionNotifier.new,
    );

class DeviceSessionNotifier extends AsyncNotifier<DeviceSessionInfo> {
  @override
  Future<DeviceSessionInfo> build() => _load();

  Future<void> refresh() async {
    final data = await _load();
    if (ref.mounted) state = AsyncData(data);
  }

  Future<DeviceSessionInfo> _load() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final label = DeviceLabel.fromUserAgent(currentUserAgent());

    String? ipAddress;
    try {
      ipAddress = await ref.read(ipLookupRepositoryProvider).fetchPublicIp();
    } catch (_) {
      ipAddress = null;
    }

    return DeviceSessionInfo(
      label: label,
      ipAddress: ipAddress,
      startedAt: tokenStorage.signedInAt,
      expiresAt: tokenStorage.expiresAtDate,
      lastAccessedAt: DateTime.now(),
    );
  }
}
