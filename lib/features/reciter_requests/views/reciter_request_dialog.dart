import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/filter_pill.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/reciter_requests/models/reciter_request.dart';
import 'package:emam_admin_web_app/features/reciter_requests/provider/reciter_requests_provider.dart';
import 'package:emam_admin_web_app/features/reciter_requests/views/reciter_requests_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves to true when the request was saved.
Future<bool?> showReciterRequestDialog(
  BuildContext context, {
  required ReciterRequest request,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ReciterRequestDialog(request: request),
  );
}

class ReciterRequestDialog extends ConsumerStatefulWidget {
  const ReciterRequestDialog({super.key, required this.request});

  final ReciterRequest request;

  @override
  ConsumerState<ReciterRequestDialog> createState() =>
      _ReciterRequestDialogState();
}

class _ReciterRequestDialogState extends ConsumerState<ReciterRequestDialog> {
  late String _status = widget.request.status;
  late final _note = TextEditingController(text: widget.request.editorNote);
  List<ReciterRequestEvent>? _events;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final d = await ref
          .read(reciterRequestsProvider.notifier)
          .loadDetail(widget.request.id);
      if (mounted) setState(() => _events = d.recentEvents);
    } catch (_) {
      if (mounted) setState(() => _events = const []);
    }
  }

  String? get _changedStatus =>
      _status != widget.request.status ? _status : null;
  String? get _changedNote {
    final v = _note.text.trim();
    return v.isNotEmpty && v != (widget.request.editorNote ?? '') ? v : null;
  }

  bool get _canSave =>
      !_saving && (_changedStatus != null || _changedNote != null);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(reciterRequestsProvider.notifier)
          .update(
            widget.request.id,
            status: _changedStatus,
            editorNote: _changedNote,
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
        _error = 'Failed to update the request. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppConstants.textSecondary,
    );
    final label = theme.textTheme.labelSmall?.copyWith(
      color: AppConstants.textMuted,
      fontWeight: FontWeight.w600,
    );

    return AdminAlertDialog(
      title: 'Reciter request',
      icon: Icons.mic_external_on_rounded,
      contentWidth: 520,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(
                  label: reciterStatusLabel(r.status),
                  color: reciterStatusColor(r.status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${r.requestCount} requests · first '
              '${formatAdminDate(r.createdAt, includeTime: true)} · last '
              '${formatAdminDate(r.lastRequestedAt, includeTime: true)}',
              style: muted,
            ),
            if (r.langCounts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.langCounts.entries
                    .map((e) => '${e.key.toUpperCase()} ${e.value}')
                    .join(' · '),
                style: muted,
              ),
            ],
            const SizedBox(height: 16),
            Text('RECENT REQUESTS', style: label),
            const SizedBox(height: 6),
            if (_events == null)
              const LinearProgressIndicator(minHeight: 2)
            else if (_events!.isEmpty)
              Text('No recent activity.', style: muted)
            else
              for (final e in _events!.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    [
                      formatAdminDate(e.createdAt, includeTime: true),
                      e.lang.toUpperCase(),
                      ?e.platform,
                      if (e.appVersion != null) 'v${e.appVersion}',
                    ].join(' · '),
                    style: muted,
                  ),
                ),
            const SizedBox(height: 20),
            Text('STATUS', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final st in kReciterStatuses)
                  FilterPill(
                    label: reciterStatusLabel(st),
                    selected: _status == st,
                    onTap: () {
                      if (!_saving) setState(() => _status = st);
                    },
                  ),
              ],
            ),
            if (_status == 'added')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Marking as added does not publish the reciter — add it to '
                  'the reciters list on the backend separately.',
                  style: muted,
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              enabled: !_saving,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Editor note'),
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
