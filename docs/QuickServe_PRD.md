---
title: "QuickServe Product Requirements Document (PRD)"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

**Project:** QuickServe  
**Document type:** Product Requirements Document  
**Program:** Swasiq Technology Internship Program — Health-tech, Nagpur  
**Assignment:** Full-Stack Mobile Application — Intern Technical Assignment  
**Challenge duration:** 5–7 days  
**Status:** Implementation-ready baseline  
**Version:** 1.0  
**Date:** 17 September 2026

> **Source and decision boundary.** This PRD consolidates the supplied internship assignment and the finalized project decisions. It is intentionally limited to Flutter/Dart, Firebase, Firestore Security Rules, and the Firebase Spark plan. Items labeled **Assumption** are implementation defaults where the brief did not specify a value; they should be confirmed only if they materially affect delivery.

## Executive Summary

QuickServe is a small end-to-end Service Request Management Application for customers, service agents, and administrators. Customers use a Flutter mobile app to browse services, submit requests, track progress, and cancel eligible requests. Service agents use the same mobile application with role-specific access to view assigned work, accept requests, update progress, add notes, and review completed work. Administrators use a Flutter Web portal to monitor operations, assign agents, manage requests, inspect customers and agents, and review activity.

The product exists as a 5–7 day technical internship challenge for Swasiq Technology Internship Program. Its purpose is to demonstrate practical product thinking, secure backend design, clean and maintainable code, and disciplined Git/GitHub practices. The implementation must be functional, demonstrable, and secure at the database layer without relying on paid Firebase services or Cloud Functions.

## Goals and Objectives

### Product goals

1. Enable a customer to create and track a service request end to end.
2. Enable an agent to manage only work assigned to that agent.
3. Enable an administrator to operate the request queue from a web portal.
4. Make request state, ownership, history, and audit activity observable.
5. Demonstrate backend-enforced RBAC using Firestore Security Rules.

### Assignment objectives

The solution should demonstrate:

- Practical product thinking and clear role-based workflows.
- Secure Firebase Authentication and Firestore authorization.
- Clean Flutter/Dart architecture shared across mobile and web.
- Sensible validation, error handling, logging, and testing.
- A professional GitHub repository, README, architecture documentation, and walkthrough.
- Delivery within the 5–7 day challenge using only free-tier-compatible capabilities.

## Target Users and Personas

| Persona | Description | Primary needs | Success outcome |
|---|---|---|---|
| Customer | A person requesting AC servicing, plumbing, electrical, or cleaning. | Quickly submit an accurate request, see status, and know what happens next. | Request is created successfully and its latest status is understandable. |
| Service Agent | A worker responsible for assigned service requests. | See assigned work, accept it, update progress, add notes, and review completed work. | Can manage assigned work without accessing other agents’ requests. |
| Administrator | An operations user managing the service queue. | View operational totals, assign agents, update requests, inspect users, and review activity. | Can supervise the complete request lifecycle with traceable changes. |

**Assumption A-01:** The demo uses one organization and one operational geography. Multi-branch, territory, pricing, and vendor-management behavior is not required.

## Scope

### In scope

- Flutter mobile app for Android and/or iOS.
- Flutter Web administration portal.
- Shared Dart models, enums, validators, constants, and domain rules.
- Firebase Authentication: registration, login, logout, session persistence, password reset.
- Cloud Firestore data model and Firestore Security Rules.
- Customer, Agent, and Admin roles stored in `users/{uid}.role`.
- Service browsing for AC servicing, plumbing, electrical, and cleaning.
- Request creation, assignment, status updates, cancellation where eligible, notes, status history, and audit records.
- Admin dashboard, request management, customer/agent views, and activity information.
- Client-side logging of meaningful events with rule-protected append-only records.
- Firebase Crashlytics for crash/error monitoring where supported by the target platform.
- Firebase Storage only if a later in-scope need requires it; no file-upload feature is required for the baseline. **Baseline does not require file upload; Storage may be enabled later without changing the core model.**
- Firebase Emulator Suite for local testing.
- Unit, widget, integration, and authorization-focused tests where practical.
- GitHub repository, README, architecture diagram, database/security documentation, setup instructions, and test credentials.
- Optional Firebase Hosting deployment for the web portal.

### Out of scope

- Cloud Functions, callable functions, scheduled functions, triggers, or any other server-side function.
- Firebase Blaze/pay-as-you-go billing, credit-card use, or paid services.
- Supabase, React, Next.js, Angular, or other UI frameworks.
- Custom Firebase Authentication claims; role enforcement uses the Firestore `users.role` field and Security Rules.
- FCM push notifications. Local notifications may be used for the demo but are not required.
- Online payments, invoices, pricing, refunds, coupons, subscriptions, or financial records.
- Provider onboarding, payroll, ratings, reviews, chat, maps, GPS tracking, or route optimization.
- Attachments, photos, signatures, or document uploads in the baseline.
- Multi-tenant organizations, branch-level permissions, localization, and advanced analytics.
- Production-grade availability, compliance certification, or a public customer launch.
- Mandatory native iOS distribution or App Store submission.

## Users, Roles, and Capability Matrix

| Capability | Customer | Agent | Admin |
|---|---:|---:|---:|
| Register | Yes | Admin-provisioned or existing account; assumption | Admin-provisioned or existing account; assumption |
| Login/logout/password reset | Yes | Yes | Yes |
| Browse active services | Yes | Optional read-only; assumption | Yes |
| Create request | Yes | No | Yes |
| View own requests | Yes | Assigned requests only | Yes |
| View all requests | No | No | Yes |
| Cancel eligible request | Yes, own request | No | Yes, operationally permitted |
| Accept assigned request | No | Yes | No; admin assigns and manages status |
| Update assigned request status | No | Yes, allowed transitions only | Yes, permitted operational transitions |
| Add request notes | No | Yes on assigned requests | Yes on operational requests |
| Assign agent | No | No | Yes |
| View customers and agents | No | No | Yes |
| View audit/activity information | No | No | Yes |

**Assumption A-02:** New registrations create Customer accounts. Agent and Admin accounts are created or promoted through a controlled setup process documented in the README because there is no Cloud Function or separate provisioning service in scope.

## Functional Requirements

### Authentication and session requirements

- **FR-AUTH-01:** The system shall allow a user to register with name, email, phone, and password.
- **FR-AUTH-02:** Registration shall create a Firebase Authentication account and a corresponding `users/{uid}` document with role `customer` unless the controlled setup process specifies another role.
- **FR-AUTH-03:** The system shall allow users to log in with email and password.
- **FR-AUTH-04:** The system shall allow users to log out.
- **FR-AUTH-05:** The system shall restore a valid Firebase session on app start and route the user to the appropriate role experience.
- **FR-AUTH-06:** The system shall provide password-reset initiation through Firebase Authentication.
- **FR-AUTH-07:** Successful login shall record `LOGIN_SUCCESS` without recording passwords, tokens, or secrets.
- **FR-AUTH-08:** Failed or unauthorized operations shall show a safe user-facing message and may record `AUTHORIZATION_FAILED` without sensitive data.
- **FR-AUTH-09:** A user whose Authentication account exists but whose `users/{uid}` profile is unavailable or invalid shall receive a recoverable error state rather than being granted access.

### Customer requirements

- **FR-C-01:** A customer shall see a splash/loading state while authentication and profile state are resolved.
- **FR-C-02:** A customer shall access Home and Services screens after successful login.
- **FR-C-03:** Services shall show active services: AC servicing, plumbing, electrical, and cleaning.
- **FR-C-04:** A customer shall create a request with service type, description, preferred date/time, address, and priority.
- **FR-C-05:** Priority shall be one of `low`, `medium`, or `high`.
- **FR-C-06:** The system shall validate required fields, valid date/time input, and reasonable text lengths before writing.
- **FR-C-07:** A successful request shall receive a unique display code in the format `REQ-YYYY-000123`, generated using a Firestore transaction on `counters/{year}`.
- **FR-C-08:** A new request shall start in `created` with `customerId` set to the authenticated user and `agentId` empty/null.
- **FR-C-09:** The customer shall see a My Requests list containing only requests owned by that customer.
- **FR-C-10:** The customer shall open Request Details and see request code, service, description, preferred schedule, address, priority, current status, notes permitted for the customer view, and visible status history.
- **FR-C-11:** The customer shall be able to cancel only an eligible own request. The app shall require a cancellation reason.
- **FR-C-12:** The customer shall not be able to read, update, or cancel another customer’s request, even if a request ID is manually supplied.
- **FR-C-13:** The customer shall access Profile and safely log out.

### Agent requirements

- **FR-A-01:** An authenticated Agent shall see an agent home/work queue rather than customer-only request creation as the primary action.
- **FR-A-02:** An Agent shall read only requests assigned to that Agent.
- **FR-A-03:** An Agent shall accept an assigned request when its current status is `assigned`.
- **FR-A-04:** An Agent shall update an assigned request through permitted workflow states, including `in_progress` and `completed`.
- **FR-A-05:** The app shall prevent an Agent from selecting an invalid transition and Security Rules shall reject it if attempted directly.
- **FR-A-06:** An Agent shall add operational notes to an assigned request.
- **FR-A-07:** An Agent shall view completed work from requests assigned to that Agent.
- **FR-A-08:** An Agent shall not assign requests, view all requests, modify another Agent’s assignment, or edit customer ownership.

### Administrator requirements

- **FR-AD-LOGIN-01:** The Admin shall log in with email/password before accessing the Flutter Web administration portal.
- **FR-AD-01:** An authenticated Admin shall access a Flutter Web portal with a dashboard.
- **FR-AD-02:** The dashboard shall show total, new, assigned, in-progress, completed, and cancelled request counts. New = status `created`.
- **FR-AD-03:** The Admin shall search requests using request code and available operational text fields.
- **FR-AD-04:** The Admin shall filter requests by status, service type, priority, assigned agent, and relevant date where supported by the indexed query design.
- **FR-AD-05:** The Admin shall open request details and view customer, agent, service, status, timestamps, notes, and status history.
- **FR-AD-06:** The Admin shall assign an eligible Agent to a request and the system shall record `REQUEST_ASSIGNED` plus a status-history entry.
- **FR-AD-07:** The Admin shall update request status only through permitted operational transitions and the system shall record `REQUEST_UPDATED` plus status history when applicable.
- **FR-AD-08:** The Admin shall view customer records and agent records with appropriate non-secret profile fields.
- **FR-AD-09:** The Admin shall view basic audit/activity records, including actor, action, target, result, and timestamp.
- **FR-AD-10:** The Admin shall not see passwords, authentication tokens, API keys, or other secrets.

### Screen requirements

| Screen | Required behavior |
|---|---|
| Splash | Resolve session/profile state and route to login, registration, customer app, agent work queue, or admin portal. |
| Login | Email/password validation, submit, loading, safe error, password reset link. |
| Admin Login | Separate Flutter Web login screen; email/password validation, submit, loading, safe error, and password reset link before portal access. |
| Registration | Name, email, phone, password, confirmation/validation, account creation. |
| Home | Role-specific entry point; customer service/request actions or agent work queue. |
| Services | Active service catalog and service descriptions. |
| Create Request | Required request fields, validation, submission, generated request code confirmation. |
| My Requests | Customer-owned request list with loading, empty, error, and refresh states. |
| Request Details | Request data, current status, lifecycle/history, permitted actions, notes, cancellation when eligible. |
| Agent Request Details | Agents reuse Request Details with role-specific actions for accept, status update, and notes. |
| Profile | Current profile fields, role display as appropriate, logout. |
| Admin Dashboard | Operational request totals and navigation to request/user/activity views. |
| Admin Request Management | Search, filters, list/table, details, assignment, status management. |
| Admin Customer/Agent Views | Basic searchable/list views of non-secret users. |
| Admin Activity | Basic audit log listing/detail. |

Logout is an action available from Profile/Home; it is listed as a screen for traceability.

### Cross-cutting behavior

- **FR-X-01:** All writes shall set `createdAt` and/or `updatedAt` using trusted Firestore server timestamps where available.
- **FR-X-02:** A request status change shall create a status-history record and update the parent request atomically where the client can safely use a Firestore transaction/batch.
- **FR-X-03:** Business rules shall be implemented in shared Dart domain logic where practical and independently enforced in Firestore Security Rules for protected data access.
- **FR-X-04:** Lists shall provide loading, empty, error, retry, and pagination/limited-result behavior as needed to remain usable on the free tier. Pagination is optional for the challenge but the design shall avoid unbounded reads.
- **FR-X-05:** Navigation shall use `go_router`; state management shall use Riverpod; UI shall use Material 3.

## Request Lifecycle and State Rules

### States

`created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`.

### Required transitions

| Current state | Allowed next state | Actor(s) | Required behavior |
|---|---|---|---|
| `created` | `assigned` | Admin | Must set an eligible `agentId`; record assignment and history. |
| `created` | `cancelled` | Customer (own request), Admin | Require/retain cancellation reason; record history and audit. |
| `assigned` | `accepted` | Assigned Agent | Only that assigned Agent may accept. |
| `assigned` | `cancelled` | Admin; customer only if product policy permits before acceptance | Assumption A-03: customer may cancel before acceptance; confirm in implementation. |
| `accepted` | `in_progress` | Assigned Agent, Admin | Record actor, timestamp, and optional note. |
| `in_progress` | `completed` | Assigned Agent, Admin | Record completion transition and optional note. |
| `accepted` | `cancelled` | Admin | Operational cancellation with reason. |
| `in_progress` | `cancelled` | Admin only | Exceptional operational cancellation with reason. |
| `completed` | none | — | Terminal state for baseline. |
| `cancelled` | none | — | Terminal state for baseline. |

The client shall not present invalid actions. Firestore Rules shall reject invalid status, ownership, or actor combinations. Every transition shall preserve prior history and shall not overwrite existing history records.

## Data Model Summary

| Collection/document | Key fields | Purpose and rules |
|---|---|---|
| `users/{uid}` | `role`, `name`, `email`, `phone`, `createdAt`, `updatedAt` | Profile and role lookup. `role` is `customer`, `agent`, or `admin`. No password storage. |
| `services/{serviceId}` | `name`, `description`, `active`, `createdAt` | Service catalog. Baseline services are AC servicing, plumbing, electrical, and cleaning. |
| `requests/{requestId}` | `requestCode`, `customerId`, `agentId`, `serviceType`, `description`, `preferredDateTime`, `address`, `priority`, `status`, `createdAt`, `updatedAt`, `cancellationReason` | Primary request record. `requestCode` is user-facing; document ID may be generated independently. |
| `requests/{requestId}/status_history/{historyId}` | `fromStatus`, `toStatus`, `changedBy`, `changedAt`, `note` | Append-only lifecycle history. |
| `audit_logs/{logId}` | `actorUserId`, `actorRole`, `action`, `targetType`, `targetId`, `oldValue`, `newValue`, `result`, `timestamp` | Append-only operational/security activity. Values must exclude secrets. |
| `counters/{year}` | `lastRequestNumber` | Counter used by transaction to generate request codes. |

### Data constraints and indexes

- `requestCode` shall be unique for the year by the counter transaction.
- `customerId` and `agentId` shall contain valid user IDs where populated.
- `status`, `priority`, and role fields shall use controlled enum values.
- `createdAt`, `updatedAt`, `preferredDateTime`, and event timestamps shall use consistent Firestore timestamp representation.
- Required composite indexes shall be committed in the Firebase configuration and documented in setup instructions. **Assumption A-04:** The exact index set will be finalized from implemented dashboard/request queries and tested in the Emulator Suite.
- Denormalized display names may be used only as convenience snapshots; authoritative identity remains the referenced user document.

## Authentication and Authorization

### Authentication

Firebase Authentication with email/password is the baseline. Session persistence is enabled for supported platforms. Password reset uses Firebase’s built-in reset flow. No password is stored in Firestore or application logs.

### Firestore Security Rules principles

- Access requires an authenticated Firebase user unless a documented public read is intentionally required.
- A user may read/update permitted fields on their own profile but may not self-promote from Customer to Agent/Admin.
- Customers may create requests with their own `customerId`, read only their own requests/history, and update only explicitly permitted fields on eligible own requests.
- Agents may read requests where `agentId == request.auth.uid` and may update only permitted operational fields on assigned requests.
- Admins may read and manage permitted operational data across users, services, requests, histories, and audit views.
- Status history and audit logs are append-only from the client: create may be allowed for authorized actors, while update and delete are denied.
- Client-provided actor IDs, roles, timestamps, status changes, and old values shall be validated against the existing document and authenticated user wherever feasible.
- Counter writes shall be narrowly scoped to the request-code transaction pattern; direct arbitrary counter manipulation shall be denied.
- Rules shall prevent cross-customer reads and cross-agent updates even if UI controls are bypassed.

**Constraint:** Because there are no custom claims or Cloud Functions, the user-role document is security-sensitive. The deployment/setup process must ensure that only a trusted administrator can create or change Agent/Admin role records. For the demo, this may be performed through controlled Emulator/Firestore setup scripts or a documented restricted operator procedure.

## Logging and Audit Trail

### Required events

| Event | When recorded |
|---|---|
| `LOGIN_SUCCESS` | A user successfully authenticates. |
| `REQUEST_CREATED` | A request and request code are successfully created. |
| `REQUEST_ASSIGNED` | An Admin assigns or changes the assigned Agent. |
| `REQUEST_UPDATED` | A permitted request field or status is updated. |
| `AUTHORIZATION_FAILED` | A protected operation is denied or an invalid role/ownership attempt is detected. |
| `DATABASE_ERROR` | A Firestore write/read fails in a way that requires diagnosis. |

### Logging rules

- Logs shall identify actor, role, action, target type/id, result, and timestamp where applicable.
- `oldValue` and `newValue` shall contain only safe, relevant changes; avoid duplicating full sensitive documents.
- Never record passwords, authentication tokens, API keys, secrets, or raw authentication errors containing credentials.
- Audit and history records are append-only. Client writes are allowed only for authorized events; updates/deletes are denied by Rules.
- Logging failure shall not silently convert a successful business operation into a misleading failure. The UI shall communicate the primary operation result; the implementation shall document whether audit write failure blocks or follows the business write. **Assumption A-05:** For this challenge, business writes should fail safely if their required audit/history write cannot be completed atomically; diagnostic-only client logs may be best effort.

## Error Handling and Recovery

| Condition | Expected behavior |
|---|---|
| Invalid form input | Inline validation, no write, clear corrective message. |
| Invalid lifecycle action | Hide/disable action, reject in domain logic, and show a safe explanation if attempted. |
| Unauthorized access | Deny at Rules, show “You do not have permission…” without exposing record details, optionally record `AUTHORIZATION_FAILED`. |
| Missing profile/role | Stop privileged navigation and show a recoverable configuration/account message. |
| Network unavailable | Preserve entered form data where safe, show offline/network message, allow retry, avoid duplicate submissions. |
| Firestore permission denied | Show safe authorization message, log non-secret diagnostic context, do not retry blindly. |
| Firestore unavailable/timeout | Show retry state and avoid claiming the write succeeded. |
| Counter transaction conflict | Retry transaction within a bounded limit; if exhausted, show a retryable error and do not create a duplicate request. |
| Duplicate submission | Disable submit while pending and use transaction/idempotency strategy where practical. |
| Empty list | Explain that no records are available and provide a relevant next action. |
| Crash/unhandled exception | Report through Crashlytics where supported and leave the user in a recoverable state. |

## Technology Stack and Trade-offs

| Layer | Technology | Rationale / trade-off |
|---|---|---|
| Mobile | Flutter + Dart | One codebase for Android/iOS, fast demo delivery, shared domain code. |
| Admin web | Flutter Web + Dart | Enforces Flutter-only constraint and maximizes shared models/validation. |
| UI | Material 3 | Consistent accessible component system and fast implementation. |
| State | Riverpod | Testable dependency/state management with clear separation. |
| Navigation | go_router | Declarative, role-aware routing and guarded navigation. |
| Authentication | Firebase Authentication | Managed email/password, session persistence, and password reset without custom backend. |
| Database | Cloud Firestore | Managed document database, real-time reads where useful, Security Rules, Emulator Suite. |
| Authorization | Firestore Security Rules + `users.role` | Database-layer enforcement without Cloud Functions/custom claims. |
| Server-side logic | None | Required by Spark/no-billing constraint; business logic remains client-side and Rules-enforced. |
| Monitoring | Firebase Crashlytics | Crash/error visibility where platform support is available; setup must remain compatible with the demo target. |
| Storage | Firebase Storage only if needed | Avoided in baseline to reduce scope and security surface. |
| Testing | flutter_test, integration_test, Firebase Emulator Suite | Covers domain/UI flows and rules without requiring production data. |
| Hosting | Firebase Hosting | Optional deployment for the Flutter Web portal. |
| Version control | Git + GitHub | Required repository discipline and reviewability. |

## Non-Functional Requirements

- **NFR-01 Security:** Authorization must be enforced by Firestore Rules, not merely by UI visibility.
- **NFR-02 Security:** No secrets, passwords, tokens, or API keys may be committed or logged.
- **NFR-03 Privacy:** Expose only the minimum customer/agent profile data needed for each role.
- **NFR-04 Performance:** Typical list and detail screens should become usable within a few seconds on a normal development network; queries must be bounded and indexed.
- **NFR-05 Reliability:** Failed writes must not be presented as successful; request creation must not create duplicate request codes.
- **NFR-06 Usability:** Every required screen shall include loading, empty, error, and retry behavior appropriate to the context.
- **NFR-07 Accessibility:** Use Material 3 semantics, readable contrast, sensible text sizing, and controls usable on mobile and desktop layouts.
- **NFR-08 Maintainability:** Organize code into presentation, state/application, domain/shared, and data/infrastructure concerns; avoid duplicated role/business rules.
- **NFR-09 Testability:** Domain validators, lifecycle transitions, role guards, key widgets, and Firestore Rules shall be testable.
- **NFR-10 Compatibility:** The solution shall run locally with the documented Flutter SDK and Firebase Emulator Suite configuration.
- **NFR-11 Cost:** The baseline shall remain compatible with Firebase Spark and shall not require billing or a credit card.

## Architecture and Implementation Boundaries

The expected architecture is:

1. Flutter mobile and Flutter Web clients.
2. Shared Dart package/modules for models, enums, validators, constants, and lifecycle rules.
3. Repository/data layer for Firebase Authentication and Cloud Firestore.
4. Riverpod providers for session, role, request, service, dashboard, and activity state.
5. Firestore Security Rules as the backend authorization boundary.
6. Firestore collections for users, services, requests, status history, audit logs, and counters.
7. Firebase Emulator Suite for local Authentication, Firestore, and Rules testing.

The separate System Architecture, Database Design, RBAC & Security, User Flow, State Diagram, Wireframes, Testing Plan, and README documents shall elaborate this boundary. They must use the same collection names, roles, statuses, event names, and constraints defined here.

## Success Metrics and Evaluation Criteria

This is an implementation challenge rather than a production launch; success is judged through observable demonstration:

| Area | Success measure |
|---|---|
| Core workflow | A customer can register/login, create a request, view it, and track a status change. |
| Agent workflow | An assigned Agent can accept, progress, note, and complete assigned work. |
| Admin workflow | An Admin can see dashboard counts, assign an Agent, update permitted status, and inspect activity. |
| Security | A customer cannot read another customer’s request; an Agent cannot access another Agent’s work; Rules tests prove denial. |
| Integrity | Request IDs follow `REQ-YYYY-000123` and are generated transactionally without duplicates in tested concurrency cases. |
| Auditability | Required events and status history are visible for demonstrated operations without secrets. |
| Quality | Validation, errors, loading/empty states, tests, and readable modular code are present. |
| Delivery discipline | Repository, README, architecture/security/database documentation, setup instructions, test credentials, and demo are complete. |
| Cost compliance | No Cloud Functions, Blaze plan, paid service, or credit card is required. |

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Client-side role field is tampered with | Privilege escalation | Lock role changes in Rules; use controlled setup for Agent/Admin accounts; test self-promotion denial. |
| No Cloud Functions | Less centralized validation/automation | Keep deterministic rules in shared Dart and Firestore Rules; use transactions/batches; document trade-offs. |
| Firestore Rules complexity | Data exposure or blocked workflows | Write Emulator Rules tests early for every role and key transition. |
| Transaction contention on counters | Failed/duplicate request codes | Use year-scoped transaction, bounded retry, and failure-safe UX. |
| Free-tier limits | Unexpected unavailable/expensive features | Bound queries, avoid FCM/Functions, use Emulator Suite, no billing. |
| 5–7 day schedule | Incomplete polish | Prioritize core lifecycle, RBAC, audit/history, tests, and documentation before bonus features. |
| Flutter Web responsive layout | Poor admin usability | Test desktop and narrower browser widths; keep portal tables/filter layouts simple. |
| Client audit write failure | Missing traceability | Use atomic writes for required history/audit where feasible and surface failures clearly. |
| Firebase platform differences | Monitoring/setup friction | Document supported demo targets and treat Crashlytics as best-effort where platform support differs. |

## Deliverables and Submission Checklist

- [ ] GitHub repository with clean structure, meaningful commits, and appropriate `.gitignore`.
- [ ] Working Flutter mobile application.
- [ ] Working Flutter Web admin portal.
- [ ] Firebase Authentication and Cloud Firestore backend.
- [ ] Firestore Security Rules with Customer, Agent, and Admin RBAC.
- [ ] Request lifecycle, assignment, cancellation, status history, and audit trail.
- [ ] Logging and graceful error handling.
- [ ] Architecture diagram.
- [ ] Database documentation.
- [ ] Security/RBAC documentation.
- [ ] README with project overview, stack, prerequisites, setup/run instructions, emulator instructions, deployment notes, and test credentials.
- [ ] Tests, including at least one cross-customer authorization denial test.
- [ ] Optional Firebase Hosting URL and Android APK/iOS build where practical.
- [ ] Demo/walkthrough covering architecture, code, database, Security Rules, lifecycle, and technical trade-offs.

## Delivery Plan for the 5–7 Day Challenge

**Day 1:** Repository, Flutter shells, Firebase/Emulator setup, shared models/enums, authentication skeleton, role/profile setup.  
**Day 2:** Customer registration/login/session flow, services, request creation, transactional request code.  
**Day 3:** Customer request list/details/cancellation, status history, baseline rules.  
**Day 4:** Agent queue, accept/progress/notes/completion, agent authorization tests.  
**Day 5:** Flutter Web Admin dashboard, request management, assignment, status controls, customer/agent views.  
**Day 6:** Audit logging, error states, rules/integration/widget tests, README and architecture/security/database documentation.  
**Day 7:** Stabilization, demo data, optional hosting/build, walkthrough, and submission verification.

The sequence is a suggested delivery order, not an additional product requirement. Bonus features should be attempted only after the baseline is demonstrably complete.

## Glossary

| Term | Definition |
|---|---|
| RBAC | Role-Based Access Control; permissions are determined by Customer, Agent, or Admin role. |
| Firestore Security Rules | Backend-enforced conditions controlling read/write access to Firestore documents. |
| Session persistence | Retaining a valid Firebase login across app restarts according to platform behavior. |
| Audit trail | Append-only record of significant actors, actions, targets, results, and timestamps. |
| Status history | Append-only record of request state transitions. |
| Request code | Human-readable identifier such as `REQ-2026-000123`. |
| Spark plan | Firebase free plan used by this assignment; no billing or credit card. |
| Emulator Suite | Local Firebase services used for development and automated tests. |
| Atomic write | A transaction/batch operation that commits related writes together or not at all. |
| Eligible cancellation | A cancellation allowed by the lifecycle and actor rules; the baseline permits customer cancellation before acceptance as an explicit assumption. |

## Appendix A — Capability Matrix {.unnumbered}

| Capability | Customer | Agent | Admin |
|---|---:|---:|---:|
| Create Request | ✓ | — | ✓ |
| View Own Requests | ✓ | ✓ (assigned) | ✓ |
| View All Requests | — | — | ✓ |
| Accept Assigned Request | — | ✓ | — |
| Update Assigned Request | — | ✓ | ✓ |
| Assign Agent | — | — | ✓ |
| View Audit/Activity | — | — | ✓ |

## Appendix B — Required Screen List {.unnumbered}

Splash; Login; Admin Login; Registration; Home; Services; Create Request; My Requests; Request Details; Agent Request Details; Profile; Logout; Admin Dashboard; Admin Request Management; Admin Customer View; Admin Agent View; Admin Activity/Audit View.

## Appendix C — Required Event List {.unnumbered}

`LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, `DATABASE_ERROR`.

## Appendix D — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — this document.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.
