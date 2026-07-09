class ApiConstants {
  ApiConstants._();

  static const String firebaseWebApiKey =
      'AIzaSyDSxatz31b4auOeKlHD9svES3zxsVqOHAU';

  static const String identityToolkitBaseUrl =
      'https://identitytoolkit.googleapis.com/v1';

  static const String secureTokenBaseUrl =
      'https://securetoken.googleapis.com/v1';

  static String get signInUrl =>
      '$identityToolkitBaseUrl/accounts:signInWithPassword?key=$firebaseWebApiKey';

  static String get refreshTokenUrl =>
      '$secureTokenBaseUrl/token?key=$firebaseWebApiKey';
}
