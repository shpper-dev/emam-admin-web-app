import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/auth/view/sign_in_view.dart';
import 'package:emam_admin_web_app/features/dashboard/view/dashboard_view.dart';
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
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RoutePaths.signIn,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
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
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => const DashboardView(),
      ),
    ],
  );
});
