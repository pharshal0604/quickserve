# QuickServe Admin Web Deployment Instructions

## 1. Purpose

These instructions cover local Admin development, Firebase Emulator Suite review, and optional hosted Flutter Web deployment. Use emulator mode for development and demonstrations. Use hosted mode only with an authorized Firebase project.

## 2. Prerequisites

Install and verify:

- Flutter SDK matching the repository environment.
- Dart SDK supplied by Flutter.
- Node.js and npm.
- Firebase CLI.
- An authenticated Firebase CLI account for hosted deployment only.

From the repository root:

```powershell
cd D:\Projects\quickserve
flutter doctor
firebase --version
node --version
```

## 3. Install Admin dependencies

```powershell
cd D:\Projects\quickserve\apps\admin
flutter pub get
```

## 4. Local Emulator Suite

Start Auth and Firestore:

```powershell
cd D:\Projects\quickserve
firebase emulators:start --only auth,firestore
```

Expected endpoints:

```text
Authentication: http://127.0.0.1:9099
Firestore:      http://127.0.0.1:8080
Emulator UI:    http://127.0.0.1:4000
```

Seed synthetic data in a second terminal:

```powershell
cd D:\Projects\quickserve

$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
$env:SEED_PASSWORD = "Admin123!"

node tools\seed\seed.js
```

The Admin seed account is:

```text
Email:    admin@example.test
Password: Admin123!
UID:      admin-uid-001
Role:     admin
```

These credentials are local emulator credentials only. Never use them for hosted Firebase.

Launch Admin against the emulators:

```powershell
cd D:\Projects\quickserve\apps\admin
flutter run -d chrome `
  --dart-define=FIREBASE_USE_EMULATORS=true `
  --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

## 5. Local verification

```powershell
cd D:\Projects\quickserve\apps\admin
dart format .
flutter analyze
flutter test
```

Use a request in `created` for assignment testing. Do not attempt to reassign requests that are already `assigned`, `accepted`, `in_progress`, `completed`, or `cancelled`.

## 6. Hosted Firebase preparation

Before hosted deployment:

1. Select or create the authorized Firebase project.
2. Confirm Authentication Email/Password is enabled.
3. Confirm Firestore is enabled.
4. Confirm the Firebase project is appropriate for the intended environment.
5. Run FlutterFire configuration for the Admin app if the project differs from the committed configuration.
6. Provision Admin accounts through a controlled operator process; do not create Admin roles through the public customer registration flow.
7. Review `firestore.rules` and `firestore.indexes.json`.
8. Confirm no emulator flags are enabled in the hosted build.

Deploy Rules and indexes from the repository root:

```powershell
cd D:\Projects\quickserve
firebase use <authorized-project-id>
firebase deploy --only firestore:rules,firestore:indexes
```

## 7. Build the hosted Admin portal

```powershell
cd D:\Projects\quickserve\apps\admin
flutter build web --release `
  --dart-define=FIREBASE_USE_EMULATORS=false
```

The generated web output is under:

```text
apps/admin/build/web
```

The repository `firebase.json` is configured to use that directory for Hosting. Deploy from the repository root:

```powershell
cd D:\Projects\quickserve
firebase deploy --only hosting
```

## 8. Hosted deployment checklist

- [ ] `FIREBASE_USE_EMULATORS=false` or omitted.
- [ ] Admin `firebase_options.dart` points to the authorized Firebase project.
- [ ] Email/Password Authentication is enabled.
- [ ] At least one controlled Admin profile exists with `users.role == "admin"`.
- [ ] Firestore Rules are deployed.
- [ ] Required Firestore indexes are deployed.
- [ ] No `.env`, service-account JSON, passwords, tokens, or emulator exports are staged.
- [ ] Admin login works.
- [ ] A non-Admin account is denied access.
- [ ] Request assignment and lifecycle updates create history and audit records.
- [ ] The deployment URL is recorded in the final handoff.

## 9. Rollback

For a Hosting rollback, restore the prior web build through the Firebase Hosting release history or redeploy a known-good build. For Rules changes, restore the last reviewed `firestore.rules` and redeploy. Never solve a production issue by disabling Rules or exposing a service account in the client.
