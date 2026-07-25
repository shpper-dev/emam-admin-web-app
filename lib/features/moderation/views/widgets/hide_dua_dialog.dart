import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/core/widgets/reason_text_field.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showHideDuaDialog(
  BuildContext context, {
  required String postId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => HideDuaDialog(postId: postId),
  );
}

class HideDuaDialog extends ConsumerStatefulWidget {
  const HideDuaDialog({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<HideDuaDialog> createState() => _HideDuaDialogState();
}

class _HideDuaDialogState extends ConsumerState<HideDuaDialog> {
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
      await ref.read(moderationRepositoryProvider).hideDuaPost(
            widget.postId,
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
        _errorMessage = 'Failed to hide dua. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postLabel = widget.postId.isNotEmpty
        ? 'post ${shortId(widget.postId)}'
        : 'this post';

    return AdminAlertDialog(
      title: 'Hide dua',
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hide $postLabel from the feed. This action is applied immediately.',
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
          label: 'Hide',
          color: _danger,
          enabled: _canSubmit,
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
