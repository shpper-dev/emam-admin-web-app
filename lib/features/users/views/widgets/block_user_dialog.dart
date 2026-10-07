import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/reason_text_field.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kRestriction30Days = '30d';
const String kRestrictionPermanent = 'permanent';

/// Resolves to the applied duration (`30d` / `permanent`), or null if cancelled.
Future<String?> showBlockUserDialog(
  BuildContext context, {
  required String userId,
  required String displayName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        BlockUserDialog(userId: userId, displayName: displayName),
  );
}

class BlockUserDialog extends ConsumerStatefulWidget {
  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  @override
  ConsumerState<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends ConsumerState<BlockUserDialog> {
  final _reasonController = TextEditingController();
  String _duration = kRestriction30Days;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting && _reasonController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(usersRepositoryProvider)
          .applyUserRestriction(
            widget.userId,
            reason: _reasonController.text.trim(),
            duration: _duration,
          );
      if (!mounted) return;
      Navigator.of(context).pop(_duration);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = parseApiError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to block user. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.displayName.isNotEmpty
        ? widget.displayName
        : 'this user';

    return AdminAlertDialog(
      title: 'Block user',
      icon: Icons.block_rounded,
      accentColor: AppConstants.danger,
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restrict $name from posting.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: kRestriction30Days, label: Text('30 days')),
              ButtonSegment(
                value: kRestrictionPermanent,
                label: Text('Permanent'),
              ),
            ],
            selected: {_duration},
            onSelectionChanged: _isSubmitting
                ? null
                : (value) => setState(() => _duration = value.first),
          ),
          const SizedBox(height: 16),
          ReasonTextField(
            controller: _reasonController,
            enabled: !_isSubmitting,
            onChanged: (_) => setState(() {}),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            DialogErrorText(_errorMessage!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DialogSubmitButton(
          label: 'Block',
          color: AppConstants.danger,
          enabled: _canSubmit,
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
