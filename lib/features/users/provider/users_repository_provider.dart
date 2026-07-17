import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/users/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(dioClientProvider));
});
