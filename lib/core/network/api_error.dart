import 'dart:convert';

import 'package:dio/dio.dart';

String parseApiError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Connection timed out. Please check your internet and try again.';
    case DioExceptionType.connectionError:
      return 'No internet connection. Please check your network and try again.';
    case DioExceptionType.cancel:
      return 'Request was cancelled. Please try again.';
    case DioExceptionType.badCertificate:
      return 'Secure connection failed. Please try again later.';
    case DioExceptionType.badResponse:
      return _parseBadResponse(error);
    case DioExceptionType.unknown:
      return _parseUnknownError(error);
  }
}

String _parseBadResponse(DioException error) {
  final data = _responseDataAsMap(error.response?.data);
  if (data != null) {
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

  final statusCode = error.response?.statusCode;
  if (statusCode != null && statusCode >= 500) {
    return 'Server error. Please try again later.';
  }

  return switch (statusCode) {
    400 => 'Invalid request. Please check your credentials.',
    401 => 'Invalid email or password.',
    403 => 'Access denied. Please contact support.',
    404 => 'Service unavailable. Please try again later.',
    429 => 'Too many attempts. Please try again later.',
    _ => 'Something went wrong. Please try again.',
  };
}

String _parseUnknownError(DioException error) {
  final underlying = error.error?.toString().toLowerCase() ?? '';
  if (underlying.contains('socket') ||
      underlying.contains('network') ||
      underlying.contains('connection') ||
      underlying.contains('failed host lookup')) {
    return 'No internet connection. Please check your network and try again.';
  }
  return 'Something went wrong. Please try again.';
}

Map<String, dynamic>? _responseDataAsMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}

String _friendlyFirebaseMessage(String message) {
  final code = message.split(' ').first.split(':').first.trim();
  return switch (code) {
    'EMAIL_NOT_FOUND' => 'No account found with this email.',
    'INVALID_PASSWORD' => 'Incorrect password. Please try again.',
    'INVALID_LOGIN_CREDENTIALS' => 'Invalid email or password.',
    'INVALID_EMAIL' => 'Please enter a valid email address.',
    'MISSING_PASSWORD' => 'Please enter your password.',
    'USER_DISABLED' => 'This account has been disabled.',
    'TOO_MANY_ATTEMPTS_TRY_LATER' =>
      'Too many attempts. Please try again later.',
    'OPERATION_NOT_ALLOWED' =>
      'Sign in is not allowed. Please contact support.',
    'CREDENTIAL_TOO_OLD_LOGIN_AGAIN' => 'Please sign in again.',
    'TOKEN_EXPIRED' => 'Your session has expired. Please sign in again.',
    _ => 'Sign in failed. Please check your credentials.',
  };
}
