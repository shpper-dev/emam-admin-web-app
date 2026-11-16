import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/ramadan_settings.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';

enum CmsAction { submit, approve, reject, publish }

class CmsRepository {
  CmsRepository(this._client);

  final DioClient _client;

  List<Map<String, dynamic>> _items(Map<String, dynamic>? data) => [
    if (data?['items'] is List)
      for (final i in data!['items'] as List)
        if (i is Map<String, dynamic>) i,
  ];

  // --- Daily modules ---------------------------------------------------
  Future<List<CmsEntry>> listDaily(CmsModule module) async {
    final r = await _client.get<Map<String, dynamic>>(
      ApiConstants.cmsDaily(module.slug),
      queryParameters: {'limit': 50},
    );
    return _items(r.data).map(CmsEntry.fromJson).toList();
  }

  Future<CmsEntry> createDaily(
    CmsModule module, {
    required String scheduledFor,
    required Map<String, dynamic> payload,
  }) async {
    final r = await _client.post<Map<String, dynamic>>(
      ApiConstants.cmsDaily(module.slug),
      data: {'scheduled_for': scheduledFor, 'payload': payload},
    );
    return CmsEntry.fromJson(r.data ?? {});
  }

  Future<void> patchDaily(
    CmsModule module,
    String id, {
    required String scheduledFor,
    required Map<String, dynamic> payload,
  }) => _client.patch<Object>(
    ApiConstants.cmsDailyEntry(module.slug, id),
    data: {'scheduled_for': scheduledFor, 'payload': payload},
  );

  Future<PublishResult?> dailyAction(
    CmsModule module,
    String id,
    CmsAction action, {
    String? reviewNote,
  }) => _workflow(
    ApiConstants.cmsDailyEntry(module.slug, id),
    action,
    reviewNote,
  );

  // --- Articles --------------------------------------------------------
  Future<List<CmsArticle>> listArticles() async {
    final r = await _client.get<Map<String, dynamic>>(
      ApiConstants.cmsArticles,
      queryParameters: {'limit': 50},
    );
    return _items(r.data).map(CmsArticle.fromJson).toList();
  }

  Future<void> createArticle(Map<String, dynamic> body) =>
      _client.post<Object>(ApiConstants.cmsArticles, data: body);

  Future<void> patchArticle(String id, Map<String, dynamic> body) =>
      _client.patch<Object>(ApiConstants.cmsArticle(id), data: body);

  Future<PublishResult?> articleAction(
    String id,
    CmsAction action, {
    String? reviewNote,
  }) => _workflow(ApiConstants.cmsArticle(id), action, reviewNote);

  Future<PublishResult?> _workflow(
    String base,
    CmsAction action,
    String? reviewNote,
  ) async {
    final r = await _client.post<Map<String, dynamic>>(
      '$base/${action.name}',
      data: action == CmsAction.approve || action == CmsAction.reject
          ? {'review_note': (reviewNote ?? '').trim()}
          : null,
    );
    if (action != CmsAction.publish) return null;
    // `redis_ok: false` is still HTTP 200: Firestore is published, the app
    // feed is not. Surface it rather than reporting plain success.
    return PublishResult(redisOk: r.data?['redis_ok'] == true);
  }

  // --- Ramadan ---------------------------------------------------------
  Future<RamadanSettings> fetchRamadan() async {
    final r = await _client.get<Map<String, dynamic>>(
      ApiConstants.ramadanSettings,
    );
    return RamadanSettings.fromJson(r.data ?? {});
  }

  Future<void> patchRamadan(Map<String, dynamic> body) =>
      _client.patch<Object>(ApiConstants.ramadanSettings, data: body);

  // --- Staff -----------------------------------------------------------
  Future<List<StaffMember>> listStaff() async {
    final r = await _client.get<Map<String, dynamic>>(ApiConstants.staff);
    return _items(r.data).map(StaffMember.fromJson).toList();
  }

  Future<void> setStaffRoles(
    String uid, {
    required Set<String> roles,
    required String email,
    required String displayName,
  }) => _client.put<Object>(
    ApiConstants.staffRoles(uid),
    data: {
      'roles': roles.toList()..sort(),
      'email': email,
      'display_name': displayName,
    },
  );
}
