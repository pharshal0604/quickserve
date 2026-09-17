---
title: "QuickServe System Architecture Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This System Architecture Document defines the technical structure, component boundaries, data flows, security model, development model, deployment model, and architectural trade-offs for QuickServe.

QuickServe is a small end-to-end Service Request Management Application created for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day challenge intended to demonstrate practical product thinking, secure backend design, clean code, and Git/GitHub discipline.

### Audience

This document is intended for:

- Flutter/Dart developers implementing the mobile application and Flutter Web portal.
- Firebase developers configuring Authentication, Firestore, Security Rules, Crashlytics, Emulator Suite, and optional Hosting.
- Reviewers evaluating architecture, security, maintainability, and technical decisions.
- Contributors maintaining the companion PRD, database, security, testing, and deployment documents.

### System scope

QuickServe provides:

- A Flutter mobile application for Customers and Service Agents.
- A Flutter Web administration portal for Administrators.
- Service browsing and service-request creation.
- Request assignment, acceptance, progress updates, completion, cancellation where eligible, notes, status history, and audit records.
- Firebase Authentication, Cloud Firestore, Firestore Security Rules, and Firebase Crashlytics where supported.
- Local Firebase Emulator Suite support for development and testing.
- Optional Firebase Hosting for the Flutter Web portal.

The baseline excludes Cloud Functions, Supabase, React, Next.js, Angular, custom Authentication claims, FCM push notifications, payments, maps, chat, ratings, attachments, and other features outside the finalized scope.

### Relationship to companion documents

The Product Requirements Document is the product baseline. The Requirements Checklist / Traceability Document maps requirements to implementation and verification. This architecture document defines the technical structure without replacing the detailed database, security, testing, wireframe, lifecycle, or deployment documents.

All companion documents must use the same roles, stored enum values, request states, collections, event names, technology decisions, and free-tier constraints.

## Architecture Goals and Principles

### Goals

1. Deliver a working Customer, Agent, and Admin experience within 5–7 days.
2. Keep all application code and UI in Flutter/Dart.
3. Use Firebase as the only backend platform.
4. Enforce authorization at the Firestore database layer.
5. Share models, enums, validators, constants, and lifecycle rules through Dart code.
6. Keep the baseline compatible with the Firebase Spark free plan.
7. Minimize system surface area and avoid unnecessary services.
8. Make request ownership, assignment, status history, and audit activity observable.
9. Keep the architecture testable with Flutter tests and Firebase Emulator Suite.

### Principles

- **Flutter-only clients:** Both mobile and web interfaces use Flutter and Dart.
- **Firebase-only backend:** Firebase Authentication and Cloud Firestore are the authoritative platform services.
- **Database-layer security:** UI visibility is not treated as authorization; Firestore Security Rules enforce access.
- **Shared domain rules:** Models, enums, validators, constants, and lifecycle transitions are shared rather than duplicated.
- **Least privilege:** Each role sees and changes only the data required for its responsibilities.
- **Append-only history:** Status history and audit records are never updated or deleted by clients.
- **Free-tier compatibility:** No billing, credit card, Blaze-only service, or Cloud Function is required.
- **Bounded operations:** Queries and reads are constrained to reduce Spark-plan usage and improve responsiveness.
- **Observable failure:** Failed operations are not presented as successful, and errors are mapped to safe messages.
- **Smallest useful architecture:** Optional services are added only when they provide clear value without weakening the baseline.

## System Context and Roles

### Roles

| Role | Primary client | Responsibilities |
|---|---|---|
| Customer | Flutter mobile | Register/login, browse services, create requests, track own requests, cancel eligible requests, manage profile/logout. |
| Agent | Flutter mobile | View assigned requests, accept work, update status, add notes, and view completed assigned work. |
| Admin | Flutter Web | Log in, view dashboard, manage requests, assign Agents, update permitted statuses, view Customers/Agents, and inspect activity. |

Stored role values are lowercase: `customer`, `agent`, and `admin`. Display labels are Customer, Agent, and Admin.

### Request lifecycle

The lifecycle is:

`created` → `assigned` → `accepted` → `in_progress` → `completed`

Eligible requests may also become `cancelled`. `completed` and `cancelled` are terminal baseline states.

### Services

The baseline service catalog contains:

- AC servicing
- Plumbing
- Electrical
- Cleaning

## High-Level Architecture

### Architecture overview

The system has two Flutter client surfaces, a shared Dart domain package, and Firebase-managed backend services. Firestore Security Rules are the authorization boundary. No custom backend server or Cloud Functions layer is used.

```text
                          Git + GitHub
                     (source, review, delivery)
                               |
                +--------------+--------------+
                |                             |
       Flutter Mobile App              Flutter Web Admin Portal
       Customer + Agent roles                  Admin role
                |                             |
                +-------------+---------------+
                              |
                    Shared Dart Package
             models, enums, validators, constants,
                    lifecycle and domain rules
                              |
                +-------------+---------------+
                |                             |
       Firebase Authentication          Cloud Firestore
       identity and sessions             application data
                |                             |
                +-------------+---------------+
                              |
                  Firestore Security Rules
             database-layer authentication/RBAC
                              |
        +---------------------+---------------------+
        |                                           |
 Firebase Crashlytics                    Firebase Emulator Suite
 crash/error monitoring                  local Auth, Firestore, Rules
        |
 Firebase Hosting (optional)
 Flutter Web deployment
```

### Architectural boundaries

- Flutter clients may call Firebase SDKs and shared Dart code.
- Shared Dart code contains domain models and deterministic validation; it does not replace backend authorization.
- Firestore Security Rules decide whether authenticated reads and writes are permitted.
- Cloud Firestore is the system of record for users, services, requests, status history, audit logs, and counters.
- Firebase Authentication is the system of record for identity and login state.
- Crashlytics receives supported crash/error information but is not a business-data store.
- Emulator Suite replaces local Firebase services during development and automated tests.
- Firebase Hosting is optional and applies only to the Flutter Web build.

## Component Descriptions

| Component | Responsibility | Inputs | Outputs | Boundary |
|---|---|---|---|---|
| Flutter Mobile App | Provides Customer and Agent screens and role-specific actions. | User input, session state, Firestore/Auth repository results. | UI state, Firebase SDK requests, safe error messages. | Must not be treated as the sole authorization layer. |
| Flutter Web Admin Portal | Provides Admin Login, dashboard, request management, user views, and activity view. | Admin input, session state, Firestore/Auth repository results. | Admin UI state and authorized Firebase SDK requests. | Accessible only after authenticated Admin routing and Rules checks. |
| Shared Dart Package | Defines models, enums, validators, constants, lifecycle transitions, and reusable domain behavior. | Plain Dart values and domain commands. | Validated models, transition decisions, formatted request code values. | Contains no secrets and cannot override Firestore Rules. |
| Presentation Layer | Renders Material 3 screens and user interactions. | Riverpod state and user gestures. | Commands/events to providers; visible states. | Depends on application/state layer, not directly on Firestore. |
| Riverpod State Layer | Coordinates session, role, services, requests, dashboard, activity, loading, and errors. | UI commands and repository streams/futures. | Immutable or controlled state exposed to widgets. | Depends on domain and repository abstractions. |
| Firebase Authentication | Registers users, authenticates credentials, persists sessions, and sends password-reset flows. | Email, password, and Auth SDK commands. | Authenticated identity/session and Auth errors. | Does not store application role authorization by custom claims. |
| Cloud Firestore | Stores application and operational records. | Authorized reads/writes from Firebase SDK. | Documents, queries, transactions, and errors. | Protected by Firestore Security Rules. |
| Firestore Security Rules | Enforces authenticated access, ownership, role permissions, field restrictions, lifecycle constraints, and append-only behavior. | Auth context, existing document, proposed write. | Allow or deny decision. | Backend authorization boundary. |
| Firebase Crashlytics | Captures supported crash/error information. | Non-secret crash and diagnostic events. | Monitoring records. | Must not receive passwords, tokens, API keys, or secrets. |
| Firebase Emulator Suite | Runs local Auth, Firestore, and Rules services. | Local Firebase configuration and test requests. | Isolated local data and test results. | Must be used for local development/testing where practical. |
| Firebase Hosting | Optionally serves the Flutter Web build. | Built Flutter Web assets and Firebase project configuration. | HTTPS-hosted Admin portal. | Optional; no requirement for production launch. |
| Git + GitHub | Stores source, history, documentation, issues, and optional workflows. | Source changes and review activity. | Versioned repository and delivery evidence. | Must not contain secrets. |

## Layered Client Architecture

### Layer model

```text
+------------------------------------------------+
| Presentation: Material 3 widgets and screens   |
+------------------------------------------------+
| State/Application: Riverpod providers          |
+------------------------------------------------+
| Domain: shared Dart models, enums, validators, |
| lifecycle transitions, constants                |
+------------------------------------------------+
| Data: Firebase Auth/Firestore repositories     |
+------------------------------------------------+
| Firebase SDK and Firestore Security Rules      |
+------------------------------------------------+
```

### Presentation layer

The Presentation layer contains Flutter widgets, screens, forms, navigation surfaces, status displays, loading states, empty states, error states, and retry controls. It uses Material 3 and must not make authorization decisions solely by hiding controls.

Required surfaces include Splash, Login, Admin Login, Registration, Home, Services, Create Request, My Requests, Request Details, Agent Request Details, Profile, Logout, Admin Dashboard, Admin Request Management, Admin Customer View, Admin Agent View, and Admin Activity/Audit View.

### State/application layer

Riverpod providers coordinate:

- Authentication/session state.
- User profile and stored role.
- Customer services and service catalog.
- Customer request creation and request lists.
- Agent assigned-request queue and completed work.
- Admin dashboard counts, request search/filtering, user views, and activity.
- Loading, empty, error, retry, and pending-submission states.

Providers depend on repository interfaces and domain services rather than directly embedding Firestore query details in widgets.

### Domain/shared Dart layer

The shared Dart package contains:

- User, Service, Request, StatusHistory, AuditLog, and Counter models.
- Role, priority, request-status, and event enums.
- Validators for required fields, text lengths, allowed values, and date/time input.
- Lifecycle transition rules.
- Request-code formatting and validation.
- Shared constants for collection paths and safe field names.

The domain layer is deterministic and testable. It does not contain credentials, secrets, or platform-specific UI code.

### Data layer

Firebase repositories encapsulate:

- Firebase Authentication calls.
- Firestore reads, writes, transactions, and batches.
- Emulator connection configuration.
- Mapping Firebase errors into application-safe result types.
- Query constraints and expected indexes.
- Audit and status-history writes where required.

The Data layer cannot grant itself access. Firestore Security Rules remain authoritative.

### Dependency direction

Dependencies flow inward:

`Presentation → Riverpod/Application → Domain abstractions → Firebase repositories → Firebase SDK`

The Domain layer must not depend on Flutter widgets. Presentation must not contain raw Firestore paths or duplicated authorization rules. Repositories must not bypass shared validation for normal application commands.

## Data Architecture

### Collections

| Collection/document | Purpose | Key fields |
|---|---|---|
| `users/{uid}` | Application profile and role lookup. | `role`, `name`, `email`, `phone`, `createdAt`, `updatedAt` |
| `services/{serviceId}` | Service catalog. | `name`, `description`, `active`, `createdAt` |
| `requests/{requestId}` | Primary service request. | `requestCode`, `customerId`, `agentId`, `serviceType`, `description`, `preferredDateTime`, `address`, `priority`, `status`, `createdAt`, `updatedAt`, `cancellationReason` |
| `requests/{requestId}/status_history/{historyId}` | Append-only request transition history. | `fromStatus`, `toStatus`, `changedBy`, `changedAt`, `note` |
| `audit_logs/{logId}` | Append-only operational/security activity. | `actorUserId`, `actorRole`, `action`, `targetType`, `targetId`, `oldValue`, `newValue`, `result`, `timestamp` |
| `counters/{year}` | Year-scoped request-code counter. | `lastRequestNumber` |

### Stored values

- Roles: `customer`, `agent`, `admin`.
- Priorities: `low`, `medium`, `high`.
- Statuses: `created`, `assigned`, `accepted`, `in_progress`, `completed`, `cancelled`.
- Events: `LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, `DATABASE_ERROR`.

### Data integrity

- Request codes are generated transactionally and must be unique per year.
- `customerId` identifies the request owner.
- `agentId` is empty/null until assignment and must identify an eligible Agent when populated.
- Status history records are never overwritten.
- Audit records are never updated or deleted by clients.
- Required composite indexes are committed after actual dashboard and operational queries are finalized.
- Display-name snapshots, if used, are convenience data; referenced user documents remain authoritative.

## Data Flow Walkthroughs

### Registration and first login

1. The user opens the Flutter mobile Registration screen.
2. The user enters name, email, phone, password, and any required confirmation field.
3. Shared validators reject missing or invalid values before the network call.
4. The Auth repository calls Firebase Authentication to create the account.
5. The application creates `users/{uid}` with profile fields, timestamps, and stored role `customer`.
6. Firestore Rules verify that the authenticated user can create their own profile and cannot self-assign an elevated role.
7. The application loads the profile and routes the user to Customer Home.
8. On later login, Firebase Authentication returns the authenticated identity and the application reads `users/{uid}` to resolve role routing.

Agent and Admin accounts are created through a controlled setup process because there is no Cloud Function or custom-claims provisioning service.

### Session restore and role routing

1. The application starts in Splash/loading state.
2. Firebase Authentication reports the current session.
3. If there is no session, the router sends the user to Login or Registration.
4. If a session exists, the application reads `users/{uid}`.
5. The stored role is validated against `customer`, `agent`, or `admin`.
6. The router sends the user to Customer Home, Agent work queue, or Admin Web Dashboard.
7. If the profile is missing or invalid, privileged navigation stops and a recoverable configuration/account error is shown.
8. Firestore Rules continue to enforce access for every later read/write.

### Customer creates a request

1. The Customer opens Services and selects a service.
2. The Customer opens Create Request and enters description, preferred date/time, address, and priority.
3. Shared validators check required fields and controlled values.
4. The request repository begins a Firestore transaction involving `counters/{year}`.
5. The transaction reads the current `lastRequestNumber` for the current year.
6. The transaction increments the counter and formats the code as `REQ-YYYY-000123`.
7. The transaction creates the request with status `created`, authenticated `customerId`, empty/null `agentId`, and timestamps.
8. The transaction creates the initial audit record or required related write according to the implementation’s atomic-write policy.
9. Firestore Security Rules validate identity, ownership, controlled fields, and permitted creation behavior.
10. The application shows the created request code and refreshes My Requests.
11. On transaction conflict, Firestore retries according to the bounded retry strategy. If retries fail, the UI shows a retryable error and does not claim success.

### Admin assigns an Agent

1. The Admin signs in through Admin Login.
2. The Admin opens Request Management and selects an eligible request in status `created`.
3. The Admin selects an eligible Agent.
4. The application verifies the proposed assignment and permitted transition.
5. A Firestore transaction or batch updates `agentId` and status to `assigned`.
6. The operation creates a status-history record with `fromStatus: created`, `toStatus: assigned`, and the Admin identity.
7. The operation creates an `REQUEST_ASSIGNED` audit record with safe old/new values.
8. Firestore Rules verify Admin role, permitted fields, Agent eligibility, and transition validity.
9. The Admin UI refreshes the request. The assigned Agent sees it in the assigned queue.

### Agent accepts and completes a request

1. The assigned Agent opens the Agent work queue.
2. The Agent opens Agent Request Details for a request in status `assigned`.
3. The Agent selects Accept.
4. Firestore Rules confirm that `request.agentId == request.auth.uid` and the transition is valid.
5. The request changes to `accepted`; status history and audit activity are written.
6. The Agent starts work and changes status to `in_progress`, optionally adding a note.
7. The Agent completes work and changes status to `completed`, optionally adding a note.
8. Each transition writes status history and the appropriate `REQUEST_UPDATED` audit record.
9. The Agent can view completed work assigned to that Agent. Other Agents cannot read or update the request.

### Customer cancels an eligible request

1. The Customer opens Request Details for an own request.
2. The application determines whether the current status is eligible for Customer cancellation.
3. The Customer enters a cancellation reason and confirms.
4. Shared lifecycle rules validate the transition.
5. Firestore Rules validate ownership, eligibility, permitted fields, and cancellation reason.
6. The request changes to `cancelled` and stores `cancellationReason`.
7. Status history and audit activity are written.
8. The Customer sees the terminal cancelled state. The request cannot be resumed in the baseline.

**Assumption A-01:** The baseline permits Customer cancellation before acceptance, subject to the finalized lifecycle policy. If implementation policy differs, the PRD, Rules, tests, and UI must be updated together.

### Authorization denial: cross-customer access attempt

1. Customer A attempts to query or open Customer B’s request.
2. The Flutter UI may prevent the action, but the request is still treated as untrusted.
3. Firestore Security Rules compare the authenticated UID with the request’s `customerId`.
4. Rules deny the read or write.
5. The repository maps the permission error to a safe message.
6. Where appropriate, the client records `AUTHORIZATION_FAILED` without exposing Customer B’s data.
7. The authorization test confirms that the operation fails through the Emulator Suite even if the UI is bypassed.

## Security Architecture

### Authentication

Firebase Authentication with email/password is the baseline identity provider. It handles registration, login, logout, session persistence, and password reset. Passwords are never stored in Firestore and must never appear in application logs.

### Role-based authorization

The application role is stored in `users/{uid}.role` using lowercase values. Firestore Security Rules read the authenticated user identity and the profile role to enforce permissions.

Because custom claims and Cloud Functions are excluded, role management is sensitive. The deployment/setup process must ensure that only a trusted operator can create or promote Agent/Admin profiles. A normal user must not be able to update their own role from `customer` to `agent` or `admin`.

### Request ownership

- Customers may create requests only with their own authenticated UID as `customerId`.
- Customers may read and update only their own permitted requests.
- Agents may read and manage only requests where `agentId` equals the authenticated UID.
- Admins may read and manage permitted operational data.
- No UI control is considered a security boundary without matching Rules.

### Field and transition protection

Rules should validate:

- Authenticated identity.
- Stored role values.
- Ownership and assignment.
- Allowed fields for each actor.
- Controlled priority and status values.
- Valid lifecycle transitions.
- Prohibition on customer ownership changes by Agents.
- Prohibition on self-promotion through `users.role`.
- Counter access limited to the request-code transaction pattern where feasible.

### Append-only history and audit records

Status history and audit logs are client-written because Cloud Functions are excluded. Rules must permit only authorized creates and must deny updates and deletes. Client-provided actor IDs, roles, timestamps, status changes, and old values must be checked against authenticated identity and existing documents wherever feasible.

### Why client-side business logic is acceptable here

Client-side business logic is an explicit constraint of the Spark/no-Cloud-Functions assignment. The architecture reduces risk by:

- Keeping deterministic models, validators, and transitions in shared Dart code.
- Repeating access-critical checks in Firestore Security Rules.
- Using Firestore transactions/batches for related writes.
- Testing Rules independently through the Emulator Suite.
- Documenting that the client is not trusted for authorization.

This is suitable for the internship demonstration but is not equivalent to a full server-side domain service for a production-scale system.

### Secret handling

Never log or commit:

- Passwords.
- Authentication tokens.
- API keys.
- Private credentials.
- Secrets embedded in configuration.

Crashlytics and audit payloads must use safe, minimal diagnostic fields.

## Request-Code Generation Architecture

### Counter model

Each calendar year uses one document:

`counters/{year}`

with:

`lastRequestNumber`

### Transaction sequence

1. Determine the current year in the application’s defined operating timezone.
2. Begin a Firestore transaction.
3. Read `counters/{year}`.
4. Use `0` when the counter does not yet exist.
5. Increment the number by one.
6. Write the new counter value in the same transaction.
7. Format `REQ-YYYY-000123` using the year and six-digit sequence.
8. Create the request using the generated code in the same transaction where supported.
9. Commit the transaction.

### Duplicate avoidance

Firestore transaction retries protect against concurrent updates to the same counter document. A failed transaction must not be reported as a successful request. The application must not generate a second request code after an uncertain write without first determining whether the original transaction committed, where the SDK and implementation permit that check.

### Trade-offs

A single yearly counter is simple and suitable for the assignment. It may become a contention point at high write volume, but that scale is outside the 5–7 day challenge. The design avoids Cloud Functions and remains compatible with the Spark plan.

## Local Development and Testing Architecture

### Emulator Suite

The Firebase Emulator Suite provides local versions of:

- Firebase Authentication.
- Cloud Firestore.
- Firestore Security Rules evaluation.

The local environment should seed representative services, users, roles, Agents, Customers, requests, histories, and audit records without using production data.

### Flutter emulator configuration

The Flutter application should use a clearly documented development configuration that:

- Connects Firebase Authentication to the Auth emulator.
- Connects Firestore to the Firestore emulator.
- Uses a local Firebase project identifier or documented emulator project configuration.
- Makes it clear when emulator mode is active.
- Prevents accidental use of production data during local tests.

### Rules testing

Rules tests should create authenticated emulator users with representative profiles and verify:

- Customer access to own requests.
- Customer denial for another Customer’s request.
- Agent access only to assigned requests.
- Agent denial for another Agent’s request.
- Admin access to permitted operational data.
- Customer/Agent denial of unauthorized role promotion.
- Append-only status history and audit logs.
- Counter restrictions and controlled fields where covered by the Rules design.

### Test layers

- `flutter_test` for domain and widget tests.
- `integration_test` for complete application flows.
- Firebase Emulator Suite for Auth, Firestore, and Rules tests.
- Repository/code review for architecture, secret handling, and documentation.

## Deployment Architecture

### Firebase project configuration

The project configuration should document:

- Firebase project identifier.
- Authentication provider configuration.
- Firestore database configuration.
- Firestore Security Rules deployment.
- Firestore indexes.
- Crashlytics configuration where supported.
- Optional Storage configuration only if a later approved need exists.
- Emulator configuration for local development.

The baseline must remain on Firebase Spark. No billing account or credit card is required.

### Flutter Web deployment

Firebase Hosting is optional for the Flutter Web Admin portal:

1. Build the Flutter Web target.
2. Configure Firebase Hosting for the generated web directory.
3. Deploy static assets through Firebase Hosting.
4. Verify Admin Login, route guards, Firestore access, and responsive layout.

A deployed URL is useful for demonstration but is not required if a local walkthrough is available.

### Mobile build delivery

The mobile application may be delivered through:

- Android APK or development device run.
- iOS development build where available.
- A recorded or live walkthrough if platform distribution is impractical.

App Store submission and mandatory production distribution are out of scope.

### Environment handling

Development, emulator, and optional hosted environments must be distinguishable. Secrets must not be committed. Environment configuration should be documented through safe templates or setup instructions.

## Technology Decisions and Trade-offs

| Decision | Alternatives | Rationale | Consequences |
|---|---|---|---|
| Flutter + Dart for mobile and web | Native Android/iOS, React, Next.js, Angular | One language and UI toolkit satisfies the Flutter-only constraint and enables shared code. | Flutter Web responsiveness and platform differences require testing. |
| Firebase over Supabase | Supabase or custom backend | Firebase Authentication, Firestore, Rules, Emulator Suite, Crashlytics, and Hosting fit the assignment. | Firestore query/data modeling and Rules syntax require careful design. |
| Firestore Security Rules over Cloud Functions | Cloud Functions, custom API | Rules provide database-layer authorization without Blaze billing. | Complex cross-document business logic remains client-side and must be carefully constrained. |
| `users.role` over custom claims | Firebase custom claims | Custom claims would require a trusted server-side provisioning path; the assignment excludes Cloud Functions. | Role documents are security-sensitive and require controlled setup. |
| No Cloud Functions | Cloud Functions or another backend | Required by Spark free-tier and no-billing constraints. | No trusted server triggers, scheduled tasks, or server-side request-code service. |
| Client-side logic with database enforcement | Central application server | Satisfies the assignment while Rules protect data access. | Client logic can be inspected or tampered with; Rules must independently enforce security. |
| Crashlytics where supported | Other monitoring tools | Included in finalized Firebase stack and useful for supported targets. | Platform support and configuration limitations must be documented. |
| Local notifications instead of FCM | FCM push notifications | FCM is skipped for the demo to reduce scope and service dependencies. | No remote push notification workflow in the baseline. |
| Optional GitHub Actions | No CI, paid CI platform | Simple Actions can improve repeatability without changing application architecture. | Optional workflow maintenance; must not require paid services. |
| Firebase Hosting optional | Other web hosting | Natural deployment path for Flutter Web and Firebase project. | Hosting deployment is not required for baseline completion. |

## Non-Functional Architecture Considerations

### Security

Security is enforced at the Firestore Rules layer. Authentication identifies users, stored roles determine permitted role behavior, and ownership/assignment checks protect request data. Secrets are excluded from logs, audit records, source control, and Crashlytics payloads.

### Performance

The application should use bounded queries, appropriate indexes, limited result sets, and role-specific reads. Dashboard counts should avoid unnecessary full-collection reads. Request history and audit views should avoid unbounded loading.

### Reliability

Transactions protect request-code generation and related request writes. Failed writes return explicit failure states. Related request, history, and audit writes should use transactions or batches where feasible.

### Maintainability

Shared Dart models and rules reduce duplication. Repositories isolate Firebase APIs. Riverpod providers isolate state coordination. Requirements, architecture, database, security, testing, and README documents use consistent terminology.

### Testability

Pure Dart validators and lifecycle rules are unit-testable. Widgets are testable without production Firebase. Rules are testable through Emulator Suite. End-to-end flows are testable through integration tests.

### Cost

The baseline does not require billing, a credit card, Cloud Functions, FCM, or a paid monitoring/service platform. Emulator Suite reduces development dependence on production resources.

### Accessibility and responsiveness

Material 3 components, readable contrast, sensible text sizes, and semantic controls should be used. Flutter Web layouts must be tested at practical desktop and narrower browser widths.

## Architectural Risks and Mitigations

| Risk | Architectural impact | Mitigation |
|---|---|---|
| Firestore Rules complexity | Incorrect Rules could expose data or block valid workflows. | Write Rules tests early for every role, ownership condition, transition, and append-only collection. |
| Client-side role tampering | A user could attempt to promote themselves or impersonate another role. | Protect `users.role` in Rules, use controlled Agent/Admin setup, and test self-promotion denial. |
| Client-side business logic tampering | A modified client could submit invalid status or field changes. | Validate in shared Dart and independently validate authorization, fields, and transitions in Rules. |
| Counter contention | Concurrent request creation could conflict or fail. | Use Firestore transaction retry behavior, bounded retries, and failure-safe UX. |
| Spark-plan limits | Unbounded reads or optional services could create cost or quota issues. | Bound queries, avoid Cloud Functions/FCM, use Emulator Suite, and remain on Spark. |
| Flutter Web responsiveness | Admin tables and filters may be difficult on narrower screens. | Use responsive layouts, bounded lists, simple filters, and test desktop/narrow widths. |
| Missing audit/history writes | Operational actions could become difficult to trace. | Use transaction/batch writes where feasible, append-only Rules, and explicit failure policy. |
| Platform monitoring differences | Crashlytics behavior may differ across targets. | Document supported targets and treat unsupported monitoring as a known limitation. |

## Open Questions and Assumptions

### Open questions

1. What exact maximum lengths should be applied to request descriptions, addresses, names, and notes?
2. Which exact Firestore composite indexes are required after final dashboard and filter queries are implemented?
3. Should the implementation block a successful business write when a required audit/history write fails, or use a documented best-effort policy for specific diagnostic events?
4. What exact controlled setup procedure will create Agent and Admin profiles without allowing self-promotion?
5. Which mobile target, Android, iOS, or both, will be used for the final walkthrough?
6. Will the optional Flutter Web deployment use Firebase Hosting or a local walkthrough only?

### Assumptions

- New registrations create `customer` profiles.
- Agent and Admin profiles are created through a trusted setup process.
- The demo represents one organization and operational geography.
- Customer cancellation is permitted only for lifecycle-eligible requests, assumed to be before acceptance unless the approved product policy states otherwise.
- Exact query indexes are finalized from implemented queries.
- Crashlytics is configured where supported by the target platform.
- Optional features are not allowed to delay baseline completion.

## Glossary

| Term | Definition |
|---|---|
| Atomic write | A transaction or batch operation that commits related writes together or not at all. |
| Audit trail | Append-only record of significant actors, actions, targets, results, and timestamps. |
| Agent | Service worker who manages requests assigned to that Agent. |
| Customer | User who browses services and creates/tracks service requests. |
| Firestore Security Rules | Backend-enforced conditions controlling access to Firestore data. |
| RBAC | Role-Based Access Control; permissions are determined by Customer, Agent, or Admin role. |
| Request code | Human-readable identifier such as `REQ-2026-000123`. |
| Session persistence | Retaining a valid Firebase Authentication session across app restarts according to platform behavior. |
| Spark plan | Firebase free plan used by the project; no billing or credit card. |
| Status history | Append-only record of request lifecycle transitions. |
| Emulator Suite | Local Firebase services used for development and testing. |

## Appendix A — Architecture Diagram {.unnumbered}

Refer to the “Architecture overview” subsection of the “High-Level Architecture” section for the full visual representation of the QuickServe architecture.

## Appendix B — Component Responsibility Matrix {.unnumbered}

| Component | Owns | Does not own | Primary verification |
|---|---|---|---|
| Flutter Mobile | Customer and Agent UI, role-specific actions, form states, mobile navigation | Final authorization decision | Widget, integration, and walkthrough tests |
| Flutter Web Portal | Admin UI, dashboard, request operations, user/activity views | Final authorization decision | Web integration and walkthrough tests |
| Shared Dart Package | Models, enums, validators, constants, lifecycle rules | Firebase credentials or UI rendering | Unit tests and code review |
| Riverpod | Application/session/request/dashboard/activity state | Persistent data authority | Widget and integration tests |
| Firebase Auth | Identity, credential authentication, sessions, password reset | Application role authorization | Auth tests and emulator run |
| Firestore | Persistent application and operational data | UI presentation | Repository tests and emulator inspection |
| Security Rules | Database authorization, ownership, field restrictions, append-only behavior | Rich server-side workflows | Rules tests |
| Crashlytics | Supported crash/error monitoring | Business records or audit trail | Configuration review |
| Emulator Suite | Local Firebase services and isolated test data | Production deployment | Local test run |
| Firebase Hosting | Optional static Flutter Web hosting | Mobile distribution | Hosting deployment review |
| Git/GitHub | Source history, collaboration, documentation, optional CI | Runtime business behavior | Repository review |

## Appendix C — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document — this document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.

The companion documents must use the same roles, states, collections, stored enum values, events, framework decisions, and billing constraints.

## Appendix D — Architecture Verification Checklist {.unnumbered}

- [ ] Flutter Mobile App supports Customer and Agent experiences.
- [ ] Flutter Web Admin Portal requires Admin authentication.
- [ ] Shared Dart Package contains models, enums, validators, constants, and lifecycle rules.
- [ ] Firebase Authentication handles identity, sessions, and password reset.
- [ ] Cloud Firestore contains the documented collections and fields.
- [ ] Firestore Security Rules enforce RBAC and ownership.
- [ ] Status history and audit logs are append-only for clients.
- [ ] Request-code generation uses a transaction on `counters/{year}`.
- [ ] Firebase Emulator Suite supports local Auth, Firestore, and Rules testing.
- [ ] Firebase Hosting is optional for Flutter Web.
- [ ] No Cloud Functions, paid services, or non-Flutter UI frameworks are required.
- [ ] Crashlytics configuration is documented where supported.
- [ ] Architecture, database, security, testing, and README documents are consistent.
