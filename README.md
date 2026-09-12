# Emam Admin

Flutter web admin panel for the Emam app: users, dua board moderation, reports, content and analytics.
It talks to the Emam backend at `https://pathway.emam.ai` and signs admins in with Firebase email/password.

Live: https://emamadmin.web.app

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

## Check before pushing

```bash
flutter analyze
flutter test
```

## Deploy

Hosting is Firebase project `emamadmin` (see `.firebaserc` and `firebase.json`).

```bash
flutter build web
firebase deploy --only hosting --project emamadmin
```

The deploying account needs access to the `emamadmin` Firebase project.

## Notes

- API endpoints live in `lib/core/constants/api_constants.dart`.
- Architecture and conventions are described in `CLAUDE.md`.
