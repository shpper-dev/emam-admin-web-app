import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/auth/model/auth_session.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<String?> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AsyncLoading();

    try {
      final session = await ref.read(authRepositoryProvider).signIn(
            email: email.trim(),
            password: password,
          );

      await ref.read(tokenStorageProvider).saveRememberMe(
            rememberMe: rememberMe,
            email: rememberMe ? email.trim() : null,
          );

      state = AsyncData(session);
      return null;
    } on DioException catch (error) {
      state = const AsyncData(null);
      return parseApiError(error);
    } catch (_) {
      state = const AsyncData(null);
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}
