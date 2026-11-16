import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/ramadan_settings.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's staff roles (null when `/admin/me` was unavailable).
final staffSessionProvider = Provider<StaffSession?>(
  (ref) => ref.watch(authProvider).value?.staff,
);

final dailyEntriesProvider = FutureProvider.autoDispose
    .family<List<CmsEntry>, CmsModule>(
      (ref, module) => ref.watch(cmsRepositoryProvider).listDaily(module),
    );

final articlesProvider = FutureProvider.autoDispose<List<CmsArticle>>(
  (ref) => ref.watch(cmsRepositoryProvider).listArticles(),
);

final ramadanSettingsProvider = FutureProvider.autoDispose<RamadanSettings>(
  (ref) => ref.watch(cmsRepositoryProvider).fetchRamadan(),
);

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>(
  (ref) => ref.watch(cmsRepositoryProvider).listStaff(),
);
