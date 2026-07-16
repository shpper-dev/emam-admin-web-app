import 'package:cached_network_image/cached_network_image.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
                return MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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

  static const double _thumbSize = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: _thumbSize,
                height: _thumbSize,
                child: CachedNetworkImage(
                  imageUrl: proxiedImageUrl(
                    item.imageUrl,
                    width: (_thumbSize * 2).toInt(),
                    height: (_thumbSize * 2).toInt(),
                  ),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppConstants.inputFillColor,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primary,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppConstants.inputFillColor,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ContentMetaChip(label: item.category),
                    if (item.sourceUrl.isNotEmpty)
                      ContentLinkButton(
                        label: 'News link',
                        url: item.sourceUrl,
                      ),
                  ],
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
