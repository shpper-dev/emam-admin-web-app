import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kReportedDuasPageSize = 50;

/// Report statuses the backend accepts as the `status` filter.
const Map<String, String> kReportStatusFilters = {
  'open': 'Open',
  'dismissed': 'Dismissed',
  'action_taken': 'Action taken',
};

class ReportedDuasState {
  const ReportedDuasState({
    required this.pages,
    required this.currentPage,
    required this.status,
    required this.hiddenPostIds,
    required this.restoredPostIds,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<ModerationReportsResponse> pages;
  final int currentPage;
  final String status;
  final Set<String> hiddenPostIds;

  /// Posts restored this session; overrides stale hidden flags in report payloads.
  final Set<String> restoredPostIds;
  final bool isLoading;
  final String? errorMessage;

  static const ReportedDuasState initial = ReportedDuasState(
    pages: [],
    currentPage: 1,
    status: 'open',
    hiddenPostIds: {},
    restoredPostIds: {},
    isLoading: true,
    errorMessage: null,
  );

  int get discoveredPages => pages.length;

  /// Reports on the page being shown.
  List<ModerationReport> get reports =>
      pages.isEmpty || currentPage < 1 || currentPage > pages.length
      ? const []
      : pages[currentPage - 1].reports;

  bool get hasNextToken =>
      pages.isNotEmpty && (pages.last.nextPageToken ?? '').isNotEmpty;

  ReportedDuasState copyWith({
    List<ModerationReportsResponse>? pages,
    int? currentPage,
    String? status,
    Set<String>? hiddenPostIds,
    Set<String>? restoredPostIds,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return ReportedDuasState(
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      restoredPostIds: restoredPostIds ?? this.restoredPostIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();

class ReportedDuasNotifier extends Notifier<ReportedDuasState> {
  @override
  ReportedDuasState build() {
    Future.microtask(_loadFirstPage);
    return ReportedDuasState.initial;
  }

  /// Reloads from the first page, keeping the selected status filter.
  Future<void> refresh() async {
    state = ReportedDuasState.initial.copyWith(
      status: state.status,
      hiddenPostIds: state.hiddenPostIds,
      restoredPostIds: state.restoredPostIds,
    );
    // Hidden ids are kept up to date by markPostHidden/markPostRestored, so
    // skip the slow full hidden-posts crawl and only reload the reports.
    await _fetch(pageToken: null, replace: true);
  }

  /// Flips the card to "hidden"/"restored" immediately, before any refetch.
  void markPostRestored(String postId) {
    state = state.copyWith(
      hiddenPostIds: {...state.hiddenPostIds}..remove(postId),
      restoredPostIds: {...state.restoredPostIds, postId},
    );
  }

  void markPostHidden(String postId) {
    state = state.copyWith(
      hiddenPostIds: {...state.hiddenPostIds, postId},
      restoredPostIds: {...state.restoredPostIds}..remove(postId),
    );
  }

  Future<void> setStatus(String status) async {
    if (status == state.status) return;
    state = state.copyWith(
      status: status,
      pages: const [],
      currentPage: 1,
      errorMessage: null,
    );
    await _fetch(pageToken: null, replace: true);
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

  /// Resolves every loaded open report for [postId]. Returns false on failure.
  Future<bool> resolveOpenReportsForPost(
    String postId, {
    required String action,
  }) async {
    final repo = ref.read(moderationRepositoryProvider);
    final reportIds = state.pages
        .expand((page) => page.reports)
        .where((r) => r.postId == postId && r.isOpen && r.id.isNotEmpty)
        .map((r) => r.id)
        .toList();
    try {
      for (final id in reportIds) {
        await repo.resolveReport(id, action: action);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadFirstPage() async {
    final repo = ref.read(moderationRepositoryProvider);
    var hiddenPostIds = <String>{};
    try {
      hiddenPostIds = await repo.fetchAllHiddenPostIds();
    } catch (_) {
      // Reports still render; hide/restore uses report payload fields as fallback.
    }
    state = state.copyWith(hiddenPostIds: hiddenPostIds);
    await _fetch(pageToken: null, replace: true);
  }

  Future<void> _fetch({
    required String? pageToken,
    required bool replace,
  }) async {
    final status = state.status;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(moderationRepositoryProvider);
      final response = await repo.fetchReports(
        status: status,
        pageToken: pageToken,
        limit: kReportedDuasPageSize,
      );
      // The filter changed while this request was in flight; drop the stale page.
      if (status != state.status) return;
      final pages = replace
          ? <ModerationReportsResponse>[response]
          : <ModerationReportsResponse>[...state.pages, response];
      state = state.copyWith(
        pages: pages,
        currentPage: pages.length,
        isLoading: false,
      );
    } on DioException catch (e) {
      if (status != state.status) return;
      state = state.copyWith(isLoading: false, errorMessage: parseApiError(e));
    } catch (_) {
      if (status != state.status) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load reported duas. Please try again.',
      );
    }
  }
}

final reportedDuasProvider =
    NotifierProvider<ReportedDuasNotifier, ReportedDuasState>(
      ReportedDuasNotifier.new,
    );
