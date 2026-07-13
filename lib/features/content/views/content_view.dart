import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/content/models/content_snapshot.dart';
import 'package:emam_admin_web_app/features/content/provider/content_provider.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/daily_inspiration_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/islamic_events_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/islamic_news_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/practice_card_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/scholarly_insights_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentView extends ConsumerWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(constraints.maxWidth);

        return contentAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.primary),
          ),
          error: (error, _) => _ContentErrorState(
            message: error is DioException
                ? parseApiError(error)
                : 'Failed to load content. Please try again.',
            onRetry: () => ref.read(contentProvider.notifier).refresh(),
          ),
          data: (snapshot) => RefreshIndicator(
            color: AppConstants.primary,
            backgroundColor: AppConstants.surfaceColor,
            onRefresh: () => ref.read(contentProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                32,
              ),
              child: _ContentBody(snapshot: snapshot),
            ),
          ),
        );
      },
    );
  }
}

class _ContentBody extends StatelessWidget {
  const _ContentBody({required this.snapshot});

  final ContentSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppConstants.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Live preview of all published content served to the Emam app.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        DailyInspirationSection(inspiration: snapshot.dailyInspiration),
        const SizedBox(height: 24),
        PracticeCardSection(card: snapshot.practiceCard),
        const SizedBox(height: 24),
        IslamicEventsSection(events: snapshot.islamicEvents),
        const SizedBox(height: 24),
        IslamicNewsSection(news: snapshot.islamicNews),
        const SizedBox(height: 24),
        ScholarlyInsightsSection(insights: snapshot.scholarlyInsights),
      ],
    );
  }
}

class _ContentErrorState extends StatelessWidget {
  const _ContentErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
