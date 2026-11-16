import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_provider.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_repository_provider.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/cms_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffTab extends ConsumerWidget {
  const StaffTab({super.key, required this.me});
  final StaffSession me;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    StaffMember? m,
  ]) async {
    final uid = TextEditingController(text: m?.uid ?? '');
    final email = TextEditingController(text: m?.email ?? '');
    final name = TextEditingController(text: m?.displayName ?? '');
    final roles = <String>{...?m?.roles};
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => CmsFormDialog(
          title: m == null ? 'Add staff member' : 'Edit roles',
          icon: Icons.badge_rounded,
          width: 480,
          fields: [
            cmsField(uid, 'Firebase UID', enabled: m == null, maxLength: 128),
            cmsField(email, 'Email', maxLength: 254),
            cmsField(name, 'Display name', maxLength: 100),
            for (final r in StaffRole.all)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(StaffRole.label(r)),
                subtitle: r == StaffRole.admin
                    ? const Text('Full access, including staff management.')
                    : null,
                value: roles.contains(r),
                onChanged: (v) => setLocal(() {
                  v == true ? roles.add(r) : roles.remove(r);
                }),
              ),
          ],
          validate: () {
            if (!CmsLimits.uid.hasMatch(uid.text.trim())) {
              return 'Enter a valid Firebase UID.';
            }
            if (!email.text.contains('@')) return 'Enter a valid email.';
            return null;
          },
          save: () => ref
              .read(cmsRepositoryProvider)
              .setStaffRoles(
                uid.text.trim(),
                roles: roles,
                email: email.text.trim(),
                displayName: name.text.trim(),
              ),
        ),
      ),
    );
    uid.dispose();
    email.dispose();
    name.dispose();
    if (saved == true) ref.invalidate(staffListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.space16),
          child: FilledButton.icon(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Add staff'),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: AppConstants.black,
            ),
          ),
        ),
        ref
            .watch(staffListProvider)
            .when(
              loading: () => const SkeletonList(rows: 3),
              error: (e, _) => InlineRetryError(
                message: e is DioException
                    ? parseApiError(e)
                    : 'Could not load staff.',
                onRetry: () => ref.invalidate(staffListProvider),
              ),
              data: (list) => list.isEmpty
                  ? const SectionEmptyMessage('No staff assigned yet.')
                  : Column(
                      children: [
                        for (final m in list)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              bottom: AppConstants.space12,
                            ),
                            padding: const EdgeInsets.all(AppConstants.space16),
                            decoration: BoxDecoration(
                              color: AppConstants.surfaceColor,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMd,
                              ),
                              border: Border.all(
                                color: AppConstants.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.displayName.isEmpty
                                            ? m.email
                                            : m.displayName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        '${m.email}${m.uid == me.uid ? ' (you)' : ''}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppConstants.textMuted,
                                            ),
                                      ),
                                      const SizedBox(
                                        height: AppConstants.space8,
                                      ),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          for (final r in m.roles)
                                            Chip(
                                              label: Text(StaffRole.label(r)),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Editing your own roles could lock you out.
                                if (m.uid != me.uid)
                                  PillActionButton(
                                    icon: Icons.edit_rounded,
                                    label: 'Roles',
                                    color: AppConstants.primary,
                                    onPressed: () => _edit(context, ref, m),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
      ],
    );
  }
}
