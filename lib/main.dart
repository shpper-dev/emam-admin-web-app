import 'package:emam_admin_web_app/app.dart';
import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Larger image cache so switching between content sections with many
  // thumbnails doesn't evict + re-decode previously-viewed images.
  // Default is 1000 entries / 100 MB — bumped to comfortably hold the full
  // combined news + scholarly-insights feed.
  PaintingBinding.instance.imageCache
    ..maximumSize = 2000
    ..maximumSizeBytes = 256 * 1024 * 1024;

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
