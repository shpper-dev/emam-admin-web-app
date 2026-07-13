import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';

class PracticeCardSection extends StatelessWidget {
  const PracticeCardSection({super.key, required this.card});

  final PracticeCard card;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: 'Practice Card',
      subtitle:
          '${card.surahName} ${card.surahNumber}:${card.verseNumber} · ${card.dateDubai}',
      icon: Icons.menu_book_rounded,
      trailing: card.isRecommended
          ? const ContentMetaChip(label: 'Recommended')
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'ID', value: card.id),
              _InfoRow(label: 'Source', value: card.source),
              if (card.generatedAt.isNotEmpty)
                _InfoRow(label: 'Generated', value: card.generatedAt),
              const SizedBox(height: 16),
              Text(
                'Focus Topic',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppConstants.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                card.focusTopic,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              if (card.audioSampleUrl.isNotEmpty)
                SelectableText(
                  card.audioSampleUrl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
            ],
          );

          final arabic = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              card.arabicText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.8,
                    fontSize: 26,
                  ),
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: arabic),
                const SizedBox(width: 20),
                Expanded(child: details),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              arabic,
              const SizedBox(height: 20),
              details,
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
