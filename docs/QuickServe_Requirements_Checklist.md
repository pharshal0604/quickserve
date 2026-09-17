---
title: "QuickServe Requirements Checklist / Traceability"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This Requirements Checklist / Traceability Document defines, organizes, and maps the requirements for QuickServe, a small end-to-end Service Request Management Application developed for the Swasiq Technology Internship Program — Health-tech, Nagpur.

The document provides a single verification reference for the finalized Product Requirements Document (PRD), the assignment brief, the Flutter applications, the Firebase backend, Firestore Security Rules, tests, documentation, and final submission materials.

### Project context

QuickServe consists of:

- A Flutter mobile application for Customers and Service Agents.
- A Flutter Web administration portal for Administrators.
- Firebase Authentication for identity and session management.
- Cloud Firestore for application data.
- Firestore Security Rules for database-layer authorization.
- Shared Dart code for models, enums, validators, constants, and lifecycle rules.

The challenge duration is 5–7 days. The goal is to demonstrate practical product thinking, secure backend design, clean code, and Git/GitHub discipline.

### Scope of this document

This document covers:

- Functional, non-functional, database, security, logging, error-handling, testing, GitHub, documentation, and bonus requirements.
- Traceability from each requirement to its assignment source and intended implementation location.
- Checklists for screens, collections, roles, events, tests, documentation, and submission deliverables.
- Verification methods and expected evidence.

This document does not introduce new roles, lifecycle states, collections, paid services, Cloud Functions, Supabase, React, Next.js, Angular, or other capabilities outside the finalized QuickServe decisions.

### Requirement status values

| Status | Meaning |
|---|---|
| Planned | Requirement is defined but implementation has not started or is not yet evidenced. |
| In Progress | Implementation or documentation work is underway. |
| Implemented | The requirement is implemented in code or documentation but has not completed verification. |
| Verified | Implementation and supporting evidence have been checked successfully. |
| N/A | Requirement is intentionally not applicable to the baseline and the reason is documented. |

**Assumption A-01:** The initial status for this checklist is `Planned` because status should be updated against the actual repository and test evidence during implementation.

## How to Read the Traceability Matrix

The main matrix uses the following columns:

| Column | Definition |
|---|---|
| Requirement ID | Stable identifier used in code comments, tests, issues, pull requests, and documentation. |
| Description | Observable requirement that the implementation must satisfy. |
| Source (Assignment Section) | Assignment or finalized decision that establishes the requirement. |
| Implementation Location | Expected Flutter, Firebase, Rules, test, or documentation location. These are target locations and may be refined in the repository. |
| Status | Current delivery status using the defined status values. |
| Notes | Verification evidence, dependencies, assumptions, or constraints. |

Requirement IDs are grouped by category:

- `FR-AUTH-*`: Authentication and session behavior.
- `FR-C-*`: Customer functionality.
- `FR-A-*`: Service Agent functionality.
- `FR-AD-*`: Administrator functionality.
- `FR-X-*`: Cross-cutting functional behavior.
- `NFR-*`: Non-functional requirements.
- `DB-*`: Database model and integrity requirements.
- `LOG-*`: Logging and audit requirements.
- `ERR-*`: Error-handling requirements.
- `TEST-*`: Testing requirements.
- `GIT-*`: GitHub and repository requirements.
- `DOC-*`: Documentation requirements.
- `BONUS-*`: Optional bonus features.

## Requirement Categories

| Category | Coverage |
|---|---|
| Authentication and session | Registration, login, logout, session persistence, password reset, and role routing. |
| Customer functionality | Service browsing, request creation, request tracking, request details, cancellation, profile, and logout. |
| Agent functionality | Assigned-request queue, acceptance, status updates, notes, completed work, and access restrictions. |
| Administrator functionality | Admin login, dashboard, request operations, assignment, user views, and audit/activity information. |
| Cross-cutting functionality | Validation, request-code generation, lifecycle history, shared rules, and bounded list behavior. |
| Non-functional requirements | Security, privacy, performance, usability, accessibility, maintainability, compatibility, and cost. |
| Database | Collections, fields, relationships, indexes, counters, and append-only records. |
| Logging and errors | Required events, safe logging, recovery behavior, and database/authorization failures. |
| Testing | Unit, widget, integration, Emulator Suite, and authorization tests. |
| GitHub and documentation | Repository hygiene, README, architecture, database, security, and delivery documentation. |
| Bonus | Optional features that must not delay or compromise the baseline. |

## Traceability Matrix

### Authentication and session requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| FR-AUTH-01 | The system shall allow a user to register with name, email, phone, and password. | Authentication & Authorization; Mobile Screens | Flutter mobile `registration` feature; Firebase Auth repository | Planned | Registration is the baseline customer onboarding flow. |
| FR-AUTH-02 | Registration shall create a Firebase Authentication account and a corresponding `users/{uid}` document with stored role `customer`. | Roles and Capabilities; Database Model | Auth service and user-profile repository | Planned | Agent and Admin accounts use controlled setup. |
| FR-AUTH-03 | The system shall allow users to log in with email and password. | Authentication & Authorization | Flutter mobile login; Flutter Web Admin Login; Firebase Auth repository | Planned | Applies to Customer, Agent, and Admin accounts. |
| FR-AUTH-04 | The system shall allow users to log out. | Roles and Capabilities; Mobile Screens | Profile/Home action; Firebase Auth repository | Planned | Logout is an action, listed as a screen for traceability. |
| FR-AUTH-05 | The system shall restore a valid Firebase session on app start and route the user to the correct role experience. | Authentication & Authorization | Splash/session provider; `go_router` guards | Planned | Invalid or missing profile data must not grant privileged access. |
| FR-AUTH-06 | The system shall provide password-reset initiation through Firebase Authentication. | Authentication & Authorization | Login and Admin Login screens; Auth repository | Planned | Verify email/password-reset flow without exposing credentials. |
| FR-AUTH-07 | A successful login shall record `LOGIN_SUCCESS` without recording passwords, tokens, or secrets. | Database, Logging & Error Handling | Auth service and audit-log writer | Planned | Verify event payload using safe fields only. |
| FR-AUTH-08 | Failed or unauthorized operations shall show a safe user-facing message and may record `AUTHORIZATION_FAILED`. | Authentication & Authorization; Logging & Error Handling | Shared error mapper; Rules-denial handling | Planned | Error messages must not expose protected record details. |
| FR-AUTH-09 | A missing or invalid `users/{uid}` profile shall produce a recoverable error rather than privileged access. | Authentication & Authorization | Session/profile provider; role router | Planned | Include an emulator test for missing profile behavior. |

### Customer requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| FR-C-01 | A Customer shall see a splash/loading state while authentication and profile state are resolved. | Mobile Screens | Flutter mobile splash/session feature | Planned | Verify loading, success, missing-profile, and error states. |
| FR-C-02 | A Customer shall access Home and Services after successful login. | Roles and Capabilities; Mobile Screens | Customer navigation shell and route guards | Planned | Access depends on authenticated `customer` role. |
| FR-C-03 | Services shall show active AC servicing, plumbing, electrical, and cleaning services. | What QuickServe Is; Mobile Screens | Services screen; `services` repository | Planned | Inactive services must not appear in the customer baseline catalog. |
| FR-C-04 | A Customer shall create a request with service type, description, preferred date/time, address, and priority. | Mobile Screens; Database Model | Create Request screen; request repository | Planned | All required fields must be validated before writing. |
| FR-C-05 | Priority shall be one of `low`, `medium`, or `high` in stored data, displayed as Low, Medium, or High. | Mobile Screens; Database Model | Shared Dart priority enum and validator | Planned | No uncontrolled priority strings are permitted. |
| FR-C-06 | The system shall validate required fields, date/time input, and reasonable text lengths before writing. | Logging & Error Handling; Testing Requirements | Shared validators and Create Request form | Planned | Exact maximum lengths are an implementation assumption. |
| FR-C-07 | A successful request shall receive a unique code in the format `REQ-YYYY-000123`. | Finalized Tech Stack; Database Model | Request creation transaction and `counters/{year}` | Planned | Verify concurrent creation behavior in Emulator Suite. |
| FR-C-08 | A new request shall start in stored status `created`, with the authenticated user as `customerId` and no assigned agent. | Request Lifecycle; Database Model | Request model, repository, Firestore Rules | Planned | `agentId` is empty/null until assignment. |
| FR-C-09 | A Customer shall see only requests owned by that Customer. | Authentication & Authorization | My Requests query and Firestore Rules | Planned | Cross-customer reads must be denied at the database layer. |
| FR-C-10 | A Customer shall view request code, service, description, schedule, address, priority, status, permitted notes, and visible status history. | Mobile Screens; Database Model | Request Details screen and history repository | Planned | Customer-visible notes must exclude restricted operational data. |
| FR-C-11 | A Customer shall cancel only an eligible own request and shall provide a cancellation reason. | Roles and Capabilities; Request Lifecycle | Request Details action; lifecycle validator; Rules | Planned | Eligibility follows the finalized lifecycle policy. |
| FR-C-12 | A Customer shall not read, update, or cancel another Customer’s request. | Authentication & Authorization | Firestore Security Rules and authorization tests | Planned | Mandatory cross-customer denial test is `TEST-07`. |
| FR-C-13 | A Customer shall access Profile and safely log out. | Roles and Capabilities; Mobile Screens | Profile screen and Auth repository | Planned | Logout is also listed for screen traceability. |

### Service Agent requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| FR-A-01 | An authenticated Agent shall see an Agent work queue rather than customer-only request creation as the primary action. | Roles and Capabilities; Mobile Screens | Agent Home/work-queue screen | Planned | Stored role is `agent`; displayed role is Agent. |
| FR-A-02 | An Agent shall read only requests assigned to that Agent. | Authentication & Authorization | Agent request query and Firestore Rules | Planned | Direct document access by another agent must fail. |
| FR-A-03 | An Agent shall accept an assigned request when its status is `assigned`. | Request Lifecycle; Roles and Capabilities | Agent Request Details; lifecycle service; Rules | Planned | The authenticated Agent must match `agentId`. |
| FR-A-04 | An Agent shall update an assigned request through permitted states, including `in_progress` and `completed`. | Request Lifecycle; Roles and Capabilities | Agent Request Details; request repository; Rules | Planned | Invalid transitions must be rejected client-side and by Rules. |
| FR-A-05 | The application shall prevent invalid Agent transitions and Firestore Rules shall reject direct invalid attempts. | Authentication & Authorization; Testing Requirements | Shared lifecycle validator and Rules tests | Planned | Cover both UI action availability and backend denial. |
| FR-A-06 | An Agent shall add operational notes to an assigned request. | Roles and Capabilities; Database Model | Agent Request Details; request/history writer | Planned | Notes must not contain secrets. |
| FR-A-07 | An Agent shall view completed work from requests assigned to that Agent. | Roles and Capabilities | Agent queue/history query and completed-work filter | Planned | Verify access remains assignment-scoped. |
| FR-A-08 | An Agent shall not assign requests, view all requests, modify another Agent’s assignment, or edit customer ownership. | Capability Matrix; Authentication & Authorization | Firestore Rules and Agent UI guards | Planned | Verify each denied operation where practical. |

### Administrator requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| FR-AD-LOGIN-01 | The Admin shall log in with email/password before accessing the Flutter Web administration portal. | Admin Web Features; finalized PRD | Flutter Web Admin Login screen and route guard | Planned | Admin portal routes must be protected before dashboard access. |
| FR-AD-01 | An authenticated Admin shall access the Flutter Web portal dashboard. | Admin Web Features; Authentication & Authorization | Flutter Web route guard and Admin Dashboard | Planned | Admin Login must occur before portal access. |
| FR-AD-02 | The dashboard shall show total, new, assigned, in-progress, completed, and cancelled request counts. New means status `created`. | Admin Web Features | Admin Dashboard queries and count cards | Planned | Queries must use bounded/indexed reads. |
| FR-AD-03 | The Admin shall search requests using request code and available operational text fields. | Admin Web Features | Admin Request Management search controls | Planned | Search behavior must match implemented indexed/query strategy. |
| FR-AD-04 | The Admin shall filter requests by status, service type, priority, assigned Agent, and relevant date where supported. | Admin Web Features | Admin Request Management filters | Planned | Exact composite indexes are documented after implementation. |
| FR-AD-05 | The Admin shall view request details, including customer, Agent, service, status, timestamps, notes, and status history. | Admin Web Features; Database Model | Admin request detail view | Planned | Do not expose secrets or passwords. |
| FR-AD-06 | The Admin shall assign an eligible Agent to a request and record `REQUEST_ASSIGNED` plus status history. | Roles and Capabilities; Logging | Assignment control, transaction/batch writer, audit writer | Planned | Assignment must preserve prior history. |
| FR-AD-07 | The Admin shall update request status only through permitted operational transitions and record `REQUEST_UPDATED`. | Request Lifecycle; Logging | Admin request detail; lifecycle service; Rules | Planned | Every transition must be auditable. |
| FR-AD-08 | The Admin shall view Customer records with appropriate non-secret profile fields. | Admin Web Features | Admin Customer View and users repository | Planned | Minimize exposed profile data. |
| FR-AD-09 | The Admin shall view Agent records with appropriate non-secret profile fields. | Admin Web Features | Admin Agent View and users repository | Planned | Role-management UI is not required by the baseline. |
| FR-AD-10 | The Admin shall view basic audit/activity information, including actor, action, target, result, and timestamp. | Admin Web Features; Logging | Admin Activity view and `audit_logs` repository | Planned | Audit records are append-only. |
| FR-AD-11 | The Admin shall not see passwords, authentication tokens, API keys, or other secrets. | Logging & Error Handling | Data projection, UI models, Rules, logging policy | Planned | Verify through code review and demo inspection. |

### Cross-cutting functional requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| FR-X-01 | All writes shall set `createdAt` and/or `updatedAt` using trusted Firestore server timestamps where available. | Database Model | Shared timestamp helpers and repositories | Planned | Avoid client-controlled timestamps for authoritative events. |
| FR-X-02 | A status change shall update the parent request and create status history atomically where feasible. | Database Model; Logging | Firestore transaction/batch writer | Planned | Rules must prevent history updates/deletes. |
| FR-X-03 | Business rules shall be shared in Dart where practical and independently enforced in Firestore Security Rules. | Finalized Tech Stack; Authentication & Authorization | Shared domain package and `firestore.rules` | Planned | UI-only authorization is insufficient. |
| FR-X-04 | Lists shall provide loading, empty, error, retry, and bounded-result behavior. | Testing & Quality; Free-tier constraint | Shared list-state components and repositories | Planned | Pagination is optional but unbounded reads are discouraged. |
| FR-X-05 | Navigation shall use `go_router`, state management shall use Riverpod, and UI shall use Material 3. | Finalized Tech Stack | Flutter application structure | Planned | Applies to mobile and Flutter Web. |
| FR-X-06 | The request lifecycle shall support `created` → `assigned` → `accepted` → `in_progress` → `completed`, with eligible requests also able to become `cancelled`. | What QuickServe Is; Request Lifecycle | Shared status enum and transition validator | Planned | No additional baseline states may be introduced. |
| FR-X-07 | Request codes shall be generated transactionally from `counters/{year}` in the format `REQ-YYYY-000123`. | Finalized Tech Stack; Database Model | Request-code service | Planned | Verify uniqueness under repeated/concurrent test attempts. |

### Non-functional requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| NFR-01 | Authorization shall be enforced by Firestore Security Rules, not only by hiding UI controls. | Authentication & Authorization | `firestore.rules`; Rules tests | Planned | Critical security requirement. |
| NFR-02 | Passwords, tokens, API keys, and secrets shall not be committed or logged. | Logging & Error Handling; GitHub Requirements | Repository policy, logging helpers, code review | Planned | Scan repository before submission. |
| NFR-03 | The system shall expose only the minimum profile data needed for each role. | Authentication & Authorization | Firestore projections/models and UI | Planned | Especially important for Customer and Agent views. |
| NFR-04 | Queries shall be bounded and use required Firestore indexes. | Free-tier constraint; Admin Web Features | Repository queries and Firebase index configuration | Planned | Prevent unnecessary Spark-plan reads. |
| NFR-05 | Failed writes shall not be presented as successful. | Logging & Error Handling | Repository result types and UI error states | Planned | Verify network and permission-denied scenarios. |
| NFR-06 | Required screens shall provide appropriate loading, empty, error, and retry states. | Testing & Quality; Mobile Screens | Flutter widgets and state providers | Planned | Validate on mobile and web portal surfaces. |
| NFR-07 | The UI shall use readable contrast, sensible text sizing, Material 3 semantics, and usable controls on mobile and desktop layouts. | Finalized Tech Stack; Testing & Quality | Flutter UI components and theme | Planned | Accessibility is appropriate to the internship scope. |
| NFR-08 | The codebase shall be modular and maintainable, with separation between presentation, state, domain, and data concerns. | Goal; GitHub Requirements | Repository structure and architecture documentation | Planned | Confirm through repository review. |
| NFR-09 | The solution shall run with the documented Flutter SDK and Firebase Emulator Suite configuration. | Local Testing; README Requirements | Tool configuration and setup documentation | Planned | Exact SDK versions belong in README. |
| NFR-10 | The baseline shall remain compatible with Firebase Spark and shall not require billing or a credit card. | Constraints | Firebase project configuration and feature scope | Planned | No Blaze-only service may be required. |
| NFR-11 | Crash/error monitoring shall use Firebase Crashlytics where supported by the target platform. | Finalized Tech Stack | Firebase Crashlytics configuration | Planned | Platform limitations must be documented. |

### Database requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| DB-01 | The system shall maintain `users/{uid}` with `role`, `name`, `email`, `phone`, `createdAt`, and `updatedAt`. | Database Model | Firestore users collection; User model | Planned | Stored roles are lowercase: `customer`, `agent`, `admin`. |
| DB-02 | The system shall maintain `services/{serviceId}` with `name`, `description`, `active`, and `createdAt`. | Database Model | Firestore services collection; Service model | Planned | Baseline services are AC servicing, plumbing, electrical, and cleaning. |
| DB-03 | The system shall maintain `requests/{requestId}` with all required request fields. | Database Model | Firestore requests collection; Request model | Planned | Required fields include customer, agent, service, schedule, address, priority, status, timestamps, and cancellation reason. |
| DB-04 | The system shall maintain `requests/{requestId}/status_history/{historyId}` with `fromStatus`, `toStatus`, `changedBy`, `changedAt`, and `note`. | Database Model | Firestore subcollection; status-history writer | Planned | Records are append-only. |
| DB-05 | The system shall maintain `audit_logs/{logId}` with actor, role, action, target, old value, new value, result, and timestamp. | Database Model; Logging | Firestore audit collection; audit writer | Planned | Values must exclude secrets. |
| DB-06 | The system shall maintain `counters/{year}` with `lastRequestNumber`. | Database Model; Request-code decision | Firestore counter document; transaction service | Planned | Direct arbitrary counter manipulation must be denied. |
| DB-07 | `requestCode` shall be unique per year through the Firestore counter transaction. | Finalized Tech Stack | Request-code service and transaction test | Planned | Evidence includes repeated/concurrent creation tests. |
| DB-08 | Status, priority, and role fields shall use controlled values. | Database Model; Roles; Lifecycle | Shared enums, validators, and Security Rules | Planned | No uncontrolled strings in accepted writes. |
| DB-09 | Required Firestore composite indexes shall be documented and committed after implemented queries are known. | Database Model; Admin Web Features | `firestore.indexes.json`; Database Design Document | Planned | Exact index list is an implementation assumption. |
| DB-10 | Status history and audit records shall not be updated or deleted by clients. | Constraints; Logging | Firestore Security Rules | Planned | Rules tests must prove update/delete denial. |

### Logging and audit requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| LOG-01 | The system shall record `LOGIN_SUCCESS` after successful authentication. | Events; Authentication | Auth repository and audit writer | Planned | Record safe actor and timestamp fields only. |
| LOG-02 | The system shall record `REQUEST_CREATED` after successful request creation. | Events | Request transaction/audit writer | Planned | Include target request ID/code without secrets. |
| LOG-03 | The system shall record `REQUEST_ASSIGNED` when an Admin assigns an Agent. | Events; Admin Requirements | Assignment transaction/audit writer | Planned | Include old/new assignment values where safe. |
| LOG-04 | The system shall record `REQUEST_UPDATED` for permitted request updates/status changes. | Events | Request update service/audit writer | Planned | Status transitions also require status history. |
| LOG-05 | The system shall record `AUTHORIZATION_FAILED` for denied or invalid protected operations where client logging is appropriate. | Events; Security | Shared authorization/error handler | Planned | Do not reveal protected record contents. |
| LOG-06 | The system shall record `DATABASE_ERROR` for relevant Firestore failures requiring diagnosis. | Events; Error Handling | Repository error handler | Planned | Error payload must exclude credentials and tokens. |
| LOG-07 | Logs shall never contain passwords, authentication tokens, API keys, or secrets. | Logging & Error Handling | Logging policy, safe event models, code review | Planned | Mandatory pre-submission review. |
| LOG-08 | Audit logs shall be append-only and viewable to Admins through basic activity information. | Constraints; Admin Web Features | `audit_logs` Rules, Admin Activity view | Planned | Clients cannot update or delete existing entries. |

### Error-handling requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| ERR-01 | Invalid form input shall be rejected before a database write and shown with a clear corrective message. | Logging & Error Handling | Shared validators and form widgets | Planned | Cover required fields and allowed values. |
| ERR-02 | Network failures shall show a retryable state and shall not claim that a write succeeded. | Logging & Error Handling | Repository result handling and UI states | Planned | Preserve entered data where safe. |
| ERR-03 | Firestore/database failures shall be mapped to safe user-facing messages and diagnostic events. | Logging & Error Handling | Firebase error mapper and `DATABASE_ERROR` writer | Planned | Do not expose raw sensitive errors. |
| ERR-04 | Unauthorized actions shall be rejected by Rules and shown without exposing protected record details. | Authentication & Authorization | Firestore Rules, UI error mapper, `AUTHORIZATION_FAILED` | Planned | Mandatory cross-customer authorization test applies. |
| ERR-05 | Invalid lifecycle transitions shall be blocked in the UI and rejected by domain logic and Rules. | Request Lifecycle; Testing | Lifecycle validator and Rules | Planned | Cover Customer, Agent, and Admin paths. |
| ERR-06 | Counter transaction conflicts shall retry within a bounded limit and fail safely without duplicate request creation. | Request-code decision | Request-code service and error state | Planned | Verify with Emulator Suite where practical. |
| ERR-07 | Duplicate submission shall be minimized through disabled pending actions and transaction/idempotency safeguards where practical. | Logging & Error Handling | Form state and repository | Planned | Exact idempotency strategy is an implementation assumption. |
| ERR-08 | Missing profile/role data shall stop privileged navigation and provide a recoverable account/configuration message. | Authentication & Authorization | Session/profile provider | Planned | Do not default a missing profile to Admin or Agent. |

### Testing requirements

**Test identifier convention:** `TEST-01` through `TEST-10` are shared anchors used across this checklist and the RBAC & Security Document. `TEST-11` and above are reserved for the RBAC & Security Document’s Firestore Rules test cases. Requirement-side testing rows in this checklist use the `REQ-TEST-*` prefix to avoid collision.

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| TEST-01 | Unit tests shall cover validators, enums, request-code formatting, and lifecycle transitions where practical. | Testing Requirements | `test/domain`, shared Dart package tests | Planned | Include valid and invalid cases. |
| TEST-02 | Widget tests shall cover important authentication, request, role, loading, empty, and error states where practical. | Testing Requirements | `test/features` | Planned | Prioritize core screens within the 5–7 day scope. |
| TEST-03 | Integration tests shall cover the primary Customer request flow. | Testing Requirements | `integration_test/customer_flow_test.dart` | Planned | Register/login, create, view, and track a request. |
| TEST-04 | Integration tests shall cover the Agent assigned-work flow. | Testing Requirements | `integration_test/agent_flow_test.dart` | Planned | Accept, update, note, and complete assigned work. |
| TEST-05 | Integration tests shall cover the Admin dashboard and assignment flow. | Testing Requirements | `integration_test/admin_flow_test.dart` | Planned | Login, dashboard, assignment, status update, activity. |
| TEST-06 | Firestore Security Rules shall be tested using the Firebase Emulator Suite. | Local Testing; Authentication & Authorization | `test/rules` or Rules test project | Planned | Avoid relying only on UI tests for authorization. |
| TEST-07 | A Customer attempting to access another Customer’s request shall be denied. | Testing Requirements | Firestore Rules authorization test | Planned | Mandatory acceptance test. |
| TEST-08 | An Agent attempting to access or update another Agent’s assigned request shall be denied. | Authentication & Authorization | Firestore Rules authorization test | Planned | Verify read and write restrictions. |
| TEST-09 | A user attempting to self-promote through `users.role` shall be denied. | Constraints; RBAC | Firestore Rules authorization test | Planned | Protect Agent/Admin setup boundary. |
| TEST-10 | An unauthenticated user shall be denied reads and writes on protected data. | Authentication & Authorization | Firestore Rules authorization test | Planned | Verify all protected paths reject unauthenticated access. |
| REQ-TEST-11 | Request-code generation shall be tested for format and uniqueness. | Request-code decision | Request-code unit/integration tests | Planned | Include year boundary behavior where practical. |
| REQ-TEST-12 | The final test run shall be documented with commands, environment, and result. | README; Submission | README and CI/local test output | Planned | Evidence must be reproducible by an evaluator. |
| REQ-TEST-13 | Clients shall be denied update/delete operations on status history and audit logs. | Constraints | Firestore Rules tests | Planned | Append-only behavior is mandatory. |

### GitHub and repository requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| GIT-01 | The repository shall use a clean, understandable structure. | GitHub Requirements | Repository root and architecture documentation | Planned | Structure must separate Flutter app, shared code, Firebase config, and tests. |
| GIT-02 | Commits shall be meaningful and traceable to implemented work. | GitHub Requirements | Git history | Planned | Avoid unexplained monolithic commits. |
| GIT-03 | The repository shall include an appropriate `.gitignore`. | GitHub Requirements | Repository root `.gitignore` | Planned | Exclude build outputs, local credentials, and generated files as appropriate. |
| GIT-04 | Secrets shall not be committed. | GitHub Requirements; Security | Repository scan and environment configuration | Planned | Firebase configuration handling must be documented safely. |
| GIT-05 | Environment-specific configuration shall be separated from source-controlled secrets. | GitHub Requirements | Configuration files and README | Planned | Exact method is an implementation assumption. |
| GIT-06 | Feature branches and pull requests should be used where practical. | GitHub Requirements | GitHub workflow | Planned | Encouraged, not a baseline blocker if schedule prevents it. |
| GIT-07 | Simple GitHub Actions CI/CD may be added without requiring paid services. | GitHub Requirements; Bonus | `.github/workflows` | N/A | Optional; must not require billing or Cloud Functions. |

### Documentation requirements

| Requirement ID | Description | Source (Assignment Section) | Implementation Location | Status | Notes |
|---|---|---|---|---|---|
| DOC-01 | README shall describe the project overview and purpose. | GitHub Requirements | `README.md` | Planned | Must use QuickServe and Swasiq spelling consistently. |
| DOC-02 | README shall document architecture and technology stack. | GitHub Requirements | `README.md`; architecture document | Planned | Must state Flutter-only and Firebase-only decisions. |
| DOC-03 | README shall document prerequisites and setup/run instructions. | GitHub Requirements | `README.md` | Planned | Include Flutter SDK, Firebase CLI/Emulator Suite, and configuration steps. |
| DOC-04 | README shall document test credentials or controlled demo-account setup. | GitHub Requirements | `README.md` | Planned | Never include passwords or secrets in public repositories. |
| DOC-05 | The project shall include an architecture diagram. | GitHub Requirements; Companion Documents | System Architecture Document and diagram asset | Planned | Diagram must show Flutter clients, Firebase Auth, Firestore, Rules, and Emulator Suite. |
| DOC-06 | The project shall include database documentation. | GitHub Requirements; Companion Documents | Database Design Document | Planned | Must match collection names and fields in this matrix. |
| DOC-07 | The project shall include security/RBAC documentation. | GitHub Requirements; Companion Documents | RBAC & Security Document | Planned | Must explain `users.role`, Rules, and no custom claims. |
| DOC-08 | The project shall include user flows and lifecycle/state documentation. | Companion Documents | User Flow Diagram and Request Lifecycle / State Diagram | Planned | Must use the finalized roles and statuses. |
| DOC-09 | The project shall include UI/UX wireframes for required screens. | Companion Documents | UI/UX Wireframes | Planned | Include Customer, Agent, and Admin portal surfaces. |
| DOC-10 | The project shall include a testing plan. | Companion Documents | Testing Plan | Planned | Must include the mandatory authorization denial test. |
| DOC-11 | The project shall include setup/deployment documentation. | Companion Documents | README / Setup & Deployment Documentation | Planned | Firebase Hosting is optional for the web portal. |
| DOC-12 | Documentation shall not introduce contradictory roles, states, collections, frameworks, billing assumptions, or server-side capabilities. | Companion Documents | Documentation review checklist | Planned | Cross-document consistency review required before submission. |

## Capability Matrix

| Capability | Customer | Agent | Admin |
|---|---:|---:|---:|
| Register | Yes | Controlled setup or existing account | Controlled setup or existing account |
| Login/logout/password reset | Yes | Yes | Yes |
| Browse active services | Yes | Optional read-only | Yes |
| Create Request | ✓ | — | ✓ |
| View Own Requests | ✓ | ✓ (assigned) | ✓ |
| View All Requests | — | — | ✓ |
| Accept Assigned Request | — | ✓ | — |
| Update Assigned Request | — | ✓ | ✓ |
| Assign Agent | — | — | ✓ |
| Cancel eligible request | Own request only | — | Operationally permitted |
| View Audit/Activity | — | — | ✓ |
| View customers and agents | — | — | ✓ |

## Screen Checklist

### Flutter mobile screens

| Requirement ID | Screen | Customer | Agent | Required checklist item | Status | Verification evidence |
|---|---|---:|---:|---|---|---|
| FR-C-01 | Splash | ✓ | ✓ | Resolves session/profile state and routes by role. | Planned | Screenshot or widget test. |
| FR-AUTH-03 | Login | ✓ | ✓ | Email/password login, validation, loading, errors, and password reset entry. | Planned | Auth test and screenshot. |
| FR-AUTH-01 | Registration | ✓ | — | Creates a Customer account with required fields. | Planned | Integration test. |
| FR-C-02 | Home | ✓ | ✓ | Shows role-appropriate actions and navigation. | Planned | Role-based navigation test. |
| FR-C-03 | Services | ✓ | Optional | Shows active AC servicing, plumbing, electrical, and cleaning services. | Planned | Seed data and screen evidence. |
| FR-C-04 | Create Request | ✓ | — | Captures service, description, preferred date/time, address, and priority. | Planned | Customer flow test. |
| FR-C-09 | My Requests | ✓ | — | Lists only the authenticated Customer’s requests. | Planned | Rules and UI evidence. |
| FR-C-10 | Request Details | ✓ | — | Shows request data, status, history, and eligible Customer actions. | Planned | Detail-screen test. |
| FR-A-03 | Agent Request Details | — | ✓ | Reuses Request Details with Agent-specific accept, update, and note actions. | Planned | Agent flow test. |
| FR-C-13 | Profile | ✓ | ✓ | Shows permitted profile information and logout action. | Planned | Widget test or walkthrough. |
| FR-AUTH-04 | Logout | ✓ | ✓ | Auth session is ended and user returns to the appropriate login route. | Planned | Auth state test. |

### Flutter Web administration screens/features

| Requirement ID | Screen/feature | Required checklist item | Status | Verification evidence |
|---|---|---|---|---|
| FR-AD-LOGIN-01 | Admin Login | Admin logs in with email/password before accessing the portal. | Planned | Admin authentication test. |
| FR-AD-01, FR-AD-02 | Admin Dashboard | Shows total, new (`created`), assigned, in-progress, completed, and cancelled counts. | Planned | Seeded data screenshot and query test. |
| FR-AD-03, FR-AD-04, FR-AD-05, FR-AD-06, FR-AD-07 | Admin Request Management | Supports search, filters, request list/table, detail view, assignment, and status updates. | Planned | Admin walkthrough and integration test. |
| FR-AD-08 | Admin Customer View | Shows permitted, non-secret Customer profile information. | Planned | Role-based query and screenshot. |
| FR-AD-09 | Admin Agent View | Shows permitted, non-secret Agent profile information. | Planned | Role-based query and screenshot. |
| FR-AD-10 | Admin Activity/Audit View | Shows basic actor, action, target, result, and timestamp information. | Planned | Audit event walkthrough. |
| FR-AUTH-04 | Admin Logout | Ends the Admin session and returns to Admin Login. | Planned | Auth state test. |

**Traceability note:** Logout is an action available from Profile/Home and is listed for traceability. Agent Request Details is a role-specific reuse of Request Details, not a separate data model.

## Database Model Checklist

| Checklist ID | Collection/document | Required fields | Access/integrity expectation | Status | Verification evidence |
|---|---|---|---|---|---|
| DB-CHK-01 | `users/{uid}` | `role`, `name`, `email`, `phone`, `createdAt`, `updatedAt` | Role is controlled; passwords are never stored. | Planned | Emulator data inspection and Rules tests. |
| DB-CHK-02 | `services/{serviceId}` | `name`, `description`, `active`, `createdAt` | Active catalog entries are readable as designed. | Planned | Seed-data inspection and Services screen. |
| DB-CHK-03 | `requests/{requestId}` | `requestCode`, `customerId`, `agentId`, `serviceType`, `description`, `preferredDateTime`, `address`, `priority`, `status`, `createdAt`, `updatedAt`, `cancellationReason` | Ownership, assignment, status, and controlled values are enforced. | Planned | Rules tests and request-flow evidence. |
| DB-CHK-04 | `requests/{requestId}/status_history/{historyId}` | `fromStatus`, `toStatus`, `changedBy`, `changedAt`, `note` | Append-only lifecycle history; no client update/delete. | Planned | Rules tests and detail view. |
| DB-CHK-05 | `audit_logs/{logId}` | `actorUserId`, `actorRole`, `action`, `targetType`, `targetId`, `oldValue`, `newValue`, `result`, `timestamp` | Append-only audit record with no secrets. | Planned | Activity view and Rules tests. |
| DB-CHK-06 | `counters/{year}` | `lastRequestNumber` | Updated only through the request-code transaction pattern. | Planned | Counter transaction test. |
| DB-CHK-07 | Firestore indexes | Query-specific composite indexes | Dashboard and operational queries remain bounded and valid. | Planned | `firestore.indexes.json` and emulator query run. |

## Authentication and RBAC Checklist

| Checklist item | Customer | Agent | Admin | Verification |
|---|---:|---:|---:|---|
| Registration | ✓ | Controlled setup | Controlled setup | Firebase Auth and user-profile test. |
| Email/password login | ✓ | ✓ | ✓ | Authentication integration tests. |
| Logout | ✓ | ✓ | ✓ | Session-state test. |
| Session persistence | ✓ | ✓ | ✓ | App restart/session test. |
| Password reset | ✓ | ✓ | ✓ | Firebase Auth reset-flow test or walkthrough. |
| Read own/assigned request data | Own only | Assigned only | All permitted operational data | Firestore Rules tests. |
| Create request | ✓ | — | ✓ | Rules and integration tests. |
| Assign Agent | — | — | ✓ | Admin operation and Rules test. |
| Update status | Eligible own cancellation | Assigned request only | Permitted operational transitions | Lifecycle and Rules tests. |
| View all requests | — | — | ✓ | Query and Rules tests. |
| View audit/activity | — | — | ✓ | Admin Activity view and Rules test. |
| Self-promote role | — | — | Denied | Rules test for protected `users.role`. |

### Stored-role convention

Stored enum values are lowercase:

- `customer`
- `agent`
- `admin`

Display labels are title case: Customer, Agent, and Admin. Firestore Security Rules use the stored values and authenticated user identity to enforce access.

## Logging and Error Handling Checklist

### Required event checklist

| Requirement ID | Event | Trigger | Required safe data | Must exclude | Status | Verification |
|---|---|---|---|---|---|---|
| LOG-01 | `LOGIN_SUCCESS` | Successful login | Actor ID/role where safe, result, timestamp | Passwords, tokens, secrets | Planned | Login audit record. |
| LOG-02 | `REQUEST_CREATED` | Successful request creation | Actor, target request, result, timestamp | Secrets and sensitive credentials | Planned | Create-request walkthrough. |
| LOG-03 | `REQUEST_ASSIGNED` | Agent assignment/change | Actor, target, old/new assignment where safe, timestamp | Secrets | Planned | Admin assignment audit record. |
| LOG-04 | `REQUEST_UPDATED` | Permitted request/status update | Actor, target, relevant change, result, timestamp | Secrets | Planned | Status-update audit record. |
| LOG-05 | `AUTHORIZATION_FAILED` | Denied protected operation | Actor, action, target type/result where safe | Protected record details and credentials | Planned | Rules-denial test and safe UI error. |
| LOG-06 | `DATABASE_ERROR` | Relevant Firestore failure | Non-secret diagnostic context and result | Tokens, keys, credentials | Planned | Emulator/network error test. |

### Error-handling checklist

| Requirement ID | Error scenario | Required behavior | Status | Verification |
|---|---|---|---|---|
| ERR-01 | Invalid input | Inline validation, no write, corrective message. | Planned | Widget/unit tests. |
| ERR-02 | Network failure | Retryable state; do not claim success; preserve data where safe. | Planned | Offline/network simulation. |
| ERR-04 | Firestore permission denial | Safe authorization message; no protected data exposure. | Planned | Rules test and UI walkthrough. |
| ERR-03 | Database timeout/unavailability | Retry state and diagnostic event where applicable. | Planned | Emulator or mocked failure test. |
| ERR-05 | Invalid lifecycle action | Action hidden/disabled and rejected by domain/Rules. | Planned | Lifecycle tests. |
| ERR-06 | Counter conflict | Bounded retry; no duplicate request. | Planned | Transaction test. |
| ERR-07 | Duplicate submission | Disable pending submission and use safeguards where practical. | Planned | Widget/integration test. |
| ERR-08 | Missing role/profile | Stop privileged navigation and show recoverable message. | Planned | Session-provider test. |
| ERR-09 | Crash/unhandled exception | Report through Crashlytics where supported and keep UI recoverable. | Planned | Monitoring configuration review. |

## GitHub and Documentation Checklist

| Checklist ID | Deliverable/check | Required evidence | Status |
|---|---|---|---|
| GIT-CHK-01 | Clean repository structure | Repository tree and architecture explanation | Planned |
| GIT-CHK-02 | Meaningful commits | Git history review | Planned |
| GIT-CHK-03 | Appropriate `.gitignore` | File review | Planned |
| GIT-CHK-04 | No committed secrets | Repository scan and reviewer confirmation | Planned |
| GIT-CHK-05 | Environment configuration | Setup documentation and example configuration | Planned |
| GIT-CHK-06 | Feature branches/PRs where practical | GitHub history, if used | Planned |
| GIT-CHK-07 | Optional GitHub Actions | Workflow file and successful run, if implemented | N/A |
| DOC-CHK-01 | README overview | README section | Planned |
| DOC-CHK-02 | Architecture documentation | Architecture document and diagram | Planned |
| DOC-CHK-03 | Technology stack documentation | README and architecture document | Planned |
| DOC-CHK-04 | Setup/run instructions | README with Flutter/Firebase/Emulator commands | Planned |
| DOC-CHK-05 | Test credentials or controlled setup | README; no secrets committed | Planned |
| DOC-CHK-06 | Database documentation | Database Design Document | Planned |
| DOC-CHK-07 | Security documentation | RBAC & Security Document | Planned |
| DOC-CHK-08 | User flows and state diagram | Companion diagrams | Planned |
| DOC-CHK-09 | UI/UX wireframes | Wireframe document | Planned |
| DOC-CHK-10 | Testing Plan | Testing Plan document | Planned |
| DOC-CHK-11 | Setup/deployment documentation | README / Setup & Deployment Document | Planned |
| DOC-CHK-12 | Cross-document consistency | Final traceability review | Planned |

## Submission Checklist

| Deliverable | Required | Evidence to collect | Status |
|---|---:|---|---|
| GitHub repository | Yes | Repository URL and commit history | Planned |
| Working Flutter mobile app | Yes | APK, device run, or live walkthrough | Planned |
| Working Flutter Web admin portal | Yes | Deployed URL or local walkthrough | Planned |
| Firebase backend and database | Yes | Firebase project/emulator configuration and data model | Planned |
| Authentication and RBAC | Yes | Login demo, Rules, and authorization tests | Planned |
| Logging/audit trail and error handling | Yes | Audit records, safe errors, and test evidence | Planned |
| Architecture/database/security documentation | Yes | Companion documents and diagrams | Planned |
| README with setup/test credentials | Yes | README review | Planned |
| Demo/walkthrough | Yes | Recorded or live walkthrough | Planned |

## Bonus Features Checklist

Bonus features are optional and must not delay or compromise the baseline requirements.

| Requirement ID | Optional feature | Baseline status | Acceptance condition if attempted | Status |
|---|---|---|---|---|
| BONUS-01 | Google/Apple login | Optional | Does not weaken email/password baseline or Rules. | N/A |
| BONUS-02 | Push notifications | Optional | Must not require FCM if the Spark/no-billing constraint would be violated; local notifications remain acceptable. | N/A |
| BONUS-03 | Offline support | Optional | Failed writes and synchronization behavior are documented and safe. | N/A |
| BONUS-04 | Additional automated tests | Optional | Tests add evidence without replacing mandatory authorization tests. | N/A |
| BONUS-05 | CI/CD | Optional | GitHub Actions remains compatible with the assignment constraints. | N/A |
| BONUS-06 | Analytics | Optional | No sensitive data is collected; no paid service is required. | N/A |
| BONUS-07 | Pagination | Optional | Queries remain bounded and UI behavior is verified. | N/A |
| BONUS-08 | Advanced search/filtering | Optional | Baseline request search/filtering remains complete first. | N/A |
| BONUS-09 | Docker | Optional | Does not introduce a replacement backend or paid dependency. | N/A |
| BONUS-10 | Production deployment | Optional | Deployment remains compatible with Firebase Hosting and documented scope. | N/A |

## Assumptions and Constraints

### Assumptions

| Assumption ID | Assumption | Impact |
|---|---|---|
| A-01 | Initial checklist status is Planned until repository and test evidence are reviewed. | Statuses must be updated during implementation. |
| A-02 | New public registrations create Customer accounts. | Agent/Admin accounts require controlled setup. |
| A-03 | The demo uses one organization and operational geography. | Multi-branch and territory behavior is excluded. |
| A-04 | Exact Firestore indexes are finalized after implemented queries are known. | Database Design Document must be updated before submission. |
| A-05 | The exact maximum text lengths and idempotency mechanism are implementation decisions. | Validators and duplicate-submission behavior must still be documented and tested. |
| A-06 | Crashlytics availability may vary by platform. | Supported targets and limitations must be documented. |

### Constraints

- Firebase Spark free plan only; no billing and no credit card.
- No Cloud Functions, triggers, scheduled functions, or other server-side functions.
- Flutter/Dart only for application code and UI.
- No Supabase, React, Next.js, Angular, or other UI frameworks.
- Business logic runs client-side but is enforced at the database layer through Firestore Security Rules.
- RBAC uses `users.role`; custom claims are not used.
- Audit logs and status history are written from the client; Rules prevent updates and deletes.
- Firebase Storage is only enabled if needed; baseline file upload is not required.
- FCM is skipped for the demo; local notifications are optional.
- Request codes use `REQ-YYYY-000123` and a Firestore transaction on `counters/{year}`.
- No passwords, tokens, API keys, or secrets may be logged or committed.

## Verification Notes

### Verification approach

Each requirement is verified through one or more of the following evidence types:

| Evidence type | Use |
|---|---|
| Code review | Confirm implementation location, shared rules, naming, and maintainability. |
| UI walkthrough | Demonstrate screens, role-specific actions, loading/empty/error states, and user-visible behavior. |
| Unit test | Verify validators, enums, lifecycle rules, and deterministic formatting. |
| Widget test | Verify screen states, form validation, navigation, and safe error presentation. |
| Integration test | Verify complete Customer, Agent, and Admin workflows. |
| Firestore Rules test | Prove database-layer access restrictions and append-only behavior. |
| Emulator Suite run | Verify Firebase Auth, Firestore, Rules, indexes, and local data behavior without production dependencies. |
| Repository review | Verify Git structure, commits, `.gitignore`, secret handling, and documentation. |
| Demo evidence | Provide screenshots, deployed URL, APK/build, or recorded walkthrough as appropriate. |

### Final verification checklist

Before submission, the evaluator or implementer should confirm:

- [ ] `Swasiq` is spelled correctly everywhere.
- [ ] The term `users.role` has no stray space.
- [ ] Stored role values are consistently `customer`, `agent`, and `admin`.
- [ ] Stored statuses are consistently `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`.
- [ ] The Customer can register/login, create a request, view it, and track status.
- [ ] The Agent can view only assigned requests, accept, update, add notes, and view completed work.
- [ ] The Admin can log in before accessing the portal.
- [ ] The Admin dashboard defines New as status `created`.
- [ ] The Admin can assign Agents and update permitted status transitions.
- [ ] Request codes match `REQ-YYYY-000123` and are transactionally generated.
- [ ] Customers cannot access another Customer’s request.
- [ ] Agents cannot access another Agent’s assigned work.
- [ ] Clients cannot update or delete status-history or audit records.
- [ ] Required events are recorded without secrets.
- [ ] Error states are safe and retryable where appropriate.
- [ ] All tables and collections match the Database Design Document.
- [ ] README, architecture, security, database, testing, wireframe, flow, and deployment documents are consistent.
- [ ] No paid service, Cloud Function, or non-Flutter UI framework is required.
- [ ] Submission artifacts and walkthrough are complete.

### Traceability maintenance

When a requirement changes, the implementer shall update:

1. This traceability matrix.
2. The PRD or source decision that changed.
3. The relevant architecture, database, security, flow, wireframe, testing, or README document.
4. The implementation and associated tests.
5. The verification evidence and status.

A requirement shall not be marked `Verified` without identifiable implementation and evidence.

## Glossary

| Term | Definition |
|---|---|
| Agent | Service worker who manages requests assigned to that Agent. |
| Admin | Administrator who manages operational data through the Flutter Web portal. |
| Audit trail | Append-only record of significant actor actions, targets, results, and timestamps. |
| Cloud Firestore | Firebase document database used for QuickServe application data. |
| Customer | End user who browses services and creates/tracks service requests. |
| Emulator Suite | Local Firebase services used for development and automated testing. |
| Firestore Security Rules | Database-layer conditions that control authenticated read/write access. |
| RBAC | Role-Based Access Control; permissions are determined by stored role. |
| Request code | Human-readable identifier such as `REQ-2026-000123`. |
| Request lifecycle | The status progression from `created` through operational states to `completed` or eligible `cancelled`. |
| Session persistence | Retaining a valid Firebase Authentication session across app restarts according to platform behavior. |
| Spark plan | Firebase free plan used by this project; no billing or credit card. |
| Status history | Append-only record of request status transitions. |
| Stored role | Lowercase Firestore value: `customer`, `agent`, or `admin`. |

## Appendix A — Requirement ID Index {.unnumbered}

| Prefix | Category |
|---|---|
| `FR-AUTH-*` | Authentication and session |
| `FR-C-*` | Customer functionality |
| `FR-A-*` | Agent functionality |
| `FR-AD-*` | Administrator functionality |
| `FR-X-*` | Cross-cutting functionality |
| `NFR-*` | Non-functional requirements |
| `DB-*` | Database requirements |
| `LOG-*` | Logging and audit requirements |
| `ERR-*` | Error-handling requirements |
| `TEST-*` | Testing requirements |
| `REQ-TEST-*` | Requirement-side testing anchors (Checklist only) |
| `GIT-*` | GitHub/repository requirements |
| `DOC-*` | Documentation requirements |
| `BONUS-*` | Optional bonus features |

## Appendix B — Required Screen List {.unnumbered}

Splash; Login; Admin Login; Registration; Home; Services; Create Request; My Requests; Request Details; Agent Request Details; Profile; Logout; Admin Dashboard; Admin Request Management; Admin Customer View; Admin Agent View; Admin Activity/Audit View.

## Appendix C — Required Event List {.unnumbered}

`LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, `DATABASE_ERROR`.

## Appendix D — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability — this document.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.

The companion documents must use the same roles, states, collections, stored enum values, event names, framework decisions, and billing constraints. The companion set must not introduce contradictory requirements.
