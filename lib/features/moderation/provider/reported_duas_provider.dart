import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportedDuasState {
  const ReportedDuasState({
    required this.reports,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<ModerationReport> reports;
  final bool isLoading;
  final String? errorMessage;

  static const ReportedDuasState initial = ReportedDuasState(
    reports: [],
    isLoading: true,
    errorMessage: null,
  );

  ReportedDuasState copyWith({
    List<ModerationReport>? reports,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return ReportedDuasState(
      reports: reports ?? this.reports,
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
    Future.microtask(_load);
    return ReportedDuasState.initial;
  }

  Future<void> refresh() async {
    state = ReportedDuasState.initial;
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(moderationRepositoryProvider);
      final response = await repo.fetchReports();
      state = state.copyWith(
        reports: response.reports,
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
        errorMessage: 'Failed to load reported duas. Please try again.',
      );
    }
  }
}

final reportedDuasProvider =
    NotifierProvider<ReportedDuasNotifier, ReportedDuasState>(
  ReportedDuasNotifier.new,
);
