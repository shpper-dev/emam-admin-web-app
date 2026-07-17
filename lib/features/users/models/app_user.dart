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

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      location: json['location'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      hasVoice: json['has_voice'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
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
