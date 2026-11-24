import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/reciter_requests/models/reciter_request.dart';
import 'package:emam_admin_web_app/features/reciter_requests/provider/reciter_requests_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kReciterRequestsPageSize = 50;

const Object _sentinel = Object();

class ReciterRequestsState {
  const ReciterRequestsState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
    required this.status,
    required this.query,
  });

  final List<ReciterRequestsResponse> pages;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;
  final String? status;
  final String query;

  static const ReciterRequestsState initial = ReciterRequestsState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
    status: null,
    query: '',
  );

  int get discoveredPages => pages.length;

  ReciterRequestsResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
      ? null
      : pages[currentPage - 1];

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  int? get newCount => pages.isEmpty ? null : pages.first.newCount;

  ReciterRequestsState copyWith({
    List<ReciterRequestsResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? status = _sentinel,
    String? query,
  }) {
    return ReciterRequestsState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      status: identical(status, _sentinel) ? this.status : status as String?,
      query: query ?? this.query,
    );
  }
}

class ReciterRequestsNotifier extends Notifier<ReciterRequestsState> {
  @override
  ReciterRequestsState build() {
    Future.microtask(_loadFirstPage);
    return ReciterRequestsState.initial;
  }

  Future<void> refresh() => _reset(state.status, state.query);

  Future<void> setStatus(String? status) => _reset(status, state.query);

  Future<void> setQuery(String query) => _reset(state.status, query.trim());

  Future<void> clearFilters() => _reset(null, '');

  Future<void> _reset(String? status, String query) {
    state = ReciterRequestsState.initial.copyWith(status: status, query: query);
    return _loadFirstPage();
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
      await _fetch(pageToken: state.pages.last.nextPageToken, replace: false);
    }
  }

  Future<ReciterRequest> loadDetail(String id) =>
      ref.read(reciterRequestsRepositoryProvider).detail(id);

  Future<ReciterRequest> update(
    String id, {
    String? status,
    String? editorNote,
  }) async {
    final updated = await ref
        .read(reciterRequestsRepositoryProvider)
        .update(id, status: status, editorNote: editorNote);
    // Status changes shift queue counts and filter membership.
    if (status != null) {
      await refresh();
    } else {
      state = state.copyWith(
        pages: [
          for (final p in state.pages)
            ReciterRequestsResponse(
              items: [for (final r in p.items) r.id == id ? updated : r],
              nextPageToken: p.nextPageToken,
              newCount: p.newCount,
            ),
        ],
      );
    }
    return updated;
  }

  Future<void> _loadFirstPage() => _fetch(pageToken: null, replace: true);

  bool _stale(ReciterRequestsState s) =>
      s.status != state.status || s.query != state.query;

  Future<void> _fetch({
    required String? pageToken,
    required bool replace,
  }) async {
    final snapshot = state;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await ref
          .read(reciterRequestsRepositoryProvider)
          .fetch(
            pageToken: pageToken,
            limit: kReciterRequestsPageSize,
            status: snapshot.status,
            query: snapshot.query,
          );
      if (_stale(snapshot)) return;
      final pages = replace
          ? <ReciterRequestsResponse>[resp]
          : <ReciterRequestsResponse>[...state.pages, resp];
      state = state.copyWith(
        pages: pages,
        currentPage: pages.length,
        isLoading: false,
      );
    } on DioException catch (e) {
      if (_stale(snapshot)) return;
      state = state.copyWith(isLoading: false, errorMessage: parseApiError(e));
    } catch (_) {
      if (_stale(snapshot)) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load requests. Please try again.',
      );
    }
  }
}

final reciterRequestsProvider =
    NotifierProvider<ReciterRequestsNotifier, ReciterRequestsState>(
      ReciterRequestsNotifier.new,
    );
