import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRestrictionProvider = FutureProvider.autoDispose
    .family<UserDetailModeration, String>(
      (ref, userId) =>
          ref.watch(usersRepositoryProvider).fetchUserRestriction(userId),
    );

final userReportsFiledProvider = FutureProvider.autoDispose
    .family<List<ModerationReport>, String>(
      (ref, userId) =>
          ref.watch(usersRepositoryProvider).fetchReportsFiled(userId),
    );

final userReportsReceivedProvider = FutureProvider.autoDispose
    .family<List<ModerationReport>, String>(
      (ref, userId) =>
          ref.watch(usersRepositoryProvider).fetchReportsReceived(userId),
    );
