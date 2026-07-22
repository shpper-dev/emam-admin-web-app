import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:emam_admin_web_app/features/users/utils/user_moderation_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showUnblockUserDialog(
  BuildContext context, {
  required String userId,
  required String displayName,
  DateTime? restrictedUntil,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => UnblockUserDialog(
      userId: userId,
      displayName: displayName,
      restrictedUntil: restrictedUntil,
    ),
  );
}

class UnblockUserDialog extends ConsumerStatefulWidget {
  const UnblockUserDialog({
    super.key,
    required this.userId,
    required this.displayName,
    this.restrictedUntil,
  });

  final String userId;
  final String displayName;
  final DateTime? restrictedUntil;

  @override
  ConsumerState<UnblockUserDialog> createState() => _UnblockUserDialogState();
}

class _UnblockUserDialogState extends ConsumerState<UnblockUserDialog> {
  static const Color _success = AppConstants.primary;

  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(usersRepositoryProvider).unblockUser(widget.userId);
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
        _errorMessage = 'Failed to unblock user. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.displayName.isNotEmpty
        ? widget.displayName
        : 'this user';
    final remaining = restrictionRemainingLabel(widget.restrictedUntil);

    return AlertDialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: Text(
        'Unblock user',
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
              'Are you sure you want to unblock $name? They will be able to post again immediately.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (remaining != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automatic unblock',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Restriction would lift in $remaining if left unchanged.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              : const Text('Unblock'),
        ),
      ],
    );
  }
}
