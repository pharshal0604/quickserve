---
title: "QuickServe Request Lifecycle / State Diagram Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This Request Lifecycle / State Diagram Document defines the authoritative request states, allowed transitions, actor permissions, preconditions, side effects, history records, audit events, concurrency behavior, repository contract, and lifecycle test scenarios for QuickServe.

QuickServe is a Service Request Management App for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day Full-Stack Mobile Application challenge using Flutter/Dart, Firebase Authentication, Cloud Firestore, and Firestore Security Rules.

### Scope

This document covers the lifecycle of documents in `requests/{requestId}` from creation through assignment, agent work, completion, or eligible cancellation. It also covers the related `status_history`, `audit_logs`, and `counters/{year}` records.

The finalized states are:

```text
created | assigned | accepted | in_progress | completed | cancelled
```

The lifecycle is enforced in two places:

- Flutter/Dart repositories validate transitions before submitting writes and provide clear user feedback.
- Firestore Security Rules enforce the authorization and transition boundary independently of the client.

This document does not introduce Cloud Functions, custom claims, FCM, Supabase, React, Next.js, Angular, a separate backend, or a new collection.

### Audience

This document is intended for:

- Flutter/Dart developers implementing Riverpod repositories, models, providers, screens, and status actions.
- Firebase developers configuring Firestore Rules, indexes, Emulator Suite data, and security tests.
- Test engineers writing unit, widget, integration, and Rules tests.
- Reviewers evaluating lifecycle correctness, role separation, auditability, and data integrity.

### Relationship to companion documents

The Product Requirements Document (PRD) defines the product baseline and the finalized request lifecycle. The Requirements Checklist / Traceability document defines requirement IDs and acceptance evidence. The System Architecture Document defines application layers and Firebase data flow. The Database Design Document defines the authoritative request and history schemas. The RBAC & Security Document defines Firestore authorization, field protection, append-only behavior, and the Rules implementation.

The User Flow Diagram Document expresses lifecycle actions as user journeys. This document is the state-machine reference that those journeys must follow. Any client screen or repository operation that conflicts with this state machine must be corrected before implementation is accepted.

## Lifecycle Overview

### Lifecycle purpose

The lifecycle provides a controlled progression from a customer-created service request to assigned agent work and a terminal outcome. Each valid transition creates an observable status-history record and, where required, an audit event. The model prevents skipped states, unauthorized ownership changes, accidental reversal, and silent operational changes.

### Actors involved

| Actor | Stored role | Client | Lifecycle responsibility |
|---|---|---|---|
| Customer | `customer` | Flutter mobile | Creates own requests, views own requests, and cancels own requests only from `created` or `assigned` |
| Agent | `agent` | Flutter mobile | Accepts and progresses requests assigned to the agent |
| Admin | `admin` | Flutter Web | Assigns agents and performs explicitly permitted operational status changes |

### Lifecycle data

| Data | Collection/path | Lifecycle use |
|---|---|---|
| Current state | `requests/{requestId}.status` | Authoritative current lifecycle state |
| Request ownership | `requests/{requestId}.customerId` | Customer access boundary |
| Assignment | `requests/{requestId}.agentId` | Agent access and work boundary |
| Transition record | `requests/{requestId}/status_history/{historyId}` | Append-only state-change history |
| Audit event | `audit_logs/{logId}` | Safe operational and security observability |
| Request number | `counters/{year}.lastRequestNumber` | Transactional request-code allocation |

### Lifecycle invariant

At every successful request update:

1. The stored previous state is known.
2. The requested next state is one of the finalized lowercase enum values.
3. The edge from previous to next is allowed.
4. The actor is permitted for that edge.
5. Immutable request fields remain unchanged.
6. `updatedAt` is refreshed.
7. A status-history record is created using the allowed schema.
8. The appropriate audit event is written with safe fields, subject to the client-write limitations documented here and in the RBAC & Security Document.

## State Definitions

| State | Stored value | Meaning | Allowed next states | Terminal yes/no |
|---|---|---|---|---|
| Created | `created` | Customer request exists and has not yet been assigned. | `assigned`, `cancelled` | No |
| Assigned | `assigned` | Admin has assigned an agent to the request. | `accepted`, `cancelled` | No |
| Accepted | `accepted` | Assigned agent has accepted responsibility for the request. | `in_progress`, `cancelled` by Admin only | No |
| In Progress | `in_progress` | Assigned agent is actively working on the request. | `completed`, `cancelled` by Admin only | No |
| Completed | `completed` | Work is finished. | None | Yes |
| Cancelled | `cancelled` | Request has been cancelled through an eligible transition. | None | Yes |

### State invariants

- `created` requests have no assigned agent in the customer-created flow.
- `assigned`, `accepted`, `in_progress`, and `completed` operational requests have an assigned agent.
- `completed` and `cancelled` are terminal and cannot transition to another state.
- Status values are lowercase and must match the finalized enum exactly.
- A request code is immutable after creation.
- Customer ownership, service details, description, preferred date/time, address, priority, and creation time are immutable after creation through lifecycle updates.
- Cancellation from `accepted` or `in_progress` is Admin-only. Customers may cancel only from `created` or `assigned`, per PRD Assumption A-03.

## Transition Table

| From | To | Permitted actor(s) | Conditions | Required side effects |
|---|---|---|---|---|
| `created` | `assigned` | Admin | Request is assignable; selected agent is an eligible agent; customer and request identity fields remain unchanged. | Update `agentId` and `status`; refresh `updatedAt`; append status history; write `REQUEST_ASSIGNED`. |
| `assigned` | `accepted` | Assigned Agent | Authenticated agent equals stored `agentId`; request is currently assigned. | Update `status`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `accepted` | `in_progress` | Assigned Agent; Admin if operationally permitted | Request is accepted; actor is permitted; no immutable field changes. | Update `status`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `in_progress` | `completed` | Assigned Agent; Admin if operationally permitted | Request is in progress; actor is permitted; no immutable field changes. | Update `status`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `created` | `cancelled` | Own Customer; Admin | Customer owns request, or actor is an authorized Admin; cancellation reason is supplied where required. | Update `status` and `cancellationReason`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `assigned` | `cancelled` | Own Customer; Admin | Customer owns request, or actor is an authorized Admin; cancellation reason is supplied where required. | Update `status` and `cancellationReason`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `accepted` | `cancelled` | Admin | Admin-only cancellation according to finalized lifecycle policy. | Update `status` and `cancellationReason`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `in_progress` | `cancelled` | Admin | Admin-only cancellation according to finalized lifecycle policy. | Update `status` and `cancellationReason`; refresh `updatedAt`; append status history; write `REQUEST_UPDATED`. |
| `completed` | None | None | Terminal state. | No lifecycle update is allowed. |
| `cancelled` | None | None | Terminal state. | No lifecycle update is allowed. |

### Requirement traceability for the transition table

| Lifecycle behavior | Requirement ID(s) |
|---|---|
| New request starts as `created` | FR-C-08 |
| Customer creates a request and receives a request code | FR-C-04, FR-C-05, FR-C-06, FR-C-07 |
| Customer views own request | FR-C-09, FR-C-10 |
| Customer cancels only eligible own request | FR-C-11 |
| Cross-customer lifecycle access is denied | FR-C-12, TEST-07 |
| Agent queue contains assigned work | FR-A-01, FR-A-02 |
| Agent accepts assigned request | FR-A-03 |
| Agent updates `in_progress` and `completed` | FR-A-04, FR-A-05 |
| Agent adds notes and views completed work | FR-A-06, FR-A-07 |
| Cross-agent lifecycle access is denied | FR-A-08, TEST-08 |
| Admin assigns an agent | FR-AD-06 |
| Admin performs permitted status updates | FR-AD-07 |
| Database-layer authorization | NFR-01 |
| Failed writes are not reported as successful | NFR-05 |

## State Diagram

```text
Forward lifecycle:

  +---------+   Admin    +----------+   Agent   +----------+
  | created |----------->| assigned |---------->| accepted |
  +---------+            +----------+           +----------+
                                                      |
                                                      | Agent
                                                      v
                                               +--------------+
                                               | in_progress  |
                                               +--------------+
                                                      |
                                                      | Agent / Admin if permitted
                                                      v
                                               +--------------+
                                               |  completed   |
                                               |  TERMINAL    |
                                               +--------------+

Cancellation edges:

  created     -- Customer own or Admin --> cancelled (TERMINAL)
  assigned    -- Customer own or Admin --> cancelled (TERMINAL)
  accepted    -- Admin only ------------> cancelled (TERMINAL)
  in_progress -- Admin only ------------> cancelled (TERMINAL)

Legend: All states are lowercase. Terminal states have no outgoing edges.
```

The diagram uses ASCII only. The labels “Admin if permitted” mean the final RBAC policy must permit the operation; the client must not infer permission from the diagram alone.

## Transition-by-Transition Detail

### Transition: `created` to `assigned`

#### Trigger

An Admin selects an eligible agent for a request that is currently in `created` status and confirms the assignment.

#### Actor(s)

- Permitted actor: Admin.
- Customer: No.
- Agent: No.

#### Preconditions

- Firebase Authentication session exists.
- `users.role` for the actor is `admin`.
- Request exists and current stored status is `created`.
- Selected agent is an eligible user with stored role `agent`.
- Request customer ID, request code, service fields, and creation time are retained.
- A valid agent ID is written.

#### Client-side validation

The Admin repository must verify that the request is still `created`, the selected user is an agent, the request is not terminal, and the assignment action is not duplicated. The UI should disable assignment while the write is pending.

#### Firestore Rules enforcement

The admin request-update branch permits only a controlled field set containing `agentId`, `status`, `updatedAt`, and `cancellationReason`. It requires a valid transition from the stored state to `assigned`, preserves immutable fields, and requires an agent ID when the next status is `assigned`.

#### Side effects

- Update `requests/{requestId}.agentId`.
- Update `requests/{requestId}.status` to `assigned`.
- Update `updatedAt`.
- Append `status_history/{historyId}` with `fromStatus: created`, `toStatus: assigned`, `changedBy`, `changedAt`, and `note`.
- Write `REQUEST_ASSIGNED` to `audit_logs` with safe target and assignment data.

#### Failure modes

- Permission denied: actor is not an Admin or the request is not accessible.
- Invalid transition: another actor already changed the request.
- Invalid agent: selected profile is not an eligible agent.
- Network failure: result is unknown; re-read before retrying.
- History or audit failure: follow the repository's documented atomicity and error policy; never report a confirmed success without a successful primary write.

#### Related requirement IDs

FR-AD-06, FR-AD-07, NFR-01, NFR-05.

### Transition: `assigned` to `accepted`

#### Trigger

The assigned Agent opens the assigned request and selects Accept.

#### Actor(s)

- Permitted actor: the Agent whose UID equals the stored `agentId`.
- Customer: No.
- Admin: Conditional if operationally permitted, but the standard agent workflow is the assigned Agent.

#### Preconditions

- Firebase Authentication session exists.
- Actor role is `agent`.
- Actor UID equals `requests/{requestId}.agentId`.
- Current status is `assigned`.
- Request is not terminal.

#### Client-side validation

The Agent repository checks the current status, assignment, and permitted next state. The Accept action is shown only for an assigned request. A stale detail screen must refresh before retrying.

#### Firestore Rules enforcement

The agent branch requires `isAgent()`, `isAssigned(resource.data.agentId)`, a status update to `accepted`, a valid transition, and an affected-field set containing only `status` and `updatedAt`. Request identity and operational fields must remain unchanged.

#### Side effects

- Update status to `accepted`.
- Refresh `updatedAt`.
- Append status history from `assigned` to `accepted`.
- Write `REQUEST_UPDATED` with safe old/new status values.

#### Failure modes

- Wrong agent: permission denied.
- Stale status: transition rejected.
- Missing assignment: operation rejected.
- Network failure: safe retry or refresh; no false success.

#### Related requirement IDs

FR-A-02, FR-A-03, NFR-01, NFR-05.

### Transition: `accepted` to `in_progress`

#### Trigger

The assigned Agent starts work on an accepted request.

#### Actor(s)

- Permitted actor: the assigned Agent.
- Admin: Conditional if operationally permitted.
- Customer: No.

#### Preconditions

- Current status is `accepted`.
- Agent assignment is present and matches the authenticated Agent.
- Actor is authenticated and role-resolved.
- No immutable request field is modified.

#### Client-side validation

The repository permits the action only when the current state is `accepted`. A note may be collected if the product flow supports a note for this transition. The client must not allow a direct move from `assigned` to `in_progress`.

#### Firestore Rules enforcement

The agent branch permits only `accepted`, `in_progress`, or `completed` as the incoming status and requires `isValidTransition(resource.data.status, request.resource.data.status)`. The Admin branch may permit the same transition only when the finalized operational policy enables it.

#### Side effects

- Update status to `in_progress`.
- Refresh `updatedAt`.
- Append status history from `accepted` to `in_progress`.
- Write `REQUEST_UPDATED` with safe fields.

#### Failure modes

- Direct transition from another state: denied.
- Non-assigned Agent: denied.
- Customer attempt: denied.
- Concurrent status change: denied or stale; refresh required.

#### Related requirement IDs

FR-A-04, FR-A-06, NFR-01, NFR-05.

### Transition: `in_progress` to `completed`

#### Trigger

The assigned Agent completes the service work and confirms completion.

#### Actor(s)

- Permitted actor: the assigned Agent.
- Admin: Conditional if operationally permitted.
- Customer: No.

#### Preconditions

- Current status is `in_progress`.
- Agent assignment is present and matches the authenticated Agent.
- Actor is authenticated.
- Any required completion note is valid and safe.

#### Client-side validation

The repository allows completion only from `in_progress`. The UI must not show completion for `created`, `assigned`, or `accepted`. The client checks for pending writes and prevents duplicate submissions.

#### Firestore Rules enforcement

Rules require the assigned Agent identity, a valid transition to `completed`, only `status` and `updatedAt` changes for the agent path, and unchanged immutable request fields. Completed is terminal after the write.

#### Side effects

- Update status to `completed`.
- Refresh `updatedAt`.
- Append status history from `in_progress` to `completed`.
- Write `REQUEST_UPDATED` with safe status values.
- Make the request read-only for subsequent ordinary lifecycle operations.

#### Failure modes

- Completion from a non-`in_progress` state: denied.
- Wrong Agent: denied.
- Customer attempt: denied.
- Duplicate completion: denied because `completed` has no outgoing transition.

#### Related requirement IDs

FR-A-05, FR-A-06, FR-A-07, NFR-01, NFR-05.

### Transition: `created` to `cancelled`

#### Trigger

The owning Customer cancels a request before assignment, or an Admin performs an allowed operational cancellation.

#### Actor(s)

- Permitted actor: owning Customer or Admin.
- Agent: No.

#### Preconditions

- Current status is `created`.
- Customer actor owns the request when the actor is a Customer.
- Cancellation reason is supplied where required by the application contract.
- Request identity and immutable fields remain unchanged.

#### Client-side validation

The Customer UI shows cancellation only for an eligible own request. The repository checks status `created` or `assigned`, ownership, and a non-empty bounded cancellation reason if required. The Admin UI uses the finalized admin authorization policy.

#### Firestore Rules enforcement

The customer branch requires ownership, `isValidTransition(resource.data.status, 'cancelled')`, and the additional finalized restriction `resource.data.status in ['created', 'assigned']`. Therefore, a customer cannot cancel an `accepted` or `in_progress` request even though the general transition helper includes those edges for Admin-only cancellation.

#### Side effects

- Update status to `cancelled`.
- Write `cancellationReason`.
- Refresh `updatedAt`.
- Append status history from `created` to `cancelled`.
- Write `REQUEST_UPDATED` with safe fields.

#### Failure modes

- Non-owner Customer: denied.
- Agent attempt: denied.
- Missing reason: client validation or Rules rejection.
- Already assigned or later state: use the appropriate transition; Customer may cancel `assigned`, but not `accepted` or `in_progress`.
- Terminal state: denied.

#### Related requirement IDs

FR-C-11, FR-C-12, TEST-07, NFR-01, NFR-05.

### Transition: `assigned` to `cancelled`

#### Trigger

The owning Customer cancels an assigned request, or an Admin performs an allowed operational cancellation.

#### Actor(s)

- Permitted actor: owning Customer or Admin.
- Agent: No.

#### Preconditions

- Current status is `assigned`.
- Customer actor owns the request when the actor is a Customer.
- An assigned agent may remain recorded for historical context unless the finalized data policy explicitly clears it; the lifecycle update must not silently change unrelated fields.
- Cancellation reason is supplied where required.

#### Client-side validation

The Customer UI permits cancellation from `assigned` and does not show cancellation for `accepted` or `in_progress`. The repository checks ownership and current state immediately before the write.

#### Firestore Rules enforcement

The customer update branch requires ownership, a valid transition, and `resource.data.status in ['created', 'assigned']`. The Admin branch remains separate and may cancel the permitted states according to the finalized administrative policy.

#### Side effects

- Update status to `cancelled`.
- Write `cancellationReason`.
- Refresh `updatedAt`.
- Append status history from `assigned` to `cancelled`.
- Write `REQUEST_UPDATED` with safe fields.

#### Failure modes

- Customer attempts to cancel after an Agent accepts: denied.
- Non-owner Customer: denied.
- Agent attempt: denied.
- Concurrent acceptance: one operation wins; the stale cancellation is rejected and the client refreshes.

#### Related requirement IDs

FR-C-11, FR-C-12, TEST-07, NFR-01, NFR-05.

### Transition: `accepted` to `cancelled`

#### Trigger

An Admin performs a permitted operational cancellation of an accepted request.

#### Actor(s)

- Permitted actor: Admin only.
- Customer: No.
- Agent: No.

#### Preconditions

- Current status is `accepted`.
- Actor role resolves to `admin`.
- The final administrative policy permits this cancellation.
- Cancellation reason is supplied where required.

#### Client-side validation

The Admin UI shows the action only when the finalized policy permits it. Customer and Agent clients must not present the action. The repository checks the current status and confirms the Admin operation before writing.

#### Firestore Rules enforcement

The Admin request-update branch is the only branch that can authorize this edge. The Customer branch rejects it through `resource.data.status in ['created', 'assigned']`. The Agent branch allows only accepted, in-progress, or completed forward work transitions, not cancellation.

#### Side effects

- Update status to `cancelled`.
- Write `cancellationReason`.
- Refresh `updatedAt`.
- Append status history from `accepted` to `cancelled`.
- Write `REQUEST_UPDATED` with safe fields.

#### Failure modes

- Customer or Agent attempt: denied.
- Admin policy does not permit the edge: denied.
- Missing reason: rejected.
- Concurrent status change: stale update rejected.

#### Related requirement IDs

FR-AD-07, NFR-01, NFR-05.

### Transition: `in_progress` to `cancelled`

#### Trigger

An Admin performs a permitted operational cancellation of a request that is in progress.

#### Actor(s)

- Permitted actor: Admin only.
- Customer: No.
- Agent: No.

#### Preconditions

- Current status is `in_progress`.
- Actor role resolves to `admin`.
- Final administrative policy permits this edge.
- Cancellation reason is supplied where required.

#### Client-side validation

The Admin UI presents this operation only under the finalized policy. Customer and Agent clients must not present a cancellation action for this status. The repository rechecks the current state before attempting the write.

#### Firestore Rules enforcement

The Admin request-update branch enforces this Admin-only edge. The Customer branch rejects it because only `created` and `assigned` are customer-cancellable. The Agent branch permits only forward transitions to `accepted`, `in_progress`, or `completed` and therefore rejects cancellation.

#### Side effects

- Update status to `cancelled`.
- Write `cancellationReason`.
- Refresh `updatedAt`.
- Append status history from `in_progress` to `cancelled`.
- Write `REQUEST_UPDATED` with safe fields.

#### Failure modes

- Customer attempt: denied.
- Agent attempt: denied.
- Admin policy does not permit the action: denied.
- Concurrent completion: stale cancellation rejected if the request is already terminal.

#### Related requirement IDs

FR-AD-07, NFR-01, NFR-05.

## Terminal States

### Completed

`completed` is terminal. It means the assigned work has reached a successful end state. No ordinary client role may move a completed request to another status. The request remains readable according to the role's access boundary, and status history remains readable but immutable.

The Admin portal may display completed work. The Agent may view completed work. A Customer may view its own completed request. No terminal-state transition is permitted by the lifecycle mapping.

### Cancelled

`cancelled` is terminal. It means the request was cancelled through an allowed transition and should retain its history and safe cancellation reason. No ordinary client role may move a cancelled request to another status.

Customers may reach `cancelled` only from their own `created` or `assigned` request. Admins may reach it from the states permitted by the final administrative policy, including `accepted` and `in_progress` in the finalized lifecycle. Agents do not cancel requests.

### Terminal immutability

Terminal status does not mean the entire Firestore document is deleted. The request and its history remain available for permitted reads. The lifecycle fields cannot be changed after completion or cancellation. Existing status-history and audit-log records cannot be updated or deleted.

## Cancellation Eligibility Rules

| Current status | Customer | Agent | Admin |
|---|---|---|---|
| `created` | Yes, own request | No | Yes |
| `assigned` | Yes, own request | No | Yes |
| `accepted` | No | No | Yes, if operationally permitted |
| `in_progress` | No | No | Yes, if operationally permitted |
| `completed` | No; terminal | No; terminal | No; terminal |
| `cancelled` | No; terminal | No; terminal | No; terminal |

The customer restriction is deliberate: `resource.data.status in ['created', 'assigned']` is required in the customer update branch. The general `isValidTransition(from, to)` helper contains the accepted and in-progress cancellation edges because those edges exist for Admin-only cancellation. The helper is not, by itself, the complete actor authorization rule.

The client must align its visible actions with this table, but Firestore Rules remain the final authority.

## Concurrency and Transaction Behavior

### Status update concurrency

Status updates must be treated as conditional operations. The repository should:

1. Read the current request state or begin a transaction.
2. Confirm the current stored status and actor eligibility.
3. Compute exactly one permitted next status.
4. Write only the allowed mutable fields.
5. Write the status-history record using the documented atomic pattern where supported.
6. Retry only when the failure is a retryable transaction conflict.
7. Re-read after an uncertain result before offering a duplicate retry.

If two actors attempt competing transitions, Firestore's transaction or write conflict behavior and Rules re-evaluation must prevent a client from assuming a stale state. The losing client displays a safe stale-state message and refreshes.

### Request-code counter transaction

A new request uses a Firestore transaction on `counters/{year}`:

```text
[Read counters/{year}]
        |
        v
[Increment lastRequestNumber by one]
        |
        v
[Format REQ-YYYY-000123]
        |
        v
[Create request with status created]
        |
        v
[Commit transaction]
```

The request repository must not allocate a number with a separate read and write. A transaction conflict causes a new transaction attempt. A failed attempt must not be reported as a created request and must not reuse a code from an uncertain attempt.

The Rules restrict counter structure and one-step increments, but without Cloud Functions they cannot fully prove that every counter update is paired with one request creation. This is a known client-side limitation and is covered by Emulator integration tests.

### Concurrent cancellation and agent acceptance

If a customer attempts to cancel an `assigned` request while the Agent attempts to accept it, only one update may succeed against the current stored state. A stale customer cancellation is rejected if the status is already `accepted`; a stale acceptance is rejected if the request is already `cancelled`. The client must refresh and show the resulting authoritative state.

## Status History Design

### Schema

Each record under `requests/{requestId}/status_history/{historyId}` contains:

| Field | Type | Meaning |
|---|---|---|
| `fromStatus` | string or null for the initial record | Previous lifecycle state |
| `toStatus` | string | New lifecycle state |
| `changedBy` | string | Authenticated actor UID |
| `changedAt` | timestamp | Time of the transition |
| `note` | string | Safe bounded operational note |

The exact field names match the finalized collection contract. Status values are lowercase and must use the finalized enum.

### Initial history record

When a request is created, the repository should create the initial status-history record representing the request entering `created`. The implementation must use the agreed initial-record convention consistently, such as `fromStatus: null` and `toStatus: created`.

### Transition history example

```text
requests/REQ_DOCUMENT/status_history/history-created
  fromStatus: null
  toStatus: created
  changedBy: CUSTOMER_UID
  changedAt: TIMESTAMP
  note: "Request created"

requests/REQ_DOCUMENT/status_history/history-assigned
  fromStatus: created
  toStatus: assigned
  changedBy: ADMIN_UID
  changedAt: TIMESTAMP
  note: "Assigned to agent"

requests/REQ_DOCUMENT/status_history/history-accepted
  fromStatus: assigned
  toStatus: accepted
  changedBy: AGENT_UID
  changedAt: TIMESTAMP
  note: "Agent accepted request"
```

The values above are illustrative safe values only; no passwords, tokens, API keys, or secrets may be placed in a note.

### Append-only behavior

The client may create a history record for an allowed action. It may not update or delete an existing history record. Rules validate the actor, statuses, transition edge, timestamp, note type, and request access boundary.

Because no Cloud Functions are used, the client repository must coordinate request updates and history writes carefully. If the chosen Firestore batch or transaction pattern cannot include the required operation safely, the implementation must document the failure behavior and test it.

## Audit Event Mapping

| Lifecycle operation | Required event | `targetType` | Safe `targetId` | Safe old/new values |
|---|---|---|---|---|
| Login and profile resolution | `LOGIN_SUCCESS` | `authentication` or `user` | Authenticated UID | Result only; never credentials |
| Create request | `REQUEST_CREATED` | `request` | Request ID or request code | `status: created`, service type if approved |
| `created` to `assigned` | `REQUEST_ASSIGNED` | `request` | Request ID or request code | Old/new status and assigned agent UID if approved |
| `assigned` to `accepted` | `REQUEST_UPDATED` | `request` | Request ID or request code | `assigned` to `accepted` |
| `accepted` to `in_progress` | `REQUEST_UPDATED` | `request` | Request ID or request code | `accepted` to `in_progress` |
| `in_progress` to `completed` | `REQUEST_UPDATED` | `request` | Request ID or request code | `in_progress` to `completed` |
| Any permitted cancellation | `REQUEST_UPDATED` | `request` | Request ID or request code | Previous status to `cancelled`; safe reason only |
| Permission denial | `AUTHORIZATION_FAILED` | Safe target type | Safe target ID | Result `denied`; no Rules source or secrets |
| Non-authorization database failure | `DATABASE_ERROR` | Safe target type | Safe target ID | Safe error category only |

Audit records use the fixed schema in `audit_logs/{logId}`. The client must use an allowlist serializer for `oldValue` and `newValue` and must never serialize complete request objects or raw exceptions without filtering.

## Rule Enforcement Summary

| Transition | Rules branch | Main enforcement |
|---|---|---|
| `created -> assigned` | Admin request-update branch | `isAdmin()`, valid transition, mutable-field allowlist, valid `agentId` |
| `assigned -> accepted` | Agent request-update branch | `isAgent()`, `isAssigned(resource.data.agentId)`, valid transition |
| `accepted -> in_progress` | Agent request-update branch; Admin branch if permitted | Assignment/role check, valid transition, immutable-field checks |
| `in_progress -> completed` | Agent request-update branch; Admin branch if permitted | Assignment/role check, valid transition, immutable-field checks |
| `created -> cancelled` | Customer or Admin request-update branch | Customer ownership plus customer status restriction; Admin policy |
| `assigned -> cancelled` | Customer or Admin request-update branch | Customer ownership plus customer status restriction; Admin policy |
| `accepted -> cancelled` | Admin request-update branch only | Customer branch rejects accepted; Agent branch rejects cancellation |
| `in_progress -> cancelled` | Admin request-update branch only | Customer branch rejects in-progress; Agent branch rejects cancellation |
| Any terminal-state update | No permitted branch | `completed` and `cancelled` have no valid outgoing edge |

## Invalid Transitions and Rejected Operations

| Invalid operation | Actor | Expected result | Reason |
|---|---|---|---|
| `created -> accepted` | Agent | Deny | Assignment must occur first. |
| `created -> in_progress` | Agent | Deny | Agent cannot skip `assigned` and `accepted`. |
| `created -> completed` | Any non-permitted actor | Deny | Lifecycle edge does not exist. |
| `assigned -> in_progress` | Agent | Deny | Agent must accept first. |
| `accepted -> completed` | Agent | Deny | Agent must start work first. |
| `completed -> cancelled` | Customer | Deny | Completed is terminal. |
| `cancelled -> assigned` | Admin | Deny | Cancelled is terminal. |
| `accepted -> cancelled` | Customer | Deny | Customer cancellation is limited to `created` and `assigned`. |
| `in_progress -> cancelled` | Customer | Deny | Customer cancellation is limited to `created` and `assigned`. |
| Any lifecycle update | Customer on another customer's request | Deny | Ownership mismatch. |
| Any lifecycle update | Agent on another agent's request | Deny | Assignment mismatch. |
| Any lifecycle update | Unauthenticated user | Deny | No authenticated session. |
| Any update changing `customerId` | Any client role | Deny | Ownership is immutable. |
| Any update changing `requestCode` | Any client role | Deny | Request code is immutable. |
| Any update changing service details after creation | Any client role | Deny | Request identity and service fields are immutable. |
| History update or delete | Any role | Deny | History is append-only. |
| Audit update or delete | Any role | Deny | Audit records are append-only. |

## Client Repository Contract

### General repository contract

Each lifecycle repository method must return a typed result that distinguishes success, permission denial, validation failure, stale state, network failure, and unknown database failure. UI code must not infer success from a button press.

Recommended conceptual methods:

```text
createRequest(input)
assignRequest(requestId, agentId)
acceptAssignedRequest(requestId)
startRequest(requestId)
completeRequest(requestId, note)
cancelCustomerRequest(requestId, reason)
cancelAdminRequest(requestId, reason)
```

The exact Dart class and method names may vary, but each method must preserve the same authorization and transition contract.

### `createRequest`

1. Validate service type, description, preferred date/time, address, and priority.
2. Confirm the Firebase user is an authenticated Customer.
3. Start a Firestore transaction on `counters/{year}`.
4. Increment `lastRequestNumber` by one.
5. Format `REQ-YYYY-000123`.
6. Create the request with `status: created`, authenticated `customerId`, null `agentId`, timestamps, and null cancellation reason.
7. Create the initial status-history record using the agreed convention.
8. Write `REQUEST_CREATED` with safe fields.
9. Show the request code only after successful completion or verified read-back.

### `assignRequest`

1. Confirm the actor is an Admin.
2. Read the request and selected profile.
3. Confirm current status is `created`.
4. Confirm selected profile has stored role `agent`.
5. Write only assignment/status/update fields.
6. Append history and write `REQUEST_ASSIGNED`.
7. Refresh the request and report success only after confirmation.

### `acceptAssignedRequest`

1. Confirm actor role is `agent`.
2. Confirm request `agentId` equals the authenticated UID.
3. Confirm current status is `assigned`.
4. Write `accepted` and `updatedAt` only.
5. Append history and write `REQUEST_UPDATED`.

### `startRequest`

1. Confirm actor is the assigned Agent or an Admin when operationally permitted.
2. Confirm current status is `accepted`.
3. Write `in_progress` and `updatedAt` only.
4. Append history and write `REQUEST_UPDATED`.

### `completeRequest`

1. Confirm actor is the assigned Agent or an Admin when operationally permitted.
2. Confirm current status is `in_progress`.
3. Validate any note as a safe bounded string.
4. Write `completed` and `updatedAt` only.
5. Append history and write `REQUEST_UPDATED`.
6. Treat the request as terminal after success.

### `cancelCustomerRequest`

1. Confirm actor role is `customer`.
2. Confirm request ownership.
3. Confirm current status is `created` or `assigned`.
4. Validate cancellation reason.
5. Write `cancelled`, `cancellationReason`, and `updatedAt`.
6. Append history and write `REQUEST_UPDATED`.
7. Never expose the action for `accepted` or `in_progress`.

### `cancelAdminRequest`

1. Confirm actor role is `admin`.
2. Confirm the final administrative policy permits the current-state cancellation.
3. Validate cancellation reason.
4. Write only the permitted mutable fields.
5. Append history and write `REQUEST_UPDATED`.
6. Treat the request as terminal after success.

### Repository error mapping

| Repository result | UI behavior |
|---|---|
| Success | Refresh state and show confirmed result |
| Validation failure | Show field or lifecycle validation message; do not write |
| Permission denied | Show safe authorization message; optionally write `AUTHORIZATION_FAILED` |
| Stale transition | Refresh request and explain that it changed |
| Network failure | Offer retry after checking current state |
| Counter conflict | Retry bounded transaction with a new attempt |
| Database error | Show safe failure message and write safe `DATABASE_ERROR` if required |

## Test Scenarios

Rules and integration tests run against Firebase Emulator Suite. Each test verifies both the Firestore result and the resulting data when the operation is allowed.

TEST-07 through TEST-10 are defined in the RBAC & Security Document as the required authorization anchors. The lifecycle tests below use the TEST-LC-* prefix to avoid conflicting identifiers.

| Test ID | Actor | From | To | Expected result | Requirement ID |
|---|---|---|---|---|---|
| TEST-LC-01 | Customer A | `created` | `cancelled` on Customer A request | Allow | FR-C-11 |
| TEST-LC-02 | Agent A | `assigned` | `accepted` on Agent A request | Allow | FR-A-03 |
| TEST-LC-03 | Customer A | `assigned` | `cancelled` on Customer A request | Allow | FR-C-11, NFR-01 |
| TEST-LC-04 | Customer A | `accepted` | `cancelled` on Customer A request | Deny | NFR-01 |
| TEST-LC-05 | Customer A | `in_progress` | `cancelled` on Customer A request | Deny | NFR-01 |
| TEST-LC-06 | Admin | `created` | `assigned` | Allow | FR-AD-06, NFR-01 |
| TEST-LC-07 | Agent A | `assigned` | `accepted` on Agent B request | Deny | FR-A-08, NFR-01 |
| TEST-LC-08 | Agent A | `created` | `in_progress` | Deny | FR-A-04, NFR-01 |
| TEST-LC-09 | Agent A | `accepted` | `in_progress` on Agent A request | Allow | FR-A-04, NFR-01 |
| TEST-LC-10 | Agent A | `in_progress` | `completed` on Agent A request | Allow | FR-A-05, NFR-01 |
| TEST-LC-11 | Agent A | `completed` | `in_progress` | Deny | FR-A-07, NFR-01 |
| TEST-LC-12 | Admin | `accepted` | `cancelled` | Allow if operationally permitted | FR-AD-07, NFR-01 |
| TEST-LC-13 | Admin | `in_progress` | `cancelled` | Allow if operationally permitted | FR-AD-07, NFR-01 |
| TEST-LC-14 | Customer A | Any state | Any update on Customer B request | Deny | FR-C-12, TEST-07, NFR-01 |
| TEST-LC-15 | Unauthenticated | Any state | Any protected update | Deny | FR-AUTH-08, NFR-01 |
| TEST-LC-16 | Any role | Existing history | Update or delete | Deny | NFR-01 |
| TEST-LC-17 | Any role | Existing audit log | Update or delete | Deny | NFR-01, LOG-05 |
| TEST-LC-18 | Customer | Counter value | Increment by more than one | Deny | NFR-01 |
| TEST-LC-19 | Customer | Counter transaction | Create request with valid code | Allow if transaction succeeds | FR-C-07, FR-C-08, NFR-05 |
| TEST-LC-20 | Customer | Failed request write | No lifecycle transition | No success shown | NFR-05 |
| TEST-LC-21 | Any actor | Any state | Audit event containing secret | Deny before write | NFR-02, LOG-07 |

The required checklist anchors `TEST-07` through `TEST-10` are used for representative ownership, assignment, and cancellation scenarios. Additional test identifiers should be reconciled with the finalized Requirements Checklist if its complete numbering contains more specific lifecycle cases.

## Open Questions and Assumptions

### Open questions

| ID | Question | Lifecycle impact | Default assumption |
|---|---|---|---|
| OQ-01 | Which exact statuses are customer-cancellable? | Controls customer cancellation UI and Rules. | `created` and `assigned` only, per PRD Assumption A-03. |
| OQ-02 | Which Admin transitions are operationally permitted? | Controls Admin status actions from accepted and in_progress. | Admin-only cancellation and forward operational actions are enabled only where the finalized RBAC policy permits them. |
| OQ-03 | Must status update and history creation be one atomic write? | Controls consistency after partial failures. | Use a Firestore transaction or batch where compatible; document any client-side limitation. |
| OQ-04 | What note length and content restrictions apply? | Controls status-history validation and safe audit fields. | Use a bounded non-secret string and validate in Dart before write. |
| OQ-05 | Is the initial history record `fromStatus: null` or an omitted field? | Controls initial history schema. | Use the exact Database Design and RBAC & Security contract consistently. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | The stored current state is `requests/{requestId}.status`; no second state source exists. |
| ASSUMP-02 | A customer-created request starts with `status: created`, authenticated `customerId`, and no assigned agent. |
| ASSUMP-03 | The agent ID is retained when an assigned request is cancelled unless the finalized data contract explicitly requires clearing it. |
| ASSUMP-04 | Admin permissions for accepted/in-progress cancellation are controlled by the finalized RBAC policy and may be narrower than the state graph. |
| ASSUMP-05 | Flutter repositories perform client-side validation, while Firestore Rules remain the backend authorization boundary. |
| ASSUMP-06 | Audit and status-history records are client-written because Cloud Functions are excluded. |
| ASSUMP-07 | The request code counter and request creation use one repository transaction attempt. |
| ASSUMP-08 | Status notes contain no passwords, tokens, API keys, secrets, or unnecessary sensitive data. |
| ASSUMP-09 | The exact Requirements Checklist IDs used here are the finalized IDs already assigned to the corresponding customer, agent, admin, security, and logging requirements. |

## Glossary

| Term | Definition |
|---|---|
| Assigned Agent | Agent whose UID equals `requests/{requestId}.agentId`. |
| Current state | The lowercase value stored in `requests/{requestId}.status`. |
| Customer ownership | Equality between authenticated UID and `requests/{requestId}.customerId`. |
| Lifecycle transition | A valid directed edge from one request state to another. |
| Terminal state | A state with no allowed outgoing lifecycle transition. |
| Status history | Append-only record under `requests/{requestId}/status_history/{historyId}`. |
| Audit event | Safe operational or security record under `audit_logs/{logId}`. |
| Counter transaction | Firestore transaction that increments `counters/{year}.lastRequestNumber` and creates a request code. |
| Request code | Human-readable identifier in the format `REQ-YYYY-000123`. |
| Operationally permitted | Allowed only when the final role and security policy authorizes the action. |
| Append-only | A record may be created but not updated or deleted by the client. |
| Stale state | A local view that no longer matches the stored request status. |

## Appendix A — Full Lifecycle Diagram {.unnumbered}

```text
                                   +----------------+
                                   |   CANCELLED    |
                                   |    TERMINAL    |
                                   +----------------+
                                    ^   ^   ^   ^
                                    |   |   |   |
                           Admin ---+   |   |   +--- Admin only
                                    |   |   |       from in_progress
                                    |   |   |
                     Customer/Admin|   |   |Admin only
                                    |   |   |       from accepted
                                    |   |   |
+-----------+       Admin       +-----------+       Agent       +-----------+
|           | ----------------> |           | ----------------> |           |
|  CREATED  |                   | ASSIGNED  |                   | ACCEPTED  |
|           |                   |           |                   |           |
+-----------+                   +-----------+                   +-----------+
      |                               |                               |
      | Customer own / Admin          | Customer own / Admin          | Agent
      v                               v                               v
+-----------+                   +-----------+                 +----------------+
| CANCELLED |                   | CANCELLED |                 |  IN_PROGRESS   |
| TERMINAL  |                   | TERMINAL  |                 +----------------+
+-----------+                   +-----------+                          |
                                                                       | Agent /
                                                                       | Admin if permitted
                                                                       v
                                                               +----------------+
                                                               |   COMPLETED    |
                                                               |    TERMINAL    |
                                                               +----------------+

Forward lifecycle:
  created -> assigned -> accepted -> in_progress -> completed

Cancellation lifecycle:
  created     -> cancelled : Customer own or Admin
  assigned    -> cancelled : Customer own or Admin
  accepted    -> cancelled : Admin only
  in_progress -> cancelled : Admin only
```

## Appendix B — Full Transition Table {.unnumbered}

| From | To | Customer | Agent | Admin | Terminal after transition |
|---|---|---|---|---|---|
| `created` | `assigned` | No | No | Yes | No |
| `assigned` | `accepted` | No | Yes, assigned | Conditional if operationally permitted | No |
| `accepted` | `in_progress` | No | Yes, assigned | Conditional if operationally permitted | No |
| `in_progress` | `completed` | No | Yes, assigned | Conditional if operationally permitted | Yes |
| `created` | `cancelled` | Yes, own | No | Yes | Yes |
| `assigned` | `cancelled` | Yes, own | No | Yes | Yes |
| `accepted` | `cancelled` | No | No | Yes | Yes |
| `in_progress` | `cancelled` | No | No | Yes | Yes |
| `completed` | Any | No | No | No | Already terminal |
| `cancelled` | Any | No | No | No | Already terminal |

## Appendix C — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram — this document.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.
