import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/content_reports/repository/content_reports_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contentReportsRepositoryProvider = Provider<ContentReportsRepository>((
  ref,
) {
  return ContentReportsRepository(ref.watch(dioClientProvider));
});
