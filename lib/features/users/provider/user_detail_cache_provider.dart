import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserDetailCacheEntry {
  const UserDetailCacheEntry({
    this.detail,
    this.postPages = const [],
    this.isLoading = false,
    this.isLoadingMorePosts = false,
    this.errorMessage,
  });

  final UserDetailResponse? detail;
  final List<UserRecentPostsPage> postPages;
  final bool isLoading;
  final bool isLoadingMorePosts;
  final String? errorMessage;

  bool get hasDetail => detail != null;

  bool get hasNextPostToken =>
      postPages.isNotEmpty && (postPages.last.nextPageToken ?? '').isNotEmpty;

  UserDetailCacheEntry copyWith({
    UserDetailResponse? detail,
    List<UserRecentPostsPage>? postPages,
    bool? isLoading,
    bool? isLoadingMorePosts,
    Object? errorMessage = _sentinel,
  }) {
    return UserDetailCacheEntry(
      detail: detail ?? this.detail,
      postPages: postPages ?? this.postPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

class UserDetailCacheState {
  const UserDetailCacheState({this.entries = const {}});

  final Map<String, UserDetailCacheEntry> entries;

  UserDetailCacheEntry entryFor(String userId) =>
      entries[userId] ?? const UserDetailCacheEntry();

  UserDetailCacheState copyWith({
    Map<String, UserDetailCacheEntry>? entries,
  }) {
    return UserDetailCacheState(entries: entries ?? this.entries);
  }
}

class UserDetailCacheNotifier extends Notifier<UserDetailCacheState> {
  final Map<String, Future<void>> _inFlight = {};

  @override
  UserDetailCacheState build() => const UserDetailCacheState();

  void clear() {
    _inFlight.clear();
    state = const UserDetailCacheState();
  }

  /// Fetches detail for [userId] if not already cached. Reuses in-flight requests.
  Future<void> ensureLoaded(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return Future.value();
    final entry = state.entryFor(id);
    if (entry.hasDetail) return Future.value();
    return _loadDetail(id);
  }

  Future<void> retry(String userId) => _fetchDetail(userId.trim());

  Future<void> fetchNextPostPage(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return;

    final entry = state.entryFor(id);
    if (!entry.hasDetail || !entry.hasNextPostToken || entry.isLoadingMorePosts) {
      return;
    }

    final token = entry.postPages.last.nextPageToken;
    _patch(id, entry.copyWith(isLoadingMorePosts: true, errorMessage: null));

    try {
      final repo = ref.read(usersRepositoryProvider);
      final response = await repo.fetchUserDetail(
        id,
        pageToken: token,
        limit: kUserDetailPostsPageSize,
      );
      final current = state.entryFor(id);
      _patch(
        id,
        current.copyWith(
          isLoadingMorePosts: false,
          postPages: [...current.postPages, response.recentPosts],
        ),
      );
    } on DioException catch (e) {
      final current = state.entryFor(id);
      _patch(
        id,
        current.copyWith(
          isLoadingMorePosts: false,
          errorMessage: parseApiError(e),
        ),
      );
    } catch (_) {
      final current = state.entryFor(id);
      _patch(
        id,
        current.copyWith(
          isLoadingMorePosts: false,
          errorMessage: 'Failed to load more posts. Please try again.',
        ),
      );
    }
  }

  Future<void> _loadDetail(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return Future.value();

    final entry = state.entryFor(id);
    if (entry.hasDetail) return Future.value();
    final existing = _inFlight[id];
    if (existing != null) return existing;

    final future = _fetchDetail(id);
    _inFlight[id] = future;
    return future.whenComplete(() => _inFlight.remove(id));
  }

  Future<void> _fetchDetail(String userId) async {
    final existing = state.entryFor(userId);
    if (!existing.hasDetail) {
      _patch(
        userId,
        existing.copyWith(isLoading: true, errorMessage: null),
      );
    }

    try {
      final repo = ref.read(usersRepositoryProvider);
      final detail = await repo.fetchUserDetail(
        userId,
        limit: kUserDetailPostsPageSize,
      );
      _patch(
        userId,
        UserDetailCacheEntry(
          detail: detail,
          postPages: [detail.recentPosts],
          isLoading: false,
        ),
      );
    } on DioException catch (e) {
      _patch(
        userId,
        state.entryFor(userId).copyWith(
              isLoading: false,
              errorMessage: parseApiError(e),
            ),
      );
    } catch (_) {
      _patch(
        userId,
        state.entryFor(userId).copyWith(
              isLoading: false,
              errorMessage: 'Failed to load user details. Please try again.',
            ),
      );
    }
  }

  void _patch(String userId, UserDetailCacheEntry entry) {
    state = state.copyWith(
      entries: {...state.entries, userId: entry},
    );
  }
}

final userDetailCacheProvider =
    NotifierProvider<UserDetailCacheNotifier, UserDetailCacheState>(
  UserDetailCacheNotifier.new,
);
