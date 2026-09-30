import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/audit/repository/audit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(dioClientProvider));
});
