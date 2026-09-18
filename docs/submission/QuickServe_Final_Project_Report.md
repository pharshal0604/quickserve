# QuickServe Final Project Report

## 1. Executive summary

QuickServe is a Firebase-backed Service Request Management Application developed for the Swasiq Technology Internship Program. It provides role-based experiences for Customers and Service Agents through Flutter mobile, and an operational Admin portal through Flutter Web.

The delivered baseline covers authentication, service-request creation and tracking, Agent lifecycle operations, Admin assignment and operational management, Firestore Security Rules, append-only status history and audit logs, local Firebase Emulator Suite support, and shared Dart domain logic.

## 2. Delivered scope

### Customer mobile experience

- Email/password registration and login.
- Customer profile creation and session restoration.
- Active service catalog.
- Request creation with service, description, preferred date/time, address, and priority.
- Transactional request-code allocation using `REQ-YYYY-000123`.
- Request list and details.
- Status history and permitted notes.
- Eligible request cancellation with a reason.
- Password reset and logout.

### Agent mobile experience

- Agent-only work queue.
- Assignment-scoped request access.
- `assigned → accepted → in_progress → completed` lifecycle actions.
- Completion note support.
- Status history visibility.
- Terminal-state protection.
- Cross-Agent authorization protection.

### Admin Web experience

- Administrator email/password login.
- Role-protected Admin portal.
- Dashboard counts for total, created, assigned, accepted, in-progress, completed, and cancelled requests.
- Request search and status filtering.
- Request detail view.
- Assignment of eligible Agents to created requests.
- Valid lifecycle status updates.
- Customer and Agent records view.
- Activity/audit log view.
- Clear-search control.
- UI protection against invalid Agent reassignment after a request leaves `created`.

## 3. Architecture

- Flutter and Dart for mobile and web.
- Firebase Authentication for identity.
- Cloud Firestore for application data.
- Firestore Security Rules as the database authorization boundary.
- Riverpod and go_router in the mobile application.
- Material 3 UI.
- Shared Dart package for enums, models, validators, lifecycle rules, request codes, and constants.
- Firebase Emulator Suite for local Auth and Firestore testing.
- No Cloud Functions, paid services, or billing-dependent baseline features.

Primary collections:

```text
users/{uid}
services/{serviceId}
requests/{requestId}
requests/{requestId}/status_history/{historyId}
audit_logs/{logId}
counters/{year}
```

## 4. Security and integrity

- Stored roles are lowercase: `customer`, `agent`, and `admin`.
- Requests are ownership- and assignment-scoped by Firestore Rules.
- Admin access requires both Firebase Authentication and `users/{uid}.role == "admin"`.
- Lifecycle transitions are validated in shared Dart code and Firestore Rules.
- Status history and audit logs are append-only.
- Terminal states are protected.
- Immutable request fields cannot be changed through lifecycle updates.
- Passwords, tokens, and private credentials are not stored in source files or audit records.
- Emulator seed passwords are local-only and must never be used for hosted data.

## 5. Lifecycle

```text
created → assigned → accepted → in_progress → completed
    └────────────── eligible cancellation → cancelled
```

Customers may cancel from `created` or `assigned`. Admins may perform the operational transitions allowed by the finalized lifecycle policy. Completed and cancelled are terminal states.

## 6. Verification evidence

Verified during implementation:

- Mobile formatting completed successfully.
- Mobile analysis completed with no issues.
- Mobile test suite passed with 30 tests.
- Admin formatting completed successfully.
- Admin analysis completed with no issues.
- Admin widget test passed.
- Shared formatting and analysis completed with no issues.
- Shared tests must be run with `flutter test` because the shared package uses `flutter_test`.
- Admin login was verified against the Firebase Auth Emulator.
- Admin dashboard, Requests, Users, Activity, search, assignment controls, lifecycle guards, status history, and audit-log views were manually exercised.
- The working tree was clean after the Admin commit.

Important local commits:

```text
6c0181f feat(admin): add operational web portal
48ae3ff feat(mobile): complete Agent request lifecycle workflow
d0eb96b feat(mobile,shared): complete registration and request workflows
cacb830 config(mobile): enable emulator launch configuration
```

## 7. Known operational boundaries

- Local emulator credentials are synthetic and are not production credentials.
- Hosted deployment requires a separately authorized Firebase project and controlled Admin account provisioning.
- The Admin portal uses bounded result sets suitable for the internship baseline; larger production datasets would need pagination and additional query/index review.
- Firebase project configuration files contain public client configuration, not private service-account credentials.

## 8. Final handoff

Before submission, run the documented mobile, Admin, and shared Flutter commands, confirm no secrets or emulator exports are staged, verify the GitHub remote contains the latest commits, and attach the demo screenshots and walkthrough evidence described in the companion deliverables.
