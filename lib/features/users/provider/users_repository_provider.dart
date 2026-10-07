import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/users/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(
    ref.watch(dioClientProvider),
    adminEmail: ref.watch(authProvider).value?.email,
    adminUserId: ref.watch(authProvider).value?.localId,
  );
});
