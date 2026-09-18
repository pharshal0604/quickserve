# QuickServe Emulator Quickstart

## Prerequisites

Install the following tools:

- Flutter SDK, with the version required by the repository.
- Node.js LTS and npm.
- Firebase CLI.

Verify the tools from the repository root in Windows `cmd.exe`:

```cmd
flutter --version
node --version
npm --version
firebase --version
```

This guide uses the synthetic values defined in `docs/Emulator_Seed_Data.md`.

## Install Seed Dependencies

From the repository root, install the only seed dependency:

```cmd
cd tools\seed
npm install
cd ..\..
```

## Start the Emulators

From the repository root:

```cmd
firebase emulators:start --only auth,firestore
```

The expected ports are Authentication `9099`, Firestore `8080`, and Emulator UI `4000`.

## Open the Emulator UI

Open this URL in a browser:

```text
http://127.0.0.1:4000
```

## Seed the Emulator

Keep the emulators running. Open a second `cmd.exe` window at the repository root and set the emulator endpoints:

```cmd
set "FIRESTORE_EMULATOR_HOST=127.0.0.1:8080"
set "FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099"
```

The seed script uses a local-only password from `SEED_PASSWORD`. If it is not set, the script uses its documented local fallback. To override it for the current terminal session, set it before running the script:

```cmd
set "SEED_PASSWORD=<local-only-password>"
```

Run the seed script from the repository root:

```cmd
node tools\seed\seed.js
```

The script is idempotent and can be run again to restore the same synthetic records.

## What Gets Seeded

| Entity | Count | Details |
|---|---:|---|
| Authentication users | 5 | Two customers, two agents, and one admin |
| `users` profiles | 5 | Matching synthetic role profiles |
| `services` | 5 | Four active services and one inactive service |
| `requests` | 7 | All lifecycle states plus an additional assigned request |
| Status history | Per request | One record for every state entered |
| `audit_logs` | 6 | At least one record for every fixed event |
| `counters/2026` | 1 | `lastRequestNumber` set to `7` |

Exact UIDs, names, `.test` emails, phone values, request codes, and request records are defined in `docs/Emulator_Seed_Data.md`.

## Reset the Emulator

Stop the emulator process with `Ctrl+C` in its terminal. Start it again without an import directory:

```cmd
firebase emulators:start --only auth,firestore
```

Run the seed script again from a second terminal if synthetic records are needed:

```cmd
set "FIRESTORE_EMULATOR_HOST=127.0.0.1:8080"
set "FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099"
node tools\seed\seed.js
```

If a local emulator export was created separately, remove that local export before restarting when a clean state is required. Do not commit local emulator exports.

## Troubleshooting

### Port conflicts

The expected ports are `9099` for Authentication, `8080` for Firestore, and `4000` for the Emulator UI. Stop the process using the port or use the repository's existing Firebase configuration. Keep the environment variables aligned with the ports actually running.

### Emulator already running

Do not start a second emulator process on the same ports. Use the existing Emulator UI and run the seed script from a separate terminal with the emulator environment variables set.

### Seed script reports a missing emulator endpoint

Set both variables in the same terminal used to run the script:

```cmd
set "FIRESTORE_EMULATOR_HOST=127.0.0.1:8080"
set "FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099"
```

### Seed script reports connection refused

Confirm that Authentication and Firestore emulators are running, then confirm the configured ports match `firebase.json`.

### Seed script reports an existing user conflict

The script expects each synthetic email to belong to its documented UID. Reset the emulator and run the seed again, or remove only the conflicting local emulator account through the Emulator UI.

### Seed script reports a permission or write failure

Confirm that the script is pointed at the emulators rather than a hosted project and that the dependency installation completed inside `tools\seed`.

## Safety Notes

- All seed data is synthetic and uses `.test` email addresses.
- Passwords are local-only and are supplied through `SEED_PASSWORD`; never commit them.
- Do not place tokens, API keys, service-account files, or private credentials in the repository.
- The seed script connects only to the local Authentication and Firestore emulators through the required environment variables.
- Do not use the seed data or seed password for hosted data.
- Keep local emulator exports and debug logs out of source control.
