import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/segmented_control.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_queue_provider.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/queue_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _QueueFilter { all, reports, hidden }

class ModerationQueueSection extends ConsumerStatefulWidget {
  const ModerationQueueSection({super.key});

  @override
  ConsumerState<ModerationQueueSection> createState() =>
      _ModerationQueueSectionState();
}

class _ModerationQueueSectionState
    extends ConsumerState<ModerationQueueSection> {
  _QueueFilter _filter = _QueueFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationQueueProvider);
    final queue = state.queue;
    final notifier = ref.read(moderationQueueProvider.notifier);

    final reports = queue?.items.where((i) => !i.isHiddenPost).length ?? 0;
    final hidden = queue?.items.where((i) => i.isHiddenPost).length ?? 0;

    // Rank is the position in the full server order, even when filtered.
    final ranked = <(int, QueueItem)>[
      for (var i = 0; i < (queue?.items.length ?? 0); i++)
        if (switch (_filter) {
          _QueueFilter.all => true,
          _QueueFilter.reports => !queue!.items[i].isHiddenPost,
          _QueueFilter.hidden => queue!.items[i].isHiddenPost,
        })
          (i + 1, queue!.items[i]),
    ];

    final Widget body;
    if (queue == null && state.isLoading) {
      body = const SectionLoadingIndicator();
    } else if (queue == null && state.errorMessage != null) {
      body = SectionErrorMessage(
        message: state.errorMessage!,
        onRetry: notifier.refresh,
      );
    } else if (queue == null || queue.items.isEmpty) {
      body = const SectionEmptyMessage(
        'All caught up — nothing is waiting for review.',
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedControl<_QueueFilter>(
            selected: _filter,
            onChanged: (value) => setState(() => _filter = value),
            options: [
              SegmentOption(
                value: _QueueFilter.all,
                label: 'All',
                icon: Icons.list_alt_rounded,
                count: '${queue.items.length}',
              ),
              SegmentOption(
                value: _QueueFilter.reports,
                label: 'Open reports',
                icon: Icons.flag_rounded,
                count: '$reports',
                countColor: AppConstants.warning,
              ),
              SegmentOption(
                value: _QueueFilter.hidden,
                label: 'Hidden',
                icon: Icons.visibility_off_rounded,
                count: '$hidden',
                countColor: AppConstants.danger,
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            SectionErrorMessage(
              message: state.errorMessage!,
              onRetry: notifier.refresh,
            ),
          ],
          const SizedBox(height: 16),
          if (ranked.isEmpty)
            const SectionEmptyMessage('Nothing in this filter.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 2 : 1;
                const spacing = 16.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    for (final (rank, item) in ranked)
                      SizedBox(
                        key: ValueKey('${item.kind}-${item.postId}-$rank'),
                        width: width,
                        child: QueueItemCard(item: item, rank: rank),
                      ),
                  ],
                );
              },
            ),
        ],
      );
    }

    return ContentSectionCard(
      title: 'Needs review',
      subtitle: 'Act on each item here, or open its full report history',
      icon: Icons.fact_check_rounded,
      accentColor: AppConstants.warning,
      trailing: state.isLoading && queue != null
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: 'Refresh queue',
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
      child: body,
    );
  }
}
