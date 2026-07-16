import 'package:cached_network_image/cached_network_image.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ScholarlyInsightsSection extends StatelessWidget {
  const ScholarlyInsightsSection({super.key, required this.insights});

  final ScholarlyInsightsResponse insights;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: 'Scholarly Insights',
      subtitle:
          '${insights.insights.length} items · Source: ${insights.source}',
      icon: Icons.podcasts_rounded,
      trailing: insights.generatedAt.isNotEmpty
          ? ContentMetaChip(label: insights.generatedAt.split('T').first)
          : null,
      child: insights.insights.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No scholarly insights available.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = contentGridColumns(constraints.maxWidth);
                return MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  itemCount: insights.insights.length,
                  itemBuilder: (context, index) {
                    return _InsightCard(insight: insights.insights[index]);
                  },
                );
              },
            ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final ScholarlyInsight insight;

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
          if (insight.thumbnailUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: _thumbSize,
                height: _thumbSize,
                child: CachedNetworkImage(
                  imageUrl: proxiedImageUrl(
                    insight.thumbnailUrl,
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
                  errorWidget: (context, url, error) {
                    debugPrint(
                      '[insight-thumb] FAILED url=$url\n'
                      'type=${error.runtimeType}\n'
                      'error=$error',
                    );
                    return Tooltip(
                      message: '$error',
                      child: Container(
                        color: AppConstants.inputFillColor,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    );
                  },
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
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${insight.author}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                // SelectableText(insight.thumbnailUrl),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ContentMetaChip(label: insight.type),
                    if (insight.externalLink.isNotEmpty)
                      ContentLinkButton(
                        label: 'Open link',
                        url: insight.externalLink,
                      ),
                    if (insight.audioUrl.isNotEmpty)
                      ContentLinkButton(
                        label: 'Play audio',
                        url: insight.audioUrl,
                        icon: Icons.play_circle_outline_rounded,
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
