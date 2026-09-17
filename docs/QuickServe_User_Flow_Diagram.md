---
title: "QuickServe User Flow Diagram Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This User Flow Diagram Document defines the user journeys, navigation behavior, role-specific screens, authorization boundaries, recovery paths, and traceability of QuickServe. The diagrams are implementation-oriented and are intended to guide Flutter mobile, Flutter Web, Riverpod, go_router, Firebase Authentication, Cloud Firestore, and Firestore Security Rules implementation.

QuickServe is a small Service Request Management Application created for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day full-stack mobile application challenge. The expected outcome demonstrates practical product thinking, secure backend design, clean code, and Git/GitHub discipline.

### Scope

This document covers:

- Application start-up, authentication, session restoration, and role routing.
- Customer, Agent, and Admin flows.
- Mobile and Flutter Web navigation.
- Request creation, assignment, status changes, cancellation, and history.
- Authorization denial, error recovery, and counter-conflict behavior.
- Screen-to-flow traceability against the Requirements Checklist.
- ASCII-only diagrams suitable for Markdown and Pandoc DOCX conversion.

This document does not replace the PRD, Database Design Document, or RBAC & Security Document. It describes how users move through the system and where those documents define the underlying contract.

### Audience

This document is intended for:

- Flutter/Dart developers implementing screens, routes, providers, repositories, and guards.
- Firebase developers configuring Authentication, Firestore, Rules, and Emulator Suite data.
- Test engineers writing widget, integration, and Rules tests.
- Reviewers evaluating completeness, usability, secure routing, and role separation.

### Relationship to companion documentation

The Product Requirements Document (PRD) defines the product scope and finalized role-specific capabilities. The Requirements Checklist / Traceability Document defines requirement identifiers and evidence expectations. The System Architecture Document defines application layers and data flow. The Database Design Document defines the authoritative collections and fields. The RBAC & Security Document defines Firestore authorization and denial behavior.

This document consumes those contracts and expresses them as user flows. If a conflict is found, the finalized PRD, Requirements Checklist, System Architecture, Database Design, and RBAC & Security decisions must be reconciled before implementation. No flow in this document authorizes an operation that Firestore Security Rules deny.

### Flow identifiers

The identifiers used in this document are traceability labels. The following prefixes are used:

| Prefix | Meaning |
|---|---|
| FR-C | Customer functional requirement |
| FR-A | Agent functional requirement |
| FR-AD | Admin functional requirement |
| FR-AUTH | Authentication and session requirement |
| TEST | Requirements Checklist test identifier |
| ASSUMP | Explicit implementation assumption |

Where the supplied project material does not provide an exact requirement statement, the identifier is used as a practical traceability label and is marked as an assumption in the assumptions section.

## Product and Navigation Baseline

### Product definition

QuickServe allows customers to create and track service requests for AC servicing, plumbing, electrical, and cleaning. Agents manage assigned requests through the same Flutter mobile application. Administrators manage operations through a Flutter Web admin portal.

The request lifecycle is:

```text
created -> assigned -> accepted -> in_progress -> completed
   |          |          |             |
   +----------+----------+-------------+----> cancelled when eligible
```

The displayed role labels are Customer, Agent, and Admin. The stored role values are lowercase: `customer`, `agent`, and `admin`.

### Finalized technical context

| Area | Finalized decision |
|---|---|
| Mobile client | Flutter + Dart for Android and iOS |
| Admin client | Flutter Web + Dart |
| Shared code | Shared Dart package |
| UI | Material 3 |
| State management | Riverpod |
| Navigation | go_router |
| Authentication | Firebase Authentication with email/password |
| Database | Cloud Firestore |
| Authorization | Firestore Security Rules using `users.role` |
| Server-side logic | None; no Cloud Functions |
| Notifications | FCM skipped; local notifications optional |
| Monitoring | Firebase Crashlytics |
| Local testing | Firebase Emulator Suite |
| Testing | `flutter_test` and `integration_test` |
| Plan constraint | Firebase Spark plan only; no billing or credit card |
| Web deployment | Firebase Hosting |

### Finalized collections used by flows

| Collection or path | Flow relevance |
|---|---|
| `users/{uid}` | Role resolution, profile, routing, ownership identity |
| `services/{serviceId}` | Service browsing and request service selection |
| `requests/{requestId}` | Request creation, assignment, status, details, tracking |
| `requests/{requestId}/status_history/{historyId}` | Visible status timeline and append-only transition records |
| `audit_logs/{logId}` | Required activity and security event records |
| `counters/{year}` | Transactional request-code allocation |

No flow introduces another collection, a server function, custom claims, or an alternate role source.

## Notation and Conventions

### Diagram notation

All diagrams use plain text in fenced `text` blocks. This avoids diagram-specific rendering dependencies and keeps diagrams readable in source Markdown and after Pandoc conversion to DOCX.

| Notation | Meaning |
|---|---|
| `[Screen]` | A navigable screen or route |
| `(Action)` | A user action or application operation |
| `<Decision?>` | A decision point with labeled branches |
| `{State}` | A system state or terminal state |
| `-->` | Normal flow direction |
| `-- No -->` | Negative decision branch |
| `-- Yes -->` | Positive decision branch |
| `|` and `+` | Connection lines and branch joins |
| `DENY` | Operation is blocked by authentication, routing, or Firestore Rules |
| `RETRY` | User may retry after correcting or waiting for a recoverable condition |
| `END` | Terminal state for the flow |

### Color and notation convention

The document is text-based and does not require color. If diagrams are later redrawn in a visual tool, the recommended convention is:

- Blue: user navigation or screen nodes.
- Green: successful data or state-changing operations.
- Amber: validation, confirmation, or recoverable warning.
- Red: denied, invalid, or failed operations.
- Gray: external Firebase services or terminal states.

The textual labels remain authoritative if color is unavailable.

### Flow interpretation rules

1. A screen transition does not imply authorization. The destination repository operation must still be allowed by Firestore Security Rules.
2. Client-side route guards improve user experience but do not replace Rules.
3. A missing or invalid profile is treated as an application recovery state, not as permission to continue.
4. Every status-changing flow must create the corresponding status-history record and permitted audit record according to the RBAC & Security Document.
5. Request-code allocation uses the Firestore transaction on `counters/{year}` and must not be simulated by a client-only increment.
6. A client must show safe messages and must not display tokens, passwords, API keys, or Rules internals.

## Global Entry Flow

### Application start, session check, and role routing

```text
[App Start]
     |
     v
[Initialize Firebase and Riverpod]
     |
     v
[Attach Auth State Listener]
     |
     v
<Authenticated Firebase user?>
     | No
     v
[Login]
     |
     +------------------------------+
     |                               |
     v                               v
[Registration]                  [Password Reset]
     |                               |
     +---------------+---------------+
                     |
                     v
             [Authenticated user]
                     |
                     v
        [Read users/{uid} profile]
                     |
          <Profile exists and role valid?>
             | No                    | Yes
             v                       v
 [Missing Profile Recovery]   <Role value?>
             |                       |
             v             +---------+----------+
            END            |                    |
                           v                    v
                    [customer / agent]       [admin]
                           |                    |
                           v                    v
                    [Mobile Home]       [Admin Dashboard]
```

### Global entry rules

- Firebase Authentication establishes whether a session exists.
- The profile document at `users/{uid}` supplies the stored role.
- The client accepts only `customer`, `agent`, or `admin` as valid role values.
- A customer or agent is routed to the Flutter mobile experience.
- An admin is routed to the Flutter Web admin experience.
- A profile that is missing, unreadable, or contains an invalid role is not silently treated as a customer. The client shows a safe recovery message and prevents protected navigation.
- If the Firebase session changes, go_router refreshes its redirect decision and sends the user to the correct authenticated entry point or Login.

## Customer Flows

### Registration and first login

```text
[Login]
   |
   v
(Select Register)
   |
   v
[Registration]
   |
   v
(Enter name, email, phone, password)
   |
   v
<Fields valid locally?>
   | No                         | Yes
   v                            v
[Show validation errors]   (Create Firebase Auth account)
   |                            |
   +------------<---------------+
                                v
                    (Create users/{uid} profile)
                                |
              <Profile write allowed and complete?>
                         | No                 | Yes
                         v                    v
              [Safe error and recovery]  (Write LOGIN_SUCCESS)
                         |                    |
                         v                    v
                        END             [Mobile Home]
```

Implementation notes:

- Registration creates an email/password Firebase Authentication account.
- The profile uses the authenticated UID and stores `role: customer` for a self-registered customer.
- The app must not allow a registrant to choose `agent` or `admin`.
- If Authentication succeeds but profile creation fails, the app must show a recovery message and must not route to protected customer screens until the profile is readable.
- `LOGIN_SUCCESS` is written only after successful authentication and profile resolution, using safe fields only.

### Session restore

```text
[App Start]
     |
     v
[Firebase Auth persistence restores session]
     |
     v
<Session restored?>
  | No                         | Yes
  v                            v
[Login]                 [Read users/{uid}]
                              |
                    <Profile available and valid?>
                         | No                 | Yes
                         v                    v
             [Missing Profile Recovery]  <Role is customer?>
                         |                 | Yes        | No
                         v                 v           v
                        END          [Mobile Home]  [Agent or Admin route]
```

### Browse services

```text
[Mobile Home]
      |
      v
[Services]
      |
      v
(Read active services from services collection)
      |
      v
<Services loaded?>
  | No                          | Yes
  v                             v
[Network Error Recovery]  [Service list]
  |                             |
  v                             v
 RETRY                    (Select service)
                                |
                                v
                         [Create Request]
```

The customer may browse the active services AC servicing, plumbing, electrical, and cleaning. Inactive services are not selectable for a new request. The final authority for any submitted request remains Firestore Rules and the current service data.

### Create request, including request-code confirmation

```text
[Create Request]
      |
      v
(Select service type)
      |
      v
(Enter description, preferred date/time, address, priority)
      |
      v
<Required fields valid?>
  | No                         | Yes
  v                            v
[Show field errors]     (Confirm Create Request)
  |                            |
  +------------<---------------+
                               v
                  (Begin Firestore transaction)
                               |
                               v
                 (Read and increment counters/{year})
                               |
                               v
                    (Create requests/{requestId})
                               |
                               v
                  (Create status_history: initial)
                               |
                               v
                     (Write REQUEST_CREATED)
                               |
                 <All permitted writes succeed?>
                    | No                    | Yes
                    v                       v
          <Counter conflict or error?> [Request Created]
              |              |              |
              v              v              v
        [Retry]       [Safe error]  [Show REQ-YYYY-000123]
              |              |              |
              +------>-------+              v
                                            [Request Details]
```

Implementation notes:

- The request begins in `created` status.
- `customerId` is the authenticated UID.
- `agentId` is unset or null until assignment.
- The request code uses the exact format `REQ-YYYY-000123` and is allocated with a Firestore transaction on `counters/{year}`.
- The confirmation screen must show the generated request code after successful creation.
- A client must not claim success before the request document is readable or the transaction has returned success.
- If a transaction conflicts, the client may retry with bounded attempts and must avoid creating duplicate requests.

### View My Requests

```text
[Mobile Home]
      |
      v
[My Requests]
      |
      v
(Query requests where customerId == currentUid)
      |
      v
<Load successful?>
  | No                         | Yes
  v                            v
[Network Error Recovery]  [Customer request list]
  |                            |
  v                            v
 RETRY                 <Requests available?>
                             | No          | Yes
                             v             v
                    [Empty State]   (Select request)
                                           |
                                           v
                                  [Request Details]
```

The customer sees only requests owned by the authenticated UID. A customer does not browse all requests and does not select an arbitrary customer ID.

### Open Request Details

```text
[My Requests]
      |
      v
(Select owned request)
      |
      v
[Request Details]
      |
      v
(Read request and status_history)
      |
      v
<Read permitted and request exists?>
  | No                         | Yes
  v                            v
[Safe denial/not found]  [Show code, service, status,
  |                       address, priority, timeline]
  v                            |
 END                            v
                    <Status cancellation-eligible?>
                         | No                 | Yes
                         v                    v
                 [No Cancel action]    [Show Cancel action]
```

The detail screen displays the request code and current lifecycle status. It must not expose another customer’s request through a guessed document ID, direct deep link, or stale cached route.

### Cancel eligible request

```text
[Request Details]
       |
       v
(Select Cancel)
       |
       v
[Enter cancellation reason]
       |
       v
<Reason valid and status eligible?>
  | No                         | Yes
  v                            v
[Show validation message]  (Confirm cancellation)
  |                            |
  +------------<---------------+
                               v
                    (Write request status change)
                               |
                               v
                    (Write status_history record)
                               |
                               v
                    (Write audit event if required)
                               |
                    <Rules permit transition?>
                       | No                 | Yes
                       v                    v
             [Permission denied message] [Request status: cancelled]
                       |                    |
                       v                    v
            (Write AUTHORIZATION_FAILED) [Refresh details]
                                            |
                                            v
                                           END
```

The exact cancellation eligibility is controlled by the finalized status-transition mapping in the RBAC & Security Document. The client must not offer cancellation for a status that Rules will reject.

### Profile and logout

```text
[Mobile Home]
      |
      v
[Profile]
      |
      v
<Profile action?>
  | Update permitted fields     | Logout
  v                             v
(Edit name, phone)          (Confirm logout)
  |                             |
  v                             v
(Save profile)             (Firebase signOut)
  |                             |
  v                             v
<Save allowed?>             [Login]
  | No          | Yes             |
  v             v                 v
[Safe error] [Refresh]           END
```

The customer may update only profile fields permitted by Rules. Logout clears the Firebase session and causes go_router to redirect to Login.

## Agent Flows

### Login and routing to Agent queue

```text
[Login]
   |
   v
(Enter email and password)
   |
   v
(Firebase signInWithEmailAndPassword)
   |
   v
[Read users/{uid}]
   |
   v
<role == agent?>
  | No                         | Yes
  v                            v
[Role mismatch recovery]  (Write LOGIN_SUCCESS)
  |                            |
  v                            v
 END                    [Agent Request Details or Agent queue]
```

An authenticated user whose profile role is `agent` is routed to the agent experience. A customer or admin must not reach agent-only screens by manually entering a route.

### View assigned requests

```text
[Agent entry]
      |
      v
[Agent Request Details / Agent queue]
      |
      v
(Query requests where agentId == currentUid)
      |
      v
<Load successful?>
  | No                         | Yes
  v                            v
[Network Error Recovery]  [Assigned request list]
  |                            |
  v                            v
 RETRY                 <Requests available?>
                             | No          | Yes
                             v             v
                    [Empty State]    (Select request)
                                           |
                                           v
                               [Agent Request Details]
```

The agent query is assignment-scoped. It must not display requests assigned to another agent.

### Open Agent Request Details

```text
[Assigned request list]
          |
          v
(Select assigned request)
          |
          v
[Agent Request Details]
          |
          v
(Read request and status_history)
          |
          v
<agentId == currentUid and read allowed?>
       | No                         | Yes
       v                            v
[Safe denial/not found]  [Show request fields and timeline]
       |                            |
       v                            v
      END                 <Current status?>
```

The agent may see the operational fields required to perform assigned work. Access remains dependent on `agentId` and Rules, not merely on a route parameter.

### Accept request

```text
[Agent Request Details]
          |
          v
<status == assigned?>
  | No                         | Yes
  v                            v
[Hide or disable Accept]   (Select Accept)
                               |
                               v
                    (Confirm acceptance if required)
                               |
                               v
                    (Write accepted status change)
                               |
                    <Rules permit assigned -> accepted?>
                         | No                 | Yes
                         v                    v
              [Permission denied message] [Write history]
                         |                    |
                         v                    v
          (Write AUTHORIZATION_FAILED) [Refresh details]
```

### Update status to `in_progress` and `completed`

```text
[Agent Request Details]
          |
          v
(Select status action)
          |
          v
<Current status permits selected next status?>
  | No                              | Yes
  v                                 v
[Invalid transition message]   (Confirm status update)
  |                                 |
  v                                 v
  END                   (Write request status and updatedAt)
                                      |
                                      v
                         (Write status_history record)
                                      |
                                      v
                            <Rules permit?>
                              | No          | Yes
                              v             v
                    [Safe denial]   [Refresh details]
```

The agent may move an eligible assigned request to `accepted`, then `in_progress`, then `completed`, subject to the exact transition rules. The client must never skip a state by assuming that a status field update is sufficient.

### Add notes

```text
[Agent Request Details]
          |
          v
(Enter note in permitted status action)
          |
          v
<Note valid and operation allowed?>
  | No                         | Yes
  v                            v
[Show validation error]   (Submit status update with note)
                               |
                               v
                    (Write status_history note)
                               |
                               v
                         [Refresh timeline]
```

Notes are stored only in the permitted `status_history.note` field. Notes must not contain passwords, tokens, API keys, or other secrets.

### View completed work

```text
[Agent queue]
      |
      v
(Filter or query assigned requests)
      |
      v
[Completed work list]
      |
      v
(Select completed request)
      |
      v
[Agent Request Details]
      |
      v
[Read-only completed timeline]
```

Completed requests are read-only for ordinary agent operations unless a finalized requirement explicitly permits another action. The client must not show a status action that Rules will deny.

### Agent logout

```text
[Agent queue or Agent Request Details]
              |
              v
[Profile]
              |
              v
(Logout)
              |
              v
(Firebase signOut)
              |
              v
[Login]
```

## Admin Flows

### Admin login

```text
[Admin Login]
      |
      v
(Enter email and password)
      |
      v
(Firebase signInWithEmailAndPassword)
      |
      v
[Read users/{uid}]
      |
      v
<role == admin?>
  | No                         | Yes
  v                            v
[Role mismatch recovery]  (Write LOGIN_SUCCESS)
  |                            |
  v                            v
 END                    [Admin Dashboard]
```

The Flutter Web admin portal must not treat a successful Firebase login as sufficient. The profile role must be `admin`, and every database operation remains protected by Rules.

### Dashboard overview

```text
[Admin Dashboard]
        |
        v
(Read permitted operational summaries)
        |
        v
<Read successful?>
  | No                         | Yes
  v                            v
[Network Error Recovery]  [Dashboard overview]
  |                            |
  v                            v
 RETRY                  (Select operational area)
                             |
              +--------------+---------------+----------------+
              |              |               |
              v              v               v
       [Request Mgmt]  [Customer View] [Agent View]
```

Dashboard content must be based on data available through the finalized collections and Rules. No unapproved analytics collection or server-side aggregation is introduced.

### Search and filter requests

```text
[Admin Request Management]
          |
          v
(Enter search or choose filters)
          |
          v
(Query permitted requests)
          |
          v
<Results loaded?>
  | No                         | Yes
  v                            v
[Safe error / retry]      <Matches?>
                               | No          | Yes
                               v             v
                        [Empty State]  [Request results]
                                             |
                                             v
                                    (Select request)
                                             |
                                             v
                                    [Request Details]
```

Search and filter behavior must stay within Firestore query and index capabilities available on the Spark plan. If a free-text search cannot be performed safely or efficiently with the finalized schema, the implementation must use supported bounded filters rather than inventing a search backend.

### Open request details

```text
[Admin Request Management]
          |
          v
(Select request)
          |
          v
[Admin Request Details]
          |
          v
(Read request and status_history)
          |
          v
<Read permitted?>
  | No                         | Yes
  v                            v
[Safe denial message]    [Show operational details]
```

The admin route is not a bypass of Rules. The admin role is authorized for operational access only where the RBAC & Security Document permits it.

### Assign Agent

```text
[Admin Request Details]
          |
          v
(Select Assign Agent)
          |
          v
[Choose eligible agent]
          |
          v
<Agent selected and request assignable?>
  | No                         | Yes
  v                            v
[Validation message]      (Confirm assignment)
                               |
                               v
                    (Write agentId and status assigned)
                               |
                               v
                    (Write status_history record)
                               |
                               v
                    (Write REQUEST_ASSIGNED audit event)
                               |
                         <Rules permit?>
                          | No          | Yes
                          v             v
                  [Safe denial]   [Refresh details]
```

Assignment changes must validate the selected agent identity and the request’s current status. The client must not assign an arbitrary UID without verifying that the selected profile is an agent through permitted reads and Rules.

### Update status

```text
[Admin Request Details]
          |
          v
(Select permitted status action)
          |
          v
<Transition valid?>
  | No                         | Yes
  v                            v
[Invalid transition]     (Confirm update)
                               |
                               v
                    (Write request status and updatedAt)
                               |
                               v
                    (Write status_history record)
                               |
                               v
                      [Refresh request details]
```

The admin may perform only the status transitions explicitly allowed by the finalized RBAC and lifecycle contract. The client must not expose unrestricted arbitrary status editing.

### View customers

```text
[Admin Dashboard]
      |
      v
[Admin Customer View]
      |
      v
(Read users filtered to role == customer)
      |
      v
<Read permitted?>
  | No                         | Yes
  v                            v
[Safe denial]             [Customer list]
```

### View agents

```text
[Admin Dashboard]
      |
      v
[Admin Agent View]
      |
      v
(Read users filtered to role == agent)
      |
      v
<Read permitted?>
  | No                         | Yes
  v                            v
[Safe denial]             [Agent list]
```

### View activity and audit

```text
[Admin Dashboard]
      |
      v
[Admin Activity/Audit View]
      |
      v
(Read permitted audit_logs)
      |
      v
<Read permitted and data available?>
  | No                         | Yes
  v                            v
[Safe denial / empty state] [Audit activity list]
                                      |
                                      v
                             (Open related target)
```

Audit logs remain append-only. The admin view may read permitted records but must not update or delete them.

### Admin logout

```text
[Admin Dashboard or admin screen]
              |
              v
[Admin Logout]
              |
              v
(Confirm logout)
              |
              v
(Firebase signOut)
              |
              v
[Admin Login]
```

## Cross-Role Flows

### Customer to Admin to Agent to Customer handoff

```text
[Customer: Create Request]
          |
          v
{created}
          |
          v
[Admin: Request Management]
          |
          v
(Admin assigns eligible Agent)
          |
          v
{assigned}
          |
          v
[Agent: Agent Request Details]
          |
          v
(Agent accepts request)
          |
          v
{accepted}
          |
          v
(Agent starts work)
          |
          v
{in_progress}
          |
          v
(Agent completes work)
          |
          v
{completed}
          |
          v
[Customer: My Requests]
          |
          v
(Customer opens Request Details)
          |
          v
[Customer sees updated status and timeline]
```

### Cross-role data ownership

| Operation | Initiating role | Primary record | Supporting record | Customer-visible result |
|---|---|---|---|---|
| Create request | Customer | `requests/{requestId}` | Initial history and audit record | Request code and `created` status |
| Assign agent | Admin | Request `agentId` and `status` | History and `REQUEST_ASSIGNED` audit event | Assigned status after refresh |
| Accept request | Assigned Agent | Request `status` | History record | Accepted status after refresh |
| Start work | Assigned Agent or permitted Admin | Request `status` | History record | `in_progress` status after refresh |
| Complete work | Assigned Agent or permitted Admin | Request `status` | History record | `completed` status after refresh |
| Cancel eligible request | Customer or permitted role | Request `status`, `cancellationReason` | History and permitted audit record | `cancelled` status after refresh |

## Authorization Denial Flows

### Customer attempts to open another customer’s request

```text
[Customer My Requests]
          |
          v
(Guessed or stale request ID)
          |
          v
[Request Details route]
          |
          v
(Firestore read request)
          |
          v
<customerId == currentUid?>
  | No                         | Yes
  v                            v
DENY: permission-denied  [Show owned request]
  |
  v
[Safe message: request unavailable]
  |
  v
(Write AUTHORIZATION_FAILED with safe target metadata)
  |
  v
[Return to My Requests]
```

### Agent attempts to open another agent’s request

```text
[Agent queue]
      |
      v
(Guessed or stale request ID)
      |
      v
[Agent Request Details route]
      |
      v
(Firestore read request)
      |
      v
<agentId == currentUid?>
  | No                         | Yes
  v                            v
DENY: permission-denied  [Show assigned request]
  |
  v
[Safe message: request unavailable]
  |
  v
(Write AUTHORIZATION_FAILED with safe target metadata)
  |
  v
[Return to Agent queue]
```

### Unauthenticated user attempts to access a protected screen

```text
[Protected route deep link]
          |
          v
<Authenticated Firebase user?>
  | No                         | Yes
  v                            v
[go_router redirect]     [Read profile and role]
  |                            |
  v                            v
[Login]                  <Role permits route?>
                            | No          | Yes
                            v             v
                    [Safe route redirect] [Protected screen]
```

The redirect is a user-experience control. Firestore Rules independently deny unauthenticated reads and writes.

## Error and Recovery Flows

### Network failure

```text
[Screen operation]
      |
      v
(Firestore operation)
      |
      v
<Network operation succeeds?>
  | No                         | Yes
  v                            v
[Show safe offline/network] [Apply returned state]
  |                            |
  v                            v
(RETRY) or (Return)           END
```

The client must avoid reporting a write as successful when the result is unknown. For a request creation or status update, the client should re-read the target before offering a duplicate retry.

### Permission denied

```text
(Firestore operation)
      |
      v
<Error code == permission-denied?>
  | No                         | Yes
  v                            v
[Handle by error category]  [Safe authorization message]
                               |
                               v
                    (Write AUTHORIZATION_FAILED)
                               |
                               v
                         [Return to prior screen]
```

`AUTHORIZATION_FAILED` records must contain safe event data only. They must not contain credentials, tokens, Rules source, or sensitive request content.

### Missing profile

```text
[Authenticated Firebase user]
          |
          v
(Read users/{uid})
          |
          v
<Profile exists?>
  | No                         | Yes
  v                            v
[Missing Profile Recovery] <Role valid?>
  |                            | No          | Yes
  v                            v             v
[Do not enter app]       [Safe recovery] [Role route]
```

Recovery may offer a retry or sign-out. It must not allow the user to self-create an `agent` or `admin` role through a client-side repair screen.

### Invalid transition

```text
(User selects status action)
          |
          v
<Client transition validation>
          |
          v
<Transition valid?>
  | No                         | Yes
  v                            v
[Show invalid transition] (Submit write)
  |                            |
  v                            v
 END                    <Rules allow transition?>
                              | No          | Yes
                              v             v
                    [Permission/safe error] [Refresh]
```

Both client validation and Rules validation are required because the client can be stale or manipulated.

### Counter conflict

```text
(Customer confirms request)
          |
          v
(Firestore transaction on counters/{year})
          |
          v
<Transaction conflict?>
  | Yes                       | No
  v                           v
<Retry limit reached?>   [Create request with code]
  | No          | Yes
  v             v
(RETRY)   [Safe retry-later error]
```

A retry must re-read the counter in a new transaction. The client must not reuse a previously failed request code or create a second request outside the transaction pattern.

## Navigation Map

```text
MOBILE APP
==========
[Splash]
   |
   +--> [Login] --register--> [Registration] --success--> [Home]
   |       |
   |       +--reset password--> [Login]
   |
   +--> [Home] --customer--> [Services] --> [Create Request] --> [Request Details]
   |       |                       |                |
   |       |                       +----------------+
   |       +--> [My Requests] --------------------> [Request Details]
   |       |                                      |
   |       |                                      +--> [Cancel eligible request]
   |       +--> [Profile] --> [Logout] ----------> [Login]
   |
   +--> [Home] --agent--> [Assigned Requests] --> [Agent Request Details]
           |                                      |
           |                                      +--> [Accept]
           |                                      +--> [in_progress]
           |                                      +--> [completed]
           |                                      +--> [Add notes]
           +--> [Profile] --> [Logout] ----------> [Login]

ADMIN WEB PORTAL
================
[Admin Login]
      |
      v
[Admin Dashboard]
      |
      +--> [Admin Request Management] --> [Admin Request Details]
      |                                      |
      |                                      +--> [Assign Agent]
      |                                      +--> [Update Status]
      |                                      +--> [Activity/Audit View]
      |
      +--> [Admin Customer View]
      +--> [Admin Agent View]
      +--> [Admin Activity/Audit View]
      +--> [Admin Logout] ------------------> [Admin Login]
```

## Screen-to-Flow Traceability

The following table maps every finalized screen to the flows in this document and to the corresponding requirements checklist identifiers.

| Screen | Client | Role | Flow coverage | Requirement ID(s) |
|---|---|---|---|---|
| Splash | Flutter mobile | All mobile users | Global entry, session resolution | FR-C-01 |
| Login | Flutter mobile | Customer, Agent | Customer and agent login | FR-AUTH-03 |
| Registration | Flutter mobile | Customer | Registration and first login | FR-AUTH-01, FR-AUTH-02 |
| Home | Flutter mobile | Customer, Agent | Home and role routing after login | FR-C-02, FR-AUTH-05 |
| Services | Flutter mobile | Customer | Browse services | FR-C-03 |
| Create Request | Flutter mobile | Customer | Create request fields and validation; request-code confirmation; initial status | FR-C-04, FR-C-05, FR-C-06, FR-C-07, FR-C-08 |
| My Requests | Flutter mobile | Customer | View owned requests | FR-C-09 |
| Request Details | Flutter mobile | Customer | Open owned request and cancel eligible request | FR-C-10, FR-C-11 |
| Agent Request Details | Flutter mobile | Agent | Open assigned request, accept, update, and add notes | FR-A-02, FR-A-03, FR-A-04, FR-A-05, FR-A-06, FR-A-07 |
| Profile | Flutter mobile | Customer, Agent | Profile and logout | FR-C-13, FR-AUTH-04 |
| Logout | Flutter mobile | Customer, Agent | Sign out and route protection | FR-AUTH-04, FR-AUTH-05, NFR-01 |
| Admin Login | Flutter Web | Admin | Admin authentication before portal access | FR-AD-LOGIN-01 |
| Admin Dashboard | Flutter Web | Admin | Dashboard access and overview | FR-AD-01, FR-AD-02 |
| Admin Request Management | Flutter Web | Admin | Search, filter, and select requests | FR-AD-03, FR-AD-04 |
| Admin Customer View | Flutter Web | Admin | View customers | FR-AD-08 |
| Admin Agent View | Flutter Web | Admin | View agents | FR-AD-09 |
| Admin Activity/Audit View | Flutter Web | Admin | View permitted audit activity and safe fields | FR-AD-10, FR-AD-11 |
| Admin Logout | Flutter Web | Admin | Sign out and route protection | FR-AUTH-04, FR-AUTH-05, NFR-01 |

## Requirements-Oriented Flow Rules

### Authentication and routing requirements

| Requirement | Flow rule | Verification evidence |
|---|---|---|
| FR-AUTH-01, FR-AUTH-02 | A customer can register with the permitted email/password flow and create the required profile. | Registration integration test and Authentication Emulator record |
| FR-AUTH-03 | A customer or agent can authenticate with email/password. | Login integration test |
| FR-AUTH-06 | A user can initiate password reset through the authentication flow. | Password reset integration test |
| FR-AUTH-05 | Session persistence and role routing resolve `users.role` before entering protected screens. | Session restore and role-routing integration test |
| FR-AUTH-04 | Logout signs out the Firebase session and returns the user to the appropriate login screen. | Logout integration test |
| FR-AD-LOGIN-01 | An admin must authenticate before entering the Flutter Web portal. | Admin portal access test |
| NFR-01 | Protected routes require authentication and database-layer authorization; UI routing alone is insufficient. | Unauthenticated route and Rules tests |

### Customer requirements

| Requirement | Flow rule | Verification evidence |
|---|---|---|
| FR-C-01 | Splash resolves the session before selecting the authenticated entry route. | Splash/session-resolution integration test |
| FR-C-02 | A customer reaches Home and Services after successful login. | Customer routing integration test |
| FR-C-03 | Customer browses active services. | Services widget and integration tests |
| FR-C-04, FR-C-05, FR-C-06 | Customer submits the finalized request fields and client validation prevents incomplete submission. | Create Request widget and validation tests |
| FR-C-07 | Successful creation shows `REQ-YYYY-000123`. | Counter transaction integration test |
| FR-C-08 | A newly created request starts in `created` status. | Request creation integration test |
| FR-C-09 | Customer sees only owned requests in My Requests. | Ownership query and Rules test |
| FR-C-10 | Customer opens only an owned request. | Request Details ownership test |
| FR-C-11 | Customer can cancel only an eligible request. | Cancellation transition test |
| FR-C-12, TEST-07 | Cross-customer request access is denied. | Cross-customer authorization test |
| FR-C-13, FR-AUTH-04 | Customer can use Profile and logout. | Profile and logout integration tests |

### Agent requirements

| Requirement | Flow rule | Verification evidence |
|---|---|---|
| FR-A-01 | Agent work queue is the primary authenticated agent action. | Agent entry and queue integration test |
| FR-A-02 | Agent reads only assigned requests. | Agent ownership Rules test |
| FR-A-03 | Agent accepts an eligible assigned request through `assigned -> accepted`. | Acceptance transition test |
| FR-A-04, FR-A-05 | Agent updates eligible work through `in_progress` and `completed`. | Transition matrix tests |
| FR-A-06 | Agent adds permitted notes during the appropriate workflow. | Note and status-history integration test |
| FR-A-07 | Agent can view completed work. | Completed-work query and UI test |
| FR-A-08, TEST-08 | Cross-agent request access is denied. | Cross-agent authorization test |
| FR-AUTH-04 | Agent logout clears the session and returns to Login. | Agent logout integration test |

### Admin requirements

| Requirement | Flow rule | Verification evidence |
|---|---|---|
| FR-AD-01 | Admin can access the dashboard after authorized login. | Admin dashboard route test |
| FR-AD-02 | Dashboard counts include new requests where `status == created`. | Dashboard query and count test |
| FR-AD-03 | Admin can search requests using supported bounded query behavior. | Admin search test |
| FR-AD-04 | Admin can filter requests using supported lifecycle and operational filters. | Admin filter test |
| FR-AD-05 | Admin can open permitted request details. | Admin request detail test |
| FR-AD-06 | Admin can assign an eligible agent to an assignable request. | Assignment integration and Rules test |
| FR-AD-07 | Admin can perform only permitted status updates. | Admin transition test |
| FR-AD-08 | Admin can view customers. | Admin customer view test |
| FR-AD-09 | Admin can view agents. | Admin agent view test |
| FR-AD-10 | Admin can view permitted activity and audit records. | Audit view integration test |
| FR-AD-11 | Admin views never display secrets. | Safe-field and UI inspection test |

### Cross-cutting requirements

| Requirement | Flow rule | Verification evidence |
|---|---|---|
| NFR-01 | Authorization is enforced at the database layer and not only through UI route guards. | Firestore Rules test suite |
| NFR-02 | Passwords, tokens, API keys, and secrets are never logged, committed, or displayed. | Logging review and repository secret scan |
| NFR-05 | Failed writes are not reported as successful; the client verifies operation results before showing success. | Failed-write integration test |
| NFR-06 | Required screens provide loading, empty, error, and retry states. | Widget and integration state tests |

## Open Questions and Assumptions

### Open questions

| ID | Question | Impact | Default pending confirmation |
|---|---|---|---|
| OQ-01 | Which exact statuses are customer-cancellable? | Controls the Cancel action and Rules transition map. | Use the finalized RBAC & Security mapping; do not infer from UI alone. |
| OQ-02 | Can an admin move a request through every lifecycle transition or only assign and oversee? | Controls Admin status actions. | Permit only transitions explicitly documented in RBAC & Security. |
| OQ-03 | Is free-text request search required, or are status/service/agent/customer filters sufficient? | Controls Firestore query implementation and indexes. | Use supported bounded filters on Spark plan. |
| OQ-04 | Is a missing profile repaired by support outside the app, or only retried/signed out? | Controls recovery UX. | Retry or sign out; no self-promotion or role repair. |
| OQ-05 | Are status notes visible to customers? | Controls detail-screen field projection. | Follow the finalized PRD and security decision; do not expose notes by assumption. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | The mobile Home screen is role-aware and renders the customer or agent landing content after routing. |
| ASSUMP-02 | The supplied mobile screen list's `Request Details` represents the customer detail screen, while `Agent Request Details` is the agent detail screen. |
| ASSUMP-03 | Admin request details is an admin state/view of request management, not a new collection or separate backend entity. |
| ASSUMP-04 | The client uses Riverpod providers for authentication, profile, request lists, services, and loading/error state. |
| ASSUMP-05 | go_router redirect logic reacts to Firebase Authentication state and profile resolution state. |
| ASSUMP-06 | All displayed dates and times are formatted for the user's locale, while Firestore timestamps remain authoritative. |
| ASSUMP-07 | The initial status-history record is created as part of request creation or the documented client transaction sequence. |
| ASSUMP-08 | Audit records are client-written and append-only, subject to the Rules constraints in the RBAC & Security Document. |
| ASSUMP-09 | No FCM notification flow is included because FCM is explicitly skipped. Local notifications, if used, do not change authorization or lifecycle behavior. |

## Glossary

| Term | Definition |
|---|---|
| Admin | A user with stored role value `admin`, using the Flutter Web admin portal. |
| Agent | A user with stored role value `agent`, using the Flutter mobile application to manage assigned work. |
| Customer | A user with stored role value `customer`, using the Flutter mobile application to create and track requests. |
| Firestore Rules | Declarative database-layer authorization rules that enforce access independently of client UI. |
| Firebase session | The authenticated Firebase Authentication state associated with the current user. |
| Handoff | A lifecycle transition in which operational responsibility moves from customer creation to admin assignment, agent work, and customer tracking. |
| Request code | Human-readable identifier in the format `REQ-YYYY-000123`. |
| Request Details | Customer-facing screen for viewing an owned request and its permitted timeline. |
| Agent Request Details | Agent-facing screen for viewing and managing an assigned request. |
| Status history | Append-only records under `requests/{requestId}/status_history`. |
| Audit log | Append-only operational or security record under `audit_logs`. |
| Role routing | Selection of the authenticated user's client route based on `users.role`. |
| Terminal state | A flow endpoint such as `END`, Login, a completed operation, or a safe recovery destination. |

## Appendix A — Complete Mobile Navigation Diagram {.unnumbered}

```text
+-------------------+
|       Splash      |
+---------+---------+
          |
          v
+-------------------+        +---------------------+
|       Login       |-------> |    Registration     |
+----+---------+----+        +----------+----------+
     |         |                         |
     |         +---- reset password -----+
     |                                   |
     +--------------------<--------------+
                          |
                          v
                   +------+------+
                   |    Home    |
                   +--+------+--+
                      |      |
        customer -----+      +----- agent
          |                         |
          v                         v
   +--------------+          +----------------------+
   |   Services   |          | Assigned Requests    |
   +------+-------+          +----------+-----------+
          |                              |
          v                              v
   +--------------+          +----------------------+
   |Create Request|          |Agent Request Details |
   +------+-------+          +--+--------+----------+
          |                      |        |
          v                      |        +--> Add notes
   +--------------+              |        +--> accepted
   |Request Detail|<-------------+        +--> in_progress
   +------+-------+                       +--> completed
          |
          +--> Cancel eligible request

   +--------------+
   | My Requests  |------> Request Details
   +--------------+

   +--------------+
   |   Profile    |------> Edit permitted profile fields
   +------+-------+
          |
          v
       Logout
          |
          v
        Login
```

## Appendix B — Complete Admin Navigation Diagram {.unnumbered}

```text
+-------------------+
|    Admin Login    |
+---------+---------+
          |
          v
+-------------------+
|  Admin Dashboard  |
+--+------+-----+---+
   |      |     |
   |      |     +----------------------+
   |      |                            |
   v      v                            v
+------+ +----------------+   +----------------------+
|Admin | |Admin Customer  |   |Admin Activity/Audit  |
|Request| |View            |   |View                  |
|Mgmt  | +----------------+   +----------------------+
   |
   v
+------------------------+
| Admin Request Details  |
+----------+-------------+
           |
           +--> Assign Agent
           |
           +--> Update Status
           |
           +--> View permitted history

+----------------+
| Admin Agent View|
+----------------+

[Admin Logout] ------------------------------> [Admin Login]
```

## Appendix C — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram — this document.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.

