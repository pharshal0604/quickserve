# QuickServe Emulator Seed Data

This document specifies the synthetic data used with the Firebase Emulator Suite during local development and testing. It is a companion to Section 12 of `QuickServe_Database_Design.md`.

**No real credentials, personal data, or secrets are used here.** All values are synthetic and safe to commit as reference.

---

## 1. Purpose

The seed data must:

- Let a developer log in as each role without needing to know any real password.
- Cover every lifecycle state so every UI branch and Firestore Rules path can be exercised.
- Provide representative service, request, history, audit, and counter records.
- Be reproducible — any developer with the repo and Firebase CLI installed can load it.
- Stay safe — no production values, no real names, no real emails, no real phone numbers.

---

## 2. Starting the Emulator

From the repository root:

```cmd
firebase emulators:start --only auth,firestore
```

The Emulator UI opens at:

```
http://127.0.0.1:4000
```

Stop it with `Ctrl+C` in the same terminal.

---

## 3. Synthetic Users

Users are created in the Authentication Emulator and mirrored in the Firestore `users` collection with a stored role.

| UID | Stored role | Display name | Email | Purpose |
|---|---|---|---|---|
| `customer-uid-001` | `customer` | Aarav Sharma | `customer1@example.test` | Own-request and cross-customer tests |
| `customer-uid-002` | `customer` | Diya Patil | `customer2@example.test` | Cross-customer denial target |
| `agent-uid-001` | `agent` | Rohan Deshmukh | `agent1@example.test` | Assigned-request workflow |
| `agent-uid-002` | `agent` | Meera Joshi | `agent2@example.test` | Cross-agent denial target |
| `admin-uid-001` | `admin` | Operations Admin | `admin@example.test` | Admin dashboard and operational workflow |

### Password policy for seed users

- Passwords are supplied through the Authentication Emulator when the accounts are created.
- Passwords are **never committed to the repo**.
- Each developer chooses their own local password when seeding.
- Suggested local password pattern (do not commit): `TestSeed-<uid>-2026!` — used only on your machine.

### Matching `users/{uid}` documents

For each seeded UID above, create a document at `users/{uid}`:

```json
{
  "role": "customer",
  "name": "Aarav Sharma",
  "email": "customer1@example.test",
  "phone": "+91-9000000001",
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>"
}
```

Change `role`, `name`, `email`, and `phone` per row in the table.

Valid stored roles are exactly:

- `customer`
- `agent`
- `admin`

---

## 4. Synthetic Services

Create these four documents under `services/{serviceId}`.

| Document ID | `name` | `description` | `active` |
|---|---|---|---|
| `ac_servicing` | AC servicing | Inspection, cleaning, and maintenance of AC units. | `true` |
| `plumbing` | Plumbing | Leak repair, pipe fitting, and general plumbing work. | `true` |
| `electrical` | Electrical | Wiring, switchboard, and general electrical work. | `true` |
| `cleaning` | Cleaning | Deep cleaning for rooms, kitchens, and bathrooms. | `true` |

Each document also has:

```json
{
  "createdAt": "<Firestore Timestamp>"
}
```

Optionally seed one inactive record for UI testing:

| Document ID | `name` | `active` |
|---|---|---|
| `inactive_service` | Archived Service (do not select) | `false` |

---

## 5. Synthetic Requests

Create these documents under `requests/{requestId}`. Each begins with `status: created`, then is moved through its lifecycle by the seed script (or manually via the Emulator UI).

| Document ID | `requestCode` | `customerId` | `agentId` | `serviceType` | `status` | `priority` |
|---|---|---|---|---|---|---|
| `request-doc-001` | `REQ-2026-000001` | `customer-uid-001` | `null` | AC servicing | `created` | `medium` |
| `request-doc-002` | `REQ-2026-000002` | `customer-uid-001` | `agent-uid-001` | Plumbing | `assigned` | `high` |
| `request-doc-003` | `REQ-2026-000003` | `customer-uid-001` | `agent-uid-001` | Electrical | `accepted` | `low` |
| `request-doc-004` | `REQ-2026-000004` | `customer-uid-001` | `agent-uid-001` | Cleaning | `in_progress` | `medium` |
| `request-doc-005` | `REQ-2026-000005` | `customer-uid-001` | `agent-uid-001` | AC servicing | `completed` | `high` |
| `request-doc-006` | `REQ-2026-000006` | `customer-uid-002` | `null` | Plumbing | `cancelled` | `low` |
| `request-doc-007` | `REQ-2026-000007` | `customer-uid-002` | `agent-uid-002` | Electrical | `assigned` | `medium` |

Each request document also has:

```json
{
  "description": "Synthetic description for testing.",
  "preferredDateTime": "<Firestore Timestamp>",
  "address": "Synthetic address for testing.",
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>",
  "cancellationReason": null
}
```

For `request-doc-006` (the cancelled request) set:

```json
{
  "cancellationReason": "Synthetic cancellation reason."
}
```

The request codes follow the `REQ-YYYY-000123` format. When the counter is seeded (Section 7), new requests created by the app will continue numbering from there.

---

## 6. Synthetic Status History

For every request, create one history record per state the request passed through. History is **append-only** — no updates, no deletes.

Example — `request-doc-004` (currently `in_progress`):

```
requests/request-doc-004/status_history/history-0001
  fromStatus: null
  toStatus: created
  changedBy: customer-uid-001
  changedAt: <Timestamp>
  note: "Request created."

requests/request-doc-004/status_history/history-0002
  fromStatus: created
  toStatus: assigned
  changedBy: admin-uid-001
  changedAt: <Timestamp>
  note: "Assigned to agent."

requests/request-doc-004/status_history/history-0003
  fromStatus: assigned
  toStatus: accepted
  changedBy: agent-uid-001
  changedAt: <Timestamp>
  note: "Agent accepted request."

requests/request-doc-004/status_history/history-0004
  fromStatus: accepted
  toStatus: in_progress
  changedBy: agent-uid-001
  changedAt: <Timestamp>
  note: "Work started."
```

Every request must have a history entry for each state it has entered.

---

## 7. Synthetic Audit Logs

Create documents under `audit_logs/{logId}`. Only these six event names are allowed:

- `LOGIN_SUCCESS`
- `REQUEST_CREATED`
- `REQUEST_ASSIGNED`
- `REQUEST_UPDATED`
- `AUTHORIZATION_FAILED`
- `DATABASE_ERROR`

Example document:

```json
{
  "actorUserId": "admin-uid-001",
  "actorRole": "admin",
  "action": "REQUEST_ASSIGNED",
  "targetType": "request",
  "targetId": "request-doc-002",
  "oldValue": { "status": "created", "agentId": null },
  "newValue": { "status": "assigned", "agentId": "agent-uid-001" },
  "result": "success",
  "timestamp": "<Firestore Timestamp>"
}
```

Seed at least:

- One `LOGIN_SUCCESS` for each role.
- One `REQUEST_CREATED` for every request.
- One `REQUEST_ASSIGNED` for every assigned request.
- One `REQUEST_UPDATED` for every subsequent transition.
- One `AUTHORIZATION_FAILED` for a synthetic denial (optional but useful).
- One `DATABASE_ERROR` for a synthetic failure (optional).

Never include passwords, tokens, API keys, or secrets in any audit record.

---

## 8. Synthetic Counter

Create:

```
counters/2026
  lastRequestNumber: 7
```

This corresponds to the highest existing request code (`REQ-2026-000007`). New requests created by the app will increment to `REQ-2026-000008`.

If you seed a different year, adjust both the counter document ID and the request codes accordingly.

---

## 9. Loading the Seed Data

You can load the seed data in one of three ways.

### 9.1 Manual through the Emulator UI

1. Start the emulators.
2. Open `http://127.0.0.1:4000`.
3. Under **Authentication**, create the five synthetic user accounts with their synthetic emails and local passwords.
4. Under **Firestore**, create every document described in this file.
5. Set timestamps to any valid Firestore timestamp value (use the current time).

This is the slowest approach but requires no scripting.

### 9.2 Manual import file (recommended for Phase 4)

Firebase Emulator Suite supports importing an export directory:

```cmd
firebase emulators:start --only auth,firestore --import=./firebase-seed-data --export-on-exit
```

The `firebase-seed-data/` directory is **not committed**. It is generated locally by exporting the emulator after seeding manually once. Every developer can then reuse their own local export.

### 9.3 Scripted (later phase)

A small Dart or Node seed script can populate the emulator automatically. This is planned for Phase 4 or later. When implemented, the script will live inside `tools/seed/` and be invoked from the repo root. The script will not commit any passwords.

---

## 10. Cleanup

To reset the emulator to a clean state:

1. Stop the emulators.
2. Delete the local export directory (e.g., `firebase-seed-data/`).
3. Start the emulators again with no `--import` flag.

To preserve state between runs, use `--export-on-exit`.

Never commit the local export directory. It is already excluded by `.gitignore` via the `.firebase/` and `firebase-debug.log` entries.

---

## 11. Safety Checklist

Before committing anything related to seed data, confirm:

- [ ] No real passwords are committed.
- [ ] No real email addresses are committed (all use `.test`).
- [ ] No real names or phone numbers are committed.
- [ ] No tokens, API keys, or service-account JSON are committed.
- [ ] No local emulator export directory is committed.
- [ ] All seeded roles are exactly `customer`, `agent`, or `admin`.
- [ ] All seeded statuses are exactly `created`, `assigned`, `accepted`, `in_progress`, `completed`, or `cancelled`.
- [ ] All seeded priorities are exactly `low`, `medium`, or `high`.
- [ ] All seeded events are from the fixed event list.
- [ ] Request codes match `REQ-YYYY-000123`.

---

## 12. Summary

- The seed data covers all three roles, all six statuses, and the four baseline services.
- Emails use `.test` and are safe to publish.
- Passwords live only in the local Emulator.
- Status history and audit logs are append-only and safe.
- The counter picks up where the highest seeded request code ends.
- Nothing in this plan commits a secret.
