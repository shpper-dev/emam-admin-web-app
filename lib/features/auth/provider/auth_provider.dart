import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/audit/provider/audit_provider.dart';
import 'package:emam_admin_web_app/features/content/provider/content_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/hidden_posts_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_queue_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/reported_duas_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/voice_server/provider/voice_server_provider.dart';
import 'package:emam_admin_web_app/features/auth/models/auth_repository.dart';
import 'package:emam_admin_web_app/features/auth/models/auth_session.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);

class SignInErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void clear() => state = null;
}

final signInErrorProvider = NotifierProvider<SignInErrorNotifier, String?>(
  SignInErrorNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    ref.read(signInErrorProvider.notifier).clear();

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password);

      await ref
          .read(tokenStorageProvider)
          .saveRememberMe(
            rememberMe: rememberMe,
            email: rememberMe ? email.trim() : null,
          );

      ref.read(signInErrorProvider.notifier).clear();
      state = AsyncData(session);
    } on NotAdminException {
      ref.read(signInErrorProvider.notifier).state = NotAdminException.message;
    } on DioException catch (error) {
      ref.read(signInErrorProvider.notifier).state = parseApiError(error);
    } catch (_) {
      ref.read(signInErrorProvider.notifier).state =
          'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(signInErrorProvider.notifier).clear();
    _resetSessionData();
    state = const AsyncData(null);
  }

  /// Drop admin data cached in memory so a later sign-in in the same tab
  /// can't see it (and re-fetches with the new admin's identity filter).
  void _resetSessionData() {
    ref
      ..invalidate(auditProvider)
      ..invalidate(dailyInspirationProvider)
      ..invalidate(practiceCardProvider)
      ..invalidate(islamicEventsProvider)
      ..invalidate(islamicNewsProvider)
      ..invalidate(scholarlyInsightsProvider)
      ..invalidate(hiddenPostsPaginationProvider)
      ..invalidate(moderationQueueProvider)
      ..invalidate(reportedDuasProvider)
      ..invalidate(restrictedUsersPaginationProvider)
      ..invalidate(userDetailCacheProvider)
      ..invalidate(usersPaginationProvider)
      ..invalidate(voiceServerProvider);
  }
}
