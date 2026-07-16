import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class IslamicEventsSection extends StatelessWidget {
  const IslamicEventsSection({super.key, required this.events});

  final IslamicEventsResponse events;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: 'Islamic Events',
      subtitle: '${events.count} upcoming events',
      icon: Icons.event_rounded,
      child: events.events.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No events available.',
                    style: TextStyle(color: Colors.white54)),
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
                  itemCount: events.events.length,
                  itemBuilder: (context, index) {
                    return _EventCard(event: events.events[index]);
                  },
                );
              },
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final IslamicEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.isToday
              ? AppConstants.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (event.isToday) const ContentMetaChip(label: 'Today'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.arabicName,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppConstants.primary,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            event.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentMetaChip(label: event.hijriDate),
              ContentMetaChip(label: event.gregorianDate),
              ContentMetaChip(
                label: event.daysRemaining == 0
                    ? 'Today'
                    : '${event.daysRemaining} days left',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
