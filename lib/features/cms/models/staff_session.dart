/// Staff roles the backend recognises. Anything else in a response is dropped
/// so an unexpected value can never widen what the UI shows.
class StaffRole {
  StaffRole._();

  static const admin = 'admin';
  static const editor = 'editor';
  static const scholarReviewer = 'scholar_reviewer';
  static const all = [admin, editor, scholarReviewer];

  static Set<String> parse(Object? raw) => {
    if (raw is List)
      for (final r in raw)
        if (r is String && all.contains(r)) r,
  };

  static String label(String role) => switch (role) {
    admin => 'Admin',
    editor => 'Editor',
    scholarReviewer => 'Scholar reviewer',
    _ => role,
  };
}

/// `GET /admin/me`. UI gating only: the backend re-checks every request.
class StaffSession {
  const StaffSession({
    required this.uid,
    required this.roles,
    required this.isPlatformAdmin,
  });

  final String uid;
  final Set<String> roles;
  final bool isPlatformAdmin;

  factory StaffSession.fromJson(Map<String, dynamic> json) => StaffSession(
    uid: (json['uid'] as String?) ?? '',
    roles: StaffRole.parse(json['staff_roles']),
    isPlatformAdmin: json['is_platform_admin'] == true,
  );

  bool get _isAdmin => roles.contains(StaffRole.admin) || isPlatformAdmin;
  bool get canEdit => _isAdmin || roles.contains(StaffRole.editor);
  bool get canReview => _isAdmin || roles.contains(StaffRole.scholarReviewer);
  bool get canManageStaff => _isAdmin;
  bool get hasCmsAccess => canEdit || canReview;
}

class StaffMember {
  const StaffMember({
    required this.uid,
    required this.roles,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final Set<String> roles;
  final String email;
  final String displayName;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    uid: (json['uid'] as String?) ?? '',
    roles: StaffRole.parse(json['roles']),
    email: (json['email'] as String?) ?? '',
    displayName: (json['display_name'] as String?) ?? '',
  );
}
