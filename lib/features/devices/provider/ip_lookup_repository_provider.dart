import 'package:emam_admin_web_app/features/devices/repository/ip_lookup_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ipLookupRepositoryProvider = Provider<IpLookupRepository>((ref) {
  return IpLookupRepository();
});
