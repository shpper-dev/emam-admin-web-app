import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(sharedPreferencesProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    refresher: ref.watch(authRepositoryProvider),
  );
});
