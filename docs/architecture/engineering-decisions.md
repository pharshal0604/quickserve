<![CDATA[# Engineering Decisions

This document explains the **why** behind QuickServe's technical choices. Each decision was made to solve a specific engineering problem, not just to use a popular library.

---

## State Management: Riverpod

**Problem:** The app needs authentication state, user profiles, real-time request lists, and computed metrics — all reactive, all interconnected.

**Why Riverpod over Provider:**
- `Provider` requires `BuildContext` to read state, which makes it impossible to use in repositories or non-widget code.
- Riverpod's `ref.watch` provides compile-time safety. If a provider is deleted, every consumer gets a compile error — not a runtime crash.
- Derived state is natural: `agentMetricsProvider` watches `agentRequestsProvider` and computes pending/active/completed counts reactively, with zero manual subscription management.

**Why not BLoC:**
- BLoC introduces significant boilerplate (Events, States, Bloc class) for operations that are fundamentally simple data transformations. Riverpod's `Provider` and `StreamProvider` express the same logic in ~5 lines vs ~50.

---

## Backend: Firebase

**Problem:** The app needs authentication, a real-time database, push notifications, and server-side security rules — all without building and maintaining a custom backend for core CRUD operations.

**Why Firebase fits:**
- **Firestore Security Rules** provide defense-in-depth. Even if a malicious client bypasses all Dart validation, the rules still enforce ownership, role-based access, field immutability, and valid status transitions.
- **Firestore Snapshots** provide real-time data sync between Customer and Agent without polling or WebSockets.
- **Firebase Auth** handles email/password, Google Sign-In, token refresh, and session management with zero custom implementation.
- **FCM** provides cross-platform push notifications with token-based targeting.

**Trade-off acknowledged:** Firebase creates vendor lock-in. The Repository Pattern mitigates this by isolating all Firebase calls behind interfaces that could be swapped for REST/GraphQL without changing any UI code.

---

## Repository Pattern

**Problem:** UI screens should never know or care whether data comes from Firebase, a REST API, or a local cache.

**What it solves:**
1. **Error Mapping:** Raw `FirebaseException` objects contain codes like `permission-denied` or `failed-precondition`. The repository catches these and returns typed `AppException` subclasses with user-safe messages like "You are not authorized to load your profile."
2. **Testability:** Repositories can be mocked in tests without touching Firebase.
3. **Portability:** If the backend changes from Firestore to Supabase or a REST API, only the repository implementations change. Zero UI modifications.

**Implementation detail:** The error mapping is centralized in `firebase_error_mapper.dart` using Dart 3 pattern matching:

```dart
final message = switch (error.code) {
  'permission-denied' => 'You are not authorized to perform this action.',
  'unavailable' => 'The service is temporarily unavailable.',
  'not-found' => 'The requested record was not found.',
  _ => 'Something went wrong. Please try again.',
};
```

---

## Shared Dart Package

**Problem:** The mobile app and admin portal both need the same entities, validators, lifecycle rules, status colors, and theme tokens. Duplicating them creates drift.

**Solution:** `packages/shared` is a pure Dart package consumed by both apps:
- **Entities** — `User`, `Request`, `Service`, `AuditLog`, `StatusHistory`, `Counter`
- **Validators** — `validateName()`, `validatePhone()`, `validateAddress()`, `validatePreferredDateTime()`
- **Lifecycle** — `requireValidTransition()`, `isCancellableByCustomer()`
- **Theme** — `AppColors`, `AppSpacing`, `AppTheme`, `AppRadius`, `AppShadows`
- **Constants** — `CollectionNames`, `StatusNames`, `RoleNames`, `EventNames`

**Key constraint:** The shared package has **zero Firebase dependencies**. All `fromMap()` / `toMap()` methods work with plain `Map<String, dynamic>`, not Firebase `DocumentSnapshot`.

---

## Navigation: GoRouter with StatefulShellRoute

**Problem:** The Agent app has a persistent bottom navigation bar with four tabs (Home, Tasks, History, Profile). Navigating between tabs should preserve scroll position and loaded data. Simultaneously, the app needs authentication-based redirects and role-based routing.

**Why GoRouter:**
- Declarative redirects: the `redirect` callback checks `authStateProvider` and `userProfileProvider` on every navigation, automatically routing unauthenticated users to `/splash` and agents to `/a/home` instead of `/home`.
- `StatefulShellRoute.indexedStack` preserves each tab's widget tree, so switching from History back to Home doesn't trigger a re-fetch.
- URL-based routing enables deep linking and makes the navigation stack inspectable.

**How role routing works:**
```dart
if (userProfile.role == UserRole.agent) {
  if (path == '/home') return '/a/home';       // Redirect to agent shell
  if (path == '/profile') return '/a/profile'; // Redirect to agent profile
}
```

---

## Atomic Firestore Transactions

**Problem:** Creating a request involves five writes: counter increment, request document, status history entry, audit log, and service availability check. If the counter increments but the request write fails, the system is in an inconsistent state.

**Solution:** All five operations run inside a single `FirebaseFirestore.instance.runTransaction()`. If any write fails, the entire transaction rolls back atomically. This guarantees:
- No orphaned counter increments
- No requests without history entries
- No audit logs for operations that didn't succeed

**The same pattern applies to status transitions:** When an Agent accepts a request, the transaction reads the current status, validates the transition, updates the request, and writes the history entry — all atomically.

---

## Centralized Design System

**Problem:** Scattered `Color(0xFF123456)`, `fontSize: 17`, and `padding: EdgeInsets.all(13)` values make the app inconsistent and hard to maintain. Updating the brand color requires finding and changing dozens of hardcoded values.

**Solution:** Every visual token is defined once in `packages/shared/lib/theme/`:

| Instead of | Use |
|------------|-----|
| `Color(0xFF075B3E)` | `AppColors.primary` |
| `EdgeInsets.all(16)` | `EdgeInsets.all(AppSpacing.lg)` |
| `BorderRadius.circular(12)` | `AppRadius.lgAll` |
| Custom `ThemeData(...)` per screen | `AppTheme.light()` / `AppTheme.dark()` |

The `AppTheme` class configures every Material 3 component theme (buttons, inputs, cards, chips, dialogs, navigation bars, switches, checkboxes) from a single source of truth.

---

## Sealed Exception Hierarchy

**Problem:** Raw exceptions are either too technical for users ("FirebaseException: FAILED_PRECONDITION") or too vague ("Something went wrong").

**Solution:** A sealed `AppException` hierarchy:

```dart
sealed class AppException implements Exception {
  final String code;        // Stable internal code for logging
  final String userMessage; // Safe message for UI display
}

final class AuthException extends AppException { ... }
final class UserRepositoryException extends AppException { ... }
final class RequestRepositoryException extends AppException { ... }
final class ServiceRepositoryException extends AppException { ... }
```

- `code` is logged for debugging but never shown to users.
- `userMessage` is always grammatically correct and actionable.
- The `sealed` keyword ensures exhaustive `switch` handling — the compiler forces you to handle every exception type.

---

## Request Lifecycle State Machine

**Problem:** Without strict rules, a request could jump from `created` directly to `completed`, or a Customer could mark someone else's request as cancelled.

**Solution:** Three layers of enforcement:

1. **Shared Package** (`utils/lifecycle.dart`) — `requireValidTransition(from, to, role)` throws `SharedLifecycleException` if the transition is invalid. This runs on the client before any network call.

2. **Repository Layer** — Inside the Firestore transaction, the repository reads the current status and validates it matches the expected status before writing. This prevents race conditions where two agents try to accept simultaneously.

3. **Firestore Security Rules** — The rules re-validate the transition server-side. Even if a malicious client bypasses all Dart code, the rules reject invalid transitions.

This defense-in-depth approach means the system is correct even if any single layer fails.
]]>
