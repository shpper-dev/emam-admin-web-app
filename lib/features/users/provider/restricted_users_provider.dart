import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of the restricted-users pagination state.
class RestrictedUsersPageState {
  const RestrictedUsersPageState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<RestrictedUsersResponse> pages;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;

  static const RestrictedUsersPageState initial = RestrictedUsersPageState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
  );

  int get discoveredPages => pages.length;

  RestrictedUsersResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
          ? null
          : pages[currentPage - 1];

  /// Total restricted users from the most recent response (server-side count).
  int? get totalRestricted =>
      pages.isEmpty ? null : pages.last.totalRestricted;

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  RestrictedUsersPageState copyWith({
    List<RestrictedUsersResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return RestrictedUsersPageState(
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

class RestrictedUsersPaginationNotifier
    extends Notifier<RestrictedUsersPageState> {
  @override
  RestrictedUsersPageState build() {
    Future.microtask(_loadFirstPage);
    return RestrictedUsersPageState.initial;
  }

  Future<void> refresh() async {
    state = RestrictedUsersPageState.initial;
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
      final repo = ref.read(usersRepositoryProvider);
      final resp = await repo.fetchRestrictedUsers(
        pageToken: pageToken,
        limit: kUsersPageSize,
      );
      final pages = replace
          ? <RestrictedUsersResponse>[resp]
          : (<RestrictedUsersResponse>[...state.pages, resp]);
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
        errorMessage: 'Failed to load restricted users. Please try again.',
      );
    }
  }
}

final restrictedUsersPaginationProvider = NotifierProvider<
    RestrictedUsersPaginationNotifier, RestrictedUsersPageState>(
  RestrictedUsersPaginationNotifier.new,
);
