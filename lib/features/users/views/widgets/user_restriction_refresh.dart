import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> refreshAfterUserRestrictionChange(
  WidgetRef ref, {
  required String userId,
}) async {
  ref.read(userDetailCacheProvider.notifier).invalidate(userId);
  await Future.wait([
    ref.read(usersPaginationProvider.notifier).refresh(),
    ref.read(restrictedUsersPaginationProvider.notifier).refresh(),
  ]);
}

void showRestrictionSnackBar(
  BuildContext context, {
  required String displayName,
  required bool blocked,
}) {
  final message = blocked
      ? '$displayName has been blocked for 30 days.'
      : '$displayName has been unblocked.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
