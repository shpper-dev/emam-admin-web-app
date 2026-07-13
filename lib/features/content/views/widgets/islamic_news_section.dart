import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';

class IslamicNewsSection extends StatelessWidget {
  const IslamicNewsSection({super.key, required this.news});

  final IslamicNewsResponse news;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: 'Islamic News',
      subtitle: '${news.newsFeed.length} articles · Source: ${news.source}',
      icon: Icons.newspaper_rounded,
      trailing: news.generatedAt.isNotEmpty
          ? ContentMetaChip(label: _formatGeneratedAt(news.generatedAt))
          : null,
      child: news.newsFeed.isEmpty
          ? const _EmptyState(message: 'No news articles available.')
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = contentGridColumns(constraints.maxWidth);
                if (columns == 1) {
                  return Column(
                    children: [
                      for (var i = 0; i < news.newsFeed.length; i++) ...[
                        _NewsCard(item: news.newsFeed[i]),
                        if (i < news.newsFeed.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns >= 3 ? 0.95 : 1.05,
                  ),
                  itemCount: news.newsFeed.length,
                  itemBuilder: (context, index) {
                    return _NewsCard(item: news.newsFeed[index]);
                  },
                );
              },
            ),
    );
  }

  String _formatGeneratedAt(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return 'Updated ${parsed.toLocal().toString().split('.').first}';
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final IslamicNewsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppConstants.inputFillColor,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.white38),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContentMetaChip(label: item.category),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.publishedAt,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  item.sourceUrl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white54),
        ),
      ),
    );
  }
}
