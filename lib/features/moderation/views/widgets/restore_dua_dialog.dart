import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_error_text.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showRestoreDuaDialog(
  BuildContext context, {
  required String postId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => RestoreDuaDialog(postId: postId),
  );
}

class RestoreDuaDialog extends ConsumerStatefulWidget {
  const RestoreDuaDialog({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<RestoreDuaDialog> createState() => _RestoreDuaDialogState();
}

class _RestoreDuaDialogState extends ConsumerState<RestoreDuaDialog> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(moderationRepositoryProvider)
          .restoreDuaPost(widget.postId);
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
        _errorMessage = 'Failed to restore dua. Please try again.';
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
      title: 'Restore dua',
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to restore $postLabel? It will be visible in the feed again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.textSecondary,
            ),
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
          label: 'Restore',
          color: AppConstants.success,
          enabled: !_isSubmitting,
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
