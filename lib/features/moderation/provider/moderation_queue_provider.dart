import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kModerationQueueLimit = 100;

class ModerationQueueState {
  const ModerationQueueState({
    required this.queue,
    required this.isLoading,
    required this.errorMessage,
  });

  final ModerationQueue? queue;
  final bool isLoading;
  final String? errorMessage;

  static const ModerationQueueState initial = ModerationQueueState(
    queue: null,
    isLoading: true,
    errorMessage: null,
  );
}

class ModerationQueueNotifier extends Notifier<ModerationQueueState> {
  @override
  ModerationQueueState build() {
    Future.microtask(refresh);
    return ModerationQueueState.initial;
  }

  Future<void> refresh() async {
    state = ModerationQueueState(
      queue: state.queue,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final queue = await ref
          .read(moderationRepositoryProvider)
          .fetchQueue(limit: kModerationQueueLimit);
      state = ModerationQueueState(
        queue: queue,
        isLoading: false,
        errorMessage: null,
      );
    } on DioException catch (e) {
      state = ModerationQueueState(
        queue: state.queue,
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    } catch (_) {
      state = ModerationQueueState(
        queue: state.queue,
        isLoading: false,
        errorMessage: 'Failed to load the moderation queue. Please try again.',
      );
    }
  }
}

final moderationQueueProvider =
    NotifierProvider<ModerationQueueNotifier, ModerationQueueState>(
      ModerationQueueNotifier.new,
    );

final postDetailProvider = FutureProvider.autoDispose
    .family<PostDetail, String>((ref, postId) {
      return ref.read(moderationRepositoryProvider).fetchPostDetail(postId);
    });
