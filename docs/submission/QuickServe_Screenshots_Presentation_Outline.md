# QuickServe Screenshots and Presentation Outline

## 1. Presentation structure

### Slide 1 — Title

**QuickServe: Service Request Management Application**

Subtitle: Swasiq Technology Internship Program

Include:

- Project name
- Your name/team
- Technology summary: Flutter, Firebase Auth, Firestore
- One clean Admin dashboard or mobile home screenshot

### Slide 2 — Problem and users

Explain the operational problem:

- Customers need a simple way to request and track services.
- Agents need assignment-scoped work management.
- Administrators need operational visibility and controlled status updates.

Show a three-role diagram:

```text
Customer → Service Request → Agent → Completion
                         ↘ Admin oversight
```

### Slide 3 — Solution overview

Show the two-client architecture:

- Flutter mobile: Customer and Agent experiences.
- Flutter Web: Admin operations portal.
- Firebase Authentication and Firestore.
- Firestore Rules and shared lifecycle logic.

### Slide 4 — Customer journey

Recommended screenshots:

1. Login or registration screen.
2. Service catalog.
3. Create Request form.
4. Request details showing generated request code and `created` status.

Caption: “Customers create and track only their own service requests.”

### Slide 5 — Agent workflow

Recommended screenshots:

1. Agent request queue.
2. Assigned request details.
3. Accepted/in-progress state.
4. Completion note or completed request.

Caption: “Agents can progress only requests assigned to them.”

### Slide 6 — Admin dashboard

Recommended screenshots:

1. Admin login screen.
2. Dashboard status cards.
3. Navigation rail showing Dashboard, Requests, Users, and Activity.

Caption: “Administrators receive an operational view across the request lifecycle.”

### Slide 7 — Admin request management

Recommended screenshots:

1. Requests table/list.
2. Search field with populated text and clear `X` control.
3. Status filter.
4. Request detail dialog before assignment.
5. Assignment control for a `created` request.

Caption: “Assignment is available only while a request is in the assignable `created` state.”

### Slide 8 — Auditability and security

Recommended screenshots:

1. Firestore `status_history` records.
2. Firestore `audit_logs` records.
3. Admin Activity view.
4. Access-denied screen for a non-Admin account.

Caption: “Every operational transition leaves a safe, append-only history and audit trail.”

### Slide 9 — Architecture and data model

Show a simplified diagram:

```text
Flutter Mobile ─┐
                ├─ Firebase Auth
Flutter Web ────┤
                └─ Firestore + Security Rules
                         ├─ users
                         ├─ services
                         ├─ requests
                         ├─ status_history
                         ├─ audit_logs
                         └─ counters
```

Mention shared Dart models, validators, constants, and lifecycle transitions.

### Slide 10 — Quality and delivery

Include verified evidence:

- Mobile: 30 tests passed.
- Admin: tests passed and analysis clean.
- Shared: formatting and analysis clean; run shared tests with `flutter test`.
- Firebase Emulator Suite supports reproducible local testing.
- No paid Firebase services or committed secrets.
- Git commit history and clean working tree.

### Slide 11 — Demo and next steps

Show the final lifecycle:

```text
created → assigned → accepted → in_progress → completed
```

Close with:

- Current delivered scope.
- Known deployment boundary: authorized Firebase project required for hosted use.
- Optional future work: pagination, richer filters, automated Rules integration tests, and production monitoring.

## 2. Screenshot capture checklist

Before capture:

- Use only synthetic emulator data.
- Do not show passwords, tokens, reset links, or browser developer tools.
- Hide unrelated tabs and personal information.
- Use a consistent browser viewport for Admin screenshots.
- Wait for loading indicators to finish.
- Prefer screenshots that show the page title and enough context to identify the workflow.

Capture these minimum images:

- `01_customer_login.png`
- `02_service_catalog.png`
- `03_create_request.png`
- `04_customer_request_details.png`
- `05_agent_queue.png`
- `06_agent_in_progress.png`
- `07_admin_login.png`
- `08_admin_dashboard.png`
- `09_admin_requests_search_clear.png`
- `10_admin_request_assignment.png`
- `11_admin_activity_audit.png`
- `12_admin_access_denied.png`

## 3. Suggested captions

- “Customer request created with a transactional public request code.”
- “Agent queue is limited to assigned work.”
- “Admin dashboard summarizes the current lifecycle state distribution.”
- “The search clear control resets the request list without a page reload.”
- “Assignment is guarded by lifecycle state and Firestore authorization.”
- “Status history and audit logs provide operational traceability.”
- “Non-Admin users cannot enter the Admin workflow.”
