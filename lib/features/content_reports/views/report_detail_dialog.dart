import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/app_snackbar.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/filter_pill.dart';
import 'package:emam_admin_web_app/features/content_reports/models/content_report.dart';
import 'package:emam_admin_web_app/features/content_reports/provider/content_reports_provider.dart';
import 'package:emam_admin_web_app/features/content_reports/views/report_display.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves to true when the report was saved.
Future<bool?> showReportDetailDialog(
  BuildContext context, {
  required ContentReport report,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ReportDetailDialog(report: report),
  );
}

class ReportDetailDialog extends ConsumerStatefulWidget {
  const ReportDetailDialog({super.key, required this.report});

  final ContentReport report;

  @override
  ConsumerState<ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends ConsumerState<ReportDetailDialog> {
  late String _status = widget.report.status;
  late final _note = TextEditingController(text: widget.report.editorNote);
  late final _dup = TextEditingController(
    text: widget.report.duplicateOfReportId,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _dup.dispose();
    super.dispose();
  }

  bool get _needsDup => _status == 'duplicate';

  String? get _changedStatus =>
      _status != widget.report.status ? _status : null;
  String? get _changedNote {
    final v = _note.text.trim();
    return v.isNotEmpty && v != (widget.report.editorNote ?? '') ? v : null;
  }

  String? get _changedDup {
    final v = _dup.text.trim();
    return _needsDup && v.isNotEmpty && v != widget.report.duplicateOfReportId
        ? v
        : null;
  }

  bool get _canSave =>
      !_saving &&
      (_changedStatus != null || _changedNote != null || _changedDup != null) &&
      (!_needsDup || _dup.text.trim().isNotEmpty);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(contentReportsProvider.notifier)
          .update(
            widget.report.id,
            status: _changedStatus,
            editorNote: _changedNote,
            duplicateOfReportId: _changedDup,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = parseApiError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to update the report. Please try again.';
      });
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppConstants.textSecondary),
    filled: true,
    fillColor: AppConstants.inputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      borderSide: BorderSide(color: AppConstants.borderColorStrong),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      borderSide: BorderSide(color: AppConstants.borderColorStrong),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final theme = Theme.of(context);
    final rtl = isRtlLang(r.lang);
    final meta = [
      '${reportTypeLabel(r.contentType)} · ${r.contentId}',
      if (r.editionId != null) 'Edition ${r.editionId}',
      'Lang ${r.lang}',
      if (r.platform != null) r.platform!,
      if (r.appVersion != null) 'v${r.appVersion}',
    ].join('  ·  ');
    final reporter = r.userId != null
        ? 'User ${shortId(r.userId!)}'
        : r.deviceId != null
        ? 'Device ${shortId(r.deviceId!)}'
        : 'Unknown';

    return AdminAlertDialog(
      title: 'Report details',
      icon: Icons.spellcheck_rounded,
      contentWidth: 560,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.readableReference,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(
                  label: reportStatusLabel(r.status),
                  color: reportStatusColor(r.status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reported by $reporter on '
              '${formatAdminDate(r.createdAt, includeTime: true)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: r.contentId));
                  showAppSnackBar(
                    ScaffoldMessenger.of(context),
                    'Content ID copied',
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: Text('Copy content ID · ${r.contentId}'),
              ),
            ),
            DetailBlock(
              label: 'TEXT AS SHOWN IN THE APP',
              value: r.originalText,
              selectable: true,
              textDirection: rtl ? TextDirection.rtl : null,
              large: rtl,
            ),
            const SizedBox(height: 12),
            DetailBlock(
              label: "USER'S NOTE",
              value: r.userNote,
              selectable: true,
            ),
            if (r.isClosed && r.closedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Closed ${formatAdminDate(r.closedAt, includeTime: true)}'
                '${r.closedBy == null ? '' : ' by ${shortId(r.closedBy!)}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'STATUS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppConstants.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final st in kReportStatuses)
                  FilterPill(
                    label: reportStatusLabel(st),
                    selected: _status == st,
                    onTap: () {
                      if (!_saving) setState(() => _status = st);
                    },
                  ),
              ],
            ),
            if (_needsDup) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _dup,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
                decoration: _decoration('Duplicate of report ID'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: _decoration('Editor note'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              DialogErrorText(_error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        DialogSubmitButton(
          label: 'Save',
          color: AppConstants.primary,
          enabled: _canSave,
          isSubmitting: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
