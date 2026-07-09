import 'package:dio/dio.dart';

String parseApiError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final firebaseError = data['error'];
    if (firebaseError is Map<String, dynamic>) {
      final message = firebaseError['message'] as String?;
      if (message != null) {
        return _friendlyFirebaseMessage(message);
      }
    }
    final message = data['message'] as String?;
    if (message != null) return message;
  }
  return 'Something went wrong. Please try again.';
}

String _friendlyFirebaseMessage(String code) {
  return switch (code) {
    'EMAIL_NOT_FOUND' => 'No account found with this email.',
    'INVALID_PASSWORD' => 'Incorrect password. Please try again.',
    'INVALID_LOGIN_CREDENTIALS' => 'Invalid email or password.',
    'USER_DISABLED' => 'This account has been disabled.',
    'TOO_MANY_ATTEMPTS_TRY_LATER' =>
      'Too many attempts. Please try again later.',
    _ => 'Sign in failed. Please check your credentials.',
  };
}
