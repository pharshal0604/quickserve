---
title: "QuickServe README and Setup Guide"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Project Overview

QuickServe is a Service Request Management Application created for the Swasiq Technology Internship Program — Health-tech, Nagpur. It is the Full-Stack Mobile Application — Intern Technical Assignment, designed for a 5–7 day challenge.

Customers create and track service requests from a Flutter mobile app. Agents manage assigned work from the same Flutter mobile app. Admins manage operations from a Flutter Web admin portal.

The supported services are AC servicing, Plumbing, Electrical, and Cleaning. The request lifecycle is:

```text
created -> assigned -> accepted -> in_progress -> completed
   |          |          |             |
   +----------+----------+-------------+----> cancelled when eligible
```

The application uses Firebase Authentication with email/password, Cloud Firestore, and Firestore Security Rules. The Firebase Spark free plan is the target environment. The project does not use Cloud Functions, custom claims, FCM, Supabase, React, Next.js, Angular, or another backend framework.

### Key features by role

| Role | Stored value | Client | Key features |
|---|---|---|---|
| Customer | `customer` | Flutter mobile | Register, sign in, browse services, create requests, receive `REQ-YYYY-000123`, view own requests, view permitted history, cancel eligible own requests, manage permitted profile fields, logout |
| Agent | `agent` | Flutter mobile | Sign in, view assigned queue, open assigned requests, accept work, move work to `in_progress`, complete work, add permitted notes, view completed work, logout |
| Admin | `admin` | Flutter Web | Sign in through Admin Login, view dashboard, search/filter requests using supported queries, assign Agents, perform permitted operational updates, view Customers, view Agents, view safe activity/audit records, logout |

### Finalized stored values

| Category | Stored values |
|---|---|
| Roles | `customer`, `agent`, `admin` |
| Priorities | `low`, `medium`, `high` |
| Statuses | `created`, `assigned`, `accepted`, `in_progress`, `completed`, `cancelled` |
| Events | `LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, `DATABASE_ERROR` |

Never store or log passwords, tokens, API keys, or secrets.

## Architecture Summary

QuickServe is a Flutter/Dart application with two clients and shared Dart code. Firebase Authentication establishes identity, Cloud Firestore stores application data, and Firestore Security Rules enforce the backend authorization boundary. Riverpod manages state and repositories, go_router manages role-aware navigation, Material 3 provides the UI system, and the Firebase Emulator Suite provides local Authentication and Firestore testing. The System Architecture Document is the authoritative companion reference for component boundaries and data flow.

```text
+----------------------+       +----------------------+
| Flutter Mobile       |       | Flutter Web          |
| Customer / Agent     |       | Admin                |
+----------+-----------+       +----------+-----------+
           |                              |
           +--------------+---------------+
                          v
                 +------------------+
                 | Shared Dart code |
                 | Riverpod/go_router|
                 +---------+--------+
                           |
          +----------------+----------------+
          v                                 v
+----------------------+          +----------------------+
| Firebase Auth        |          | Cloud Firestore       |
| email/password       |          | data and indexes      |
+----------------------+          +----------+-----------+
                                             |
                                             v
                                  +----------------------+
                                  | Firestore Rules      |
                                  | authorization        |
                                  +----------------------+

Local development uses Firebase Emulator Suite for Auth and Firestore.
```

## Repository Structure

The repository uses the following approved structure. The listed folders and files are the project structure contract for this assignment.

```text
QuickServe/
|-- apps/mobile/                  Flutter mobile application for Customer and Agent
|-- apps/admin/                   Flutter Web Admin portal
|-- packages/shared/              Shared Dart package for models, contracts, and reusable code
|-- firestore.rules                Firestore Security Rules source
|-- firestore.indexes.json         Firestore index declarations
|-- firebase.json                  Firebase Emulator and Hosting configuration
|-- .github/workflows/             Optional GitHub Actions workflow definitions
|-- docs/                          Companion project documentation
|-- .gitignore                     Files and folders excluded from Git
|-- README.md                      Repository entry-point documentation
```

Do not commit generated build output, local emulator exports, passwords, tokens, API keys, service-account files, or secret configuration. The exact repository tree above must remain consistent with the project documentation set.

## Prerequisites

The following baseline versions are recommended for the assignment. The Flutter version is a stable-version assumption and should be pinned in the repository's setup notes before implementation begins.

| Tool | Required baseline | Purpose |
|---|---|---|
| Flutter SDK | Stable Flutter `3.35.3` or the stable version pinned by the repository | Mobile and Web application development |
| Dart SDK | Bundled with the selected Flutter SDK | Dart application and package code |
| Node.js | Node.js `22.x` LTS | Firebase CLI and Emulator Suite tooling |
| Firebase CLI | Firebase CLI `14.16.0` or the version pinned by the repository | Emulator, Rules, indexes, and Hosting commands |
| Git | Git `2.50` or newer | Version control and GitHub workflow |
| Android Studio | Current stable release | Android SDK, emulator, and Flutter Android development |
| Xcode | Current compatible release on macOS | iOS Simulator and iOS builds |
| Browser | Current Chrome, Edge, or another supported modern browser | Flutter Web Admin portal |

### Verify prerequisites on Windows

Run these commands in Windows `cmd.exe`:

```cmd
flutter --version
```

```cmd
dart --version
```

```cmd
node --version
```

```cmd
firebase --version
```

```cmd
git --version
```

```cmd
flutter doctor
```

Resolve blocking `flutter doctor` issues before running emulator-backed tests. Android Studio and Xcode are platform-specific prerequisites; Xcode is required on macOS for iOS builds.

## Local Setup

### Clone the repository

Open Windows `cmd.exe`, choose a workspace location, and clone the repository:

```cmd
cd C:\work
```

```cmd
git clone <repository-url> QuickServe
```

```cmd
cd QuickServe
```

Use the repository URL supplied by the project owner. Do not place credentials or tokens in the URL.

### Install Flutter dependencies

Run dependency installation for the mobile app, Admin Web app, and shared Dart package using the repository's approved structure:

```cmd
cd apps\mobile
flutter pub get
```

```cmd
cd ..\admin
flutter pub get
```

```cmd
cd ..\..\packages\shared
flutter pub get
```

Return to the repository root before Firebase commands:

```cmd
cd ..\..
```

If the repository uses a documented root-level bootstrap command, follow that command instead of inventing a new package layout.

### Install Firebase CLI

Install the pinned Firebase CLI through Node.js LTS:

```cmd
npm install -g firebase-tools@14.16.0
```

Verify the installation:

```cmd
firebase --version
```

Authenticate the CLI only when a Firebase-hosted operation requires it. Authentication credentials must remain outside source files and logs:

```cmd
firebase login
```

### Initialize the local Firebase project for emulators

The repository's `firebase.json` is the authoritative Firebase configuration. If the project has not yet been initialized locally, run the interactive Firebase initialization from the repository root:

```cmd
firebase init emulators
```

Select Authentication and Firestore emulators when prompted. Do not select Cloud Functions. Use the expected local ports listed in Emulator Suite Setup. If the repository already contains `firebase.json`, review the existing configuration rather than overwriting it.

### Configure emulator connection settings

Configure the Flutter clients to use emulator services only in local development and test mode. The implementation should keep the emulator switch in one documented configuration path, such as a Dart compile-time environment value or a development provider.

A local Windows `cmd.exe` session may set a non-secret emulator flag before launching the app:

```cmd
set FIREBASE_USE_EMULATORS=true
```

The application must use the documented local host aliases for the selected target:

| Target | Authentication emulator host | Firestore emulator host |
|---|---|---|
| Windows desktop or local Web | `127.0.0.1` | `127.0.0.1` |
| Android emulator | Android emulator host alias documented by the repository | Android emulator host alias documented by the repository |
| iOS Simulator | `127.0.0.1` | `127.0.0.1` |

Do not hard-code a production project endpoint into emulator mode. Do not copy secrets into Dart source or commit local configuration containing credentials.

### Seed emulator data

Seed data must be synthetic and must use the finalized roles, services, request statuses, histories, audit events, and counter fields. Use the repository's documented Dart seed utility or Emulator import procedure. If seed data is loaded through a project script, run that script from the repository root as documented by the implementation.

The minimum seed set should include:

- One synthetic Customer with stored role `customer`.
- One synthetic Agent with stored role `agent`.
- One synthetic Admin with stored role `admin`.
- Services for AC servicing, Plumbing, Electrical, and Cleaning.
- Requests across `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`.
- Status-history records for the seeded lifecycle paths.
- Safe audit records using only the fixed events.
- A counter document with a known `lastRequestNumber`.

Never seed real names, phone numbers, passwords, tokens, API keys, or secrets.

### Run the mobile app

From the mobile application directory, select a connected Android device or emulator and run:

```cmd
cd apps\mobile
flutter devices
```

```cmd
flutter run
```

When the application supports a documented emulator flag, use the repository's configured Dart define rather than changing source code. A typical non-secret local flag is:

```cmd
flutter run --dart-define=FIREBASE_USE_EMULATORS=true
```

The exact define name must match the implementation. Do not add a second competing configuration mechanism.

### Run the Admin Web portal

From the Admin application directory, run the Flutter Web client in a modern browser:

```cmd
cd ..\admin
flutter run -d chrome
```

For emulator-backed local development, pass the repository's documented emulator define if required:

```cmd
flutter run -d chrome --dart-define=FIREBASE_USE_EMULATORS=true
```

The Admin portal must resolve a signed-in profile with stored role `admin` before showing Admin Dashboard.

## Emulator Suite Setup

### Expected local ports

| Emulator service | Expected port | Used by |
|---|---:|---|
| Authentication | 9099 | Firebase email/password test accounts |
| Cloud Firestore | 8080 | Application data, Rules, and transaction tests |
| Emulator UI | 4000 | Local emulator inspection |
| Firebase Hosting emulator if configured | 5000 | Optional local Web hosting preview |

Only Authentication and Firestore are required for QuickServe. No Cloud Functions emulator is required.

### Start the emulators

From the repository root in Windows `cmd.exe`:

```cmd
firebase emulators:start --only auth,firestore
```

Open the local Emulator UI in a browser when available:

```cmd
start http://127.0.0.1:4000
```

The Emulator UI is for local inspection. It is not a production administration interface.

### Safe isolation from production

- Use the Firebase Emulator Suite for local and automated tests.
- Confirm the Flutter clients connect to emulator hosts before creating data.
- Do not run test seed scripts against a production project.
- Do not store a production credential or token in the repository.
- Keep emulator data synthetic.
- Use a separate local project configuration from any hosted deployment configuration.
- Stop emulators after local work when another process needs the expected ports.

Stop the foreground emulator process with `Ctrl+C` in the same `cmd.exe` window. Do not use production Firebase credentials as a substitute for a local emulator configuration.

## Test Credentials

### Demo account policy

Demo users are created by local seed configuration or through the Firebase Authentication Emulator. Demo passwords are supplied through local seed configuration and are never committed to GitHub, Markdown files, screenshots, logs, or source code.

| Demo account | Stored role | Client | Password handling |
|---|---|---|---|
| Synthetic Customer demo | `customer` | Flutter mobile | Password supplied through local seed configuration only |
| Synthetic Agent demo | `agent` | Flutter mobile | Password supplied through local seed configuration only |
| Synthetic Admin demo | `admin` | Flutter Web | Password supplied through local seed configuration only |

Use synthetic `.test` email addresses or the project seed utility's generated identifiers. Do not publish actual account credentials in this README. If a reviewer needs a demo password, provide it through an approved private channel or local setup file that is ignored by Git.

## Running the Tests

### Static analysis and formatting

From each Dart application or package directory, run the repository's documented format and analysis checks. The following commands are Windows `cmd.exe` commands:

```cmd
flutter analyze
```

```cmd
dart format --output=none --set-exit-if-changed .
```

### Unit and widget tests

Run the Flutter test suite from the relevant Dart project directory:

```cmd
flutter test
```

If the repository separates test groups through supported Dart test names, run the documented group command without adding a new test framework.

### Integration tests

Start Authentication and Firestore emulators first:

```cmd
firebase emulators:start --only auth,firestore
```

In another Windows `cmd.exe` window, run the integration tests:

```cmd
flutter test integration_test
```

The integration tests must connect to the emulators and use synthetic fixtures.

### Rules tests

Rules tests must run against the Firestore Emulator Suite. Use the repository's Rules test runner and documented Dart/Node test entry point. The test suite must cover the existing RBAC anchors TEST-07, TEST-08, TEST-09, and TEST-10, plus the Rules cases defined in the RBAC & Security Document.

At minimum, verify:

- Cross-customer request access is denied.
- Cross-agent request access is denied.
- Customer self-promotion through `users.role` is denied.
- Unauthenticated protected reads and writes are denied.
- Ownership, assignment, immutable fields, lifecycle transitions, append-only records, and counter boundaries are tested.

### Run all local checks

A simple Windows `cmd.exe` sequence is:

```cmd
flutter analyze
```

```cmd
flutter test
```

```cmd
flutter test integration_test
```

Run emulator-backed commands only after the Authentication and Firestore emulators are available.

## Firestore Security Rules

### Source location

The authoritative Rules source is:

```text
firestore.rules
```

Rules use `users.role` and enforce authentication, role, ownership, assignment, field-level protection, lifecycle transitions, append-only history/audit behavior, and controlled counter writes. The client UI must not be treated as the security boundary.

### Local Rules workflow

Start the Firestore emulator with the Rules file configured in `firebase.json`:

```cmd
firebase emulators:start --only firestore
```

Run the Rules test suite against the emulator. Never validate only by clicking through the UI; direct Firestore allow/deny tests are required.

### Deploy Rules when hosting a Firebase project

Deployment is optional for the Spark-plan assignment and must use the project owner's authorized Firebase project. From the repository root:

```cmd
firebase deploy --only firestore:rules
```

Review the target project and authenticated CLI account before deployment. Do not put credentials, tokens, or service-account data into the command line or repository.

## Firestore Indexes

### Source location

The authoritative index declaration is:

```text
firestore.indexes.json
```

Indexes must support the bounded queries required by My Requests, the Agent queue, and Admin Request Management. Do not add an index for an unapproved query or introduce a new search service.

### Local index behavior

The Firestore Emulator uses the project configuration and can execute the supported local queries without a paid plan. Keep index declarations versioned so another developer can reproduce the same query behavior.

### Deploy indexes when required

From the repository root and only after reviewing the target project:

```cmd
firebase deploy --only firestore:indexes
```

Index deployment does not grant authorization. Firestore Rules remain the security boundary.

## Firebase Hosting Deployment

Hosting deployment is optional for the Admin Web portal. It must remain separate from emulator configuration and must not require Cloud Functions or a paid Firebase plan.

### Build the Admin Web portal

From the Admin application directory in Windows `cmd.exe`:

```cmd
cd apps\admin
flutter build web --release
```

If the implementation uses an explicit hosted-environment flag, use the documented non-secret define:

```cmd
flutter build web --release --dart-define=FIREBASE_USE_EMULATORS=false
```

The exact define name must match the application configuration. Never embed a secret or private key in the Web bundle.

### Deploy Firebase Hosting

From the repository root:

```cmd
firebase deploy --only hosting
```

The `firebase.json` Hosting configuration must point to the generated Admin Web build output. Review the Hosting target and Firebase project before deployment.

### Emulator and hosted separation

- Emulator mode must point to local Authentication and Firestore hosts.
- Hosted Admin Web mode must point to the authorized hosted Firebase project configuration.
- Do not use emulator seed credentials against a hosted environment.
- Do not copy local emulator flags into a production deployment unintentionally.
- Firebase Hosting deployment does not deploy Cloud Functions because QuickServe does not use them.

## Mobile Build

### Android APK

From the mobile application directory:

```cmd
cd apps\mobile
flutter build apk --release
```

The output location is reported by Flutter. Do not commit generated APKs unless the submission process explicitly requests an artifact outside the source repository.

### iOS build

An iOS build requires macOS, Xcode, an Apple development environment, and a connected or configured iOS target. From the mobile application directory on the macOS build machine, run the Flutter build command documented by the repository:

```cmd
cd apps\mobile
flutter build ios --release
```

The command syntax shown is intentionally compatible with Windows `cmd.exe` documentation formatting, but the iOS build itself must be executed on macOS because Xcode is required. App Store submission is not required for this assignment.

## Environment Configuration

### Configuration boundaries

| Configuration | Local emulator mode | Hosted/deployment mode |
|---|---|---|
| Authentication endpoint | Local Authentication emulator on port 9099 | Authorized Firebase Authentication project |
| Firestore endpoint | Local Firestore emulator on port 8080 | Authorized Cloud Firestore project |
| Data | Synthetic fixtures | Only approved project data |
| Billing | Not required | Firebase Spark target where supported |
| Build flag | Emulator flag enabled | Emulator flag disabled |
| Secrets | Outside Git and local-only | Managed through approved deployment environment; never bundled unnecessarily |

### Files and values that stay out of Git

Never commit:

- Passwords.
- Firebase Authentication tokens.
- API keys that are not intended for public client configuration.
- Private keys or service-account JSON.
- Local seed files containing passwords.
- Production environment files containing secrets.
- Emulator exports containing sensitive or real data.

Use `.gitignore` to exclude local-only files. Do not instruct contributors to paste secrets into `README.md`, Dart source, Rules, seed fixtures, commit messages, or issue comments.

### Local versus hosted configuration

Use one explicit application configuration path to select emulator or hosted endpoints. The mode must be visible in development diagnostics without printing credentials. Review the selected mode before every integration test run and Hosting deployment.

## Git Workflow

### Branch naming

Use short descriptive branches such as:

```text
feature/customer-request-form
feature/agent-status-flow
fix/firestore-rules-denial
chore/emulator-test-data
```

Do not use branch names containing passwords, tokens, or personal secrets.

### Commit messages

Use meaningful commits that explain one coherent change:

```text
feat: add customer request form validation
fix: restrict customer cancellation transitions
test: add Firestore ownership denial coverage
```

### Pull requests

A pull request should include:

- Summary of the implementation.
- Screens or flows affected.
- Tests run and their environment.
- Rules and emulator evidence for authorization changes.
- Any known limitation or open question.
- Confirmation that no secrets or generated files were committed.

Keep pull requests focused and reviewable. Do not merge a UI-only authorization change without corresponding Rules tests when the data boundary is affected.

### `.gitignore` expectations

`.gitignore` should exclude build output, IDE metadata, local emulator data, local seed credentials, secret environment files, generated reports, and platform-generated files that are not part of the approved source tree.

## Optional GitHub Actions

An optional GitHub Actions workflow may run:

1. Flutter SDK setup.
2. Dependency installation.
3. `flutter analyze`.
4. Formatting verification.
5. Unit and widget tests.
6. Authentication and Firestore Emulator Suite startup.
7. Rules and integration tests against emulators.

The workflow must not require Firebase billing, Cloud Functions, a production credential, a credit card, or a paid service. CI logs must not print secrets or test passwords.

## Troubleshooting

### `flutter doctor` reports issues

Run:

```cmd
flutter doctor -v
```

Then verify the Flutter SDK path, Android SDK licenses, connected device, browser installation, and Xcode installation on macOS. Run the project from the Flutter version documented by the repository.

### Emulator port conflict

Expected ports are Authentication 9099, Firestore 8080, Emulator UI 4000, and optional Hosting emulator 5000. Close another emulator process or use the documented project port configuration. Do not change client ports in only one app; mobile, Web, tests, and documentation must use the same configuration.

To inspect the local Emulator UI:

```cmd
start http://127.0.0.1:4000
```

### Firestore `permission-denied` during development

Check the following in order:

1. The user is signed in to the Authentication emulator.
2. `users/{uid}` exists and contains the expected lowercase stored role.
3. The request ownership or agent assignment matches the authenticated UID.
4. The status transition is valid.
5. The attempted fields are allowed for the actor.
6. The client is connected to the same emulator project and ports used by the Rules tests.
7. The Rules test reproduces the operation directly.

Do not weaken Rules to make a UI test pass.

### Missing profile

If Authentication succeeds but `users/{uid}` cannot be read, do not infer a role. Confirm that the profile seed or registration write succeeded, retry the profile read, or sign out and use the documented provisioning/recovery process.

### Counter conflict

A counter conflict is expected to trigger transaction retry behavior. Re-read the current request state before retrying a user action. Do not reuse an uncertain request code and do not show success until the transaction result is known.

### Flutter Web CORS or host alias issue

Confirm that the Web client uses the documented emulator host and that Authentication and Firestore emulators are running. Check browser developer tools for the local endpoint being used, but do not paste tokens or authorization headers into issue reports. For Android emulator testing, use the host alias documented by the repository rather than assuming `127.0.0.1` reaches the Windows host.

### Admin route opens for the wrong role

Confirm that go_router waits for Firebase session and profile resolution, that the profile reads `users.role`, and that Firestore Rules independently deny unauthorized Admin data. Clear the emulator session and repeat with a fresh synthetic user.

### Tests pass locally but fail in CI

Compare Flutter, Dart, Node.js, Firebase CLI, emulator ports, seed data, and platform settings. Ensure CI starts the emulators before integration or Rules tests and does not depend on local uncommitted files.

## Documentation Index

| Order | Document | Purpose |
|---:|---|---|
| 1 | PRD (Product Requirements Document) | Product scope, requirements, roles, screens, and acceptance criteria |
| 2 | Requirements Checklist / Traceability | Requirement IDs, evidence, and evaluator checklist |
| 3 | System Architecture Document | Client layers, Firebase components, data flow, and deployment topology |
| 4 | Database Design Document | Firestore collections, fields, relationships, indexes, and counters |
| 5 | RBAC & Security Document | Authentication, role routing, Rules, ownership, field protection, threats, and security tests |
| 6 | User Flow Diagram | Customer, Agent, Admin, denial, recovery, and navigation flows |
| 7 | Request Lifecycle / State Diagram | States, transitions, actors, terminal behavior, and lifecycle tests |
| 8 | UI/UX Wireframes | Mobile/Web screens, components, responsive behavior, and accessibility |
| 9 | Testing Plan | Test levels, emulator strategy, detailed cases, CI, and exit criteria |
| 10 | README / Setup & Deployment Documentation | This repository setup, emulator, testing, deployment, and submission guide |

## Submission Checklist

- [ ] Project name is QuickServe.
- [ ] Program name is spelled Swasiq.
- [ ] Flutter mobile app exists for Customer and Agent roles.
- [ ] Flutter Web Admin portal exists for Admin role.
- [ ] Firebase Authentication email/password flow works.
- [ ] `users.role` uses only `customer`, `agent`, or `admin`.
- [ ] Customer can browse AC servicing, Plumbing, Electrical, and Cleaning.
- [ ] Customer can create a request with all finalized fields.
- [ ] Request code follows `REQ-YYYY-000123`.
- [ ] New request starts with status `created`.
- [ ] Agent queue is assignment-scoped.
- [ ] Request lifecycle follows the finalized statuses and transitions.
- [ ] Customer cancellation is limited to `created` and `assigned`.
- [ ] Firestore Rules deny cross-customer and cross-agent access.
- [ ] Customer cannot self-promote `users.role`.
- [ ] Unauthenticated protected access is denied.
- [ ] Status history and audit logs are append-only.
- [ ] Audit events use the fixed event list.
- [ ] Passwords, tokens, API keys, and secrets are not stored or logged.
- [ ] Firebase Emulator Suite runs Authentication and Firestore tests.
- [ ] Unit, widget, integration, and Rules tests are documented and runnable.
- [ ] `firestore.rules` is reviewed and tested.
- [ ] `firestore.indexes.json` is reviewed for supported queries.
- [ ] Optional Admin Web Hosting configuration is separated from emulator configuration.
- [ ] No Cloud Functions, Supabase, React, Next.js, Angular, custom claims, or paid feature is required.
- [ ] Git history contains meaningful commits and no secrets.
- [ ] Documentation set is complete and consistent.

## Limitations and Known Trade-offs

### Spark plan constraint

The Firebase Spark free plan constrains usage, query scale, and hosted resources. The application should use bounded queries, synthetic local testing, and small demonstration data. No billing account or credit card is required by the documented workflow.

### No Cloud Functions

Request-code allocation, status history, and audit writes are client-coordinated. Firestore Rules still enforce authorization, but the client cannot provide the same trusted atomic orchestration as a server-side function. The Testing Plan and RBAC & Security Document identify these limitations and require emulator coverage.

### No custom claims

Roles are resolved from `users.role` rather than custom claims. Rules protect the ordinary profile update path from self-promotion, but controlled Agent/Admin provisioning must remain outside customer self-registration. A production system should introduce a trusted role-management process.

### No FCM

FCM is not used. Local notifications may be optional and must not change authorization, lifecycle, or data behavior.

### Client-written audit and counter behavior

The client writes audit logs and status history and coordinates the request-code counter transaction. Rules limit field shapes and writes, but a trusted server would provide stronger guarantees for atomic mutation, audit completeness, counter allocation, and abuse protection.

### Production recommendations

If the project evolves beyond the internship constraints, consider custom claims, Cloud Functions or another trusted backend, server-side request-code allocation, server-side lifecycle transactions, centralized audit creation, rate limiting, and stronger observability. These recommendations are future evolution items and are not requirements for this Spark-plan assignment.

## License or Attribution

QuickServe is an internship assignment deliverable for the Swasiq Technology Internship Program — Health-tech, Nagpur.

## Open Questions and Assumptions

### Open questions

| ID | Question | Impact | Default assumption |
|---|---|---|---|
| OQ-01 | Which exact Flutter and Node versions will be pinned in the final repository? | Reproducibility and CI setup | Use the baseline versions in Prerequisites until the repository pins alternatives. |
| OQ-02 | Which Firebase project ID is authorized for optional Hosting deployment? | Hosting target selection | Use the project owner's authorized Firebase project and keep the ID out of generic documentation if private. |
| OQ-03 | What exact seed command is selected by the implementation? | Local setup repeatability | Use the documented project seed utility or Emulator import procedure without adding a new framework. |
| OQ-04 | Which supported browser and mobile devices will the evaluator use? | Manual verification matrix | Test at least one modern browser and the available Android/iOS target. |
| OQ-05 | Which Admin Web queries require composite indexes? | Index deployment | Keep `firestore.indexes.json` authoritative and add only reviewed supported queries. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | The repository structure in this document is the approved structure and no additional application folder is required. |
| ASSUMP-02 | The selected stable Flutter version is pinned by the repository before team implementation begins. |
| ASSUMP-03 | Firebase Authentication and Cloud Firestore emulators are the only required emulator services. |
| ASSUMP-04 | Test users, request data, history, audit data, and counters are synthetic. |
| ASSUMP-05 | Hosted Firebase configuration is never reused as a local emulator credential or secret store. |
| ASSUMP-06 | The Admin Web portal may be deployed to Firebase Hosting only when the project owner authorizes the target. |
| ASSUMP-07 | GitHub Actions remains optional and must not require billing or a production secret. |

## Glossary

| Term | Definition |
|---|---|
| Admin | User with stored role `admin`, using the Flutter Web Admin portal. |
| Agent | User with stored role `agent`, using Flutter mobile to manage assigned work. |
| Customer | User with stored role `customer`, using Flutter mobile to create and track requests. |
| Emulator Suite | Local Firebase Authentication and Cloud Firestore services for development and testing. |
| Firebase CLI | Command-line tool used to run emulators and deploy Rules, indexes, or Hosting. |
| Hosted mode | Application configuration that connects to the authorized Firebase project rather than local emulators. |
| Local mode | Application configuration that connects to Firebase Emulator Suite. |
| Request code | Identifier in the format `REQ-YYYY-000123`. |
| Stored role | Lowercase value in `users.role`: `customer`, `agent`, or `admin`. |
| Spark plan | Firebase free plan targeted by this assignment. |
| Synthetic data | Non-real test data created for local development and evaluation. |
| Terminal status | `completed` or `cancelled`, with no valid outgoing lifecycle transition. |

## Appendix A — Full Repository Tree {.unnumbered}

```text
QuickServe/
|-- apps/mobile/                  Flutter mobile application for Customer and Agent
|-- apps/admin/                   Flutter Web Admin portal
|-- packages/shared/              Shared Dart package for models, contracts, and reusable code
|-- firestore.rules                Firestore Security Rules source
|-- firestore.indexes.json         Firestore index declarations
|-- firebase.json                  Firebase Emulator and Hosting configuration
|-- .github/workflows/             Optional GitHub Actions workflow definitions
|-- docs/                          Companion project documentation
|-- .gitignore                     Files and folders excluded from Git
|-- README.md                      Repository entry-point documentation
```

## Appendix B — Emulator and Test Commands {.unnumbered}

All commands in this appendix are for Windows `cmd.exe`.

```cmd
cd C:\work
```

```cmd
git clone <repository-url> QuickServe
```

```cmd
cd QuickServe
```

```cmd
firebase emulators:start --only auth,firestore
```

```cmd
start http://127.0.0.1:4000
```

```cmd
cd apps\mobile
flutter pub get
flutter test
```

```cmd
cd ..\admin
flutter pub get
flutter test
```

```cmd
cd ..\..\packages\shared
flutter pub get
flutter test
```

```cmd
cd ..\..
flutter analyze
```

Integration tests run inside each Flutter project directory, not from the repository root.

```cmd
cd apps\mobile
flutter test integration_test
```

```cmd
cd ..\admin
flutter test integration_test
```

```cmd
firebase deploy --only firestore:rules
```

```cmd
firebase deploy --only firestore:indexes
```

```cmd
cd apps\admin
flutter build web --release
```

```cmd
cd ..\..
firebase deploy --only hosting
```

No command in this appendix requires Cloud Functions, a paid Firebase plan, a credit card, or a real secret.

## Appendix C - Companion Documentation Set

1. System Architecture Document
2. Database Design Document
3. RBAC & Security Document
4. README / Setup & Deployment Documentation - this document.

