import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/reason_text_field.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showBlockUserDialog(
  BuildContext context, {
  required String userId,
  required String displayName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => BlockUserDialog(
      userId: userId,
      displayName: displayName,
    ),
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
  static const Color _danger = Color(0xFFE57373);

  final _reasonController = TextEditingController();
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
      await ref.read(usersRepositoryProvider).applyUserRestriction(
            widget.userId,
            reason: _reasonController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply a 30-day posting restriction to $name.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
          color: _danger,
          enabled: _canSubmit,
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
