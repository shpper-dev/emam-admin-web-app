import 'package:emam_admin_web_app/features/users/views/widgets/users_management_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedUsersTabProvider =
    NotifierProvider<SelectedUsersTabNotifier, UsersTab>(
  SelectedUsersTabNotifier.new,
);

class SelectedUsersTabNotifier extends Notifier<UsersTab> {
  @override
  UsersTab build() => UsersTab.all;

  void select(UsersTab tab) => state = tab;
}
