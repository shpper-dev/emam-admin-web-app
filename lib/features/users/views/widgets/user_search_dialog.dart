import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showUserSearchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) => const UserSearchDialog(),
  );
}

class UserSearchDialog extends ConsumerStatefulWidget {
  const UserSearchDialog({super.key});

  @override
  ConsumerState<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<UserSearchDialog> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  List<AppUser> _results = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _validationMessage;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() {
        _validationMessage = 'Enter at least 2 characters to search.';
        _errorMessage = null;
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _validationMessage = null;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final response = await ref
          .read(usersRepositoryProvider)
          .searchUsers(query: query);
      if (!mounted) return;
      setState(() {
        _results = response.users;
        _isSearching = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = parseApiError(e);
        _results = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed. Please try again.';
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    final maxWidth = (MediaQuery.sizeOf(context).width * 0.92).clamp(
      360.0,
      720.0,
    );

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppConstants.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Search users',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        focusNode: _focusNode,
                        enabled: !_isSearching,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        onChanged: (_) {
                          if (_validationMessage != null) {
                            setState(() => _validationMessage = null);
                          }
                        },
                        style: const TextStyle(color: Colors.white),
                        cursorColor: AppConstants.primary,
                        decoration: InputDecoration(
                          hintText: 'Name or email',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
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
                            borderSide: const BorderSide(
                              color: AppConstants.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _isSearching ? null : _search,
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: AppConstants.primary.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                  ],
                ),
              ),
            ),
            if (_validationMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _validationMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE57373),
                    ),
                  ),
                ),
              ),
            const Divider(height: 1, color: Color(0xFF1E1E20)),
            Flexible(child: _buildResults(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Search by display name or email address.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No users found.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _results[index];
        return UserCard(
          user: user,
          onTap: () {
            Navigator.of(context).pop();
            showUserDetailDialog(context, userId: user.id);
          },
        );
      },
    );
  }
}
