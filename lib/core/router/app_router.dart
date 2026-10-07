import 'package:emam_admin_web_app/core/responsive/admin_shell.dart';
import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/features/audit/views/audit_view.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/auth/views/sign_in_view.dart';
import 'package:emam_admin_web_app/features/content/views/content_view.dart';
import 'package:emam_admin_web_app/features/dashboard/views/dashboard_view.dart';
import 'package:emam_admin_web_app/features/devices/views/devices_view.dart';
import 'package:emam_admin_web_app/features/system_tools/views/system_tools_view.dart';
import 'package:emam_admin_web_app/features/voice_server/views/voice_server_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerListenableProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: RoutePaths.signIn,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final isAuthenticated = authState.maybeWhen(
        data: (session) => session != null,
        orElse: () => false,
      );

      final location = state.matchedLocation;
      final isSignIn = location == RoutePaths.signIn;

      if (!isAuthenticated && !isSignIn) return RoutePaths.signIn;
      if (isAuthenticated && isSignIn) return RoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInView(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final title = switch (state.matchedLocation) {
            RoutePaths.content => 'Contents',
            RoutePaths.voiceDemo => 'Voice Demo',
            RoutePaths.devices => 'Signed-in Devices',
            RoutePaths.audit => 'Audit Log',
            RoutePaths.systemTools => 'System Tools',
            _ => 'Dashboard',
          };
          return AdminShell(title: title, body: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
          ),
          GoRoute(
            path: RoutePaths.content,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ContentView()),
          ),
          GoRoute(
            path: RoutePaths.voiceDemo,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VoiceServerView()),
          ),
          GoRoute(
            path: RoutePaths.devices,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DevicesView()),
          ),
          GoRoute(
            path: RoutePaths.audit,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AuditView()),
          ),
          GoRoute(
            path: RoutePaths.systemTools,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SystemToolsView()),
          ),
        ],
      ),
    ],
  );
});
