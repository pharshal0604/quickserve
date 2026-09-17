---
title: "QuickServe Testing Plan"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This Testing Plan defines the quality strategy, test levels, environments, test data, coverage areas, detailed test cases, authorization verification, lifecycle verification, UI validation, manual walkthrough, CI checks, exit criteria, and known testing risks for QuickServe.

QuickServe is a Service Request Management Application for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day Full-Stack Mobile Application challenge. Customers create and track service requests through Flutter mobile, Agents manage assigned work through Flutter mobile, and Admins manage operations through a Flutter Web portal.

### Scope

This plan covers:

- Firebase Authentication email/password flows.
- Role resolution through `users.role`.
- Firestore Security Rules as the authorization boundary.
- Request creation, request-code allocation, ownership, assignment, lifecycle transitions, cancellation, history, and audit behavior.
- Flutter mobile Customer and Agent screens.
- Flutter Web Admin screens.
- Riverpod providers, go_router redirects, Material 3 states, and form validation.
- Firebase Emulator Suite testing without paid services or real secrets.
- `flutter_test`, `integration_test`, and manual walkthrough evidence.

The plan does not introduce Cloud Functions, custom claims, FCM, Supabase, React, Next.js, Angular, a new collection, a new role, a new status, a new event, or a new product screen.

### Audience

This plan is intended for:

- Flutter/Dart developers writing unit, widget, repository, and integration tests.
- Firebase developers writing Firestore Rules tests and emulator seed data.
- QA reviewers evaluating authorization, lifecycle, error handling, and acceptance evidence.
- Internship evaluators reviewing implementation quality and Git/GitHub discipline.

### Relationship to companion documents

The Product Requirements Document (PRD) defines the product scope and acceptance expectations. The Requirements Checklist / Traceability document defines requirement IDs and evidence. The System Architecture Document defines application layers and Firebase flows. The Database Design Document defines collections and fields. The RBAC & Security Document defines authentication, `users.role`, ownership, assignment, field protection, append-only records, and Firestore Rules.

The User Flow Diagram Document defines user journeys and route outcomes. The Request Lifecycle / State Diagram Document defines the authoritative status graph and uses `TEST-LC-01` through `TEST-LC-21` for lifecycle scenarios. The UI/UX Wireframes Document defines screen structure and required UI states. This Testing Plan verifies those contracts without replacing them.

## Testing Goals and Quality Objectives

### Testing goals

The test suite must prove that:

- A valid authenticated user can reach the correct role experience.
- Customers, Agents, and Admins receive only their permitted data and operations.
- Firestore Rules deny unauthorized direct reads and writes even when the UI is bypassed.
- Request lifecycle transitions follow the finalized state graph.
- Customer cancellation is limited to requests in `created` or `assigned`.
- Agent operations are limited to assigned requests.
- Admin operations remain within the finalized operational permissions.
- Request codes follow `REQ-YYYY-000123` and counter conflicts do not create duplicates.
- Status history and audit logs are append-only and contain safe fields.
- Loading, empty, error, retry, validation, and permission-denied states are understandable.
- Failed writes are not reported as successful.
- The application works against the Firebase Emulator Suite without billing or real secrets.

### Definition of done

A feature is considered tested when:

1. Its repository and validation logic have unit coverage where practical.
2. Its critical widgets have loading, content, empty, error, and retry coverage.
3. Its authorization behavior has Emulator Rules coverage.
4. Its critical end-to-end flow has an integration test or documented manual walkthrough.
5. Requirement evidence is linked to finalized requirement IDs.
6. No known critical or high-severity defect remains open.
7. The final test run is reproducible from the repository setup instructions.
8. No password, token, API key, secret, or real customer data appears in source, fixtures, logs, or screenshots.

## Testing Levels

| Level | Scope | Primary tooling | Evidence |
|---|---|---|---|
| Unit | Dart models, enum parsing, validators, lifecycle transition helpers, safe audit serializer, request-code formatter | `flutter_test` | Test results and source-level coverage |
| Widget | Individual Flutter screens, reusable widgets, form states, loading/empty/error/retry behavior, route-aware UI | `flutter_test` | Widget test output and screenshots where useful |
| Integration | Authentication, repository flows, emulator-backed Customer, Agent, Admin, and cross-role scenarios | `integration_test`, Flutter driver support, Firebase Emulator Suite | Passing integration tests and captured evidence |
| Rules | Firestore allow/deny behavior for every role, ownership, assignment, field, transition, append-only, and counter path | Firebase Emulator Suite Rules test tooling | Rules test report |
| Manual walkthrough | Human review of navigation, accessibility, responsive behavior, safe messages, and demo flow | Android/iOS device or emulator, browser, Firebase Emulator Suite | Reviewer checklist and issue log |

### Unit testing scope

Unit tests must run without network access. They should verify deterministic application logic such as:

- Required-field validation.
- Priority and status enum parsing.
- Request-code formatting.
- Lifecycle transition eligibility.
- Customer cancellation eligibility.
- Safe audit field selection.
- Error-category mapping.
- Route redirect decisions using mocked authentication/profile state.

Unit tests do not replace Firestore Rules tests. A passing client validator is not evidence that an unauthorized direct database call is denied.

### Widget testing scope

Widget tests should use mocked Riverpod providers or repositories to control loading, success, empty, error, permission-denied, and stale-state outcomes. Critical controls must be located by semantic labels or stable keys rather than fragile screen coordinates.

### Integration testing scope

Integration tests connect the Flutter application to Firebase Emulator Suite services. They should create isolated test users and data, run one scenario, verify the visible result, and clean up or use an isolated emulator reset between scenarios.

### Rules testing scope

Rules tests run direct Firestore operations as different authenticated and unauthenticated actors. They must test both positive and negative paths and must not assume that hidden UI controls provide security.

### Manual walkthrough scope

Manual testing is required for visual hierarchy, keyboard navigation on Flutter Web, text scaling, responsive layouts, safe messages, and evaluator-facing demo evidence. Manual testing supplements, rather than replaces, automated tests.

## Test Environment

### Required environment

| Component | Test requirement |
|---|---|
| Flutter SDK | Version pinned or documented by the repository; run `flutter doctor` before testing |
| Dart SDK | Version supplied by the selected Flutter SDK |
| Node.js | Required by Firebase Emulator Suite tooling |
| Firebase CLI | Required to start and inspect local emulators |
| Firebase Emulator Suite | Authentication and Cloud Firestore local services |
| Android | Android emulator or supported device for Flutter mobile testing |
| iOS | iOS Simulator or supported device on macOS for Flutter mobile testing |
| Flutter Web | Supported browser for Admin portal testing |
| Test framework | `flutter_test` and `integration_test` |
| Source control | Git and GitHub; optional GitHub Actions |
| Billing | Firebase Spark free plan; no billing account or credit card |

### Emulator connections

The application must use emulator configuration in test and local development modes. Authentication and Firestore clients must connect to the local emulator host and ports defined in the repository configuration. Emulator use must be explicit so a test cannot accidentally write to a production Firebase project.

For Android emulators, use the documented host alias for the development machine. For iOS Simulator and Flutter Web, use the local machine host configuration documented by the repository. The exact ports must be kept in one configuration source and must not be duplicated across tests.

### Environment separation

| Environment | Data policy | Purpose |
|---|---|---|
| Unit test | In-memory or mocked | Fast deterministic logic tests |
| Widget test | Mocked repositories/providers | UI state and interaction tests |
| Emulator integration | Synthetic seed data only | Auth, Firestore, Rules, and end-to-end flows |
| Manual local demo | Emulator data only | Reviewer walkthrough |
| Production-like review | Only if separately authorized | Never use real secrets in the assignment test suite |

### Test isolation

Each Rules or integration scenario should use unique synthetic identifiers or reset the Emulator Suite between test groups. A failed test must not leave data that changes the result of a later test. Test users must have deterministic role profiles and must never use real email addresses or passwords.

## Test Data Strategy

### Seed users

| Fixture | Stored role | Purpose |
|---|---|---|
| `customerA` | `customer` | Owns baseline and positive Customer requests |
| `customerB` | `customer` | Cross-customer denial tests |
| `agentA` | `agent` | Owns assigned positive Agent scenarios |
| `agentB` | `agent` | Cross-agent denial tests |
| `adminA` | `admin` | Admin dashboard, assignment, audit, and operational scenarios |
| `noProfileUser` | No `users/{uid}` profile | Missing-profile recovery |
| `unauthenticated` | None | Protected data denial tests |

Synthetic emails and passwords must be generated for local tests only. No real credentials are permitted in fixtures.

### Seed services

| Service fixture | Name | Active state | Use |
|---|---|---|---|
| `serviceAc` | AC servicing | `true` | Positive service selection |
| `servicePlumbing` | Plumbing | `true` | Positive service selection |
| `serviceElectrical` | Electrical | `true` | Enum and list coverage |
| `serviceCleaning` | Cleaning | `true` | Enum and list coverage |
| `serviceInactive` | A finalized service record with `active: false` | `false` | Inactive service presentation if included in test data |

The services remain within the finalized service domain. The inactive fixture is used only if the implementation displays inactive records or verifies that inactive services cannot be selected.

### Seed requests

| Fixture | Customer | Agent | Status | Purpose |
|---|---|---|---|---|
| `requestCreated` | `customerA` | null | `created` | Customer creation and Admin assignment |
| `requestAssignedA` | `customerA` | `agentA` | `assigned` | Agent acceptance and Customer cancellation |
| `requestAcceptedA` | `customerA` | `agentA` | `accepted` | Agent start-work and Admin-only cancellation |
| `requestInProgressA` | `customerA` | `agentA` | `in_progress` | Agent completion and Admin-only cancellation |
| `requestCompletedA` | `customerA` | `agentA` | `completed` | Terminal-state and completed-work reads |
| `requestCancelledA` | `customerA` | null or finalized assigned value | `cancelled` | Terminal-state reads |
| `requestCustomerB` | `customerB` | `agentB` | `assigned` | Cross-customer and cross-agent denial |

Every request fixture must use the finalized request fields and a synthetic request code in the format `REQ-YYYY-000123`. Test data must not contain secrets or real personal information.

### Seed history, audit, and counters

- Create status-history records for each request state path using the finalized fields `fromStatus`, `toStatus`, `changedBy`, `changedAt`, and `note`.
- Create audit records using only the finalized events `LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, and `DATABASE_ERROR`.
- Seed `counters/{year}` with a known integer `lastRequestNumber` and verify controlled increments.
- Use synthetic actor IDs and safe old/new maps.

### Fixture cleanup

Test teardown must sign out users, clear Riverpod state, reset emulator data when the test group requires isolation, and remove temporary test artifacts. A test must not rely on a previous test's current authentication session.

## Test Categories and Coverage

### Authentication

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Registration | Customer creates Firebase account and customer profile | Unit, integration, Authentication Emulator record |
| Login | Customer, Agent, and Admin authenticate | Widget and integration tests |
| Password reset | User initiates reset with safe generic response | Widget and integration test |
| Session persistence | Valid session restores and profile resolves | Integration test |
| Profile failure | Missing profile or invalid profile does not enter protected content | Integration test |
| Logout | Session clears and correct Login route appears | Widget and integration tests |

### RBAC and Firestore Rules

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Customer ownership | Customer A cannot read Customer B's request | TEST-07 Rules test |
| Agent assignment | Agent A cannot read Agent B's assigned request | TEST-08 Rules test |
| Role immutability | Customer cannot change `users.role` to `admin` | TEST-09 Rules test |
| Unauthenticated denial | Unauthenticated user cannot access protected data | TEST-10 Rules test |
| Field protection | Immutable request/profile fields cannot be changed | TEST-PLAN-06 through TEST-PLAN-09 |
| Append-only records | History and audit update/delete are denied | TEST-PLAN-10, TEST-PLAN-11 |

### Request lifecycle transitions

The lifecycle tests use `TEST-LC-01` through `TEST-LC-21` from the Request Lifecycle / State Diagram Document. This plan references those IDs and does not redefine them.

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Creation | New request starts as `created` | TEST-PLAN-41 |
| Assignment | Admin moves `created` to `assigned` | TEST-LC-06 |
| Acceptance | Assigned Agent moves `assigned` to `accepted` | TEST-LC-02 |
| Work start | Assigned Agent moves `accepted` to `in_progress` | TEST-LC-09 |
| Completion | Assigned Agent moves `in_progress` to `completed` | TEST-LC-10 |
| Customer cancellation | Own Customer cancels only `created` or `assigned` | TEST-LC-01, TEST-LC-03, TEST-LC-04, TEST-LC-05 |
| Admin cancellation | Admin-only cancellation from later eligible states | TEST-LC-12, TEST-LC-13 |
| Terminal states | Completed and cancelled reject outgoing transitions | TEST-LC-11 and terminal-state tests |

### Request-code allocation and counter transaction

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Format | Code matches `REQ-YYYY-000123` | TEST-PLAN-12 |
| Sequential increment | Counter increments by one in a successful transaction | TEST-PLAN-13 |
| Conflict retry | Concurrent transactions retry safely | TEST-PLAN-14 |
| Duplicate prevention | One successful request does not create duplicate request code | TEST-PLAN-15 |
| Failed write | Unknown or failed result is not shown as success | TEST-PLAN-16 |

### Audit logging and safe fields

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Event names | Only finalized uppercase events are accepted | TEST-PLAN-17 |
| Actor identity | Audit actor UID and role match authenticated context | TEST-PLAN-18 |
| Safe fields | Old/new values contain only allowlisted data | TEST-PLAN-19 |
| Forbidden fields | Passwords, tokens, API keys, and secrets are absent | TEST-PLAN-20 |
| Append-only | Existing audit records cannot update or delete | TEST-PLAN-11 |

### Error handling and recovery

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Network failure | Read and write interruption offers safe recovery | TEST-PLAN-21 |
| Permission denied | Safe authorization message and valid route recovery | TEST-PLAN-22 |
| Missing profile | Retry or sign-out without role inference | TEST-PLAN-23 |
| Invalid transition | Client blocks and Rules deny stale/invalid transition | TEST-PLAN-24 |
| Counter conflict | Bounded retry without duplicate creation | TEST-PLAN-14 |
| Database error | Safe error mapping and optional safe `DATABASE_ERROR` event | TEST-PLAN-25 |

### UI states

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Loading | Splash, lists, details, forms, and Admin tables show progress | TEST-PLAN-26 |
| Empty | My Requests, Agent queue, services, and Admin lists explain no data | TEST-PLAN-27 |
| Error | Screen-level failures show safe message | TEST-PLAN-28 |
| Retry | Recoverable reads and writes offer retry without duplicate submission | TEST-PLAN-29 |
| Validation | Create Request and authentication forms show field errors | TEST-PLAN-30 |

### Navigation and route guards

| Coverage area | Scenarios | Evidence |
|---|---|---|
| Session redirect | Unauthenticated protected route returns to Login | TEST-PLAN-31 |
| Customer routing | Stored role `customer` reaches Customer Home | TEST-PLAN-32 |
| Agent routing | Stored role `agent` reaches Agent queue | TEST-PLAN-33 |
| Admin routing | Stored role `admin` reaches Admin Dashboard | TEST-PLAN-34 |
| Wrong-route protection | User cannot enter another role's protected screen through a deep link | TEST-PLAN-35 |
| Logout routing | Logout clears state and returns to correct Login screen | TEST-PLAN-36 |

## Detailed Test Cases

The following table contains the required RBAC anchors, references to lifecycle tests, and new tests using only the `TEST-PLAN-*` prefix. TEST-07 through TEST-10 remain definitions from the RBAC & Security Document and are used only for those authorization anchor scenarios.

| Test ID | Level | Scenario | Actor | Precondition | Steps (summary) | Expected Result | Requirement ID |
|---|---|---|---|---|---|---|---|
| TEST-07 | Rules | Customer A reads Customer B's request | Customer A | Customer B owns target request | Authenticate as Customer A; read Customer B request | Deny with permission-denied | FR-C-12, NFR-01 |
| TEST-08 | Rules | Agent A reads Agent B's assigned request | Agent A | Target is assigned to Agent B | Authenticate as Agent A; read target request | Deny with permission-denied | FR-A-08, NFR-01 |
| TEST-09 | Rules | Customer attempts to change `users.role` to `admin` | Customer | Own profile has role `customer` | Update only role to `admin` | Deny; stored role remains unchanged | FR-AUTH-08, NFR-01 |
| TEST-10 | Rules | Unauthenticated user reads or writes protected data | Unauthenticated | No Firebase session | Read and attempt write on protected paths | Deny all protected operations | FR-AUTH-08, NFR-01 |
| TEST-LC-01 | Rules/Integration | Own Customer cancels created request | Customer A | Own request is `created` | Submit cancellation with reason | `created -> cancelled` succeeds | FR-C-11, NFR-01 |
| TEST-PLAN-41 | Integration | Customer creates request in `created` | Customer | Valid form and counter fixture | Submit Create Request; inspect request and history | Request is created with status `created` and code | FR-C-07, FR-C-08 |
| TEST-LC-02 | Rules/Integration | Assigned Agent accepts request | Agent A | Request is `assigned` to Agent A | Submit accept transition | `assigned -> accepted` succeeds with history | FR-A-03, NFR-01 |
| TEST-LC-03 | Rules/Integration | Own Customer cancels assigned request | Customer A | Own request is `assigned` | Submit cancellation with reason | `assigned -> cancelled` succeeds | FR-C-11, NFR-01 |
| TEST-LC-04 | Rules | Customer cancels accepted request | Customer A | Own request is `accepted` | Attempt cancellation write | Deny; Customer may cancel only `created` or `assigned` | FR-C-11, NFR-01 |
| TEST-LC-05 | Rules | Customer cancels in-progress request | Customer A | Own request is `in_progress` | Attempt cancellation write | Deny; Admin-only later cancellation | NFR-01 |
| TEST-LC-06 | Rules/Integration | Admin assigns an eligible Agent | Admin A | Request is `created`; Agent profile exists | Assign Agent and update request | `created -> assigned` succeeds | FR-AD-06, NFR-01 |
| TEST-LC-07 | Rules | Agent A acts on Agent B request | Agent A | Target assigned to Agent B | Attempt accept or read | Deny | FR-A-08, NFR-01 |
| TEST-LC-08 | Rules | Agent skips states | Agent A | Request is `created` | Attempt `created -> in_progress` | Deny | FR-A-04, NFR-01 |
| TEST-LC-09 | Rules/Integration | Agent starts accepted work | Agent A | Request is `accepted` and assigned | Submit start-work transition | `accepted -> in_progress` succeeds | FR-A-04, NFR-01 |
| TEST-LC-10 | Rules/Integration | Agent completes in-progress work | Agent A | Request is `in_progress` and assigned | Submit completion | `in_progress -> completed` succeeds and becomes terminal | FR-A-05, NFR-01 |
| TEST-LC-11 | Rules | Terminal request is changed | Agent A or Admin A | Request is `completed` or `cancelled` | Attempt any outgoing transition | Deny | FR-A-07, NFR-01 |
| TEST-LC-12 | Rules/Integration | Admin cancels accepted request | Admin A | Admin operational policy permits it | Submit cancellation | Allow if finalized policy permits; otherwise deny | FR-AD-07, NFR-01 |
| TEST-LC-13 | Rules/Integration | Admin cancels in-progress request | Admin A | Admin operational policy permits it | Submit cancellation | Allow if finalized policy permits; otherwise deny | FR-AD-07, NFR-01 |
| TEST-LC-14 | Rules | Cross-customer lifecycle write | Customer A | Target belongs to Customer B | Attempt update or cancellation | Deny | FR-C-12, TEST-07, NFR-01 |
| TEST-LC-15 | Rules | Unauthenticated lifecycle write | Unauthenticated | No session | Attempt status update | Deny | FR-AUTH-08, NFR-01 |
| TEST-LC-16 | Rules | Status history update/delete | Any role | Existing history document | Attempt update and delete | Deny both operations | NFR-01 |
| TEST-LC-17 | Rules | Audit log update/delete | Any role | Existing audit document | Attempt update and delete | Deny both operations | LOG-05, NFR-01 |
| TEST-LC-18 | Rules | Counter increments by more than one | Customer | Existing counter | Write a jump in `lastRequestNumber` | Deny | NFR-01 |
| TEST-LC-19 | Integration | Valid request-code transaction | Customer | Counter initialized | Create request through repository transaction | Unique formatted code and request created | FR-C-07, FR-C-08 |
| TEST-LC-20 | Integration | Failed request write is reported | Customer | Simulated database failure | Submit request; inspect UI | No success state; safe error shown | NFR-05 |
| TEST-LC-21 | Rules | Audit event contains forbidden field | Any role | Audit builder attempts secret field | Attempt audit write | Serializer rejects before write or Rules deny invalid record | NFR-02, LOG-07 |
| TEST-PLAN-01 | Unit | Email/password form validation | Customer | Empty and malformed values | Run validator cases | Correct field errors are returned | FR-AUTH-01, FR-AUTH-03 |
| TEST-PLAN-02 | Integration | Customer registration creates profile | Customer | Valid synthetic credentials | Register; read profile | Profile uses authenticated UID and role `customer` | FR-AUTH-01, FR-AUTH-02 |
| TEST-PLAN-03 | Integration | Session persistence restores role | Customer | Signed-in session exists | Restart app; wait for profile | Customer route loads only after profile resolution | FR-AUTH-05 |
| TEST-PLAN-04 | Integration | Password reset initiation | Customer | Login screen available | Submit reset email | Safe generic result; no secret displayed | FR-AUTH-06 |
| TEST-PLAN-05 | Rules | User profile immutable fields | Customer | Own profile exists | Attempt role/email/createdAt update | Deny immutable changes | NFR-01 |
| TEST-PLAN-06 | Rules | Request identity fields immutable | Agent or Admin | Existing request | Change customerId, requestCode, service, or description | Deny | NFR-01 |
| TEST-PLAN-07 | Rules | Agent update limited to status fields | Agent | Assigned request | Change address or priority with status | Deny | NFR-01 |
| TEST-PLAN-08 | Rules | Admin assignment field boundary | Admin | Created request | Change description while assigning | Deny | FR-AD-06, NFR-01 |
| TEST-PLAN-09 | Rules | Invalid priority or status enum | Customer or Agent | Valid request path | Write unsupported enum value | Deny | NFR-01 |
| TEST-PLAN-10 | Rules | Status-history append-only | Any role | Existing history | Update and delete | Deny | NFR-01 |
| TEST-PLAN-11 | Rules | Audit append-only | Any role | Existing audit log | Update and delete | Deny | LOG-05, NFR-01 |
| TEST-PLAN-12 | Unit | Request-code format | Customer | Year and sequence values | Format multiple values | All codes match `REQ-YYYY-000123` | FR-C-07 |
| TEST-PLAN-13 | Integration | Counter increments once | Customer | Counter has known number | Create one request | Counter increases by one and request code matches | FR-C-07, NFR-01 |
| TEST-PLAN-14 | Integration | Counter transaction conflict | Customer A and Customer B | Both create concurrently | Start overlapping transactions | Transactions retry safely; no duplicate code | FR-C-07, NFR-05 |
| TEST-PLAN-15 | Integration | Duplicate request prevention | Customer | Retry after uncertain result | Re-read before retry; inspect requests | One logical submission creates at most one confirmed request | NFR-05 |
| TEST-PLAN-16 | Integration | Unknown write result | Customer | Simulated network interruption | Submit request; reconnect; inspect data | UI does not show false success or blindly duplicate | NFR-05 |
| TEST-PLAN-17 | Unit/Rules | Event enum validation | Any role | Audit builder available | Try fixed and unsupported action values | Fixed events accepted; unsupported values rejected | LOG-07 |
| TEST-PLAN-18 | Rules | Audit actor identity | Signed-in role | Authenticated profile exists | Write mismatched actor UID or role | Deny | NFR-01, LOG-07 |
| TEST-PLAN-19 | Unit | Audit safe-field serializer | Any role | Request and exception objects available | Serialize approved and forbidden fields | Only allowlisted values remain | NFR-02, LOG-07 |
| TEST-PLAN-20 | Integration | Forbidden secret logging | Any role | Synthetic secret marker | Trigger logging and audit paths | Passwords, tokens, API keys, and secrets absent | NFR-02 |
| TEST-PLAN-21 | Integration | Network read/write failure | Customer | Emulator connection can be interrupted | Load list and submit write during interruption | Safe error, retry path, no false success | NFR-05, NFR-06 |
| TEST-PLAN-22 | Integration | Permission-denied UI mapping | Customer or Agent | Unauthorized target exists | Trigger denied read/write | Safe authorization message and valid route recovery | NFR-01, NFR-06 |
| TEST-PLAN-23 | Integration | Missing profile recovery | Authenticated user | No `users/{uid}` profile | Start app and resolve session | No role inferred; retry or sign-out path shown | FR-AUTH-05, NFR-01 |
| TEST-PLAN-24 | Unit/Rules | Invalid transition mapping | Any lifecycle actor | Stale or invalid state | Validate client and direct Rules write | Client blocks; Rules deny | NFR-01 |
| TEST-PLAN-25 | Integration | Database error mapping | Any role | Emulator returns database failure | Trigger operation | Safe error and optional safe `DATABASE_ERROR` event | NFR-06 |
| TEST-PLAN-26 | Widget | Loading states | All relevant screens | Provider loading state | Pump widgets with loading state | Skeleton/progress appears and duplicate actions disabled | NFR-06 |
| TEST-PLAN-27 | Widget | Empty states | Customer, Agent, Admin | Empty provider results | Pump each list screen | Clear empty explanation and valid next action | NFR-06 |
| TEST-PLAN-28 | Widget | Error states | All relevant screens | Provider error state | Pump error result | Safe error banner and recovery action appear | NFR-06 |
| TEST-PLAN-29 | Widget/Integration | Retry behavior | Customer or Agent | First operation fails, second succeeds | Tap Retry | Operation retries without duplicate submission | NFR-05, NFR-06 |
| TEST-PLAN-30 | Widget | Create Request validation | Customer | Missing and invalid fields | Submit form | Field errors appear; no database write occurs | FR-C-04, FR-C-05, FR-C-06 |
| TEST-PLAN-31 | Integration | Unauthenticated route guard | Unauthenticated | Protected route deep link | Open route | Redirect to Login; data remains protected | FR-AUTH-05, NFR-01 |
| TEST-PLAN-32 | Integration | Customer route resolution | Customer | Valid customer profile | Sign in and resolve | Customer Home loads | FR-C-01, FR-C-02, FR-AUTH-05 |
| TEST-PLAN-33 | Integration | Agent route resolution | Agent | Valid agent profile | Sign in and resolve | Agent queue loads | FR-A-01, FR-AUTH-05 |
| TEST-PLAN-34 | Integration | Admin route resolution | Admin | Valid admin profile | Sign in and resolve | Admin Dashboard loads | FR-AD-LOGIN-01, FR-AD-01 |
| TEST-PLAN-35 | Integration | Wrong-role deep link | Customer or Agent | Valid session and another role route | Open Admin/Agent route | Redirect or deny safely | NFR-01, FR-AUTH-05 |
| TEST-PLAN-36 | Integration | Logout routing | Customer, Agent, or Admin | Authenticated session | Select Logout | Session clears and correct Login appears | FR-AUTH-04 |
| TEST-PLAN-37 | Widget | Customer Request Details cancellation visibility | Customer | Requests in all statuses | Pump detail screen per status | Cancel action appears only for `created` and `assigned` | FR-C-11 |
| TEST-PLAN-38 | Widget | Agent status-action visibility | Agent | Assigned request in each state | Pump detail screen | Only valid next action appears | FR-A-03, FR-A-04, FR-A-05 |
| TEST-PLAN-39 | Widget | Admin table filters | Admin | Seeded request fixtures | Apply status, priority, and service filters | Results and empty state match filter | FR-AD-03, FR-AD-04 |
| TEST-PLAN-40 | Manual | Keyboard and responsive Admin review | Admin reviewer | Web build available | Tab through shell, filters, table, dialogs at widths | Focus order, scaling, and layout are usable | NFR-06 |

## Authorization Test Matrix

| Role | Operation | Expected result | Primary evidence |
|---|---|---|---|
| Unauthenticated | Read `users`, `services`, `requests`, histories, or audit data | Deny for protected paths | TEST-10 |
| `customer` | Read own request | Allow | TEST-PLAN-32 |
| `customer` | Read another customer's request | Deny | TEST-07 |
| `customer` | Create own request with status `created` | Allow when fields are valid | TEST-PLAN-41 |
| `customer` | Create request with another customer ID | Deny | TEST-PLAN-06 |
| `customer` | Cancel own `created` request | Allow | TEST-LC-01 |
| `customer` | Cancel own `assigned` request | Allow | TEST-LC-03 |
| `customer` | Cancel own `accepted` or `in_progress` request | Deny | TEST-LC-04, TEST-LC-05 |
| `customer` | Change `users.role` | Deny | TEST-09 |
| `agent` | Read assigned request | Allow | TEST-LC-02 |
| `agent` | Read another Agent's assigned request | Deny | TEST-08 |
| `agent` | Accept assigned request | Allow | TEST-LC-02 |
| `agent` | Update unassigned request | Deny | TEST-LC-07 |
| `agent` | Change immutable request fields | Deny | TEST-PLAN-07 |
| `admin` | Read permitted operational request | Allow | TEST-PLAN-39 |
| `admin` | Assign eligible Agent | Allow | TEST-LC-06 |
| `admin` | Perform unapproved arbitrary update | Deny | TEST-PLAN-08 |
| Any role | Update existing status history | Deny | TEST-LC-16 |
| Any role | Delete existing audit log | Deny | TEST-LC-17 |

## Rules Test Checklist

The following checklist must be implemented against Firebase Emulator Suite. Each item must verify the actual Firestore result.

| Checklist item | Allow/Deny | Verification |
|---|---|---|
| Signed-in user reads own profile | Allow | Owner profile read |
| Signed-in user reads another profile | Deny unless permitted Admin view | Profile access test |
| Self-registration creates role `customer` | Allow | Profile creation test |
| Self-registration creates role `agent` or `admin` | Deny | Role escalation test |
| Own profile updates name/phone/updatedAt | Allow | Profile update test |
| Own profile updates role/email/createdAt | Deny | Immutable profile test |
| Signed-in user reads services | Allow | Service catalog read |
| Unauthorized service create/update/delete | Deny | Service Rules tests |
| Admin permitted service management | Allow if enabled by final policy | Admin service Rules test |
| Customer creates valid own request | Allow | Request creation test |
| Customer creates request for another UID | Deny | Ownership create test |
| Request initial status is not `created` | Deny | Initial-state test |
| Invalid priority | Deny | Enum validation test |
| Customer reads own request | Allow | Ownership read test |
| Customer reads another customer's request | Deny | TEST-07 |
| Agent reads assigned request | Allow | Assignment read test |
| Agent reads another Agent's request | Deny | TEST-08 |
| Admin reads permitted request | Allow | Admin read test |
| Agent accepts assigned request | Allow | TEST-LC-02 |
| Agent accepts unassigned request | Deny | Assignment update test |
| Agent skips lifecycle state | Deny | TEST-LC-08 |
| Customer cancels own `created` request | Allow | TEST-LC-01 |
| Customer cancels own `assigned` request | Allow | TEST-LC-03 |
| Customer cancels own `accepted` request | Deny | TEST-LC-04 |
| Customer cancels own `in_progress` request | Deny | TEST-LC-05 |
| Admin performs permitted assignment | Allow | TEST-LC-06 |
| Admin changes immutable request fields | Deny | TEST-PLAN-08 |
| Existing status history update/delete | Deny | TEST-LC-16 |
| Existing audit log update/delete | Deny | TEST-LC-17 |
| Counter read | Deny | TEST-PLAN-13 |
| Counter increment by exactly one in supported path | Allow | TEST-PLAN-13 |
| Counter jump, decrease, or extra field | Deny | TEST-LC-18 |
| Audit action outside fixed event list | Deny | TEST-PLAN-17 |
| Audit actor UID/role mismatch | Deny | TEST-PLAN-18 |
| Unauthenticated protected operation | Deny | TEST-10 |
| Catch-all unspecified path | Deny | Rules default-deny test |

## Request-Code and Concurrency Tests

### Format verification

The request-code formatter must be tested with boundary years and sequence values. Every successful result must match `REQ-YYYY-000123`, with a four-digit year and six-digit zero-padded number.

### Transaction conflict simulation

Use two synthetic Customer sessions and coordinate overlapping request creation attempts against the same `counters/{year}` document. Verify that Firestore transaction retry behavior produces distinct sequence values, both request documents remain valid, and no UI reports a request as successful before the transaction returns success.

### Duplicate prevention

Simulate an interrupted client after a transaction commit but before the UI receives the response. On reconnect, the repository must inspect existing data or use its documented idempotency strategy before retrying. The test must verify that a user does not receive two confirmed requests for one logical submission.

### Counter failure behavior

Simulate permission denial, malformed counter data, unavailable emulator connection, and transaction exhaustion. Verify safe error mapping, no invalid request code, no false success, and no secret-bearing logs.

### Evidence

Capture transaction logs that contain only synthetic IDs and safe sequence information. Never include passwords, tokens, API keys, or secrets in test output.

## Audit and Logging Tests

### Event validation

Test only these fixed event values:

```text
LOGIN_SUCCESS
REQUEST_CREATED
REQUEST_ASSIGNED
REQUEST_UPDATED
AUTHORIZATION_FAILED
DATABASE_ERROR
```

An unsupported event must be rejected by the client serializer and/or Firestore Rules. Stored event values remain uppercase exactly as shown.

### Safe-field verification

Verify that audit records contain only the finalized fields `actorUserId`, `actorRole`, `action`, `targetType`, `targetId`, `oldValue`, `newValue`, `result`, and `timestamp`. Verify that old/new maps contain only allowlisted status, assignment, request-code, or safe operational values.

### Forbidden-field scan

Use synthetic marker strings such as `TEST_PASSWORD`, `TEST_TOKEN`, `TEST_API_KEY`, and `TEST_SECRET` in negative tests. Verify that these markers are rejected or omitted before audit/log write and do not appear in captured logs, Crashlytics test output, or repository artifacts.

### Append-only verification

Create a valid status-history record and a valid audit record. Attempt update and delete as Customer, Agent, and Admin. Every update and delete must be denied. Read behavior must remain according to the RBAC & Security contract.

## Error-Handling Tests

### Network failure

Disable or interrupt the emulator connection during list reads, detail reads, request creation, status update, and logout. Verify a safe error, preserved user input where appropriate, retry action, and no duplicate submission.

### Permission denied

Trigger TEST-07, TEST-08, TEST-09, and TEST-10 through direct Rules operations and through the UI where applicable. Verify a safe authorization message, correct route recovery, and an optional safe `AUTHORIZATION_FAILED` event.

### Missing profile

Authenticate a synthetic user with no `users/{uid}` profile. Start the application and verify that it does not infer `customer`, `agent`, or `admin`. Verify retry, sign-out, or the finalized support recovery path.

### Invalid transition

Use stale request state, unsupported target status, skipped lifecycle edges, terminal-state updates, and Customer cancellation from `accepted` or `in_progress`. Verify client validation and direct Rules denial.

### Counter conflict

Run overlapping request creation transactions and force a retryable conflict. Verify distinct codes, safe retry behavior, and no false success.

### Database error

Use emulator failure or a controlled repository error to verify safe display, typed error mapping, optional `DATABASE_ERROR` event, and absence of raw exception or credential output.

## UI and Widget Tests

### Critical screens

| Screen | Critical widget coverage |
|---|---|
| Splash | Loading, profile success, missing profile, retry, sign-out recovery |
| Login | Required fields, invalid credentials, loading, password reset action |
| Registration | Field validation, loading, customer profile creation result |
| Home | Customer actions, Agent queue entry, empty/error summary |
| Services | Loading, service list, empty, error, retry |
| Create Request | All fields, priority selection, validation, pending write, success code |
| My Requests | Loading, list, empty, error, retry, request navigation |
| Request Details | Status display, timeline, eligible cancellation, terminal state |
| Agent Request Details | Assignment, status action visibility, note, terminal state |
| Profile | Read, permitted update, role display, logout |
| Admin Login | Authentication, role mismatch, error, loading |
| Admin Dashboard | Summary loading, zero values, error, retry, navigation |
| Admin Request Management | Search/filter states, table loading, empty, error, detail navigation |
| Admin Customer View | List loading, empty, error, safe fields |
| Admin Agent View | List loading, empty, error, safe fields |
| Admin Activity/Audit View | Safe event rendering, empty, error, retry, no edit/delete controls |

### Form validation assertions

- Required fields are identified consistently.
- Invalid values show inline messages near the relevant field.
- The first invalid field receives focus where supported.
- A failed validation does not write to Firestore.
- Submit controls are disabled while a request is pending.
- Stored enum values remain lowercase even when display labels are title case.

### UI state assertions

Widget tests must assert visible content and semantics for loading, empty, error, retry, permission-denied, and success states. A test that only verifies a provider state without pumping the relevant widget is insufficient for screen acceptance.

## Integration Test Scenarios

### Customer flow

1. Start Authentication and Firestore emulators.
2. Register a synthetic Customer.
3. Verify `users/{uid}` contains role `customer`.
4. Restore the session and verify Customer Home.
5. Browse Services.
6. Create a request with valid fields and priority `medium`.
7. Verify request code format and initial status `created`.
8. Open My Requests and Request Details.
9. Cancel a request from `created` or `assigned` where the fixture permits.
10. Verify `cancelled` is terminal and the timeline is visible.
11. Logout and verify Login.

### Agent flow

1. Seed or provision a synthetic Agent profile.
2. Sign in as Agent.
3. Verify Agent queue is the primary route.
4. Confirm an assigned request is visible.
5. Open Agent Request Details.
6. Accept `assigned` request.
7. Move it to `in_progress`.
8. Add a safe note if supported by the workflow.
9. Complete the request.
10. Verify completed work is read-only for lifecycle actions.
11. Attempt another Agent's request and verify denial.

### Admin flow

1. Seed or provision a synthetic Admin profile.
2. Sign in through Admin Login.
3. Verify Admin Dashboard.
4. Verify Dashboard counts and zero/loaded states.
5. Search and filter requests using supported queries.
6. Open Admin request details.
7. Assign an eligible Agent to a `created` request.
8. Perform only finalized permitted status updates.
9. View Customer and Agent lists.
10. View Activity/Audit records without edit/delete controls.
11. Logout and verify Admin Login.

### Cross-role handoff

1. Customer creates a request.
2. Admin reads the request and assigns Agent A.
3. Agent A accepts and starts work.
4. Customer refreshes My Requests and sees status changes permitted by the role.
5. Agent A completes the request.
6. Customer sees `completed` as terminal.
7. Verify status history and safe audit records exist according to the finalized write pattern.

## Manual Demo and Walkthrough Script

1. Start Firebase Authentication and Firestore emulators.
2. Launch the Flutter mobile app and show Splash session resolution.
3. Register a synthetic Customer and show that the stored role is `customer`.
4. Browse AC servicing, Plumbing, Electrical, and Cleaning.
5. Create a request with description, preferred date/time, address, and priority.
6. Show the generated `REQ-YYYY-000123` code and `created` status.
7. Open My Requests and Request Details.
8. Demonstrate cancellation only when the request is `created` or `assigned`.
9. Sign out.
10. Sign in as an Agent and show the assigned work queue.
11. Accept an assigned request and show `accepted`.
12. Move it to `in_progress`, add a safe note if supported, and complete it.
13. Sign out.
14. Sign in through Admin Login and show Admin Dashboard.
15. Search/filter requests and assign an eligible Agent to a created request.
16. Show Customer View and Agent View with safe fields only.
17. Show Activity/Audit View and verify event labels and timestamps.
18. Attempt a cross-customer or cross-agent access path and show safe denial behavior.
19. Resize the browser and demonstrate responsive Admin layout.
20. Use keyboard navigation on the Admin shell and verify focus visibility.
21. Stop or interrupt the emulator connection and show safe error and Retry behavior.
22. Capture only synthetic data in screenshots and logs.

## CI/CD Testing

### Optional GitHub Actions workflow

GitHub Actions is optional. If enabled, the workflow should run on pull requests and the primary branch using a pinned Flutter environment and the repository's documented Node/Firebase CLI setup.

Recommended checks:

1. Check out the repository.
2. Set up the documented Flutter SDK.
3. Run formatting and static analysis.
4. Run unit and widget tests.
5. Install or invoke Firebase Emulator Suite tooling.
6. Start Authentication and Firestore emulators.
7. Run Rules and integration tests against emulators.
8. Upload test reports and logs without secrets.

### CI restrictions

CI must not require a paid Firebase plan, billing account, credit card, Cloud Functions deployment, or real credentials. Secrets used by CI infrastructure, if any, must not be copied into application logs or test fixtures.

### CI failure policy

A failed Rules test, authentication integration test, lifecycle test, or critical widget test blocks acceptance. Flaky tests must be diagnosed rather than ignored. Emulator startup failures must be reported distinctly from application assertion failures.

## Test Tooling Summary

| Tool | Purpose | Requirement coverage |
|---|---|---|
| `flutter_test` | Unit and widget tests | Validation, UI states, repository helpers, route decisions |
| `integration_test` | End-to-end Flutter scenarios | Customer, Agent, Admin, cross-role flows |
| Firebase Emulator Suite | Local Authentication and Firestore | Rules, data, transactions, safe test isolation |
| Firebase CLI | Start, inspect, and reset emulators | Reproducible local and CI test environment |
| Flutter SDK | Build and run mobile/Web clients | Platform compatibility |
| Dart analyzer | Static analysis | Code quality and type safety |
| Git | Versioned test evidence and history | Git/GitHub discipline |
| GitHub Actions | Optional repeatable CI | Pull-request and branch validation |
| Material 3 test finders/semantics | Accessible widget interaction | Screen and accessibility assertions |

## Exit Criteria

### Required before submission

- All four RBAC anchors TEST-07 through TEST-10 pass.
- All referenced lifecycle scenarios TEST-LC-01 through TEST-LC-21 are implemented or explicitly marked not applicable with evidence.
- No critical or high-severity authorization defect remains open.
- Customer cancellation from `accepted` and `in_progress` is denied.
- Cross-customer and cross-agent access is denied.
- `users.role` cannot be self-promoted.
- Unauthenticated protected access is denied.
- Request-code format and counter transaction tests pass.
- Audit event, safe-field, forbidden-field, and append-only tests pass.
- Loading, empty, error, retry, and validation states exist on required screens.
- Customer, Agent, Admin, and cross-role integration flows pass against emulators.
- Manual demo walkthrough is completed on the available mobile and Web targets.
- No real credentials, secrets, or customer data are present in the repository or artifacts.
- Test commands and environment setup are documented and reproducible.

### Evidence package

The submission should retain:

- Test source files.
- Emulator Rules test output.
- Flutter test output.
- Integration test output.
- Manual walkthrough checklist.
- Defect list and disposition.
- Safe screenshots or screen recordings where useful.
- Git history showing meaningful implementation and test commits.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| UI hides an unauthorized action but Rules are untested | Security defect | Direct Emulator Rules tests for every role/path |
| Client validation differs from Rules | Confusing failures or data exposure | Test valid and invalid operations through both repository and direct Firestore calls |
| Test data leaks between scenarios | False passes or failures | Reset emulator data or isolate fixture IDs per test |
| Counter conflict creates duplicate request code | Data integrity defect | Concurrent transaction tests and read-before-retry behavior |
| Audit log contains a secret | Credential exposure | Safe-field serializer, forbidden-marker tests, repository scan |
| Status transition becomes stale | Incorrect lifecycle state | Transaction/re-read behavior and stale-state tests |
| Emulator configuration points to production | Data loss or privacy incident | Explicit emulator connection configuration and CI checks |
| Flutter Web layout fails at narrow width | Admin usability defect | Responsive manual walkthrough and widget tests |
| Accessibility is checked only visually | Exclusion or navigation defect | Semantics, keyboard, focus, text-scale, and contrast checks |
| Spark limits affect broad Admin queries | Slow or failing Admin portal | Bounded queries, indexes, fixture-sized tests, no unapproved search service |
| Optional CI environment differs from local | False CI result | Pin tool versions and document emulator startup |
| Missing profile blocks valid session | Routing confusion | Explicit missing-profile test and safe recovery state |

## Open Questions and Assumptions

### Open questions

| ID | Question | Testing impact | Default assumption |
|---|---|---|---|
| OQ-01 | Which exact Admin transitions are operationally permitted? | Determines positive Admin lifecycle tests. | Run allow tests only for transitions approved by the finalized RBAC policy; run deny tests for all others. |
| OQ-02 | Must audit persistence block the primary operation if audit write fails? | Determines expected partial-failure result. | Follow the finalized RBAC and repository contract and test the selected behavior explicitly. |
| OQ-03 | What exact Flutter and Node versions are pinned? | Determines CI reproducibility. | Use the versions documented in repository setup and fail early when unavailable. |
| OQ-04 | Are status-history notes visible to Customers? | Determines detail-view assertions. | Follow the finalized PRD and RBAC decision; do not expose notes by assumption. |
| OQ-05 | What browser/device matrix is available to the evaluator? | Determines manual coverage depth. | Test at least one supported Android/iOS path and one Flutter Web browser where available. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | The Firebase Emulator Suite is the default environment for automated Authentication, Firestore, Rules, and integration tests. |
| ASSUMP-02 | All fixtures use synthetic users, timestamps, request codes, notes, and audit values. |
| ASSUMP-03 | `users.role` is read from Firestore because custom claims are excluded. |
| ASSUMP-04 | The Request Lifecycle document remains authoritative for TEST-LC-01 through TEST-LC-21. |
| ASSUMP-05 | The RBAC & Security Document remains authoritative for TEST-07 through TEST-10. |
| ASSUMP-06 | The test suite may use helper utilities and fixture factories, but those helpers must not weaken Rules tests by bypassing Firestore. |
| ASSUMP-07 | No automated test depends on a paid Firebase service or Cloud Functions. |
| ASSUMP-08 | Requirement IDs in this document use the finalized checklist vocabulary and do not create new requirement prefixes. |

## Glossary

| Term | Definition |
|---|---|
| Allow test | A test that verifies an explicitly authorized operation succeeds. |
| Deny test | A test that verifies an unauthorized or invalid operation is rejected. |
| Emulator Suite | Local Firebase Authentication and Cloud Firestore services used for testing. |
| Fixture | Synthetic test data prepared for a repeatable scenario. |
| Integration test | Test that exercises multiple application components and emulator services together. |
| Lifecycle test | Test covering a request state or transition defined by the Request Lifecycle document. |
| Rules test | Direct Firestore operation test evaluated by Firestore Security Rules. |
| Safe field | A value allowed in UI, audit, or test output that does not contain credentials or secrets. |
| Stored role | Lowercase value in `users.role`: `customer`, `agent`, or `admin`. |
| Terminal status | `completed` or `cancelled`, with no valid outgoing transition. |
| Test anchor | Existing test ID defined by a companion document and referenced without redefinition. |
| Test isolation | Keeping one scenario's data and authentication state from affecting another scenario. |

## Appendix A — Full Test Case Inventory {.unnumbered}

| Test ID range or ID | Area | Level | Expected evidence |
|---|---|---|---|
| TEST-07 | Cross-customer read denial | Rules | Permission denied |
| TEST-08 | Cross-agent read denial | Rules | Permission denied |
| TEST-09 | Customer self-promotion denial | Rules | Permission denied and unchanged role |
| TEST-10 | Unauthenticated protected access denial | Rules | All protected operations denied |
| TEST-LC-01 through TEST-LC-21 | Request lifecycle | Rules/Integration | State graph and actor permissions verified |
| TEST-PLAN-01 through TEST-PLAN-11 | Auth, profiles, fields, append-only | Unit/Rules/Integration | Correct validation and denial behavior |
| TEST-PLAN-12 through TEST-PLAN-16 | Request code and concurrency | Unit/Integration | Format, uniqueness, conflict, and no false success |
| TEST-PLAN-17 through TEST-PLAN-20 | Audit and safe logging | Unit/Rules/Integration | Fixed events and no forbidden fields |
| TEST-PLAN-21 through TEST-PLAN-25 | Error handling | Integration | Safe recovery and typed failures |
| TEST-PLAN-26 through TEST-PLAN-30 | UI states and validation | Widget | Loading, empty, error, retry, and field validation |
| TEST-PLAN-31 through TEST-PLAN-36 | Navigation and route guards | Integration | Role-correct route behavior |
| TEST-PLAN-37 through TEST-PLAN-40 | Critical UI actions and manual review | Widget/Manual | Correct action visibility and responsive access |

## Appendix B — Emulator Setup Commands {.unnumbered}

The following are test-side commands for Windows `cmd.exe` and are not part of the application document contract. They use local emulator services and do not require billing.

```cmd
flutter pub get
```

```cmd
firebase emulators:start --only auth,firestore
```

```cmd
flutter test
```

```cmd
flutter test integration_test
```

```cmd
flutter analyze
```

If the repository uses a documented project-specific emulator test script, run that script after the Authentication and Firestore emulators are available. Do not point automated tests at a production Firebase project.

## Appendix C — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan — this document.
10. README / Setup & Deployment Documentation.
