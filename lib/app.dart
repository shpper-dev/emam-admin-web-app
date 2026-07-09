import 'package:emam_admin_web_app/core/router/app_router.dart';
import 'package:emam_admin_web_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Emam Admin',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
