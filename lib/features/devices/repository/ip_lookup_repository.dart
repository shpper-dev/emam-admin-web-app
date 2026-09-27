import 'package:dio/dio.dart';

/// Looks up this browser's own public IP address via a small, CORS-friendly
/// public API. The `pathway.emam.ai` backend has no session/device tracking
/// endpoint yet, so this is the only source available client-side — this
/// repository never talks to the admin backend.
class IpLookupRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  Future<String> fetchPublicIp() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.ipify.org',
      queryParameters: const {'format': 'json'},
    );
    final ip = response.data?['ip'] as String?;
    if (ip == null || ip.isEmpty) {
      throw Exception('IP address unavailable');
    }
    return ip;
  }
}
