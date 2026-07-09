import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/providers/core_providers.dart';
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

final signInErrorProvider =
    NotifierProvider<SignInErrorNotifier, String?>(SignInErrorNotifier.new);

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
    state = const AsyncData(null);
  }
}
