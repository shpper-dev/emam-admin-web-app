import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_provider.dart';
import 'package:emam_admin_web_app/features/cms/provider/cms_repository_provider.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/cms_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _locales = {'en': 'English', 'bn': 'Bangla'};

class ArticlesTab extends ConsumerWidget {
  const ArticlesTab({super.key, required this.staff});
  final StaffSession staff;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    CmsArticle? a,
  ]) async {
    final slug = TextEditingController(text: a?.slug ?? '');
    final type = TextEditingController(text: a?.contentType ?? 'guide');
    final hero = TextEditingController(text: a?.heroImageUrl ?? '');
    final fields = {
      for (final l in _locales.keys)
        l: {
          for (final k in ['title', 'summary', 'body'])
            k: TextEditingController(
              text: (a?.locales[l]?[k] as String?) ?? '',
            ),
        },
    };
    Map<String, dynamic>? body;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CmsFormDialog(
        title: a == null ? 'New article' : 'Edit article',
        icon: Icons.article_rounded,
        width: 680,
        fields: [
          cmsField(
            slug,
            'Slug (a-z, 0-9, hyphens)',
            maxLength: CmsLimits.slugMax,
            enabled: a == null,
          ),
          cmsField(type, 'Content type', maxLength: 32),
          cmsField(hero, 'Hero image URL (https)', maxLength: 500),
          for (final l in _locales.entries) ...[
            Text(l.value, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppConstants.space8),
            cmsField(
              fields[l.key]!['title']!,
              'Title',
              maxLength: CmsLimits.titleMax,
            ),
            cmsField(
              fields[l.key]!['summary']!,
              'Summary',
              maxLength: CmsLimits.summaryMax,
              maxLines: 3,
            ),
            cmsField(
              fields[l.key]!['body']!,
              'Body (shown as plain text)',
              maxLength: CmsLimits.bodyMax,
              maxLines: 10,
            ),
          ],
        ],
        validate: () {
          final s = slug.text.trim();
          if (a == null && (s.isEmpty || !CmsLimits.slug.hasMatch(s))) {
            return 'Slug must be lowercase letters, digits and single hyphens.';
          }
          if (!CmsLimits.contentType.hasMatch(type.text.trim())) {
            return 'Content type must be lowercase letters or underscores.';
          }
          final h = hero.text.trim();
          if (h.isNotEmpty && !CmsLimits.validHttpsUrl(h)) {
            return 'Hero image must be an https:// URL.';
          }
          // Keep any locales we don't edit; only replace the ones we show.
          final locales = <String, dynamic>{...?a?.locales};
          for (final l in _locales.keys) {
            final f = fields[l]!;
            final t = f['title']!.text.trim();
            final sm = f['summary']!.text.trim();
            final b = f['body']!.text.trim();
            if (t.isEmpty && sm.isEmpty && b.isEmpty) {
              if (l == 'en') return 'English title and body are required.';
              locales.remove(l);
              continue;
            }
            if (t.isEmpty || b.isEmpty) {
              return '${_locales[l]} needs both a title and a body.';
            }
            locales[l] = {'title': t, 'summary': sm, 'body': b};
          }
          body = {
            if (a == null) 'slug': s,
            'content_type': type.text.trim(),
            'locales': locales,
            'hero_image_url': h,
          };
          return null;
        },
        save: () {
          final repo = ref.read(cmsRepositoryProvider);
          return a == null
              ? repo.createArticle(body!)
              : repo.patchArticle(a.id, body!);
        },
      ),
    );
    slug.dispose();
    type.dispose();
    hero.dispose();
    for (final m in fields.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    if (saved == true) ref.invalidate(articlesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final articles = ref.watch(articlesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (staff.canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space16),
            child: FilledButton.icon(
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New article'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primary,
                foregroundColor: AppConstants.black,
              ),
            ),
          ),
        articles.when(
          loading: () => const SkeletonList(rows: 3, rowHeight: 80),
          error: (e, _) => InlineRetryError(
            message: e is DioException
                ? parseApiError(e)
                : 'Could not load articles.',
            onRetry: () => ref.invalidate(articlesProvider),
          ),
          data: (list) => list.isEmpty
              ? const SectionEmptyMessage('No articles yet.')
              : Column(
                  children: [
                    for (final a in list)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.space12,
                        ),
                        padding: const EdgeInsets.all(AppConstants.space16),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(color: AppConstants.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: AppConstants.space12),
                                statusBadge(a.status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${a.slug} · ${a.contentType} · '
                              '${a.locales.keys.join(', ')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppConstants.textMuted,
                              ),
                            ),
                            if (a.reviewNote.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.space8),
                              Text(
                                'Review note: ${a.reviewNote}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.warning,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.space12),
                            EntryActions(
                              staff: staff,
                              status: a.status,
                              onEdit: () => _edit(context, ref, a),
                              onAction: (act) => runWorkflow(
                                context,
                                action: act,
                                subject: a.title,
                                call: (note) => ref
                                    .read(cmsRepositoryProvider)
                                    .articleAction(a.id, act, reviewNote: note),
                                onDone: () => ref.invalidate(articlesProvider),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
