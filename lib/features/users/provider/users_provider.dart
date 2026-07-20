import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many users to request per page.
const int kUsersPageSize = 50;

/// Immutable snapshot of the users pagination state.
class UsersPageState {
  const UsersPageState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
  });

  /// Loaded pages in order (index 0 = page 1). Every page except possibly the
  /// last one is guaranteed to be full.
  final List<UsersResponse> pages;

  /// 1-based index of the page currently displayed.
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;

  static const UsersPageState initial = UsersPageState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
  );

  int get discoveredPages => pages.length;

  UsersResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
          ? null
          : pages[currentPage - 1];

  /// True when the last discovered page reports a `next_page_token`, i.e. the
  /// server says there is at least one more page we haven't fetched yet.
  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  UsersPageState copyWith({
    List<UsersResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return UsersPageState(
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

class UsersPaginationNotifier extends Notifier<UsersPageState> {
  @override
  UsersPageState build() {
    Future.microtask(_loadFirstPage);
    return UsersPageState.initial;
  }

  Future<void> refresh() async {
    ref.read(userDetailCacheProvider.notifier).clear();
    state = UsersPageState.initial;
    await _loadFirstPage();
  }

  /// Navigate to [page]. Cached pages switch instantly; the first
  /// undiscovered page is fetched using the previous page's `next_page_token`.
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

  Future<void> _fetch({required String? pageToken, required bool replace}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(usersRepositoryProvider);
      final resp = await repo.fetchUsers(
        pageToken: pageToken,
        limit: kUsersPageSize,
      );
      final pages = replace
          ? <UsersResponse>[resp]
          : (<UsersResponse>[...state.pages, resp]);
      state = state.copyWith(
        pages: pages,
        currentPage: pages.length,
        isLoading: false,
      );
      ref.read(userDetailCacheProvider.notifier).schedulePrefetch(
            resp.users.map((user) => user.id),
          );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: parseApiError(e),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load users. Please try again.',
      );
    }
  }
}

final usersPaginationProvider =
    NotifierProvider<UsersPaginationNotifier, UsersPageState>(
  UsersPaginationNotifier.new,
);
