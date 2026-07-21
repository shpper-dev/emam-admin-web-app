import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
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
        'Hide dua',
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
              'Hide $postLabel from the feed. This action is applied immediately.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              enabled: !_isSubmitting,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              cursorColor: AppConstants.primary,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Reason',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                filled: true,
                fillColor: AppConstants.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppConstants.primary),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(color: _danger),
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
          onPressed: _canSubmit ? _submit : null,
          style: TextButton.styleFrom(foregroundColor: _danger),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hide'),
        ),
      ],
    );
  }
}
