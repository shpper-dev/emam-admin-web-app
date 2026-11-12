import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_crash_report.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_detail_providers.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UnitCrashReportsCard extends ConsumerWidget {
  const UnitCrashReportsCard({super.key, required this.unit});

  final DeviceUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = unitCrashReportsProvider(unit.installId);
    final onUnit = unit.crashes;
    return ContentSectionCard(
      title: 'Crash reports',
      subtitle: onUnit > 0
          ? 'The unit holds ${onUnit == 1 ? '1 report' : '$onUnit reports'}. '
                '"Upload crash reports" sends them here.'
          : 'Reports this unit has uploaded.',
      icon: Icons.bug_report_rounded,
      trailing: IconButton(
        tooltip: 'Refresh crash reports',
        onPressed: () => ref.invalidate(provider),
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: ref
          .watch(provider)
          .when(
            skipLoadingOnReload: true,
            loading: () => const SectionLoadingIndicator(),
            error: (error, _) => InlineRetryError(
              message: unitErrorMessage(error),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (reports) => reports.isEmpty
                ? const SectionEmptyMessage(
                    'No crash reports uploaded.',
                    icon: Icons.bug_report_outlined,
                  )
                : Column(
                    children: [
                      for (final report in reports) _CrashTile(report: report),
                    ],
                  ),
          ),
    );
  }
}

class _CrashTile extends StatelessWidget {
  const _CrashTile({required this.report});

  final UnitCrashReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppConstants.space12),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppConstants.primary,
      collapsedIconColor: AppConstants.textMuted,
      title: Text(report.name, style: theme.textTheme.titleSmall),
      subtitle: Text(
        'Received ${formatAdminDate(report.receivedAt, unknownLabel: 'at an unknown time', includeTime: true)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppConstants.textMuted,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.all(AppConstants.space12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              report.text.isEmpty ? 'The report is empty.' : report.text,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                height: 1.45,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report.text));
              showUnitToast(context, 'Crash report copied.');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy report'),
          ),
        ),
      ],
    );
  }
}
