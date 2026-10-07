import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/system_tools/provider/system_tools_repository_provider.dart';
import 'package:emam_admin_web_app/features/system_tools/repository/system_tools_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemToolsView extends ConsumerWidget {
  const SystemToolsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(systemToolsRepositoryProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(
          constraints.maxWidth,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Tools',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clear server caches and reload the Dua RAG index without '
                'restarting the backend.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              for (final domain in CacheDomain.values) ...[
                _ToolCard(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Clear ${domain.label} cache',
                  description: _cacheDescription(domain),
                  buttonLabel: 'Clear cache',
                  confirmTitle: 'Clear the ${domain.label} cache?',
                  confirmBody:
                      'Cached ${domain.label} data is dropped and rebuilt on '
                      'the next request, which may be briefly slower.',
                  action: () => repo
                      .invalidateCache(domain)
                      .then((m) => m ?? '${domain.label} cache cleared.'),
                ),
                const SizedBox(height: AppConstants.space16),
              ],
              _ToolCard(
                icon: Icons.refresh_rounded,
                title: 'Reload Dua RAG index',
                description:
                    'Loads the rebuilt index from disk into memory. Run this '
                    'after the index build script has finished.',
                buttonLabel: 'Reload index',
                confirmTitle: 'Reload the Dua RAG index?',
                confirmBody:
                    'The in-memory index is replaced with the one on disk. '
                    'This fails if the index is missing.',
                action: repo.reloadRag,
              ),
            ],
          ),
        );
      },
    );
  }

  static String _cacheDescription(CacheDomain domain) => switch (domain) {
    CacheDomain.duaBoard => 'Clears the cached dua board.',
    CacheDomain.duaRag => 'Clears cached dua RAG results.',
    CacheDomain.quranReader => 'Clears the cached Quran reader data.',
  };
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.confirmTitle,
    required this.confirmBody,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final String confirmTitle;
  final String confirmBody;
  final Future<String> Function() action;

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _busy = false;
  String? _result;
  bool _failed = false;

  Future<void> _run() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminAlertDialog(
        title: widget.confirmTitle,
        icon: widget.icon,
        accentColor: AppConstants.warning,
        content: Text(
          widget.confirmBody,
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(widget.buttonLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    String message;
    var failed = false;
    try {
      message = await widget.action();
    } on DioException catch (error) {
      message = parseApiError(error);
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = message;
      _failed = failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final resultColor = _failed ? AppConstants.danger : AppConstants.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
                child: Icon(
                  widget.icon,
                  color: AppConstants.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          Text(
            widget.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.space16),
          Wrap(
            spacing: AppConstants.space12,
            runSpacing: AppConstants.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: _busy ? null : _run,
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                  foregroundColor: AppConstants.black,
                ),
                child: Text(widget.buttonLabel),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: AppConstants.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _failed
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: resultColor,
                ),
                const SizedBox(width: AppConstants.space8),
                Expanded(
                  child: Text(
                    result,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: resultColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
