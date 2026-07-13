import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';

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
                child: Text('No scholarly insights available.',
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = contentGridColumns(constraints.maxWidth);
                if (columns == 1) {
                  return Column(
                    children: [
                      for (var i = 0; i < insights.insights.length; i++) ...[
                        _InsightCard(insight: insights.insights[i]),
                        if (i < insights.insights.length - 1)
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
                    childAspectRatio: columns >= 3 ? 0.9 : 1.0,
                  ),
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
          if (insight.thumbnailUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                insight.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppConstants.inputFillColor,
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_outline, color: Colors.white38),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ContentMetaChip(label: insight.type),
                    ContentMetaChip(label: insight.author),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  insight.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                if (insight.externalLink.isNotEmpty)
                  SelectableText(
                    insight.externalLink,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                if (insight.audioUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    insight.audioUrl,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
