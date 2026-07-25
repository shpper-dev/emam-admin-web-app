# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Flutter web admin panel for the Emam app (`emam_admin_web_app`). It talks to a REST backend at
`https://pathway.emam.ai` and to Firebase Identity Toolkit directly for email/password auth. Primary
target platform is web; Android/iOS/desktop platform folders exist (default `flutter create` scaffolding)
but are not the focus of this app.

## Commands

```bash
flutter pub get                     # install dependencies
flutter run -d chrome                # run the app locally in Chrome
flutter analyze                      # static analysis (uses analysis_options.yaml / flutter_lints)
flutter test                         # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter build web                    # production web build
```

There is no custom lint config beyond the default `flutter_lints` rules — `analysis_options.yaml` doesn't
override anything. Dart SDK constraint is `^3.12.2` (see `pubspec.yaml`).

## Architecture

Feature-based structure under `lib/`:

- `lib/core/` — cross-cutting infrastructure shared by all features:
  - `network/` — `DioClient` (wraps a single `Dio` instance with the base URL and `AuthInterceptor`),
    `auth_interceptor.dart` (attaches `Authorization: Bearer`, and on a 401 calls back into the auth
    repo to refresh the token and retries the original request once), `api_error.dart`
    (`parseApiError` turns `DioException`s, including raw Firebase Identity Toolkit error bodies, into
    user-facing messages).
  - `storage/token_storage.dart` — thin wrapper over `SharedPreferences` for access/refresh tokens,
    expiry, and "remember me" email.
  - `providers/core_providers.dart` — root Riverpod providers (`sharedPreferencesProvider` is
    overridden in `main()` with the real instance; everything else, including `dioClientProvider`,
    is derived from it).
  - `router/` — `go_router` config (`app_router.dart`) and route path constants (`route_paths.dart`).
    Auth-gated redirects are driven by `authProvider`'s state via a `ValueNotifier` bridge
    (`routerListenableProvider`) so `GoRouter` re-evaluates `redirect` whenever auth state changes.
  - `responsive/` — `ResponsiveLayout` picks between `mobile`/`tablet`/`desktop` builders based on
    `LayoutBuilder` width breakpoints (600 / 1200 by default); `AdminShell` is the top-level scaffold
    used inside the app's `ShellRoute` and switches between `MobileScaffold`/`TabletScaffold`/
    `DesktopScaffold`.
  - `utils/image_proxy.dart` — `proxiedImageUrl()` routes remote image URLs through
    `images.weserv.nl` on web only, because Flutter Web's `Image.network`/`CachedNetworkImage` fail
    on hosts that don't send CORS headers. Non-web platforms and already-proxied URLs pass through
    unchanged. Use this whenever displaying a remote image URL from the API on web.

- `lib/features/<feature>/` — each feature (`auth`, `content`, `dashboard`, `moderation`, `users`)
  follows the same layering:
  - `models/` — plain Dart data classes with `fromJson`/response wrapper types.
  - `repository/` (or `models/` for `auth`) — one class per feature that takes a `DioClient` and
    exposes typed methods calling the endpoints in `core/constants/api_constants.dart`.
  - `provider/<feature>_repository_provider.dart` — a `Provider<XRepository>` built from
    `dioClientProvider`. This is the standard wiring pattern for every feature — follow it for new
    features rather than inventing a new DI approach.
  - `provider/` — Riverpod `Notifier`/`AsyncNotifier` classes holding UI state (pagination, loading,
    error message), reading the repository provider.
  - `views/` and `views/widgets/` — the widget tree.

- **Auth flow**: `AuthRepository` (`features/auth/models/auth_repository.dart`) implements
  `TokenRefresher` (declared in `dio_client.dart` to avoid a circular import between the repository
  and the client). It signs in directly against Firebase Identity Toolkit (`ApiConstants.signInUrl`),
  persists tokens via `TokenStorage`, and refreshes via `ApiConstants.refreshTokenUrl`. `AuthNotifier`
  (`features/auth/provider/auth_provider.dart`) is the single `AsyncNotifierProvider<AuthNotifier,
  AuthSession?>` that the router and UI watch; `restoreSession()` runs on app start and auto-refreshes
  an expired token from storage.

- **Admin-user filtering**: the signed-in admin account itself
  (`kAdminPanelUserEmail` in `features/users/utils/admin_panel_user.dart`) must never show up in user
  lists, restricted-user lists, or user-detail lookups. `UsersRepository` and
  `hideAdminPanelUserDetail`/`withoutAdminPanelUsers`/`withoutAdminPanelRestrictedUsers` filter it out
  and adjust counts accordingly — apply the same filtering if you add new endpoints that return user
  lists.

- **Pagination pattern**: list-heavy providers (e.g. `usersPaginationProvider` in
  `features/users/provider/users_provider.dart`) cache previously fetched pages in a list and only
  fetch a new page from the backend's opaque `next_page_token` when navigating past the last
  discovered page; going back to an earlier page is instant (no refetch). Follow this pattern for any
  new paginated list rather than refetching on every page change.

- Request/response endpoints and non-backend URLs (Firebase Identity Toolkit / Secure Token) all live
  in `lib/core/constants/api_constants.dart` — add new endpoints there rather than inlining path
  strings in repositories.
