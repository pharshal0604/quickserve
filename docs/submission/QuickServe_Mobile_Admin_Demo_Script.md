# QuickServe Mobile and Admin Demo Script

Recommended duration: 8–12 minutes.

## 1. Prepare the demo

From the repository root, start the emulators:

```powershell
firebase emulators:start --only auth,firestore
```

In a second terminal, seed synthetic data:

```powershell
$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
$env:SEED_PASSWORD = "Admin123!"
node tools\seed\seed.js
```

Use the local synthetic accounts:

```text
Customer: customer1@example.test
Agent:    agent1@example.test
Admin:    admin@example.test
Password: Admin123!
```

Do not present these as production credentials.

## 2. Customer mobile demonstration

1. Launch the mobile app in emulator mode.
2. Sign in as `customer1@example.test`.
3. Show the Customer home screen and active service catalog.
4. Create a request with:
   - Service: AC servicing
   - Description: Synthetic demonstration request
   - Preferred date/time
   - Address: Synthetic address
   - Priority: medium
5. Show the generated request code in `REQ-YYYY-000123` format.
6. Open request details and show the initial `created` status.
7. Explain that Customer access is limited to owned requests.
8. Optionally demonstrate eligible cancellation with a reason.

## 3. Admin login and dashboard

1. Launch the Admin portal in Chrome with:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_USE_EMULATORS=true `
  --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

2. Sign in as `admin@example.test`.
3. Show the Dashboard navigation and status-count cards.
4. Point out Dashboard, Requests, Users, and Activity sections.

## 4. Admin request operations

1. Open Requests.
2. Search for `REQ-` or a service name.
3. Enter a search term and show the clear `X` control.
4. Click `X` and show that the complete request list returns.
5. Open a request currently in `created`.
6. Assign `agent1@example.test`.
7. Save and confirm the request becomes `assigned`.
8. Open Activity and show `REQUEST_ASSIGNED`.
9. Open the request history and show the status transition.
10. Reopen the request and show that reassignment is disabled after leaving `created`.

## 5. Agent lifecycle demonstration

1. Launch or switch to the mobile Agent experience.
2. Sign in as `agent1@example.test`.
3. Open the assigned request.
4. Accept it: `assigned → accepted`.
5. Start work: `accepted → in_progress`.
6. Complete work with a note: `in_progress → completed`.
7. Show the updated status history.
8. Return to Admin Activity and show the corresponding update events.

## 6. Security demonstration

1. Attempt to open the Admin portal as a Customer account.
2. Show the administrator-access-denied result.
3. Explain that UI routing is not the only protection: Firestore Rules enforce role, ownership, assignment, and lifecycle boundaries.
4. Show that completed and cancelled requests are terminal.

## 7. Closing statement

QuickServe demonstrates an end-to-end service-request workflow with role-based mobile and web experiences, Firebase-backed persistence, transaction-aware lifecycle updates, append-only history and audit records, and local emulator reproducibility without paid Firebase services.

## Demo recovery notes

- If a request is already in progress, do not try to reassign it; use it for completion testing.
- Use `request-doc-001` for a clean assignment demonstration after reseeding.
- If a seeded password is uncertain, reset the Auth Emulator accounts and reseed with an explicit local password.
- Never paste tokens, reset links, or service-account credentials into the demo.
