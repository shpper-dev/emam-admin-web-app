import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';

enum CacheDomain {
  duaBoard('dua_board', 'Dua board'),
  duaRag('dua_rag', 'Dua RAG'),
  quranReader('quran_reader', 'Quran reader');

  const CacheDomain(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class SystemToolsRepository {
  SystemToolsRepository(this._client);

  final DioClient _client;

  /// Returns the backend's message, if it sent one.
  Future<String?> invalidateCache(CacheDomain domain) async {
    final response = await _client.post<Object>(
      ApiConstants.cacheInvalidate,
      data: {'domain': domain.apiValue},
    );
    return _message(response.data);
  }

  /// Returns a one-line summary of the reloaded index.
  Future<String> reloadRag() async {
    final response = await _client.post<Object>(ApiConstants.ragReload);
    final data = response.data;
    final message = _message(data) ?? 'Dua RAG index reloaded.';
    if (data is Map && data['chunk_count'] != null) {
      return '$message (${data['chunk_count']} chunks loaded)';
    }
    return message;
  }

  static String? _message(Object? data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
