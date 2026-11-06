import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_repository_provider.dart';
import 'package:emam_admin_web_app/features/devices/models/signed_in_session.dart';
import 'package:emam_admin_web_app/features/devices/repository/sessions_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  return SessionsRepository(ref.watch(dioClientProvider));
});

final sessionsProvider =
    AsyncNotifierProvider.autoDispose<SessionsNotifier, SignedInSessions>(
      SessionsNotifier.new,
    );

class SessionsNotifier extends AsyncNotifier<SignedInSessions> {
  SessionsRepository get _repo => ref.read(sessionsRepositoryProvider);

  @override
  Future<SignedInSessions> build() => _load();

  /// Reloads without flashing the loading state; keeps old data on failure.
  Future<void> refresh() async {
    try {
      final data = await _load();
      if (ref.mounted) state = AsyncData(data);
    } catch (_) {}
  }

  /// Registers this browser first so `X-Emam-Auth-Session` is on the list
  /// request and the matching row can be marked current.
  Future<SignedInSessions> _load() async {
    final sessionId = await ref
        .read(authRepositoryProvider)
        .ensurePortalSession();
    final data = await _repo.fetchSessions();
    return data.withCurrent(sessionId);
  }

  /// Throws on failure so the caller can show the error.
  Future<void> revoke(SignedInSession session) async {
    await _repo.revokeSession(session.id, adminUserId: session.adminUserId);
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(current.without(session.id));
    }
  }
}
