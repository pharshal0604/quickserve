---
title: "QuickServe RBAC & Security Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This RBAC & Security Document defines authentication, role-based access control, Firestore authorization, field protection, lifecycle transition enforcement, append-only audit behavior, denial handling, security testing, and known limitations for QuickServe.

QuickServe is a Service Request Management Application for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day Full-Stack Mobile Application challenge. The implementation must demonstrate secure backend design, clean Flutter/Dart code, practical product thinking, and disciplined Git/GitHub delivery.

### Scope

This document covers:

- Firebase Authentication using email/password.
- Session persistence, password reset, profile creation, and role routing.
- Stored roles in `users.role`: `customer`, `agent`, and `admin`.
- Firestore Security Rules as the backend authorization boundary.
- Ownership and assignment enforcement for requests.
- Field-level protection for users, services, requests, status history, audit logs, and counters.
- Status transition rules for `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`.
- Append-only status-history and audit-log behavior.
- Safe client-side audit logging and denial handling.
- Firebase Emulator Suite security testing.
- Free-tier compatibility with Firebase Spark and no Cloud Functions.

This document does not introduce custom claims, Cloud Functions, FCM, a separate backend, Supabase, React, Next.js, Angular, or a paid Firebase configuration.

### Audience

This document is intended for:

- Flutter/Dart developers implementing authentication, repositories, providers, route guards, and screens.
- Firebase developers configuring Authentication, Firestore, Rules, indexes, and Emulator Suite data.
- Test engineers writing Rules, integration, widget, and denial-path tests.
- Reviewers evaluating least privilege, ownership enforcement, data integrity, and free-tier compatibility.

### Relationship to companion documents

The Product Requirements Document (PRD) defines the product baseline and finalized capabilities. The Requirements Checklist / Traceability document defines requirement identifiers and evidence expectations. The System Architecture Document defines application layers and Firebase data flow. The Database Design Document defines the authoritative collections, fields, relationships, indexes, and counter model.

This document is the authorization contract consumed by the Flutter mobile application and Flutter Web admin portal. The User Flow Diagram Document describes the corresponding user journeys. The Testing Plan defines broader application tests; the Rules test matrix in this document defines the minimum authorization scenarios that must run in the Firebase Emulator Suite.

If implementation artifacts conflict with this document, the finalized project decisions must be reconciled before deployment. A client-side screen, provider, or route must never be treated as an authorization substitute for Firestore Rules.

## Security Goals and Principles

### Database-layer enforcement

Firestore Security Rules are the backend authorization boundary. Every protected read and write must be evaluated against authentication state, the stored profile role, ownership, assignment, field changes, and lifecycle transitions. Client-side checks are for user experience only.

### Least privilege

Each role receives only the access required for its workflow:

- Customers read and manage their own requests and their own permitted profile fields.
- Agents read and manage requests assigned to them and their own permitted profile fields.
- Admins perform explicitly permitted operational management actions and read permitted operational data.
- No role receives unrestricted write access to another role's profile, request ownership, audit history, or counters.

### Defense in depth

QuickServe uses layered controls:

1. Firebase Authentication identifies the signed-in account.
2. `users/{uid}` supplies the stored role.
3. go_router limits navigation to appropriate screens.
4. Riverpod repositories validate client-side inputs and lifecycle transitions.
5. Firestore Rules enforce authentication, role, ownership, assignment, field, and transition checks.
6. Emulator Rules tests verify allow and deny behavior.
7. Safe error handling prevents credential and Rules-detail disclosure.

### No client trust for authorization

A client can be modified or directly call Firestore. Therefore, values supplied by the client, including role, actor role, customer ID, agent ID, status, action, and target IDs, are untrusted until validated by Rules.

### Append-only history

`status_history` and `audit_logs` are append-only from clients. Existing records cannot be updated or deleted. This prevents a client from rewriting or erasing operational history through the normal application API.

### Controlled role provisioning

Self-registration creates only a `customer` profile. A customer cannot promote itself to `agent` or `admin`. Agent and admin provisioning must occur through a controlled administrative process outside the ordinary self-registration screen. Because Cloud Functions and server-side logic are excluded, the project must document and tightly control any development-time role provisioning process.

### Free-tier compatibility

The design is compatible with Firebase Spark, Firebase Emulator Suite, Flutter/Dart, and client-written records. It does not require billing, a credit card, Cloud Functions, or a paid notification service. The limitations of client-written counters, audit logs, and status history are stated explicitly rather than hidden.

## Roles and Stored Values

| Display label | Stored value | Primary client | Responsibility |
|---|---|---|---|
| Customer | `customer` | Flutter mobile | Create and track own service requests |
| Agent | `agent` | Flutter mobile | Manage assigned service requests |
| Admin | `admin` | Flutter Web | Manage permitted operational data and activity |

The stored role field is exactly `users.role`. Role values are lowercase and must be validated against the finalized set `customer`, `agent`, `admin`.

## Collections and Security Boundaries

| Path | Security purpose |
|---|---|
| `users/{uid}` | Profile, role resolution, ownership identity, and controlled self-profile updates |
| `services/{serviceId}` | Active service catalog and service selection |
| `requests/{requestId}` | Request ownership, assignment, lifecycle, and customer/agent operations |
| `requests/{requestId}/status_history/{historyId}` | Append-only lifecycle history |
| `audit_logs/{logId}` | Append-only operational and security events |
| `counters/{year}` | Narrowly controlled request-number increment |

No other collection is authorized by the Rules in this document. The final catch-all rule denies every unspecified path.

## Permission Matrix

Legend: Yes means the capability is allowed for the role when all listed conditions are satisfied. No means the capability is not allowed. Conditional means the capability is allowed only for the stated ownership, assignment, status, field, or role condition.

| Capability | Customer | Agent | Admin |
|---|---|---|---|
| Register with email/password | Yes | No through self-registration | No through self-registration |
| Sign in with email/password | Yes | Yes | Yes |
| Initiate password reset | Yes | Yes | Yes |
| Read own `users/{uid}` profile | Yes | Yes | Yes |
| Update own permitted profile fields | Conditional | Conditional | Conditional |
| Change own role | No | No | No through client profile update |
| Read another user profile | No | No | Conditional; permitted operational view |
| Create a customer profile after self-registration | Yes, role forced to `customer` | No | No through ordinary client flow |
| Read active services | Yes | Yes | Yes |
| Create services | No | No | Conditional; admin-only if finalized configuration permits |
| Update services | No | No | Conditional; admin-only if finalized configuration permits |
| Delete services | No | No | No through client Rules |
| Create a request | Yes, with `customerId == request.auth.uid` | No | No as a customer-originated operation |
| Read own customer requests | Conditional; `customerId == uid` | No | No need for ownership condition; operational access is admin-only |
| Read assigned agent requests | No | Conditional; `agentId == uid` | No need for assignment condition; operational access is admin-only |
| Read any request | No | No | Conditional; only permitted admin request access |
| Update own request description or identity fields | No after creation | No | No |
| Cancel an eligible own request | Conditional; own request and status `created` or `assigned` only | No | Conditional; only if finalized admin transition permits |
| Assign an agent | No | No | Conditional; eligible request and valid agent |
| Accept assigned request | No | Conditional; assigned agent and `assigned -> accepted` |
| Move assigned request to `in_progress` | No | Conditional; assigned agent and valid transition |
| Move assigned request to `completed` | No | Conditional; assigned agent and valid transition |
| Add status-history note | Conditional; only as part of permitted own transition | Conditional; only as part of permitted assigned transition | Conditional; only as part of permitted operational transition |
| Create initial status history | Conditional; as part of own request creation | No | No as customer-originated creation |
| Update status history | No | No | No |
| Delete status history | No | No | No |
| Create audit log | Conditional; for permitted own action | Conditional; for permitted assigned action | Conditional; for permitted admin action |
| Update audit log | No | No | No |
| Delete audit log | No | No | No |
| Increment request counter | Conditional; only with request creation transaction pattern | No | Conditional only if an admin-supported creation path is explicitly implemented |
| Read counters | No | No | No through client Rules |
| Write arbitrary counter value | No | No | No |
| Read audit activity | No | No | Conditional; admin-only |

The exact allowed update fields and transitions are enforced in the Rules below. If a product decision later narrows an admin operation, the Rules must be narrowed before the UI is shipped.

## Authentication Model

### Firebase Authentication

QuickServe uses Firebase Authentication with email/password. Authentication establishes the account identity represented by `request.auth.uid` in Firestore Rules. The application must not implement a second password store in Firestore.

Passwords are managed by Firebase Authentication and are never written to `users`, `requests`, `audit_logs`, local application logs, Crashlytics messages, source control, or any Firestore document.

### Registration

Self-registration follows this sequence:

1. Validate name, email, phone, and password locally.
2. Call Firebase Authentication email/password account creation.
3. Create `users/{uid}` with the authenticated UID, profile fields, timestamps, and `role: customer`.
4. Read the profile back.
5. Route to the customer mobile experience only after the profile exists and contains a valid role.

The client must not expose a role selector during ordinary registration. Rules reject a self-registration profile whose role is not `customer`.

### Profile creation and provisioning

The profile document is the role source for this design. Agent and admin profiles must be provisioned through a controlled process. Since Cloud Functions and custom claims are excluded, the project must restrict this process to trusted project operators using the Emulator Suite or a controlled Firebase Console/development procedure, and must not expose role promotion in the customer-facing client.

A production deployment should replace client-trusted provisioning with a server-side administrative workflow, as described in Production Recommendations.

### Session persistence

Firebase Authentication session persistence is used so a valid signed-in user can restore a session after application restart. Session persistence does not bypass profile resolution. On restoration, the client must read `users/{uid}`, validate the role, and route only after the profile is available.

### Password reset

The Login screen may initiate Firebase Authentication password reset by email. The client must display a generic result that does not reveal whether an email address is registered. Password reset tokens and email-action details are handled by Firebase Authentication and must not be copied into application logs or audit records.

### Sign-out

Logout calls Firebase Authentication sign-out and clears role-dependent providers and route state. After sign-out, go_router redirects to Login. Firestore Rules independently reject subsequent unauthenticated reads and writes.

## Session and Role Routing

### Routing sequence

```text
[Application start]
        |
        v
[Firebase Auth state listener]
        |
        v
<Authenticated user?> -- No --> [Login]
        |
       Yes
        v
[Read users/{uid}]
        |
        v
<Profile exists and role valid?>
      | No                         | Yes
      v                            v
[Safe recovery or sign-out]   <Role value>
                                   |
              +--------------------+--------------------+
              |                    |                    |
              v                    v                    v
          customer              agent                admin
              |                    |                    |
              v                    v                    v
       [Customer Home]      [Agent queue]       [Admin Dashboard]
```

### go_router behavior

The router should expose public routes such as Login, Registration, and password reset initiation. Protected routes require an authenticated session and a resolved valid profile. The redirect decision must account for loading state so the app does not briefly expose a protected screen before profile resolution.

Recommended route decisions:

| Condition | Route result |
|---|---|
| No Firebase user | Login or Registration |
| Firebase user but profile loading | Splash or guarded loading state |
| Firebase user and missing profile | Safe recovery screen or sign-out |
| Valid `customer` role | Customer mobile routes |
| Valid `agent` role | Agent mobile routes |
| Valid `admin` role | Admin Web routes |
| Valid session with wrong client route | Redirect to role-appropriate entry route |
| Signed-out user attempts protected route | Redirect to Login |

The router must not use a role supplied by route parameters, local storage, or an unverified client object. Firestore Rules remain authoritative.

## Role Protection and Provisioning

### No self-promotion

The following operations are prohibited for all client roles:

- Changing `users.role` from one valid value to another.
- Adding `agent` or `admin` to a self-registration request.
- Updating another user's role.
- Writing a profile with a UID that is not the authenticated UID.
- Creating a user profile that omits or falsifies the authenticated identity.

### Controlled Agent/Admin provisioning

The intended assignment workflow is:

1. A trusted project operator identifies the Firebase Authentication UID.
2. The operator provisions or updates the profile through a controlled administrative process.
3. The resulting profile is checked for exactly one lowercase role value.
4. The operator records the change outside the customer-facing workflow according to project governance.
5. The user signs in and the client resolves the role from `users/{uid}`.

Because this assignment excludes Cloud Functions and custom claims, the application Rules cannot independently prove that a role change was performed by an organization administrator unless a separate trusted provisioning boundary is introduced. The client therefore never exposes role promotion, and production recommendations include moving role administration to a server-side process.

## Data and Enum Validation

### Roles

```text
customer | agent | admin
```

### Priorities

```text
low | medium | high
```

### Statuses

```text
created | assigned | accepted | in_progress | completed | cancelled
```

### Required event names

```text
LOGIN_SUCCESS
REQUEST_CREATED
REQUEST_ASSIGNED
REQUEST_UPDATED
AUTHORIZATION_FAILED
DATABASE_ERROR
```

### Request code

Request codes use the exact format:

```text
REQ-YYYY-000123
```

The numeric portion is allocated using a Firestore transaction on `counters/{year}`. The client must not generate a code by reading a counter and writing later without a transaction.

## Full Firestore Security Rules

The following is the implementation baseline for `firestore.rules`. The Rules use `users.role` as the role source and deny any path not explicitly listed.

```firebase
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- Authentication and role helpers ----------

    function isSignedIn() {
      return request.auth != null;
    }

    function userRole() {
      return isSignedIn()
        ? get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role
        : null;
    }

    function isCustomer() {
      return isSignedIn() && userRole() == 'customer';
    }

    function isAgent() {
      return isSignedIn() && userRole() == 'agent';
    }

    function isAdmin() {
      return isSignedIn() && userRole() == 'admin';
    }

    function isOwner(customerId) {
      return isSignedIn() && request.auth.uid == customerId;
    }

    function isAssigned(agentId) {
      return isSignedIn() && request.auth.uid == agentId;
    }

    function isValidRole(value) {
      return value in ['customer', 'agent', 'admin'];
    }

    function isValidStatus(value) {
      return value in [
        'created',
        'assigned',
        'accepted',
        'in_progress',
        'completed',
        'cancelled'
      ];
    }

    function isValidPriority(value) {
      return value in ['low', 'medium', 'high'];
    }

    function isValidTransition(from, to) {
      return (from == 'created' && to == 'assigned')
        || (from == 'assigned' && to == 'accepted')
        || (from == 'accepted' && to == 'in_progress')
        || (from == 'in_progress' && to == 'completed')
        || (from == 'created' && to == 'cancelled')
        || (from == 'assigned' && to == 'cancelled')
        || (from == 'accepted' && to == 'cancelled')
        || (from == 'in_progress' && to == 'cancelled');
    }

    function unchanged(field) {
      return request.resource.data[field] == resource.data[field];
    }

    function hasOnlyKeys(keys) {
      return request.resource.data.keys().hasOnly(keys);
    }

    function hasRequiredKeys(keys) {
      return request.resource.data.keys().hasAll(keys);
    }

    function hasValidTimestamp(field) {
      return request.resource.data[field] is timestamp;
    }

    function hasValidRequestCode() {
      return request.resource.data.requestCode.matches('REQ-[0-9]{4}-[0-9]{6}');
    }

    function isValidRequestBase() {
      return hasOnlyKeys([
          'requestCode',
          'customerId',
          'agentId',
          'serviceType',
          'description',
          'preferredDateTime',
          'address',
          'priority',
          'status',
          'createdAt',
          'updatedAt',
          'cancellationReason'
        ])
        && hasRequiredKeys([
          'requestCode',
          'customerId',
          'serviceType',
          'description',
          'preferredDateTime',
          'address',
          'priority',
          'status',
          'createdAt',
          'updatedAt'
        ])
        && request.resource.data.requestCode is string
        && hasValidRequestCode()
        && request.resource.data.customerId is string
        && request.resource.data.agentId == null
        && request.resource.data.serviceType is string
        && request.resource.data.description is string
        && request.resource.data.preferredDateTime is timestamp
        && request.resource.data.address is string
        && isValidPriority(request.resource.data.priority)
        && isValidStatus(request.resource.data.status)
        && hasValidTimestamp('createdAt')
        && hasValidTimestamp('updatedAt')
        && request.resource.data.cancellationReason == null;
    }

    function isValidProfileCreate() {
      return hasOnlyKeys([
          'role',
          'name',
          'email',
          'phone',
          'createdAt',
          'updatedAt'
        ])
        && hasRequiredKeys([
          'role',
          'name',
          'email',
          'phone',
          'createdAt',
          'updatedAt'
        ])
        && request.resource.data.role == 'customer'
        && request.resource.data.name is string
        && request.resource.data.email is string
        && request.resource.data.phone is string
        && hasValidTimestamp('createdAt')
        && hasValidTimestamp('updatedAt');
    }

    function isValidAuditAction() {
      return request.resource.data.action in [
        'LOGIN_SUCCESS',
        'REQUEST_CREATED',
        'REQUEST_ASSIGNED',
        'REQUEST_UPDATED',
        'AUTHORIZATION_FAILED',
        'DATABASE_ERROR'
      ];
    }

    // ---------- User profiles ----------

    match /users/{uid} {
      allow read: if isSignedIn() && (
        request.auth.uid == uid || isAdmin()
      );

      allow create: if isSignedIn()
        && request.auth.uid == uid
        && isValidProfileCreate();

      allow update: if isSignedIn()
        && request.auth.uid == uid
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'name',
          'phone',
          'updatedAt'
        ])
        && unchanged('role')
        && unchanged('email')
        && unchanged('createdAt')
        && request.resource.data.name is string
        && request.resource.data.phone is string
        && hasValidTimestamp('updatedAt');

      allow delete: if false;
    }

    // ---------- Services ----------

    match /services/{serviceId} {
      allow read: if isSignedIn();

      allow create: if isAdmin()
        && request.resource.data.keys().hasOnly([
          'name',
          'description',
          'active',
          'createdAt'
        ])
        && request.resource.data.name is string
        && request.resource.data.description is string
        && request.resource.data.active is bool
        && request.resource.data.createdAt is timestamp;

      allow update: if isAdmin()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'name',
          'description',
          'active'
        ])
        && request.resource.data.name is string
        && request.resource.data.description is string
        && request.resource.data.active is bool
        && unchanged('createdAt');

      allow delete: if false;
    }

    // ---------- Requests ----------

    match /requests/{requestId} {
      allow read: if isSignedIn() && (
        isOwner(resource.data.customerId)
        || isAssigned(resource.data.agentId)
        || isAdmin()
      );

      allow create: if isCustomer()
        && request.resource.data.customerId == request.auth.uid
        && isValidRequestBase()
        && request.resource.data.status == 'created';

      allow update: if isSignedIn() && (
        // Customer cancellation of an eligible own request.
        (
          isCustomer()
          && isOwner(resource.data.customerId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'status',
            'updatedAt',
            'cancellationReason'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('agentId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && request.resource.data.status == 'cancelled'
          && isValidTransition(resource.data.status, 'cancelled')
          && resource.data.status in ['created', 'assigned']
          && request.resource.data.cancellationReason is string
          && hasValidTimestamp('updatedAt')
        )
        ||
        // Assigned agent status updates.
        (
          isAgent()
          && isAssigned(resource.data.agentId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'status',
            'updatedAt'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('agentId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && isValidTransition(resource.data.status, request.resource.data.status)
          && request.resource.data.status in [
            'accepted',
            'in_progress',
            'completed'
          ]
          && hasValidTimestamp('updatedAt')
        )
        ||
        // Admin assignment and explicitly permitted status updates.
        (
          isAdmin()
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'agentId',
            'status',
            'updatedAt',
            'cancellationReason'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && isValidStatus(request.resource.data.status)
          && isValidTransition(resource.data.status, request.resource.data.status)
          && (
            request.resource.data.status != 'assigned'
            || request.resource.data.agentId is string
          )
          && (
            request.resource.data.status != 'cancelled'
            || request.resource.data.cancellationReason is string
          )
          && hasValidTimestamp('updatedAt')
        )
      );

      allow delete: if false;

      match /status_history/{historyId} {
        allow read: if isSignedIn() && (
          isAdmin()
          || isOwner(get(/databases/$(database)/documents/requests/$(requestId)).data.customerId)
          || isAssigned(get(/databases/$(database)/documents/requests/$(requestId)).data.agentId)
        );

        allow create: if isSignedIn()
          && request.resource.data.keys().hasOnly([
            'fromStatus',
            'toStatus',
            'changedBy',
            'changedAt',
            'note'
          ])
          && request.resource.data.changedBy == request.auth.uid
          && request.resource.data.changedAt is timestamp
          && request.resource.data.toStatus is string
          && isValidStatus(request.resource.data.toStatus)
          && (
            request.resource.data.fromStatus == null
            || isValidStatus(request.resource.data.fromStatus)
          )
          && (
            request.resource.data.fromStatus == null
            || isValidTransition(
              request.resource.data.fromStatus,
              request.resource.data.toStatus
            )
            || request.resource.data.fromStatus == request.resource.data.toStatus
          )
          && request.resource.data.note is string
          && (
            isAdmin()
            || isOwner(get(/databases/$(database)/documents/requests/$(requestId)).data.customerId)
            || isAssigned(get(/databases/$(database)/documents/requests/$(requestId)).data.agentId)
          );

        allow update: if false;
        allow delete: if false;
      }
    }

    // ---------- Audit logs ----------

    match /audit_logs/{logId} {
      allow read: if isAdmin();

      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly([
          'actorUserId',
          'actorRole',
          'action',
          'targetType',
          'targetId',
          'oldValue',
          'newValue',
          'result',
          'timestamp'
        ])
        && request.resource.data.actorUserId == request.auth.uid
        && request.resource.data.actorRole == userRole()
        && isValidRole(request.resource.data.actorRole)
        && isValidAuditAction()
        && request.resource.data.targetType is string
        && request.resource.data.targetId is string
        && request.resource.data.result in ['success', 'denied', 'failure']
        && request.resource.data.timestamp is timestamp
        && request.resource.data.oldValue is map
        && request.resource.data.newValue is map;

      allow update: if false;
      allow delete: if false;
    }

    // ---------- Request counters ----------

    match /counters/{year} {
      allow read: if false;

      // The client may increment only by one. Pairing this update with the
      // request creation transaction is required by the repository contract.
      // Rules cannot prove every cross-document transaction intent, so this
      // is supplemented by client code and Emulator integration tests.
      allow update: if isCustomer()
        && request.resource.data.keys().hasOnly(['lastRequestNumber'])
        && resource.data.keys().hasOnly(['lastRequestNumber'])
        && resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber == resource.data.lastRequestNumber + 1;

      allow create: if isAdmin()
        && request.resource.data.keys().hasOnly(['lastRequestNumber'])
        && request.resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber >= 0;

      allow delete: if false;
    }

    // ---------- Deny every unspecified collection or document ----------

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Rule-by-Rule Explanation

### Global helpers

| Helper | Purpose | Security effect |
|---|---|---|
| `isSignedIn()` | Checks for a Firebase Authentication session. | Prevents unauthenticated access from passing role checks. |
| `userRole()` | Reads the role from `users/{uid}`. | Makes `users.role` the role source; it is not supplied by the client request. |
| `isCustomer()` | Checks stored role `customer`. | Limits customer operations to authenticated customer profiles. |
| `isAgent()` | Checks stored role `agent`. | Limits agent operations to authenticated agent profiles. |
| `isAdmin()` | Checks stored role `admin`. | Limits operational access to authenticated admin profiles. |
| `isOwner(customerId)` | Compares the request UID with a request customer ID. | Prevents cross-customer request access. |
| `isAssigned(agentId)` | Compares the request UID with a request agent ID. | Prevents cross-agent request access. |
| `isValidStatus()` | Validates the finalized status enum. | Rejects arbitrary status strings. |
| `isValidPriority()` | Validates the finalized priority enum. | Rejects arbitrary priority strings. |
| `isValidTransition()` | Encodes allowed lifecycle edges. | Prevents skipped, reversed, or arbitrary transitions. |
| `unchanged(field)` | Compares the incoming field with the stored field. | Protects immutable identity and request fields. |

### `users/{uid}`

Reads are allowed to the signed-in owner and to admins. This supports profile display and controlled admin user views without making profiles public.

Self-profile creation is allowed only when the authenticated UID equals the document ID and the role is exactly `customer`. The allowed field set prevents extra fields from being injected during self-registration.

Self-profile updates are limited to `name`, `phone`, and `updatedAt`. Role, email, UID identity, and creation time cannot be changed through this update path. Deletes are always denied.

The Rules do not provide a client-side role-promotion path. Controlled Agent/Admin provisioning must occur outside ordinary self-registration.

### `services/{serviceId}`

Signed-in users may read the service catalog. Admins may create or update services if that administrative capability is enabled in the final product configuration. Creation and update field sets are explicit, `createdAt` is immutable after creation, and deletes are denied.

The mobile client should select only active services for new requests. Rules validate request structure and authorization; the repository should also verify that the selected service is currently active before creation. If active-service validation is made a hard database requirement, it must be added deliberately with an allowed `get()` path and Rules test coverage.

### `requests/{requestId}` reads

A customer may read a request only when `customerId` equals the authenticated UID. An agent may read a request only when `agentId` equals the authenticated UID. An admin may read operational requests according to the admin role.

A guessed document ID, stale route, or modified client query cannot create ownership access because the Rules evaluate the stored request document.

### `requests/{requestId}` creation

Only a customer may create a request. The stored customer ID must equal the authenticated UID. The request must have the exact allowed field set, valid request code format, valid priority, valid initial status, required timestamps, and no initial agent or cancellation reason.

The Rules do not independently prove that the request code came from a counter transaction. The client repository must use the counter transaction pattern, and Emulator integration tests must verify the complete request-creation workflow.

### `requests/{requestId}` updates

Customer updates are restricted to eligible cancellation from created or assigned status only. Request identity, service, description, address, priority, timestamps of creation, request code, and assignment cannot be changed by the customer.

Agent updates are restricted to lifecycle status and `updatedAt`. The authenticated agent must match the stored `agentId`, and the transition must be one of the permitted agent transitions.

Admin updates are restricted to assignment, permitted status changes, `updatedAt`, and cancellation reason. Admin writes cannot change the customer, request code, service, description, preferred time, address, priority, or creation time.

All update branches require a valid lifecycle transition. A client cannot change a status from `created` directly to `completed`, set an arbitrary string, or rewrite an immutable field.

### `status_history` reads and creates

A status-history read is allowed to the request's customer, assigned agent, or admin. A history create requires an authenticated actor, exact field set, actor identity matching the Firebase UID, valid statuses, a valid transition or initial/null source status, a timestamp, and a string note.

Status-history update and delete are always denied. The Rules cannot guarantee that every status update and history write are atomically paired without a trusted server; the client must use the documented transaction/batch pattern and tests must verify the intended workflow.

### `audit_logs/{logId}`

Admins may read audit logs. Any signed-in role may create a log only with the actor UID matching the session and actor role matching the role resolved from `users.role`.

The action must be one of the finalized event names. The record must contain only the declared fields, a safe result value, maps for old and new values, and a timestamp. Updates and deletes are always denied.

Rules validate structure, identity, action names, and result values. Rules cannot reliably detect every secret embedded in arbitrary client-provided map content. Client audit builders therefore must use an allowlisted safe-field serializer and must reject or omit forbidden values before writing.

### `counters/{year}`

Counter reads are denied. Customer counter updates may increment `lastRequestNumber` by exactly one and may not add extra fields. Admin creation is limited to initializing a non-negative integer counter. Counter deletes are denied.

Rules cannot fully prove that a counter increment is paired with exactly one request creation across a client transaction. The repository must perform the counter update and request creation in a Firestore transaction, and Emulator tests must cover conflicts, retries, and duplicate prevention. A trusted server would provide stronger enforcement.

### Catch-all deny

The recursive catch-all match denies every path not explicitly authorized. A newly added collection is denied until a deliberate Rules change, schema review, and test coverage are completed.

## Ownership and Assignment Enforcement

### Customer ownership

A request is owned by the value stored in `requests/{requestId}.customerId`. Customer reads and cancellation updates require that this value equal `request.auth.uid`. The client must query by authenticated UID and must not rely only on a locally filtered all-requests query.

On create, the Rules force the customer ID to the authenticated UID. On update, the customer ID is immutable. This prevents a customer from transferring a request into or out of another user's account.

### Agent assignment

An assigned request is controlled by the value stored in `requests/{requestId}.agentId`. Agent reads and lifecycle updates require that this value equal `request.auth.uid`. The agent cannot change its own assignment, customer ID, request code, or request details.

Admin assignment changes are explicitly restricted to the assignment/status/update fields. The client should present only users whose stored role is `agent`, but the Rules should also validate the operational assignment path according to the final provisioning and query design.

### Admin access

Admin access is role-based, not based on a route string or a locally stored boolean. Admin reads and writes are still limited by field sets and transitions. Admin is not a universal bypass for append-only history or audit immutability.

## Field-Level Protection

| Collection | Immutable after creation | Customer update | Agent update | Admin update |
|---|---|---|---|---|
| `users/{uid}` | Role, email, createdAt, UID identity | Name, phone, updatedAt for own profile | Name, phone, updatedAt for own profile | Read permitted profiles; role changes are not exposed through ordinary client Rules |
| `services/{serviceId}` | createdAt, document identity | None | None | Name, description, active if administrative service management is enabled |
| `requests/{requestId}` | requestCode, customerId, serviceType, description, preferredDateTime, address, priority, createdAt | Status, updatedAt, cancellationReason only for eligible own cancellation | Status, updatedAt only for assigned lifecycle transitions | agentId, status, updatedAt, cancellationReason only for permitted operational transitions |
| `status_history/{historyId}` | All fields after creation | Create only as permitted transition actor | Create only as permitted transition actor | Create only as permitted transition actor |
| `audit_logs/{logId}` | All fields after creation | Create only for own permitted action | Create only for own permitted action | Create only for own permitted action |
| `counters/{year}` | Document identity and field set | Increment only by one in creation transaction pattern | No | Initialize or use only through explicitly supported operational path |

## Status Transition Enforcement

### Lifecycle mapping

| From | To | Customer | Agent | Admin |
|---|---|---:|---:|---:|
| `created` | `assigned` | No | No | Conditional |
| `assigned` | `accepted` | No | Conditional; assigned agent | Conditional if operationally permitted |
| `accepted` | `in_progress` | No | Conditional; assigned agent | Conditional if operationally permitted |
| `in_progress` | `completed` | No | Conditional; assigned agent | Conditional if operationally permitted |
| `created` | `cancelled` | Conditional; own request | No | Conditional if finalized |
| `assigned` | `cancelled` | Conditional; own request | No | Conditional if finalized |
| `accepted` | `cancelled` | No | No | Conditional if finalized |
| `in_progress` | `cancelled` | No | No | Conditional if finalized |
| `completed` | Any other status | No | No | No |
| `cancelled` | Any other status | No | No | No |

### Client-side enforcement

Repositories should validate the current status, requested next status, role, ownership or assignment, required note, and required cancellation reason before calling Firestore. The UI should hide or disable actions that are not valid for the current state.

Client validation is not sufficient. A stale client, modified APK, direct Firestore call, or concurrent update may bypass the UI. Rules repeat the transition validation using stored `resource.data` and incoming `request.resource.data`.

### Concurrent updates

A status update should use a transaction or a conditional read-update sequence that rechecks the current status immediately before writing. If Rules reject the update because another actor changed the status, the client must show a safe stale-state message and refresh rather than reporting success.

## Append-Only Enforcement

### Status history

The client may create a status-history document when it is the actor for a permitted transition. It may not update or delete any history document. History IDs should be generated in a way that avoids accidental overwrite, such as an auto-generated Firestore document ID.

### Audit logs

The client may create an audit log for an allowed event. It may not update or delete an existing audit log. The audit record must contain only safe fields and must not be used as a secret-storage location.

### Client write ordering

For a lifecycle operation, the repository should:

1. Validate the transition locally.
2. Read or transact against the current request state.
3. Write the request update and status history using the documented atomic pattern where supported.
4. Write the audit record with safe values.
5. Re-read the request and show success only after the operation result is known.

Because there is no server-side logic, the project must document any unavoidable gap between a request update, history write, and audit write. The Rules still prevent later edits or deletion of records that were successfully written.

## Counter Protection and Request-Code Generation

### Required sequence

```text
[Customer confirms request]
        |
        v
[Begin Firestore transaction]
        |
        v
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

The repository must retry a transaction conflict using a new transaction attempt. It must not reuse a failed code or write a request outside the transaction. A failed write must not be shown as successful.

### Security boundary

The Rules restrict counter field shape and numeric increment. Without Cloud Functions, Rules cannot prove complete intent across all documents in a client transaction. This is a known limitation, not an authorization guarantee. The counter process must therefore be covered by integration tests and replaced or strengthened with trusted server-side allocation in production.

## Audit Logging Policy

### Required event names

| Event | When written | Required safe target |
|---|---|---|
| `LOGIN_SUCCESS` | Authentication and profile resolution succeed | User target ID may be the authenticated UID; no password or token |
| `REQUEST_CREATED` | Request creation succeeds | Request ID and request code may be recorded |
| `REQUEST_ASSIGNED` | Admin assignment succeeds | Request ID and assigned agent UID may be recorded if permitted |
| `REQUEST_UPDATED` | Permitted lifecycle or allowed request update succeeds | Request ID, old status, new status, and result |
| `AUTHORIZATION_FAILED` | A protected operation receives permission-denied or an equivalent authorization failure | Safe target type and ID; no Rules source or secret |
| `DATABASE_ERROR` | A non-authorization Firestore failure requires operational diagnosis | Error category and safe target metadata; no raw credential or token |

### Safe fields

Allowed audit values should be created through an allowlist serializer:

- Actor UID and role after they have been resolved by the authenticated session.
- Event name from the finalized event enum.
- Target type such as `request`, `user`, `service`, or `authentication`.
- Target document ID or a non-secret request code.
- Old and new status values.
- Result: `success`, `denied`, or `failure`.
- Timestamp.
- Non-sensitive operational reason or note with bounded length.

### Forbidden fields

Never store or log:

- Passwords.
- Firebase ID tokens, refresh tokens, OAuth tokens, session cookies, or authorization headers.
- API keys, private keys, service-account JSON, or secrets.
- Password-reset links or action codes.
- Full raw exception objects when they can contain credentials or request headers.
- Unnecessary private customer data.

### Client audit behavior

The client writes an audit record only after it knows which event occurred and which safe fields are available. If an audit write fails, the client must not expose the failure as a successful primary operation unless the product explicitly defines audit persistence as non-blocking. This decision must be consistent across repositories and tests.

For denial events, the client should attempt `AUTHORIZATION_FAILED` only with safe metadata. If the denial log itself is rejected, the user still receives a safe denial message and no retry loop is created solely for audit logging.

## Error Handling and Denial Behavior

### Safe user messages

| Internal condition | User-facing message pattern |
|---|---|
| `permission-denied` | “You are not authorized to perform this action.” |
| Unauthenticated | “Please sign in to continue.” |
| Missing profile | “Your account profile is not ready. Please retry or contact support.” |
| Invalid transition | “This request changed or cannot be moved to that status. Refresh and try again.” |
| Network failure | “Connection failed. Check your network and retry.” |
| Counter conflict | “The request number was busy. Please retry.” |
| Unknown database error | “The operation could not be completed. Please retry later.” |

Do not show raw Rules expressions, document paths containing sensitive information, authentication tokens, exception stacks, or secret configuration.

### Permission-denied mapping

The repository maps Firebase `permission-denied` to a typed authorization failure. The UI shows a safe message and returns to a valid prior screen or refreshes the current record. The audit layer may write `AUTHORIZATION_FAILED` using the safe-field policy.

### Failed writes

The UI must show a success state only after the Firestore operation returns successfully and the repository has enough information to confirm the resulting state. If a network interruption leaves the result unknown, the client should re-read before retrying. This prevents duplicate requests, duplicate status entries, and false completion messages.

## Secret and Credential Handling

### Source control

Never commit passwords, Firebase tokens, API keys, private keys, service-account JSON, `.env` secrets, or copied production credentials. Use safe Firebase configuration appropriate to the Flutter client and keep sensitive operator credentials outside the repository.

### Application code

Do not hard-code credentials. Do not print Authentication credential objects, ID tokens, HTTP authorization headers, or raw Firebase exception payloads. Crashlytics messages and custom keys must be reviewed for personally identifiable information and secrets before release.

### Local configuration

Use documented local configuration and Emulator Suite settings. Any developer-specific secret must remain in an ignored local file or an approved environment mechanism. A local configuration file is not safe merely because it is not visible in the UI; it must also be excluded from Git.

### Logging review

Before committing a repository change, inspect debug logging, audit builders, exception handlers, test fixtures, and seed data. Test fixtures must use fake values and must not resemble real credentials.

## Rules Test Matrix

Rules tests should run against the Firebase Emulator Suite with seeded `users`, `services`, `requests`, status histories, audit logs, and counters. Each test must verify the result of the Firestore operation, not merely a UI state.

| Test ID | Scenario | Actor | Target | Expected result | Requirement ID |
|---|---|---|---|---|---|
| TEST-07 | Customer reads another customer's request | Customer A | Request owned by Customer B | Deny | FR-C-12, TEST-07, NFR-01 |
| TEST-08 | Agent reads another agent's assigned request | Agent A | Request assigned to Agent B | Deny | FR-A-08, TEST-08, NFR-01 |
| TEST-09 | Customer attempts to change `users.role` to `admin` | Customer | Own `users/{uid}` profile | Deny | FR-AUTH-08, NFR-01 |
| TEST-10 | Unauthenticated user reads or writes protected data | Unauthenticated | `requests`, `users`, or `audit_logs` | Deny | FR-AUTH-08, NFR-01 |
|    | Customer creates a request with another customer ID | Customer A | New request | Deny | NFR-01 |
| TEST-12 | Agent updates a request not assigned to the agent | Agent A | Request assigned to Agent B | Deny | NFR-01 |
| TEST-13 | Agent skips `assigned` and writes `completed` | Agent | Assigned request | Deny | NFR-01 |
| TEST-14 | Customer cancels completed request | Customer | Own completed request | Deny | NFR-01 |
| TEST-15 | Existing status-history record is updated | Any signed-in user | Existing history document | Deny | NFR-01 |
| TEST-16 | Existing audit log is deleted | Admin | Existing audit document | Deny | NFR-01 |
| TEST-17 | Counter decreases or increments by more than one | Customer | `counters/{year}` | Deny | NFR-01 |
| TEST-18 | Customer creates request with invalid priority | Customer | New request | Deny | NFR-01 |
| TEST-19 | Customer creates request with status other than `created` | Customer | New request | Deny | NFR-01 |
| TEST-20 | Agent accepts assigned request from `assigned` | Assigned Agent | Assigned request | Allow | NFR-01 |
| TEST-21 | Admin assigns an eligible agent | Admin | Assignable request | Allow | NFR-01 |
| TEST-22 | Admin reads audit activity | Admin | `audit_logs` | Allow | LOG-05 |
| TEST-23 | Customer reads audit activity | Customer | `audit_logs` | Deny | LOG-05 |
| TEST-24 | Audit log contains an unsupported event | Signed-in role | New audit log | Deny | LOG-07, NFR-02 |
| TEST-25 | Audit log contains token or password in client serializer | Any client | Audit builder | Deny before write | NFR-02, LOG-07 |
| TEST-26 | Successful request write is incorrectly shown after failure | Customer | Request creation UI | No success; safe error | NFR-05 |

The exact test identifiers `TEST-07` through `TEST-10`, `FR-AUTH-08`, `NFR-01`, `NFR-02`, `LOG-05`, and `LOG-07` are required traceability anchors. Additional test identifiers above are implementation test cases and should be reconciled with the full Requirements Checklist if its numbering differs.

## Known Limitations of Client-Side Security

### Client-written audit and history records

Without Cloud Functions or another trusted backend, the client writes status history and audit records. Rules can restrict identity, role, field shape, event names, and append-only behavior, but they cannot fully prove that every client-written record is semantically paired with the intended request update.

### Client-written counter allocation

Rules can require a one-step counter increment, but they cannot fully verify that the increment is part of exactly one correctly formed request-creation transaction in every client scenario. A modified client may attempt to burn counter values. It cannot create an unauthorized request if request Rules reject it, but sequence integrity remains weaker than server-side allocation.

### Role provisioning

With no custom claims or server-side administrative workflow, the profile role is stored in Firestore and is read by Rules. Rules prevent ordinary self-promotion through the client path, but a trusted operator must control any out-of-band provisioning access. A compromised operator or overly permissive administrative tool remains a governance risk.

### Denial of service and abuse

Firestore Rules authorize requests but are not a complete abuse-prevention, rate-limiting, fraud-detection, or queue-management system. Spark-plan usage limits and client retry behavior must be monitored.

### Query and search limits

Cloud Firestore query capabilities may not provide arbitrary full-text search. The admin portal must use supported bounded filters and indexes rather than implying a search engine that does not exist in the finalized stack.

### Data validation limits

Rules validate types and enum values but do not replace application-level validation for address quality, phone formatting, duplicate submissions, or business-specific content moderation. Those validations belong in Dart repositories and tests, with Rules enforcing the security boundary.

## Production Recommendations

These recommendations preserve the current client architecture while moving high-trust operations to a backend when the project is no longer constrained to a 5–7 day Spark-plan assignment.

### Custom claims

Use a trusted administrative service to assign role claims for `customer`, `agent`, and `admin`. Keep Firestore `users.role` as a profile/display field if useful, but make the trusted claim or server-side authorization record the authoritative privilege source. The Flutter client can continue resolving the role through the same Riverpod authentication/profile layer.

### Cloud Functions or another trusted backend

Move request-code allocation, status transitions, status history, and audit creation into callable or HTTPS server-side operations. The client continues to call repository methods, but the repository delegates high-trust mutations to the backend.

The backend should:

- Validate the authenticated identity and role.
- Read the current request state transactionally.
- Apply an allowed transition.
- Generate the request code atomically.
- Write the request, history, and audit records together.
- Reject duplicate or stale mutations.
- Sanitize all logged fields.

### Server-side provisioning

Create an admin-only provisioning workflow outside the customer client. Require review for Agent/Admin role changes, record the operator, and prevent a client from changing its own privilege.

### Server-side validation and monitoring

Add structured validation, rate limits, abuse monitoring, secret scanning, audit retention, alerting, and centralized error monitoring. Keep the Flutter UI and route structure unchanged where possible so the migration is incremental rather than a full client rewrite.

### Rules migration

When the backend is introduced, keep deny-by-default Rules. Narrow direct client writes to records that do not require trusted mutation, and allow only the backend service account or controlled server path to perform high-trust writes. Re-run all Emulator Rules tests after each migration step.

## Threat Model Summary

| Threat | Impact | Mitigation |
|---|---|---|
| Unauthenticated Firestore access | Data disclosure or unauthorized writes | `isSignedIn()` checks and deny-by-default Rules |
| Customer reads another customer's request | Privacy breach | `isOwner(customerId)` on request reads and updates |
| Agent reads another agent's request | Operational data breach | `isAssigned(agentId)` on agent reads and updates |
| Self-promotion to admin | Privilege escalation | Self-profile creation forces `role == customer`; role immutable in client update |
| Client modifies immutable request fields | Data integrity loss | Explicit affected-field checks and `unchanged()` checks |
| Client skips lifecycle states | Incorrect operational state | `isValidTransition()` in Rules and client repository validation |
| History tampering | Loss of accountability | Status history update/delete denied |
| Audit tampering | Loss of security evidence | Audit update/delete denied and admin read-only access |
| Counter manipulation | Duplicate or burned request numbers | Narrow numeric increment rule, transaction contract, Emulator tests |
| Secret in logs or audit fields | Credential compromise | Safe-field allowlist, logging review, NFR-02, LOG-07 |
| Stale concurrent update | Incorrect status or duplicate action | Transactions, re-read before retry, Rules transition checks |
| Malicious or modified client | Bypass of UI restrictions | Database-layer Rules rather than UI-only authorization |
| Overly broad future collection | Unreviewed exposure | Recursive deny catch-all and required Rules change review |

## Open Questions and Assumptions

### Open questions

| ID | Question | Security impact | Default assumption |
|---|---|---|---|
| OQ-01 | Which exact statuses are customer-cancellable? | Controls cancellation Rules and UI actions. | `created` and `assigned` only, per PRD Assumption A-03. |
| OQ-02 | Can admins perform every lifecycle transition or only assignment and operational oversight? | Controls admin update branches. | Permit only transitions explicitly approved in the final RBAC matrix. |
| OQ-03 | Must audit writing block a primary operation when the audit write fails? | Controls consistency and user feedback. | Decide per repository; document and test the selected behavior. |
| OQ-04 | What controlled process provisions Agent/Admin profiles during the internship? | Controls development governance. | Use a trusted operator procedure; do not expose role promotion in the app. |
| OQ-05 | Are status notes visible to customers? | Controls history read projection and privacy. | Follow the PRD and final UI/security decision; do not expose notes by assumption. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | `users.role` is the role source for this assignment because custom claims are explicitly excluded. |
| ASSUMP-02 | The client writes audit logs and status history because Cloud Functions are explicitly excluded. |
| ASSUMP-03 | The initial request status is `created`, and no customer-created request has an assigned agent. |
| ASSUMP-04 | All timestamps use Firestore timestamps and are validated as timestamp values by Rules. |
| ASSUMP-05 | The application uses repository methods and Riverpod providers so UI code does not directly duplicate authorization logic. |
| ASSUMP-06 | The final Requirements Checklist defines any narrower admin transition permissions not fully specified in this prompt. |
| ASSUMP-07 | Audit old/new values are maps created by an allowlisted safe-field serializer. |
| ASSUMP-08 | Firebase Emulator Suite is the required local environment for Rules and integration testing. |

## Glossary

| Term | Definition |
|---|---|
| Agent | User with stored role value `agent`, using the Flutter mobile application to manage assigned work. |
| Admin | User with stored role value `admin`, using the Flutter Web admin portal for permitted operational management. |
| Audit log | Append-only record under `audit_logs` describing a safe operational or security event. |
| Authentication | Firebase email/password identity verification and session state. |
| Authorization | Decision about whether an authenticated identity may perform a specific Firestore operation. |
| Counter | Firestore document under `counters/{year}` used for request-number allocation. |
| Customer | User with stored role value `customer`, using the Flutter mobile application to create and track requests. |
| Defense in depth | Multiple independent controls rather than reliance on one UI or client check. |
| Firestore Rules | Declarative authorization and validation rules evaluated by Cloud Firestore. |
| Least privilege | Giving each role only the access required for its responsibilities. |
| Role routing | Selecting the application route based on the valid stored role in `users.role`. |
| Status history | Append-only request lifecycle record under `requests/{requestId}/status_history`. |
| Stored role | Lowercase role value stored in `users.role`: `customer`, `agent`, or `admin`. |
| Transition | A permitted change from one request status to another. |

## Appendix A — Full firestore.rules Clean Copy {.unnumbered}

```firebase
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- Authentication and role helpers ----------

    function isSignedIn() {
      return request.auth != null;
    }

    function userRole() {
      return isSignedIn()
        ? get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role
        : null;
    }

    function isCustomer() {
      return isSignedIn() && userRole() == 'customer';
    }

    function isAgent() {
      return isSignedIn() && userRole() == 'agent';
    }

    function isAdmin() {
      return isSignedIn() && userRole() == 'admin';
    }

    function isOwner(customerId) {
      return isSignedIn() && request.auth.uid == customerId;
    }

    function isAssigned(agentId) {
      return isSignedIn() && request.auth.uid == agentId;
    }

    function isValidRole(value) {
      return value in ['customer', 'agent', 'admin'];
    }

    function isValidStatus(value) {
      return value in [
        'created',
        'assigned',
        'accepted',
        'in_progress',
        'completed',
        'cancelled'
      ];
    }

    function isValidPriority(value) {
      return value in ['low', 'medium', 'high'];
    }

    function isValidTransition(from, to) {
      return (from == 'created' && to == 'assigned')
        || (from == 'assigned' && to == 'accepted')
        || (from == 'accepted' && to == 'in_progress')
        || (from == 'in_progress' && to == 'completed')
        || (from == 'created' && to == 'cancelled')
        || (from == 'assigned' && to == 'cancelled')
        || (from == 'accepted' && to == 'cancelled')
        || (from == 'in_progress' && to == 'cancelled');
    }

    function unchanged(field) {
      return request.resource.data[field] == resource.data[field];
    }

    function hasOnlyKeys(keys) {
      return request.resource.data.keys().hasOnly(keys);
    }

    function hasRequiredKeys(keys) {
      return request.resource.data.keys().hasAll(keys);
    }

    function hasValidTimestamp(field) {
      return request.resource.data[field] is timestamp;
    }

    function hasValidRequestCode() {
      return request.resource.data.requestCode.matches('REQ-[0-9]{4}-[0-9]{6}');
    }

    function isValidRequestBase() {
      return hasOnlyKeys([
          'requestCode',
          'customerId',
          'agentId',
          'serviceType',
          'description',
          'preferredDateTime',
          'address',
          'priority',
          'status',
          'createdAt',
          'updatedAt',
          'cancellationReason'
        ])
        && hasRequiredKeys([
          'requestCode',
          'customerId',
          'serviceType',
          'description',
          'preferredDateTime',
          'address',
          'priority',
          'status',
          'createdAt',
          'updatedAt'
        ])
        && request.resource.data.requestCode is string
        && hasValidRequestCode()
        && request.resource.data.customerId is string
        && request.resource.data.agentId == null
        && request.resource.data.serviceType is string
        && request.resource.data.description is string
        && request.resource.data.preferredDateTime is timestamp
        && request.resource.data.address is string
        && isValidPriority(request.resource.data.priority)
        && isValidStatus(request.resource.data.status)
        && hasValidTimestamp('createdAt')
        && hasValidTimestamp('updatedAt')
        && request.resource.data.cancellationReason == null;
    }

    function isValidProfileCreate() {
      return hasOnlyKeys([
          'role',
          'name',
          'email',
          'phone',
          'createdAt',
          'updatedAt'
        ])
        && hasRequiredKeys([
          'role',
          'name',
          'email',
          'phone',
          'createdAt',
          'updatedAt'
        ])
        && request.resource.data.role == 'customer'
        && request.resource.data.name is string
        && request.resource.data.email is string
        && request.resource.data.phone is string
        && hasValidTimestamp('createdAt')
        && hasValidTimestamp('updatedAt');
    }

    function isValidAuditAction() {
      return request.resource.data.action in [
        'LOGIN_SUCCESS',
        'REQUEST_CREATED',
        'REQUEST_ASSIGNED',
        'REQUEST_UPDATED',
        'AUTHORIZATION_FAILED',
        'DATABASE_ERROR'
      ];
    }

    // ---------- User profiles ----------

    match /users/{uid} {
      allow read: if isSignedIn() && (
        request.auth.uid == uid || isAdmin()
      );

      allow create: if isSignedIn()
        && request.auth.uid == uid
        && isValidProfileCreate();

      allow update: if isSignedIn()
        && request.auth.uid == uid
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'name',
          'phone',
          'updatedAt'
        ])
        && unchanged('role')
        && unchanged('email')
        && unchanged('createdAt')
        && request.resource.data.name is string
        && request.resource.data.phone is string
        && hasValidTimestamp('updatedAt');

      allow delete: if false;
    }

    // ---------- Services ----------

    match /services/{serviceId} {
      allow read: if isSignedIn();

      allow create: if isAdmin()
        && request.resource.data.keys().hasOnly([
          'name',
          'description',
          'active',
          'createdAt'
        ])
        && request.resource.data.name is string
        && request.resource.data.description is string
        && request.resource.data.active is bool
        && request.resource.data.createdAt is timestamp;

      allow update: if isAdmin()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'name',
          'description',
          'active'
        ])
        && request.resource.data.name is string
        && request.resource.data.description is string
        && request.resource.data.active is bool
        && unchanged('createdAt');

      allow delete: if false;
    }

    // ---------- Requests ----------

    match /requests/{requestId} {
      allow read: if isSignedIn() && (
        isOwner(resource.data.customerId)
        || isAssigned(resource.data.agentId)
        || isAdmin()
      );

      allow create: if isCustomer()
        && request.resource.data.customerId == request.auth.uid
        && isValidRequestBase()
        && request.resource.data.status == 'created';

      allow update: if isSignedIn() && (
        // Customer cancellation of an eligible own request.
        (
          isCustomer()
          && isOwner(resource.data.customerId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'status',
            'updatedAt',
            'cancellationReason'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('agentId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && request.resource.data.status == 'cancelled'
          && isValidTransition(resource.data.status, 'cancelled')
          && resource.data.status in ['created', 'assigned']
          && request.resource.data.cancellationReason is string
          && hasValidTimestamp('updatedAt')
        )
        ||
        // Assigned agent status updates.
        (
          isAgent()
          && isAssigned(resource.data.agentId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'status',
            'updatedAt'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('agentId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && isValidTransition(resource.data.status, request.resource.data.status)
          && request.resource.data.status in [
            'accepted',
            'in_progress',
            'completed'
          ]
          && hasValidTimestamp('updatedAt')
        )
        ||
        // Admin assignment and explicitly permitted status updates.
        (
          isAdmin()
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'agentId',
            'status',
            'updatedAt',
            'cancellationReason'
          ])
          && unchanged('requestCode')
          && unchanged('customerId')
          && unchanged('serviceType')
          && unchanged('description')
          && unchanged('preferredDateTime')
          && unchanged('address')
          && unchanged('priority')
          && unchanged('createdAt')
          && isValidStatus(request.resource.data.status)
          && isValidTransition(resource.data.status, request.resource.data.status)
          && (
            request.resource.data.status != 'assigned'
            || request.resource.data.agentId is string
          )
          && (
            request.resource.data.status != 'cancelled'
            || request.resource.data.cancellationReason is string
          )
          && hasValidTimestamp('updatedAt')
        )
      );

      allow delete: if false;

      match /status_history/{historyId} {
        allow read: if isSignedIn() && (
          isAdmin()
          || isOwner(get(/databases/$(database)/documents/requests/$(requestId)).data.customerId)
          || isAssigned(get(/databases/$(database)/documents/requests/$(requestId)).data.agentId)
        );

        allow create: if isSignedIn()
          && request.resource.data.keys().hasOnly([
            'fromStatus',
            'toStatus',
            'changedBy',
            'changedAt',
            'note'
          ])
          && request.resource.data.changedBy == request.auth.uid
          && request.resource.data.changedAt is timestamp
          && request.resource.data.toStatus is string
          && isValidStatus(request.resource.data.toStatus)
          && (
            request.resource.data.fromStatus == null
            || isValidStatus(request.resource.data.fromStatus)
          )
          && (
            request.resource.data.fromStatus == null
            || isValidTransition(
              request.resource.data.fromStatus,
              request.resource.data.toStatus
            )
            || request.resource.data.fromStatus == request.resource.data.toStatus
          )
          && request.resource.data.note is string
          && (
            isAdmin()
            || isOwner(get(/databases/$(database)/documents/requests/$(requestId)).data.customerId)
            || isAssigned(get(/databases/$(database)/documents/requests/$(requestId)).data.agentId)
          );

        allow update: if false;
        allow delete: if false;
      }
    }

    // ---------- Audit logs ----------

    match /audit_logs/{logId} {
      allow read: if isAdmin();

      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly([
          'actorUserId',
          'actorRole',
          'action',
          'targetType',
          'targetId',
          'oldValue',
          'newValue',
          'result',
          'timestamp'
        ])
        && request.resource.data.actorUserId == request.auth.uid
        && request.resource.data.actorRole == userRole()
        && isValidRole(request.resource.data.actorRole)
        && isValidAuditAction()
        && request.resource.data.targetType is string
        && request.resource.data.targetId is string
        && request.resource.data.result in ['success', 'denied', 'failure']
        && request.resource.data.timestamp is timestamp
        && request.resource.data.oldValue is map
        && request.resource.data.newValue is map;

      allow update: if false;
      allow delete: if false;
    }

    // ---------- Request counters ----------

    match /counters/{year} {
      allow read: if false;

      // The client may increment only by one. Pairing this update with the
      // request creation transaction is required by the repository contract.
      // Rules cannot prove every cross-document transaction intent, so this
      // is supplemented by client code and Emulator integration tests.
      allow update: if isCustomer()
        && request.resource.data.keys().hasOnly(['lastRequestNumber'])
        && resource.data.keys().hasOnly(['lastRequestNumber'])
        && resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber == resource.data.lastRequestNumber + 1;

      allow create: if isAdmin()
        && request.resource.data.keys().hasOnly(['lastRequestNumber'])
        && request.resource.data.lastRequestNumber is int
        && request.resource.data.lastRequestNumber >= 0;

      allow delete: if false;
    }

    // ---------- Deny every unspecified collection or document ----------

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Appendix B — Required Events and Safe Fields {.unnumbered}

### Required events

| Event | Allowed meaning | Safe target examples |
|---|---|---|
| `LOGIN_SUCCESS` | Firebase authentication and profile resolution succeeded | `authentication`, `user` |
| `REQUEST_CREATED` | A new request was successfully created | `request` |
| `REQUEST_ASSIGNED` | An eligible request was assigned to an agent | `request` |
| `REQUEST_UPDATED` | A permitted request lifecycle or field update succeeded | `request` |
| `AUTHORIZATION_FAILED` | A protected action was denied | `request`, `user`, `service`, `authentication` |
| `DATABASE_ERROR` | A non-authorization database failure was handled | `request`, `user`, `service`, `database` |

### Safe-field allowlist

| Field category | Allowed examples | Forbidden examples |
|---|---|---|
| Actor | Authenticated UID, stored role | Password, token, credential object |
| Target | Collection type, document ID, request code | Authorization header, session cookie |
| Change | Old/new status, assignment UID where permitted | Raw request payload containing secrets |
| Result | `success`, `denied`, `failure` | Raw stack trace or secret-bearing exception |
| Timestamp | Firestore timestamp | Password reset token timestamp payload |
| Reason | Bounded operational reason | API key, private key, secret configuration |

### Serialization requirements

The client must build `oldValue` and `newValue` with an allowlist rather than serializing an entire Dart model or exception object. Before a write, the serializer must reject forbidden key names and omit fields that are not needed for the event.

## Appendix C — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document — this document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes.
9. Testing Plan.
10. README / Setup & Deployment Documentation.
