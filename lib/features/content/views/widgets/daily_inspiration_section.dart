import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';

class DailyInspirationSection extends StatelessWidget {
  const DailyInspirationSection({super.key, required this.inspiration});

  final DailyInspiration inspiration;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: 'Daily Inspiration',
      subtitle: 'Source: ${inspiration.source}',
      icon: Icons.auto_awesome_rounded,
      trailing: inspiration.generatedAt.isNotEmpty
          ? ContentMetaChip(label: inspiration.generatedAt.split('T').first)
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final duaCard = _InspirationBlock(
            title: 'Daily Dua',
            english: inspiration.dailyDua.textEn,
            arabic: inspiration.dailyDua.textAr,
            footer: inspiration.dailyDua.source,
          );
          final ayahCard = _InspirationBlock(
            title: 'Ayah of the Day',
            english: inspiration.ayahOfTheDay.textEn,
            arabic: inspiration.ayahOfTheDay.textAr,
            footer: inspiration.ayahOfTheDay.surahInfo,
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: duaCard),
                const SizedBox(width: 16),
                Expanded(child: ayahCard),
              ],
            );
          }

          return Column(
            children: [
              duaCard,
              const SizedBox(height: 16),
              ayahCard,
            ],
          );
        },
      ),
    );
  }
}

class _InspirationBlock extends StatelessWidget {
  const _InspirationBlock({
    required this.title,
    required this.english,
    required this.arabic,
    required this.footer,
  });

  final String title;
  final String english;
  final String arabic;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.8,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            english,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          ContentMetaChip(label: footer),
        ],
      ),
    );
  }
}
