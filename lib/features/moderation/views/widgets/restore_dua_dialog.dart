import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
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
  static const Color _success = Color(0xFF66BB6A);

  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(moderationRepositoryProvider).restoreDuaPost(widget.postId);
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

  String _shortId(String value) {
    if (value.length <= 10) return value;
    return '${value.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postLabel = widget.postId.isNotEmpty
        ? 'post ${_shortId(widget.postId)}'
        : 'this post';

    return AlertDialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: Text(
        'Restore dua',
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore $postLabel? It will be visible in the feed again.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE57373),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          style: TextButton.styleFrom(foregroundColor: _success),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Restore'),
        ),
      ],
    );
  }
}
