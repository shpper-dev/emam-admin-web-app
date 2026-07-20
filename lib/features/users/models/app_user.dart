class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.location,
    required this.age,
    required this.gender,
    required this.hasVoice,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String location;
  final int? age;
  final String? gender;
  final bool hasVoice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Best URL for this user's profile image from list/detail JSON.
  String resolvePhotoUrl({String? cachedDetailPhotoUrl}) {
    final direct = photoUrl.trim();
    if (direct.isNotEmpty) return direct;
    final cached = cachedDetailPhotoUrl?.trim() ?? '';
    if (cached.isNotEmpty) return cached;
    return '';
  }

  static String photoUrlFromJson(Map<String, dynamic> json) {
    String? pick(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    for (final key in const [
      'photo_url',
      'photoUrl',
      'profile_picture_url',
      'profilePictureUrl',
      'profile_image_url',
      'profileImageUrl',
      'picture',
      'photo',
    ]) {
      final url = pick(json[key]);
      if (url != null) return url;
    }

    final profile = json['profile'];
    if (profile is Map<String, dynamic>) {
      return photoUrlFromJson(profile);
    }
    return '';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizeUserJson(json);
    return AppUser(
      id: normalized['id'] as String? ?? '',
      displayName: normalized['display_name'] as String? ?? '',
      email: normalized['email'] as String? ?? '',
      photoUrl: photoUrlFromJson(normalized),
      location: normalized['location'] as String? ?? '',
      age: normalized['age'] as int?,
      gender: normalized['gender'] as String?,
      hasVoice: normalized['has_voice'] as bool? ?? false,
      createdAt: _parseDate(normalized['created_at']),
      updatedAt: _parseDate(normalized['updated_at']),
    );
  }

  /// Merges nested `profile` maps so list payloads expose photo/name fields.
  static Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    if (profile is! Map<String, dynamic>) return json;

    final merged = <String, dynamic>{...profile, ...json};
    final photo = photoUrlFromJson(json);
    final profilePhoto = photoUrlFromJson(profile);
    if (photo.isNotEmpty) {
      merged['photo_url'] = photo;
    } else if (profilePhoto.isNotEmpty) {
      merged['photo_url'] = profilePhoto;
    }
    return merged;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class UsersResponse {
  const UsersResponse({
    required this.users,
    required this.nextPageToken,
    required this.count,
  });

  final List<AppUser> users;
  final String? nextPageToken;
  final int count;

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>? ?? const [];
    return UsersResponse(
      users: rawUsers
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
      count: json['count'] as int? ?? rawUsers.length,
    );
  }
}
