import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/cms/repository/cms_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cmsRepositoryProvider = Provider<CmsRepository>(
  (ref) => CmsRepository(ref.watch(dioClientProvider)),
);
