import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/segmented_control.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_provider.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/articles_tab.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/daily_tab.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/ramadan_tab.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/staff_tab.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Tab { daily, articles, ramadan, staff }

class CmsView extends ConsumerStatefulWidget {
  const CmsView({super.key});

  @override
  ConsumerState<CmsView> createState() => _CmsViewState();
}

class _CmsViewState extends ConsumerState<CmsView> {
  _Tab _tab = _Tab.daily;

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(staffSessionProvider);
    final theme = Theme.of(context);

    if (staff == null || !staff.hasCmsAccess) {
      return const SectionEmptyMessage(
        'You do not have access to the content manager.',
        hint: 'Ask a platform admin to assign you a staff role.',
        icon: Icons.lock_outline_rounded,
      );
    }

    final tabs = <(_Tab, String, IconData)>[
      (_Tab.daily, 'Daily', Icons.today_rounded),
      (_Tab.articles, 'Articles', Icons.article_rounded),
      (_Tab.ramadan, 'Ramadan', Icons.nights_stay_rounded),
      if (staff.canManageStaff) (_Tab.staff, 'Staff', Icons.badge_rounded),
    ];
    final current = tabs.any((t) => t.$1 == _tab) ? _tab : _Tab.daily;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = contentHorizontalPadding(constraints.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Manager',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Draft, review and publish what the app shows.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SegmentedControl<_Tab>(
                    selected: current,
                    onChanged: (t) => setState(() => _tab = t),
                    options: [
                      for (final t in tabs)
                        SegmentOption(value: t.$1, label: t.$2, icon: t.$3),
                    ],
                  ),
                  const SizedBox(height: 24),
                  switch (current) {
                    _Tab.daily => DailyTab(staff: staff),
                    _Tab.articles => ArticlesTab(staff: staff),
                    _Tab.ramadan => RamadanTab(staff: staff),
                    _Tab.staff => StaffTab(me: staff),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
