---
title: "QuickServe Database Design Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This Database Design Document defines the Cloud Firestore data model, field schemas, relationships, integrity rules, indexes, access boundaries, counter design, local seed data, and schema-evolution approach for QuickServe.

QuickServe is a small end-to-end Service Request Management Application created for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day challenge intended to demonstrate practical product thinking, secure backend design, clean code, and Git/GitHub discipline.

### Scope

This document covers:

- Cloud Firestore collections and document paths.
- Field types, required fields, examples, and constraints.
- Stored roles, priorities, request statuses, and event names.
- Relationships between users, services, requests, histories, audit records, and counters.
- Request-code generation and status-history behavior.
- Audit logging, indexing, access summaries, and integrity rules.
- Emulator seed data, growth considerations, migration notes, and sample queries.

This document does not define the complete Firestore Security Rules implementation. Detailed Rules belong in the RBAC & Security Document, but this document identifies the schema conditions that Rules must enforce.

### Audience

This document is intended for:

- Flutter/Dart developers implementing repositories and models.
- Firebase developers configuring Firestore, indexes, Rules, and Emulator Suite data.
- Test engineers writing data, Rules, integration, and authorization tests.
- Reviewers evaluating data integrity, security, maintainability, and free-tier compatibility.

### Relationship to companion documents

The Product Requirements Document (PRD) is the product baseline. The Requirements Checklist / Traceability Document maps requirements to implementation and evidence. The System Architecture Document defines system components and data flows. This document provides the authoritative database structure used by those documents.

The RBAC & Security Document contains the full Firestore Security Rules design. The Testing Plan contains detailed test cases. The README / Setup & Deployment Documentation contains project setup, emulator commands, and deployment instructions.

All companion documents must use the same roles, stored values, request states, collections, fields, events, and technology constraints.

## Design Principles

### Document-oriented model

Cloud Firestore is a document database. QuickServe stores operational records as documents with stable IDs and uses a subcollection for request status history. Data is modeled for the expected role-specific reads rather than normalized as if it were a relational database.

### Controlled denormalization

The primary identity and operational records remain authoritative in their own collections. Small display-name snapshots may be stored only when useful for a bounded read, but referenced user documents remain authoritative. Denormalized values must not be used to bypass ownership or role checks.

### Append-only operational history

Status history and audit logs are append-only from clients. Clients may create authorized records but must not update or delete existing history or audit records. This preserves an observable record of transitions and significant actions.

### Bounded queries

Queries must be role-scoped, indexed, and bounded. The design avoids unbounded collection reads to preserve responsiveness and Firebase Spark-plan compatibility.

### Client logic with database enforcement

Business logic runs in Flutter/Dart because Cloud Functions and other server-side functions are excluded. Firestore Security Rules independently enforce authentication, role, ownership, field, and transition constraints. Client-side checks improve user experience but are not the authorization boundary.

### Free-tier compatibility

The design does not require billing, a credit card, Cloud Functions, FCM, or another paid backend service. Firebase Emulator Suite is used for local development and testing.

### Stable field names

Field names and stored enum values are treated as contracts. Changes require a documented migration or compatibility strategy.

## Collection Overview

| Collection or document path | Purpose | Primary owners/readers | Client write behavior |
|---|---|---|---|
| `users/{uid}` | Application profile and stored role. | Authenticated user for own profile; Admin for permitted operational views. | Controlled create/update; role changes are protected. |
| `services/{serviceId}` | Service catalog. | Customers, Agents where applicable, and Admins according to Rules. | Controlled setup/Admin maintenance; baseline does not require a public service-management UI. |
| `requests/{requestId}` | Primary service-request record. | Customer owns own requests; assigned Agent reads assigned requests; Admin reads permitted operational data. | Authorized creates and role-specific updates. |
| `requests/{requestId}/status_history/{historyId}` | Request lifecycle transitions. | Request-eligible readers and Admins according to Rules. | Authorized client creates only; update/delete denied. |
| `audit_logs/{logId}` | Operational and authorization activity. | Admin activity view and authorized diagnostic access. | Authorized client creates only; update/delete denied. |
| `counters/{year}` | Year-scoped request-number counter. | Request-code transaction only. | Narrowly controlled transaction update. |

## Detailed Collection Schemas

### Users

#### Purpose

Stores the application profile associated with a Firebase Authentication UID and the stored RBAC role used by Firestore Security Rules.

#### Document path

`users/{uid}`

The document ID must equal the Firebase Authentication UID.

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `role` | string enum | Yes | Stored role used for access decisions. Allowed values are `customer`, `agent`, `admin`. | `customer` |
| `name` | string | Yes | Display name of the user. | `Aarav Sharma` |
| `email` | string | Yes | Email associated with the account. | `aarav@example.com` |
| `phone` | string | Yes | Contact phone number as entered or normalized by the application. | `+91-9876543210` |
| `createdAt` | Firestore Timestamp | Yes | Profile creation time. | `2026-09-17T10:00:00Z` |
| `updatedAt` | Firestore Timestamp | Yes | Most recent permitted profile update time. | `2026-09-17T10:00:00Z` |

#### Example document

```json
{
  "role": "customer",
  "name": "Aarav Sharma",
  "email": "aarav@example.com",
  "phone": "+91-9876543210",
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>"
}
```

#### Access rules summary

| Actor | Read | Create | Update | Delete |
|---|---|---|---|---|
| Customer | Own profile | Own registration profile with role `customer` | Own permitted non-role fields | Not required in baseline |
| Agent | Own profile and any explicitly permitted operational profile views | Controlled setup | Own permitted non-role fields | Not required in baseline |
| Admin | Permitted user profiles | Controlled setup | Permitted operational fields; role management is restricted | Not required in baseline |
| Unauthenticated user | No | No | No | No |

#### Constraints and validation

- The document ID must equal the authenticated Firebase UID.
- `role` must be exactly `customer`, `agent`, or `admin`.
- A normal user must not self-promote by changing `role`.
- Passwords, tokens, API keys, and secrets must never be stored in this document.
- Email and phone validation must be applied before profile writes.
- Authoritative authentication credentials remain in Firebase Authentication.

#### Relationships and notes

- `users/{uid}` is referenced by `requests.customerId`.
- `users/{uid}` may be referenced by `requests.agentId` when the user has stored role `agent`.
- User display names may be copied into UI-specific view models but are not authoritative references.

### Services

#### Purpose

Stores the active service catalog used when Customers create requests.

#### Document path

`services/{serviceId}`

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `name` | string | Yes | Display name of the service. | `AC servicing` |
| `description` | string | Yes | Short service description. | `Inspection, cleaning, and maintenance of AC units.` |
| `active` | boolean | Yes | Whether the service is available in the active catalog. | `true` |
| `createdAt` | Firestore Timestamp | Yes | Service creation time. | `2026-09-17T10:00:00Z` |

#### Example document

```json
{
  "name": "AC servicing",
  "description": "Inspection, cleaning, and maintenance of AC units.",
  "active": true,
  "createdAt": "<Firestore Timestamp>"
}
```

#### Baseline service records

| Suggested document ID | `name` | `active` |
|---|---|---:|
| `ac_servicing` | AC servicing | true |
| `plumbing` | Plumbing | true |
| `electrical` | Electrical | true |
| `cleaning` | Cleaning | true |

#### Access rules summary

| Actor | Read | Create/update | Delete |
|---|---|---|---|
| Customer | Active services needed for request creation | No baseline requirement | No |
| Agent | Optional read-only access | No baseline requirement | No |
| Admin | Permitted service records | Controlled setup or permitted maintenance | No baseline requirement |
| Unauthenticated user | No | No | No |

#### Constraints and validation

- `name` must be non-empty and unique enough for the active catalog.
- `active` must be boolean.
- The four baseline services must be seeded for the demo.
- A request should reference the selected service using `serviceType` as defined by the finalized product model.

### Requests

#### Purpose

Stores the primary service-request record created by a Customer or permitted operational actor.

#### Document path

`requests/{requestId}`

The Firestore document ID is an internal identifier. `requestCode` is the human-readable identifier shown to users.

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `requestCode` | string | Yes | Unique yearly display code generated transactionally. | `REQ-2026-000123` |
| `customerId` | string | Yes | Firebase UID of the Customer who owns the request. | `customer-uid-001` |
| `agentId` | string or null | No at creation; required when assigned | Firebase UID of the assigned Agent. | `agent-uid-001` |
| `serviceType` | string | Yes | Selected service type. | `AC servicing` |
| `description` | string | Yes | Customer’s description of the required service. | `AC is not cooling properly.` |
| `preferredDateTime` | Firestore Timestamp | Yes | Customer’s requested schedule. | `2026-09-20T09:30:00Z` |
| `address` | string | Yes | Service location entered by the Customer. | `12 Main Road, Nagpur` |
| `priority` | string enum | Yes | Stored priority: `low`, `medium`, or `high`. | `medium` |
| `status` | string enum | Yes | Stored lifecycle state. | `created` |
| `createdAt` | Firestore Timestamp | Yes | Request creation time. | `2026-09-17T10:15:00Z` |
| `updatedAt` | Firestore Timestamp | Yes | Most recent request update time. | `2026-09-17T10:15:00Z` |
| `cancellationReason` | string or null | No | Required when a permitted cancellation occurs. | `Customer unavailable` |

#### Example document

```json
{
  "requestCode": "REQ-2026-000123",
  "customerId": "customer-uid-001",
  "agentId": null,
  "serviceType": "AC servicing",
  "description": "AC is not cooling properly.",
  "preferredDateTime": "<Firestore Timestamp>",
  "address": "12 Main Road, Nagpur",
  "priority": "medium",
  "status": "created",
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>",
  "cancellationReason": null
}
```

#### Access rules summary

| Actor | Read | Create | Update | Delete |
|---|---|---|---|---|
| Customer | Own requests only | Own request with own `customerId` and status `created` | Own permitted fields and eligible cancellation | No baseline delete |
| Assigned Agent | Requests where `agentId` equals authenticated UID | No | Permitted fields/statuses on assigned requests | No |
| Admin | Permitted operational requests | Yes where operationally permitted | Assignment and permitted status/operational fields | No baseline delete |
| Unauthenticated user | No | No | No | No |

#### Constraints and validation

- `requestCode` must match `REQ-YYYY-000123` and be unique for the year.
- `customerId` must equal the authenticated Customer UID when created by a Customer.
- `agentId` must be null/empty until assignment and must reference an Agent when populated.
- `priority` must be `low`, `medium`, or `high`.
- `status` must be one of the defined lifecycle states.
- A Customer must not change `customerId`.
- An Agent must not change ownership or assignment to another Agent.
- `cancellationReason` is required when status changes to `cancelled`.
- `createdAt` must not be rewritten after creation.
- `updatedAt` must change with permitted updates.
- Passwords, tokens, API keys, and secrets must not be stored.

#### Relationships and notes

- `customerId` references `users/{uid}` with role `customer`.
- `agentId` references `users/{uid}` with role `agent` when populated.
- `serviceType` corresponds to an active service catalog entry.
- A request has many status-history records in its `status_history` subcollection.
- A request can have multiple audit records in `audit_logs`, identified by target type and target ID.

### Request status history

#### Purpose

Stores an append-only record of each request lifecycle transition and optional operational note.

#### Document path

`requests/{requestId}/status_history/{historyId}`

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `fromStatus` | string enum or null | Yes | Previous status; null for an initial creation record if one is stored. | `created` |
| `toStatus` | string enum | Yes | New status after the transition. | `assigned` |
| `changedBy` | string | Yes | Firebase UID of the actor making the transition. | `admin-uid-001` |
| `changedAt` | Firestore Timestamp | Yes | Time of the transition. | `2026-09-17T10:25:00Z` |
| `note` | string or null | No | Optional safe transition note. | `Assigned to available Agent.` |

#### Example document

```json
{
  "fromStatus": "created",
  "toStatus": "assigned",
  "changedBy": "admin-uid-001",
  "changedAt": "<Firestore Timestamp>",
  "note": "Assigned to available Agent."
}
```

#### Access rules summary

- Customers may read history for their own requests where permitted.
- Assigned Agents may read history for requests assigned to them where permitted.
- Admins may read operational history.
- Authorized actors may create a history record as part of a valid transition.
- Clients may not update or delete an existing history record.
- Unauthenticated users have no access.

#### Lifecycle transitions

| From status | To status | Permitted actor(s) | Required history behavior |
|---|---|---|---|
| `created` | `assigned` | Admin | Store assignment transition and actor. |
| `created` | `cancelled` | Customer for own eligible request; Admin | Store cancellation reason and actor. |
| `assigned` | `accepted` | Assigned Agent | Confirm authenticated UID equals `agentId`. |
| `assigned` | `cancelled` | Admin; Customer only if product policy permits | Store cancellation reason and actor. |
| `accepted` | `in_progress` | Assigned Agent; Admin | Store actor and optional note. |
| `in_progress` | `completed` | Assigned Agent; Admin | Store completion transition and optional note. |
| `accepted` | `cancelled` | Admin | Store operational cancellation reason. |
| `in_progress` | `cancelled` | Admin only | Store exceptional cancellation reason. |
| `completed` | None | None | Terminal state. |
| `cancelled` | None | None | Terminal state. |

**Assumption A-01:** Customer cancellation is permitted before acceptance unless the approved product policy defines a narrower eligibility rule.

### Audit logs

#### Purpose

Stores append-only records of meaningful authentication, request, authorization, and database events.

#### Document path

`audit_logs/{logId}`

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `actorUserId` | string | Yes | UID of the user or actor associated with the event. | `admin-uid-001` |
| `actorRole` | string enum | Yes | Stored actor role. | `admin` |
| `action` | string enum | Yes | Required event name. | `REQUEST_ASSIGNED` |
| `targetType` | string | Yes | Type of target record. | `request` |
| `targetId` | string | Yes | Target document ID or safe target identifier. | `request-doc-001` |
| `oldValue` | map, string, or null | No | Safe representation of changed prior value. | `{ "status": "created" }` |
| `newValue` | map, string, or null | No | Safe representation of changed new value. | `{ "status": "assigned" }` |
| `result` | string | Yes | Operation outcome. | `success` |
| `timestamp` | Firestore Timestamp | Yes | Event time. | `2026-09-17T10:25:00Z` |

#### Example document

```json
{
  "actorUserId": "admin-uid-001",
  "actorRole": "admin",
  "action": "REQUEST_ASSIGNED",
  "targetType": "request",
  "targetId": "request-doc-001",
  "oldValue": { "status": "created", "agentId": null },
  "newValue": { "status": "assigned", "agentId": "agent-uid-001" },
  "result": "success",
  "timestamp": "<Firestore Timestamp>"
}
```

#### Required events

| Event | When recorded |
|---|---|
| `LOGIN_SUCCESS` | A user successfully authenticates. |
| `REQUEST_CREATED` | A request and request code are successfully created. |
| `REQUEST_ASSIGNED` | An Admin assigns or changes the assigned Agent. |
| `REQUEST_UPDATED` | A permitted request field or status is updated. |
| `AUTHORIZATION_FAILED` | A protected operation is denied or an invalid authorization attempt is detected. |
| `DATABASE_ERROR` | A relevant Firestore read/write failure requires diagnosis. |

#### Safe and forbidden values

Audit records may contain actor IDs, roles, event names, target types, target IDs, safe field changes, results, and timestamps. They must never contain passwords, authentication tokens, API keys, private credentials, or other secrets. Raw authentication errors must be sanitized before logging.

#### Access and retention behavior

Audit records are append-only from clients. Authorized event writers may create records; clients cannot update or delete records. Admins may view permitted activity records. **Assumption A-02:** No automated archival or deletion process is included in the free-tier baseline; retention must be reviewed if the system grows beyond demo scale.

### Counters and request codes

#### Purpose

The counter collection provides a transaction-safe sequence for human-readable request codes.

#### Document path

`counters/{year}`

#### Fields

| Field | Type | Required | Description | Example |
|---|---|---:|---|---|
| `lastRequestNumber` | integer | Yes after first allocation | Last allocated sequence for the year. | `123` |

#### Transaction sequence

1. Determine the operating year used for the request code.
2. Start a Firestore transaction.
3. Read `counters/{year}`.
4. Treat a missing counter as zero.
5. Increment `lastRequestNumber` by one.
6. Write the updated counter.
7. Format `REQ-YYYY-000123` using a six-digit sequence.
8. Create the request with that code in the same transaction where supported.
9. Commit the transaction.

#### Duplicate avoidance

Firestore transaction retries handle concurrent updates to the same counter. A failed transaction must not be presented as a successful request. The client must avoid creating a second request after an uncertain result without determining whether the original transaction committed, where the SDK permits that determination.

#### Access rules summary

- Customers do not directly edit counters.
- Agents do not directly edit counters.
- Admins do not directly edit counters outside the approved request-code operation.
- Rules should narrowly restrict counter writes to the transaction pattern and trusted field shape.

#### Trade-offs

A single yearly counter is simple and appropriate for the 5–7 day challenge. It can become a contention point at high write volume, but that scale is outside the assignment. A server-side sequence service is intentionally excluded because Cloud Functions and paid backend services are not allowed.

## Relationships

### Entity relationship overview

```text
users/{uid}
   | customerId
   | agentId
   v
requests/{requestId} --------------------> services/{serviceId}
   |
   +---- requests/{requestId}/status_history/{historyId}
   |
   +---- audit_logs/{logId} via targetType + targetId

counters/{year} ---- transactionally allocates ----> requests.requestCode
```

### Relationship rules

| Relationship | Meaning | Integrity requirement |
|---|---|---|
| User to Customer requests | `requests.customerId` references `users/{uid}`. | Customer can read only own requests. |
| User to Agent requests | `requests.agentId` references an Agent user when populated. | Agent can read/update only assigned requests. |
| Request to Service | `serviceType` identifies the selected service. | Service must be an allowed active catalog value at creation. |
| Request to status history | One request has many transition records. | History is append-only and follows valid transitions. |
| Request to audit logs | Audit records identify target request through `targetType` and `targetId`. | Audit records are append-only and secret-free. |
| Counter to request code | Year counter allocates request-code sequence. | Allocation is transaction-based and unique per year. |

## Stored Enums

### Roles

| Display label | Stored value | Meaning |
|---|---|---|
| Customer | `customer` | End user who creates and tracks own requests. |
| Agent | `agent` | Service worker managing assigned requests. |
| Admin | `admin` | Operational administrator. |

### Priorities

| Display label | Stored value |
|---|---|
| Low | `low` |
| Medium | `medium` |
| High | `high` |

### Request statuses

| Stored value | Meaning | Terminal |
|---|---|---:|
| `created` | Request created but not assigned. | No |
| `assigned` | Admin assigned an Agent. | No |
| `accepted` | Assigned Agent accepted the work. | No |
| `in_progress` | Assigned Agent or Admin marked work in progress. | No |
| `completed` | Work completed. | Yes |
| `cancelled` | Eligible request cancelled. | Yes |

### Events

| Event | Meaning |
|---|---|
| `LOGIN_SUCCESS` | Successful authentication. |
| `REQUEST_CREATED` | Successful request creation. |
| `REQUEST_ASSIGNED` | Agent assignment or change. |
| `REQUEST_UPDATED` | Permitted request update or status change. |
| `AUTHORIZATION_FAILED` | Denied or invalid protected operation. |
| `DATABASE_ERROR` | Relevant Firestore failure requiring diagnosis. |

## Indexing Strategy

Firestore automatically indexes many single fields. The following composite indexes are recommended for the role-specific queries required by QuickServe.

**Assumption A-03:** Exact index syntax and collection-group settings will be finalized from the implemented repository queries and committed in the Firebase configuration.

| Suggested index name | Collection | Fields | Query purpose |
|---|---|---|---|
| `requests_customer_createdAt` | `requests` | `customerId` ascending; `createdAt` descending | Customer’s own requests ordered by newest creation time. |
| `requests_agent_status_createdAt` | `requests` | `agentId` ascending; `status` ascending; `createdAt` descending | Agent assigned requests filtered by status and ordered by creation time. |
| `requests_status_createdAt` | `requests` | `status` ascending; `createdAt` descending | Admin requests filtered by status and ordered by creation time. |
| `requests_agent_createdAt` | `requests` | `agentId` ascending; `createdAt` descending | Admin requests filtered by assigned Agent and ordered by creation time. |
| `requests_priority_createdAt` | `requests` | `priority` ascending; `createdAt` descending | Admin requests filtered by priority and ordered by creation time. |
| `requests_serviceType_createdAt` | `requests` | `serviceType` ascending; `createdAt` descending | Admin requests filtered by service type and ordered by creation time. |
| `audit_actor_timestamp` | `audit_logs` | `actorUserId` ascending; `timestamp` descending | Activity for a specific actor ordered by newest event. |
| `audit_action_timestamp` | `audit_logs` | `action` ascending; `timestamp` descending | Activity filtered by event type and ordered by newest event. |

Indexing rules:

- Add an index only for an implemented query.
- Keep query filters and sort order aligned with the index.
- Document index errors and generated recommendations during development.
- Avoid indexes for fields that are not queried.
- Use bounded result sets and pagination if dataset size requires it.

## Security and Access Considerations

### Schema-related Rules requirements

Firestore Security Rules must enforce:

- Authentication for protected collections.
- Role lookup through `users.role`.
- Customer ownership through `customerId`.
- Agent assignment through `agentId`.
- Admin access to permitted operational records.
- Controlled roles, priorities, statuses, and event names.
- Valid lifecycle transitions.
- Protected immutable fields such as original ownership and creation timestamps.
- Append-only status history and audit logs.
- Counter field shape and restricted write behavior.

### Immutable and protected fields

The following fields require special protection:

- `users/{uid}` document ID.
- `users.role` for normal self-service updates.
- `requests.customerId` after request creation.
- `requests.createdAt` after request creation.
- `requests.requestCode` after allocation.
- Existing status-history documents.
- Existing audit-log documents.
- Counter values outside the approved allocation operation.

Full Rule expressions, helper functions, and emulator test setup belong in the RBAC & Security Document.

## Data Integrity Constraints

| Constraint area | Required rule |
|---|---|
| Required fields | Required fields in each schema must exist and use the expected type. |
| Role values | Only `customer`, `agent`, and `admin` are allowed. |
| Priority values | Only `low`, `medium`, and `high` are allowed. |
| Status values | Only `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled` are allowed. |
| Event values | Only the six defined event names are allowed for the baseline. |
| Ownership | Customer-created requests must use the authenticated Customer UID. |
| Assignment | An assigned Agent must have stored role `agent`. |
| Status transitions | Only approved actor/state transitions are allowed. |
| Cancellation | `cancellationReason` is required when status becomes `cancelled`. |
| Request code | Must match `REQ-YYYY-000123` and be unique per year. |
| Timestamps | Authoritative timestamps use Firestore Timestamp values. |
| Creation immutability | Request ownership, request code, and original creation time cannot be changed after creation. |
| Append-only history | Existing status-history and audit documents cannot be updated or deleted by clients. |
| Secret exclusion | Passwords, tokens, API keys, and secrets must never be stored. |

## Data Volume and Growth Considerations

### Expected demo volume

The internship demo is expected to contain a small dataset:

- A limited number of Customers, Agents, and Admin test profiles.
- Four baseline service documents.
- Dozens to hundreds of request documents for demonstration and testing.
- Several status-history records per request.
- Several audit records per meaningful operation.
- One counter document per calendar year used by the demo.

### Growth behavior

- Customer and Agent queries must remain role-scoped.
- Admin lists should use bounded results and pagination if volume grows.
- Activity views should avoid loading all audit records at once.
- Request history should load only for the selected request.
- Indexes should be added only for real queries.

### Cleanup and archival

No automated archival or cleanup service is included in the Spark/no-Cloud-Functions baseline. **Assumption A-04:** If the system grows beyond the internship demo, a future approved retention and archival design will be required. It must not silently delete audit or status-history records.

## Sample Queries and Required Indexes

| Query | Collection | Filters and order | Required index |
|---|---|---|---|
| Customer’s recent requests | `requests` | `customerId == auth.uid`, order by `createdAt desc` | `requests_customer_createdAt` |
| Agent assigned requests by status | `requests` | `agentId == auth.uid`, `status == selectedStatus`, order by `createdAt desc` | `requests_agent_status_createdAt` |
| Admin requests by status | `requests` | `status == selectedStatus`, order by `createdAt desc` | `requests_status_createdAt` |
| Admin requests by Agent | `requests` | `agentId == selectedAgent`, order by `createdAt desc` | `requests_agent_createdAt` |
| Admin requests by priority | `requests` | `priority == selectedPriority`, order by `createdAt desc` | `requests_priority_createdAt` |
| Admin requests by service | `requests` | `serviceType == selectedService`, order by `createdAt desc` | `requests_serviceType_createdAt` |
| Activity for actor | `audit_logs` | `actorUserId == selectedActor`, order by `timestamp desc` | `audit_actor_timestamp` |
| Activity by event | `audit_logs` | `action == selectedAction`, order by `timestamp desc` | `audit_action_timestamp` |

Search by request code may use a direct document lookup if the implementation maps the code to a document, or an indexed equality query if the repository design requires it. Full-text search is not part of the baseline.

## Local Development and Emulator Seed Data

### Emulator architecture

Firebase Emulator Suite provides local Authentication and Firestore services. Flutter applications must be configured to connect to emulators in development/test mode and must not accidentally use production data.

### Sample users

| UID | Stored role | Name | Email | Purpose |
|---|---|---|---|---|
| `customer-uid-001` | `customer` | Aarav Sharma | `customer1@example.test` | Own-request and cross-customer tests. |
| `customer-uid-002` | `customer` | Diya Patil | `customer2@example.test` | Cross-customer denial target. |
| `agent-uid-001` | `agent` | Rohan Deshmukh | `agent1@example.test` | Assigned-request workflow. |
| `agent-uid-002` | `agent` | Meera Joshi | `agent2@example.test` | Cross-agent denial target. |
| `admin-uid-001` | `admin` | Operations Admin | `admin@example.test` | Admin dashboard and operational workflow. |

Test passwords must be supplied through local emulator setup or documented test configuration and must never be committed to a public repository.

### Sample services

| Document ID | Name | Active |
|---|---|---:|
| `ac_servicing` | AC servicing | true |
| `plumbing` | Plumbing | true |
| `electrical` | Electrical | true |
| `cleaning` | Cleaning | true |

### Sample requests

| Document ID | Request code | Customer | Agent | Status | Service |
|---|---|---|---|---|---|
| `request-doc-001` | `REQ-2026-000001` | `customer-uid-001` | null | `created` | AC servicing |
| `request-doc-002` | `REQ-2026-000002` | `customer-uid-001` | `agent-uid-001` | `assigned` | Plumbing |
| `request-doc-003` | `REQ-2026-000003` | `customer-uid-002` | `agent-uid-002` | `in_progress` | Electrical |
| `request-doc-004` | `REQ-2026-000004` | `customer-uid-001` | `agent-uid-001` | `completed` | Cleaning |
| `request-doc-005` | `REQ-2026-000005` | `customer-uid-002` | null | `cancelled` | Plumbing |

### Seed histories and audit records

Seed at least:

- A `created` history record for each request.
- An `assigned` history record for assigned requests.
- An `accepted` and `in_progress` history record for the active Agent workflow.
- A `completed` history record for completed work.
- A `cancelled` history record with a cancellation reason for cancelled work.
- Audit records for `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, and relevant authorization outcomes.

Seed records are test data only and must not contain real credentials or personal secrets.

## Migration and Schema Evolution Notes

### Adding fields

1. Add the field to the Database Design Document.
2. Define whether it is required for new documents or optional for existing documents.
3. Update Dart models, validators, repositories, Rules, indexes, and tests.
4. Make readers tolerant of missing values during the migration period.
5. Backfill existing documents only through a controlled, documented process.
6. Update seed data and companion documentation.

### Renaming fields

Avoid renaming fields during the 5–7 day challenge. If a rename becomes necessary, use a compatibility period in which readers support both fields, write the new field, migrate existing documents, then remove the old field only after verification.

### Enum changes

Adding a new role, status, priority, or event is a security and schema change. Update:

- Shared Dart enums and validators.
- Firestore Security Rules.
- UI transition logic.
- Database and architecture documentation.
- Traceability and tests.
- Seed data and indexes where required.

Never silently reinterpret an existing stored value. Terminal-state changes require a product and security review.

### Versioning

**Assumption A-05:** The baseline does not require an explicit per-document schema-version field. If future migrations become complex, an approved `schemaVersion` field may be introduced through the documented migration process.

### Backward compatibility

Readers should treat newly added optional fields as absent until populated. Writers must preserve fields they do not own. Rules should reject unexpected sensitive fields where feasible.

## Open Questions and Assumptions

### Open questions

1. What exact maximum lengths should apply to descriptions, addresses, names, phone numbers, and notes?
2. Should `serviceType` store the service document ID or the display name, provided the choice remains consistent with the finalized PRD and schema?
3. Should request and history writes fail together when a required audit write fails, or should selected diagnostic records use a best-effort policy?
4. What exact Firestore composite index file will result from the implemented queries?
5. Which timezone determines the year in `REQ-YYYY-000123`?
6. What controlled setup script or operator process will create Agent and Admin profiles?

### Assumptions

- New public registrations create users with stored role `customer`.
- Agent and Admin profiles are created through a trusted setup process.
- The demo uses one organization and operational geography.
- Customer cancellation is allowed only for eligible requests, assumed to be before acceptance unless product policy states otherwise.
- Four baseline service documents are seeded and active.
- The project remains on Firebase Spark with no billing or credit card.
- No Cloud Functions, custom claims, FCM, or paid backend service is required.
- Firebase Emulator Suite is the preferred local data and Rules test environment.
- Exact text lengths, index definitions, and retention settings are implementation details to be documented before verification.

## Glossary

| Term | Definition |
|---|---|
| Agent | Service worker who manages requests assigned to that Agent. |
| Audit trail | Append-only record of significant actors, actions, targets, results, and timestamps. |
| Cloud Firestore | Firebase document database used for QuickServe data. |
| Counter | Year-scoped document used to allocate sequential request numbers. |
| Customer | User who browses services and creates/tracks own service requests. |
| Emulator Suite | Local Firebase services used for development and automated testing. |
| Firestore Security Rules | Backend-enforced conditions controlling read/write access to Firestore documents. |
| RBAC | Role-Based Access Control; permissions are determined by stored role. |
| Request code | Human-readable identifier such as `REQ-2026-000123`. |
| Session persistence | Retaining a valid Firebase Authentication session across app restarts. |
| Spark plan | Firebase free plan used by this project; no billing or credit card. |
| Status history | Append-only record of request lifecycle transitions. |
| Stored enum | Controlled lowercase string value used consistently in Firestore. |

## Appendix A — Full Collection Schema at a Glance {.unnumbered}

| Collection/document | Field | Type | Required | Summary |
|---|---|---|---:|---|
| `users/{uid}` | `role` | string enum | Yes | `customer`, `agent`, or `admin`. |
| `users/{uid}` | `name` | string | Yes | Display name. |
| `users/{uid}` | `email` | string | Yes | Account email. |
| `users/{uid}` | `phone` | string | Yes | Contact phone. |
| `users/{uid}` | `createdAt` | Timestamp | Yes | Profile creation time. |
| `users/{uid}` | `updatedAt` | Timestamp | Yes | Profile update time. |
| `services/{serviceId}` | `name` | string | Yes | Service display name. |
| `services/{serviceId}` | `description` | string | Yes | Service description. |
| `services/{serviceId}` | `active` | boolean | Yes | Catalog availability. |
| `services/{serviceId}` | `createdAt` | Timestamp | Yes | Service creation time. |
| `requests/{requestId}` | `requestCode` | string | Yes | `REQ-YYYY-000123`. |
| `requests/{requestId}` | `customerId` | string | Yes | Owning Customer UID. |
| `requests/{requestId}` | `agentId` | string/null | Conditional | Assigned Agent UID. |
| `requests/{requestId}` | `serviceType` | string | Yes | Selected service. |
| `requests/{requestId}` | `description` | string | Yes | Request description. |
| `requests/{requestId}` | `preferredDateTime` | Timestamp | Yes | Preferred schedule. |
| `requests/{requestId}` | `address` | string | Yes | Service address. |
| `requests/{requestId}` | `priority` | string enum | Yes | `low`, `medium`, or `high`. |
| `requests/{requestId}` | `status` | string enum | Yes | Lifecycle status. |
| `requests/{requestId}` | `createdAt` | Timestamp | Yes | Request creation time. |
| `requests/{requestId}` | `updatedAt` | Timestamp | Yes | Request update time. |
| `requests/{requestId}` | `cancellationReason` | string/null | Conditional | Required when cancelled. |
| `status_history/{historyId}` | `fromStatus` | enum/null | Yes | Previous status. |
| `status_history/{historyId}` | `toStatus` | enum | Yes | New status. |
| `status_history/{historyId}` | `changedBy` | string | Yes | Actor UID. |
| `status_history/{historyId}` | `changedAt` | Timestamp | Yes | Transition time. |
| `status_history/{historyId}` | `note` | string/null | No | Safe transition note. |
| `audit_logs/{logId}` | `actorUserId` | string | Yes | Actor UID. |
| `audit_logs/{logId}` | `actorRole` | role enum | Yes | Actor role. |
| `audit_logs/{logId}` | `action` | event enum | Yes | Event name. |
| `audit_logs/{logId}` | `targetType` | string | Yes | Target type. |
| `audit_logs/{logId}` | `targetId` | string | Yes | Target ID. |
| `audit_logs/{logId}` | `oldValue` | map/string/null | No | Safe prior value. |
| `audit_logs/{logId}` | `newValue` | map/string/null | No | Safe new value. |
| `audit_logs/{logId}` | `result` | string | Yes | Operation result. |
| `audit_logs/{logId}` | `timestamp` | Timestamp | Yes | Event time. |
| `counters/{year}` | `lastRequestNumber` | integer | Conditional | Last allocated sequence. |

## Appendix B — Enum Reference {.unnumbered}

### Roles

| Display | Stored value |
|---|---|
| Customer | `customer` |
| Agent | `agent` |
| Admin | `admin` |

### Priorities

| Display | Stored value |
|---|---|
| Low | `low` |
| Medium | `medium` |
| High | `high` |

### Statuses

| Stored value | Description |
|---|---|
| `created` | Created and awaiting assignment. |
| `assigned` | Assigned to an Agent. |
| `accepted` | Accepted by assigned Agent. |
| `in_progress` | Work is in progress. |
| `completed` | Work is completed; terminal. |
| `cancelled` | Request cancelled; terminal. |

### Events

| Stored event | Description |
|---|---|
| `LOGIN_SUCCESS` | Successful login. |
| `REQUEST_CREATED` | Request created successfully. |
| `REQUEST_ASSIGNED` | Agent assigned or changed. |
| `REQUEST_UPDATED` | Request updated or status changed. |
| `AUTHORIZATION_FAILED` | Protected action denied or invalid. |
| `DATABASE_ERROR` | Relevant database failure. |

## Appendix C - Companion Documentation Set

1. System Architecture Document
2. Database Design Document - this document
3. RBAC & Security Document
4. README / Setup & Deployment Documentation

The companion documents must use the same roles, states, collections, fields, stored enum values, event names, framework decisions, and billing constraints.

