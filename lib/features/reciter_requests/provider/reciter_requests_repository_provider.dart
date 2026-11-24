import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/reciter_requests/repository/reciter_requests_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reciterRequestsRepositoryProvider = Provider<ReciterRequestsRepository>((
  ref,
) {
  return ReciterRequestsRepository(ref.watch(dioClientProvider));
});
