import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_provider.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_repository_provider.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/cms_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyTab extends ConsumerStatefulWidget {
  const DailyTab({super.key, required this.staff});
  final StaffSession staff;

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab> {
  CmsModule _module = CmsModule.dailyInspiration;

  Future<void> _edit([CmsEntry? entry]) async {
    final module = _module;
    final date = TextEditingController(text: entry?.scheduledFor ?? '');
    final json = TextEditingController(
      text: const JsonEncoder.withIndent(
        '  ',
      ).convert(entry?.payload ?? module.template),
    );
    late Map<String, dynamic> payload;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CmsFormDialog(
        title: entry == null ? 'New ${module.label} draft' : 'Edit entry',
        icon: Icons.edit_note_rounded,
        width: 640,
        fields: [
          cmsField(
            date,
            'Scheduled for (YYYY-MM-DD)',
            maxLength: 10,
            helper: 'Leave empty for today (Asia/Dubai).',
          ),
          cmsField(
            json,
            'Payload (JSON)',
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            helper: 'Must resemble the public API response for this module.',
          ),
        ],
        validate: () {
          final d = date.text.trim();
          if (d.isNotEmpty && !CmsLimits.validDate(d)) {
            return 'Date must be a real date like 2026-11-16.';
          }
          if (json.text.length > CmsLimits.payloadMax) {
            return 'Payload is too large.';
          }
          try {
            final decoded = jsonDecode(json.text);
            if (decoded is! Map<String, dynamic>) {
              return 'Payload must be a JSON object.';
            }
            payload = decoded;
          } on FormatException catch (e) {
            return 'Invalid JSON: ${e.message}';
          }
          return null;
        },
        save: () {
          final repo = ref.read(cmsRepositoryProvider);
          final d = date.text.trim();
          return entry == null
              ? repo.createDaily(module, scheduledFor: d, payload: payload)
              : repo.patchDaily(
                  module,
                  entry.id,
                  scheduledFor: d.isEmpty ? entry.scheduledFor : d,
                  payload: payload,
                );
        },
      ),
    );
    date.dispose();
    json.dispose();
    if (saved == true) ref.invalidate(dailyEntriesProvider(module));
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(dailyEntriesProvider(_module));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppConstants.space8,
          runSpacing: AppConstants.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final m in CmsModule.values)
              ChoiceChip(
                label: Text(m.label),
                selected: m == _module,
                onSelected: (_) => setState(() => _module = m),
              ),
            if (widget.staff.canEdit)
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New draft'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                  foregroundColor: AppConstants.black,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.space16),
        entries.when(
          loading: () => const SkeletonList(rows: 3, rowHeight: 96),
          error: (e, _) => InlineRetryError(
            message: e is DioException
                ? parseApiError(e)
                : 'Could not load entries.',
            onRetry: () => ref.invalidate(dailyEntriesProvider(_module)),
          ),
          data: (list) => list.isEmpty
              ? const SectionEmptyMessage('No entries yet.')
              : Column(
                  children: [
                    for (final e in list)
                      _EntryCard(
                        entry: e,
                        module: _module,
                        staff: widget.staff,
                        onEdit: () => _edit(e),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({
    required this.entry,
    required this.module,
    required this.staff,
    required this.onEdit,
  });

  final CmsEntry entry;
  final CmsModule module;
  final StaffSession staff;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preview = const JsonEncoder.withIndent('  ').convert(entry.payload);
    final subject = '${module.label} ${entry.scheduledFor}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.space12),
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.scheduledFor,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppConstants.space12),
              statusBadge(entry.status),
            ],
          ),
          const SizedBox(height: AppConstants.space8),
          // Plain text only: payload content is never interpreted as markup.
          Text(
            preview,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: AppConstants.textSecondary,
            ),
          ),
          if (entry.reviewNote.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Text(
              'Review note: ${entry.reviewNote}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.warning,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.space12),
          EntryActions(
            staff: staff,
            status: entry.status,
            onEdit: onEdit,
            onAction: (a) => runWorkflow(
              context,
              action: a,
              subject: subject,
              call: (note) => ref
                  .read(cmsRepositoryProvider)
                  .dailyAction(module, entry.id, a, reviewNote: note),
              onDone: () => ref.invalidate(dailyEntriesProvider(module)),
            ),
          ),
        ],
      ),
    );
  }
}
