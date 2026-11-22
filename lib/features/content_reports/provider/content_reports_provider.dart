import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/content_reports/models/content_report.dart';
import 'package:emam_admin_web_app/features/content_reports/provider/content_reports_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kContentReportsPageSize = 50;

const Object _sentinel = Object();

class ContentReportsState {
  const ContentReportsState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
    required this.status,
    required this.contentType,
    required this.query,
  });

  final List<ContentReportsResponse> pages;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;
  final String? status;
  final String? contentType;
  final String query;

  static const ContentReportsState initial = ContentReportsState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
    status: null,
    contentType: null,
    query: '',
  );

  int get discoveredPages => pages.length;

  ContentReportsResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
      ? null
      : pages[currentPage - 1];

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  /// Open-queue count reported by the backend (first page only).
  int? get newCount => pages.isEmpty ? null : pages.first.newCount;

  ContentReportsState copyWith({
    List<ContentReportsResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? status = _sentinel,
    Object? contentType = _sentinel,
    String? query,
  }) {
    return ContentReportsState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      status: identical(status, _sentinel) ? this.status : status as String?,
      contentType: identical(contentType, _sentinel)
          ? this.contentType
          : contentType as String?,
      query: query ?? this.query,
    );
  }
}

class ContentReportsNotifier extends Notifier<ContentReportsState> {
  @override
  ContentReportsState build() {
    Future.microtask(_loadFirstPage);
    return ContentReportsState.initial;
  }

  Future<void> refresh() => _reset(state);

  Future<void> setFilters({
    Object? status = _sentinel,
    Object? contentType = _sentinel,
    String? query,
  }) {
    final next = ContentReportsState.initial.copyWith(
      status: identical(status, _sentinel) ? state.status : status,
      contentType: identical(contentType, _sentinel)
          ? state.contentType
          : contentType,
      query: query ?? state.query,
    );
    return _reset(next);
  }

  Future<void> setStatus(String? status) => setFilters(status: status);
  Future<void> setContentType(String? type) => setFilters(contentType: type);
  Future<void> setQuery(String query) => setFilters(query: query.trim());

  Future<void> _reset(ContentReportsState from) {
    state = ContentReportsState.initial.copyWith(
      status: from.status,
      contentType: from.contentType,
      query: from.query,
    );
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

  /// Saves an editor update and swaps the returned report into the cached page.
  Future<ContentReport> update(
    String id, {
    String? status,
    String? editorNote,
    String? duplicateOfReportId,
  }) async {
    final updated = await ref
        .read(contentReportsRepositoryProvider)
        .update(
          id,
          status: status,
          editorNote: editorNote,
          duplicateOfReportId: duplicateOfReportId,
        );
    final pages = [
      for (final p in state.pages)
        ContentReportsResponse(
          reports: [for (final r in p.reports) r.id == id ? updated : r],
          nextPageToken: p.nextPageToken,
          newCount: p.newCount,
        ),
    ];
    state = state.copyWith(pages: pages);
    // Status changes shift queue counts and filter membership.
    if (status != null) await refresh();
    return updated;
  }

  Future<void> _loadFirstPage() => _fetch(pageToken: null, replace: true);

  bool _stale(ContentReportsState s) =>
      s.status != state.status ||
      s.contentType != state.contentType ||
      s.query != state.query;

  Future<void> _fetch({
    required String? pageToken,
    required bool replace,
  }) async {
    final snapshot = state;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await ref
          .read(contentReportsRepositoryProvider)
          .fetch(
            pageToken: pageToken,
            limit: kContentReportsPageSize,
            status: snapshot.status,
            contentType: snapshot.contentType,
            query: snapshot.query,
          );
      if (_stale(snapshot)) return;
      final pages = replace
          ? <ContentReportsResponse>[resp]
          : <ContentReportsResponse>[...state.pages, resp];
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
        errorMessage: 'Failed to load reports. Please try again.',
      );
    }
  }
}

final contentReportsProvider =
    NotifierProvider<ContentReportsNotifier, ContentReportsState>(
      ContentReportsNotifier.new,
    );
