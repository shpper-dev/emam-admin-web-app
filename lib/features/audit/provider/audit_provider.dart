import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/audit/models/audit_entry.dart';
import 'package:emam_admin_web_app/features/audit/provider/audit_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kAuditPageSize = 50;

class AuditPageState {
  const AuditPageState({
    required this.pages,
    required this.currentPage,
    required this.isLoading,
    required this.errorMessage,
    required this.actionFilter,
  });

  /// Loaded pages in order (index 0 = page 1).
  final List<AuditResponse> pages;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;

  /// Server-side `action` filter, or null for all actions.
  final String? actionFilter;

  static const AuditPageState initial = AuditPageState(
    pages: [],
    currentPage: 1,
    isLoading: true,
    errorMessage: null,
    actionFilter: null,
  );

  int get discoveredPages => pages.length;

  AuditResponse? get currentResponse =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
      ? null
      : pages[currentPage - 1];

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  AuditPageState copyWith({
    List<AuditResponse>? pages,
    int? currentPage,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? actionFilter = _sentinel,
  }) {
    return AuditPageState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      actionFilter: identical(actionFilter, _sentinel)
          ? this.actionFilter
          : actionFilter as String?,
    );
  }
}

const Object _sentinel = Object();

class AuditNotifier extends Notifier<AuditPageState> {
  @override
  AuditPageState build() {
    Future.microtask(_loadFirstPage);
    return AuditPageState.initial;
  }

  Future<void> refresh() async {
    state = AuditPageState.initial.copyWith(actionFilter: state.actionFilter);
    await _loadFirstPage();
  }

  Future<void> setActionFilter(String? action) async {
    state = AuditPageState.initial.copyWith(actionFilter: action);
    await _loadFirstPage();
  }

  /// Cached pages switch instantly; the first undiscovered page is fetched
  /// with the previous page's `next_page_token`.
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

  Future<void> _loadFirstPage() => _fetch(pageToken: null, replace: true);

  Future<void> _fetch({
    required String? pageToken,
    required bool replace,
  }) async {
    final filter = state.actionFilter;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await ref
          .read(auditRepositoryProvider)
          .fetchAudit(
            pageToken: pageToken,
            limit: kAuditPageSize,
            action: filter,
          );
      // Ignore results that arrived after the filter changed.
      if (filter != state.actionFilter) return;
      final pages = replace
          ? <AuditResponse>[resp]
          : <AuditResponse>[...state.pages, resp];
      state = state.copyWith(
        pages: pages,
        currentPage: pages.length,
        isLoading: false,
      );
    } on DioException catch (e) {
      if (filter != state.actionFilter) return;
      state = state.copyWith(isLoading: false, errorMessage: parseApiError(e));
    } catch (_) {
      if (filter != state.actionFilter) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load the audit log. Please try again.',
      );
    }
  }
}

final auditProvider = NotifierProvider<AuditNotifier, AuditPageState>(
  AuditNotifier.new,
);
