import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/app_snackbar.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/repository/cms_repository.dart';
import 'package:flutter/material.dart';

/// Input rules shared by editors. Mirrors the backend's documented limits so
/// bad input is caught before the request, but the server stays the authority.
class CmsLimits {
  CmsLimits._();

  static final slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
  static final date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final uid = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final contentType = RegExp(r'^[a-z_]{1,32}$');
  static const slugMax = 80;
  static const titleMax = 200;
  static const summaryMax = 500;
  static const bodyMax = 50000;
  static const payloadMax = 100000;
  static const noteMax = 500;

  /// `tryParse` rolls 2026-13-45 over to a later date, so require the
  /// parsed value to print back as the same string.
  static bool validDate(String v) {
    if (!date.hasMatch(v)) return false;
    final d = DateTime.tryParse(v);
    return d != null && d.toIso8601String().startsWith(v);
  }

  /// Only https links may be stored; blocks `javascript:`/`data:` URLs from
  /// ever reaching apps that render the hero image or link.
  static bool validHttpsUrl(String v) {
    final uri = Uri.tryParse(v);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}

Color statusColor(CmsStatus s) => switch (s) {
  CmsStatus.draft => AppConstants.textMuted,
  CmsStatus.pendingReview => AppConstants.warning,
  CmsStatus.approved => AppConstants.info,
  CmsStatus.rejected => AppConstants.danger,
  CmsStatus.published => AppConstants.success,
};

Widget statusBadge(CmsStatus s) =>
    StatusBadge(label: s.label, color: statusColor(s));

/// Mirrors the backend's workflow rules so the UI offers only legal moves.
List<CmsAction> availableActions(StaffSession s, CmsStatus st) => [
  if (s.canEdit && (st == CmsStatus.draft || st == CmsStatus.rejected))
    CmsAction.submit,
  if (s.canReview && st == CmsStatus.pendingReview) ...[
    CmsAction.approve,
    CmsAction.reject,
  ],
  if (s.canEdit && (st == CmsStatus.draft || st == CmsStatus.approved))
    CmsAction.publish,
];

bool canPatch(StaffSession s, CmsStatus st) => switch (st) {
  CmsStatus.draft || CmsStatus.rejected => s.canEdit || s.canReview,
  CmsStatus.pendingReview || CmsStatus.approved => s.canReview,
  CmsStatus.published => false,
};

/// Runs [op], then reports the outcome. Returns true on success. Errors come
/// from the server's `detail`, never from raw exception text.
Future<bool> cmsRun(
  BuildContext context,
  Future<void> Function() op, {
  required String success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await op();
    showAppSnackBar(messenger, success);
    return true;
  } on DioException catch (e) {
    showAppSnackBar(messenger, parseApiError(e), error: true);
  } catch (_) {
    showAppSnackBar(
      messenger,
      'Unexpected response from the server.',
      error: true,
    );
  }
  return false;
}

/// Runs a workflow action after the confirmation it deserves: publish goes
/// live to every app user, reject needs a reason the author can act on.
Future<void> runWorkflow(
  BuildContext context, {
  required CmsAction action,
  required String subject,
  required Future<dynamic> Function(String? note) call,
  required VoidCallback onDone,
}) async {
  String? note;
  if (action == CmsAction.approve || action == CmsAction.reject) {
    note = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NoteDialog(reject: action == CmsAction.reject, subject: subject),
    );
    if (note == null) return;
  } else {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminAlertDialog(
        title: action == CmsAction.publish
            ? 'Publish now?'
            : 'Submit for review?',
        icon: action == CmsAction.publish
            ? Icons.public_rounded
            : Icons.rate_review_rounded,
        accentColor: action == CmsAction.publish
            ? AppConstants.warning
            : AppConstants.primary,
        contentWidth: 400,
        content: Text(
          action == CmsAction.publish
              ? '"$subject" becomes visible to every app user right away.'
              : '"$subject" will be locked for editing until a scholar reviews it.',
          style: Theme.of(
            ctx,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action == CmsAction.publish ? 'Publish' : 'Submit'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await call(note);
    if (result is PublishResult && !result.redisOk) {
      showAppSnackBar(
        messenger,
        'Published, but the app feed cache is down (redis_ok: false). '
        'Publish again once Redis is back.',
        error: true,
        duration: const Duration(seconds: 8),
      );
    } else {
      showAppSnackBar(messenger, switch (action) {
        CmsAction.submit => 'Submitted for review.',
        CmsAction.approve => 'Approved.',
        CmsAction.reject => 'Rejected.',
        CmsAction.publish => 'Published.',
      });
    }
  } on DioException catch (e) {
    showAppSnackBar(messenger, parseApiError(e), error: true);
  } catch (_) {
    showAppSnackBar(
      messenger,
      'Unexpected response from the server.',
      error: true,
    );
  }
  onDone();
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.reject, required this.subject});
  final bool reject;
  final String subject;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.reject ? AppConstants.danger : AppConstants.success;
    final ok = !widget.reject || _c.text.trim().isNotEmpty;
    return AdminAlertDialog(
      title: widget.reject ? 'Reject' : 'Approve',
      icon: widget.reject ? Icons.close_rounded : Icons.check_rounded,
      accentColor: color,
      contentWidth: 420,
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: 3,
        maxLength: CmsLimits.noteMax,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: widget.reject ? 'What needs fixing?' : 'Note (optional)',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DialogSubmitButton(
          label: widget.reject ? 'Reject' : 'Approve',
          color: color,
          enabled: ok,
          isSubmitting: false,
          onPressed: () => Navigator.of(context).pop(_c.text.trim()),
        ),
      ],
    );
  }
}

/// Action row for one entry/article card.
class EntryActions extends StatelessWidget {
  const EntryActions({
    super.key,
    required this.staff,
    required this.status,
    required this.onEdit,
    required this.onAction,
  });

  final StaffSession staff;
  final CmsStatus status;
  final VoidCallback onEdit;
  final ValueChanged<CmsAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.space8,
      runSpacing: AppConstants.space8,
      children: [
        if (canPatch(staff, status))
          PillActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppConstants.primary,
            onPressed: onEdit,
          ),
        for (final a in availableActions(staff, status))
          PillActionButton(
            icon: switch (a) {
              CmsAction.submit => Icons.rate_review_rounded,
              CmsAction.approve => Icons.check_rounded,
              CmsAction.reject => Icons.close_rounded,
              CmsAction.publish => Icons.public_rounded,
            },
            label: switch (a) {
              CmsAction.submit => 'Submit',
              CmsAction.approve => 'Approve',
              CmsAction.reject => 'Reject',
              CmsAction.publish => 'Publish',
            },
            color: switch (a) {
              CmsAction.reject => AppConstants.danger,
              CmsAction.publish => AppConstants.warning,
              CmsAction.approve => AppConstants.success,
              CmsAction.submit => AppConstants.info,
            },
            onPressed: () => onAction(a),
          ),
      ],
    );
  }
}

/// Generic save-dialog scaffold: validates via [validate] (returns an error
/// string or null), blocks double submits, and shows server errors inline.
class CmsFormDialog extends StatefulWidget {
  const CmsFormDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
    required this.validate,
    required this.save,
    this.submitLabel = 'Save',
    this.width = 560,
  });

  final String title;
  final IconData icon;
  final List<Widget> fields;
  final String? Function() validate;
  final Future<void> Function() save;
  final String submitLabel;
  final double width;

  @override
  State<CmsFormDialog> createState() => _CmsFormDialogState();
}

class _CmsFormDialogState extends State<CmsFormDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_saving) return;
    final problem = widget.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save();
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (mounted) setState(() => _error = parseApiError(e));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unexpected response from the server.');
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminAlertDialog(
      title: widget.title,
      icon: widget.icon,
      contentWidth: widget.width,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.fields,
            if (_error != null) ...[
              const SizedBox(height: AppConstants.space12),
              DialogErrorText(_error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        DialogSubmitButton(
          label: widget.submitLabel,
          color: AppConstants.primary,
          enabled: !_saving,
          isSubmitting: _saving,
          onPressed: _submit,
        ),
      ],
    );
  }
}

Widget cmsField(
  TextEditingController c,
  String label, {
  int? maxLength,
  int maxLines = 1,
  bool enabled = true,
  String? helper,
  TextStyle? style,
}) => Padding(
  padding: const EdgeInsets.only(bottom: AppConstants.space12),
  child: TextField(
    controller: c,
    enabled: enabled,
    maxLength: maxLength,
    minLines: maxLines > 1 ? 2 : 1,
    maxLines: maxLines,
    style: style,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      alignLabelWithHint: maxLines > 1,
      border: const OutlineInputBorder(),
    ),
  ),
);
