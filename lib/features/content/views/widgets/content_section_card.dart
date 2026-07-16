import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentSectionCard extends StatelessWidget {
  const ContentSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppConstants.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppConstants.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E1E20)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Compact pill-shaped button that opens [url] in an external browser tab.
/// Renders nothing (returns a zero-sized widget) when [url] is empty.
class ContentLinkButton extends StatelessWidget {
  const ContentLinkButton({
    super.key,
    required this.label,
    required this.url,
    this.icon = Icons.open_in_new_rounded,
  });

  final String label;
  final String url;
  final IconData icon;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    var normalized = url.trim();
    if (normalized.isEmpty) return;
    if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Invalid link: $url')),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Could not open $normalized')),
        );
      }
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Failed to open link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppConstants.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppConstants.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentMetaChip extends StatelessWidget {
  const ContentMetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

int contentGridColumns(double width) {
  if (width >= 1400) return 3;
  if (width >= 900) return 2;
  return 1;
}

double contentHorizontalPadding(double width) {
  if (width >= 1200) return 32;
  if (width >= 600) return 24;
  return 16;
}

/// Renders loading / error placeholders for a section while its dedicated
/// API request is still in-flight. On success it defers to [builder], which is
/// expected to return its own fully-styled [ContentSectionCard].
class ContentSectionAsync<T> extends StatelessWidget {
  const ContentSectionAsync({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.builder,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => ContentSectionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        child: const _SectionLoading(),
      ),
      error: (error, _) => ContentSectionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        child: _SectionError(
          message: error is DioException
              ? parseApiError(error)
              : 'Failed to load. Please try again.',
          onRetry: onRetry,
        ),
      ),
      data: (data) => builder(context, data),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppConstants.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
