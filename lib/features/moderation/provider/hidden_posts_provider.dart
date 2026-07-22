import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kHiddenPostsPageSize = 50;

class HiddenPostsPageState {
  const HiddenPostsPageState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<HiddenPostsResponse> pages;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;

  static const HiddenPostsPageState initial = HiddenPostsPageState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
  );

  int get discoveredPages => pages.length;

  HiddenPostsResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
          ? null
          : pages[currentPage - 1];

  int get totalLoadedPosts =>
      pages.fold<int>(0, (sum, page) => sum + page.posts.length);

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  HiddenPostsPageState copyWith({
    List<HiddenPostsResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return HiddenPostsPageState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

class HiddenPostsPaginationNotifier extends Notifier<HiddenPostsPageState> {
  @override
  HiddenPostsPageState build() {
    Future.microtask(_loadFirstPage);
    return HiddenPostsPageState.initial;
  }

  Future<void> refresh() async {
    state = HiddenPostsPageState.initial;
    await _loadFirstPage();
  }

  Future<void> goToPage(int page) async {
    if (page < 1) return;
    if (page <= state.pages.length) {
      if (page != state.currentPage) {
        state = state.copyWith(currentPage: page, errorMessage: null);
      }
      return;
    }
    if (page == state.pages.length + 1 && state.hasNextToken) {
      await _fetchNextPage();
    }
  }

  Future<void> _loadFirstPage() => _fetch(pageToken: null, replace: true);

  Future<void> _fetchNextPage() {
    final token = state.pages.last.nextPageToken;
    return _fetch(pageToken: token, replace: false);
  }

  Future<void> _fetch({
    required String? pageToken,
    required bool replace,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(moderationRepositoryProvider);
      final resp = await repo.fetchHiddenPosts(
        pageToken: pageToken,
        limit: kHiddenPostsPageSize,
      );
      final pages = replace
          ? <HiddenPostsResponse>[resp]
          : (<HiddenPostsResponse>[...state.pages, resp]);
      state = state.copyWith(
        pages: pages,
        currentPage: pages.length,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load hidden posts. Please try again.',
      );
    }
  }
}

final hiddenPostsPaginationProvider = NotifierProvider<
    HiddenPostsPaginationNotifier, HiddenPostsPageState>(
  HiddenPostsPaginationNotifier.new,
);

/// Post IDs from every loaded hidden-posts page (for reported-dua cards).
final hiddenPostIdsProvider = Provider<Set<String>>((ref) {
  final pages = ref.watch(hiddenPostsPaginationProvider).pages;
  final ids = <String>{};
  for (final page in pages) {
    for (final post in page.posts) {
      if (post.id.isNotEmpty) ids.add(post.id);
    }
  }
  return ids;
});
