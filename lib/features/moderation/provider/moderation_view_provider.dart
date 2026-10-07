import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sub-views of the dashboard's Moderation section.
enum ModerationView { needsReview, reports, hidden }

class ModerationViewNotifier extends Notifier<ModerationView> {
  @override
  ModerationView build() => ModerationView.needsReview;

  void select(ModerationView view) => state = view;
}

final moderationViewProvider =
    NotifierProvider<ModerationViewNotifier, ModerationView>(
      ModerationViewNotifier.new,
    );
