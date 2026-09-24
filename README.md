# QuickServe Assignment Submission

**Candidate:** Harshal Pidurkar
**Submission For:** Founding Engineering Internship at Swasiq

## Deliverables Quick Links
- **[Setup & Run Instructions](#setup)**
- **[Architecture & Security Documentation](docs/QuickServe_System_Architecture.md)**
- **[RBAC & Firestore Rules Documentation](docs/QuickServe_RBAC_Security.md)**
- **[Complete Documentation Directory](docs/)**

---
# QuickServe

A production-oriented home-service platform built with **Flutter**, **Firebase**, and **Riverpod**.

> **Customer App** · **Agent App** · **Admin Portal**

[Screenshots](#screenshots) · [Architecture](#architecture) · [Features](#features) · [Setup](#setup)

---

```
┌─────────────────────────────────────────────────┐
│                   QUICKSERVE                    │
│                                                 │
│   Customer  →  Browse · Request · Track         │
│        ↓                                        │
│   Agent     →  Accept · Work · Complete         │
│        ↓                                        │
│   Admin     →  Manage · Monitor · Configure     │
│                                                 │
│   Flutter + Riverpod + GoRouter + Firebase      │
└─────────────────────────────────────────────────┘
```

---

## Project Overview

QuickServe is a multi-role service request management system designed for home-service businesses. It connects **Customers** who need services (AC repair, plumbing, electrical work, etc.) with **Agents** who perform the work, supervised by **Admins** who manage operations.

The system is built as a **Flutter monorepo** with a shared Dart package, and uses **Firebase** for authentication, real-time database, push notifications, and security rules.

### User Roles

| Role | Description |
|------|-------------|
| **Customer** | Creates service requests, tracks progress, receives real-time updates |
| **Agent** | Receives assignments, accepts/starts/completes work, views history |
| **Admin** | Manages agents, services, customers, and monitors all requests |

---

## Screenshots

### Customer App
<p align="center">
  <img src="screenshots/customer/Splash.jpeg" width="22%" alt="Splash Screen" />
  <img src="screenshots/customer/login.jpeg" width="22%" alt="Login" />
  <img src="screenshots/customer/resgiter.jpeg" width="22%" alt="Register" />
  <img src="screenshots/customer/Customer_HomeScreen.jpeg" width="22%" alt="Customer Home" />
</p>
<p align="center">
  <img src="screenshots/customer/Customer_Services.jpeg" width="22%" alt="Services" />
  <img src="screenshots/customer/CreateRequest_Step1.jpeg" width="22%" alt="Create Request Step 1" />
  <img src="screenshots/customer/CreateRequest_Step2.jpeg" width="22%" alt="Create Request Step 2" />
  <img src="screenshots/customer/CreateRequest_Step3.jpeg" width="22%" alt="Create Request Step 3" />
</p>
<p align="center">
  <img src="screenshots/customer/Cutomer_requestScreen.jpeg" width="22%" alt="My Requests" />
  <img src="screenshots/customer/TrackRequest_Screen.jpeg" width="22%" alt="Track Request" />
</p>

### Agent App
<p align="center">
  <img src="screenshots/agent/Agnet_HomeScreen.jpeg" width="22%" alt="Agent Home" />
  <img src="screenshots/agent/Agent_AssignedTaskScreen.jpeg" width="22%" alt="Assigned Tasks" />
  <img src="screenshots/agent/Agent_RequestDetail.jpeg" width="22%" alt="Request Details" />
  <img src="screenshots/agent/Agent_SettingScreen.jpeg" width="22%" alt="Settings" />
</p>

### Admin Portal
<p align="center">
  <img src="screenshots/admin/DashBoard.png" width="48%" alt="Dashboard" />
  <img src="screenshots/admin/RequestScreen.png" width="48%" alt="Requests" />
</p>
<p align="center">
  <img src="screenshots/admin/RequestDetailedScreen.png" width="48%" alt="Request Details" />
  <img src="screenshots/admin/AgentScreen.png" width="48%" alt="Agents" />
</p>
<p align="center">
  <img src="screenshots/admin/CustomerScreen.png" width="48%" alt="Customers" />
  <img src="screenshots/admin/ServicesScreen.png" width="48%" alt="Services" />
</p>
<p align="center">
  <img src="screenshots/admin/Audit_ActivityScreen.png" width="48%" alt="Audit Logs" />
</p>

---

## Features

### Feature Matrix

| Feature | Customer | Agent | Admin |
|---|:---:|:---:|:---:|
| Email + Google Authentication | ✅ | ✅ | ✅ |
| Service browsing | ✅ | — | ✅ |
| Create service request | ✅ | — | ✅ |
| Real-time request tracking | ✅ | ✅ | ✅ |
| Cancel request | ✅ | — | ✅ |
| Accept assigned request | — | ✅ | ✅ |
| Start / Complete work | — | ✅ | ✅ |
| Request history | ✅ | ✅ | ✅ |
| Push notifications (FCM) | ✅ | ✅ | ✅ |
| Profile management | ✅ | ✅ | ✅ |
| Agent management | — | — | ✅ |
| Service management | — | — | ✅ |
| Customer management | — | — | ✅ |
| Dashboard analytics | — | ✅ | ✅ |
| Dark mode | ✅ | ✅ | — |
| Audit logging | — | — | ✅ |

### Key Technical Features

- **Atomic Firestore Transactions** — Request status transitions, counter increments, audit logs, and status history are all written in a single Firestore transaction. No partial writes.
- **Request Lifecycle State Machine** — Strict server-side and client-side validation of status transitions (`created → assigned → accepted → in_progress → completed`). Invalid transitions are rejected at both the code layer and Firestore Security Rules.
- **Yearly Request Codes** — Auto-incrementing human-readable codes (e.g., `REQ-2026-0001`) generated atomically via a Firestore counter document.
- **Real-time Streams** — All request lists and details use Firestore `snapshots()` streams. When an Agent accepts a request, the Customer's UI updates instantly.
- **Push Notifications** — FCM tokens are stored per-user. A Node.js backend on Render sends push notifications on status changes.
- **Centralized Design System** — All colors, spacing, typography, radii, shadows, and component themes live in a shared Dart package. Zero hardcoded values in UI screens.

---

## Architecture

The application follows a **layered architecture** separating presentation, domain, and data concerns so that UI components never directly depend on Firebase implementations.

```
                    PRESENTATION
                         │
               Flutter Widgets + Riverpod
                         │
                         ▼
                      DOMAIN
                         │
              Entities · Validators · Lifecycle
                         │
                         ▼
                       DATA
                         │
              Repository Implementations
                         │
                         ▼
                     FIREBASE
              ┌──────────┼───────────┐
              │          │           │
            Auth    Firestore       FCM
```

### Why This Architecture?

- **Presentation** layer uses `ConsumerWidget` / `ConsumerStatefulWidget` and reads state via Riverpod providers. Screens never import `cloud_firestore` or `firebase_auth`.
- **Data** layer contains repository classes that encapsulate all Firebase operations and map Firebase errors to safe, user-facing `AppException` subclasses.
- **Domain** layer (shared package) contains pure Dart entities, validators, lifecycle rules, and constants with zero Flutter or Firebase dependencies. It is consumed by both the mobile app and the admin portal.

### State Management

| Concern | Tool |
|---|---|
| Authentication state | `StreamProvider<User?>` (Firebase Auth) |
| User profile | `FutureProvider<shared.User?>` |
| Request lists | `StreamProvider` (Firestore snapshots) |
| Agent metrics | Derived `Provider` (computed from request stream) |
| Navigation | GoRouter with `StatefulShellRoute` |
| Theme | `shared` package `AppTheme.light()` / `AppTheme.dark()` |

---

## Security

### Firebase Authentication
- Email/password and Google Sign-In
- Role resolved from Firestore `users/{uid}.role` after authentication

### Firestore Security Rules (518 lines)

The security rules enforce:

| Rule | Description |
|---|---|
| **Role-based access** | Customers can only read their own requests. Agents can only read requests assigned to them. Admins have read access to all collections. |
| **Ownership validation** | `request.auth.uid == resource.data.customerId` for customer operations |
| **Immutable fields** | `createdAt`, `role`, and `email` cannot be changed after creation |
| **Status transition validation** | Only valid state transitions are permitted (e.g., an Agent cannot move a request from `created` directly to `completed`) |
| **Input validation** | Field types, string lengths, and required fields are validated at the rules level |
| **Write authorization** | Agents can only update requests assigned to them, and only the `status` and `updatedAt` fields |

> Full security documentation: [`docs/QuickServe_RBAC_Security.md`](docs/QuickServe_RBAC_Security.md)

### What Is NOT Committed

- No Firebase service account keys
- No API keys or secrets
- `.env.example` provided as a template (actual `.env` is gitignored)

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.47 · Dart 3.13 |
| **State Management** | Riverpod |
| **Navigation** | GoRouter (StatefulShellRoute for persistent bottom nav) |
| **Backend** | Firebase Auth · Cloud Firestore · Firebase Cloud Messaging |
| **Push Notifications** | Node.js backend on Render + FCM |
| **Cloud Functions** | Firebase Cloud Functions (TypeScript) |
| **Admin Portal** | Flutter Web with Riverpod + GoRouter |
| **Design System** | Material 3 · Centralized theme package |
| **CI/CD** | GitHub Actions (analyze + format + test) |
| **Monorepo** | Dart workspace with shared package |

---

## Project Structure

```
quickserve/
│
├── apps/
│   ├── mobile/                    Flutter mobile app (Customer + Agent)
│   │   └── lib/
│   │       ├── config/
│   │       │   ├── routes/        GoRouter configuration
│   │       │   └── theme/         Re-exports from shared package
│   │       ├── core/
│   │       │   └── error/         AppException hierarchy + Firebase error mapping
│   │       ├── features/
│   │       │   ├── agent/         Agent dashboard, requests, history
│   │       │   ├── auth/          Login, register, password reset
│   │       │   ├── home/          Customer + Agent home screens
│   │       │   ├── profile/       Profile view/edit, settings, notifications
│   │       │   ├── requests/      Create, track, cancel, details
│   │       │   └── services/      Service catalog browsing
│   │       └── shared/
│   │           └── widgets/       Reusable UI components
│   │
│   └── admin/                     Flutter Web admin portal
│       └── lib/
│           ├── config/            Routes + injection container
│           └── features/          Dashboard, agents, customers, requests, services
│
├── packages/
│   └── shared/                    Pure Dart shared package
│       └── lib/
│           ├── constants/         Collection names, enums, status colors
│           ├── entities/          Domain entities (User, Request, Service, AuditLog)
│           ├── models/            fromMap/toMap data models
│           ├── theme/             AppColors, AppSpacing, AppTheme, AppRadius
│           ├── utils/             Lifecycle rules, request codes, error types
│           └── validators/        Input validation (name, phone, address, etc.)
│
├── firebase/
│   └── firestore/
│       ├── rules/                 firestore.rules (518 lines)
│       └── indexes/               Composite index definitions
│
├── functions/                     Firebase Cloud Functions (TypeScript)
├── custom_backend/                Node.js notification server (Render)
│
├── docs/                          Project documentation (10 documents)
│
├── .github/
│   ├── workflows/flutter_ci.yml   CI: analyze + format + test
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── LICENSE                        MIT
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
└── README.md
```

---

## Application Flow

### Customer Flow

```
Authentication
      ↓
Customer Home
      ↓
Browse Services
      ↓
Create Request
      ↓
Review & Confirm
      ↓
Track Request (real-time)
      ↓
Service Completed / Cancelled
```

### Agent Flow

```
Authentication
      ↓
Agent Dashboard (metrics + upcoming tasks)
      ↓
Assigned Requests
      ↓
Request Details
      ↓
Accept Request → Start Work → Complete Work
      ↓
History
```

### Admin Flow

```
Authentication
      ↓
Admin Dashboard
      ↓
Manage: Users · Agents · Services · Requests
      ↓
Activity Logs · Settings
```

### Request Lifecycle State Machine

```
            ┌───────────────────────────────────────┐
            │                                        │
      ┌─────┴──────┐     ┌───────────┐     ┌─────────┴───┐
      │  created   │────▶│ assigned  │────▶│  accepted    │
      └─────┬──────┘     └───────────┘     └───────┬──────┘
            │                                       │
            │                                 ┌─────▼───────┐
            │                                 │ in_progress │
            │                                 └─────┬───────┘
            │                                       │
      ┌─────▼──────┐                          ┌─────▼──────┐
      │ cancelled  │                          │ completed  │
      └────────────┘                          └────────────┘
```

Transition rules are enforced at three levels:
1. **Dart code** — `shared/utils/lifecycle.dart`
2. **Repository layer** — Transaction-level validation
3. **Firestore Security Rules** — Server-side enforcement

---

## Design System

The design system is centralized in `packages/shared/lib/theme/` and consumed by both the mobile app and admin portal:

| Token | File | Examples |
|---|---|---|
| Colors | `app_colors.dart` | `AppColors.primary`, `AppColors.success`, `AppColors.mintSurface` |
| Spacing | `app_spacing.dart` | `AppSpacing.sm` (8), `AppSpacing.md` (12), `AppSpacing.lg` (16) |
| Typography | `app_theme.dart` | Centralized `TextTheme` with consistent weights and sizes |
| Radii | `app_radius.dart` | `AppRadius.sm`, `AppRadius.lg`, `AppRadius.xl` |
| Shadows | `app_shadows.dart` | Semantic elevation shadows |
| Breakpoints | `app_breakpoints.dart` | Responsive layout breakpoints |

### Reusable Components (`shared/widgets/`)

- `StatusPill` — Color-coded request status chips
- `SectionHeader` — Consistent section titles with optional actions
- `CustomerBottomNav` / `AgentShellScreen` — Role-specific navigation
- `HomeBackScope` — Android back-button handling for tab navigation

---

## Quality

### Local Verification

```bash
flutter analyze       # Static analysis
flutter test          # Unit and widget tests
flutter build apk     # Release build verification
```

---

## Setup

### Prerequisites

- Flutter SDK 3.47+
- Dart SDK 3.13+
- Firebase CLI
- Node.js 18+ (for Cloud Functions and notification backend)

### Quick Start

```bash
# Clone
git clone https://github.com/pharshal0604/quickserve.git
cd quickserve

# Install dependencies
cd packages/shared && flutter pub get && cd ../..
cd apps/mobile && flutter pub get && cd ../..
cd apps/admin && flutter pub get && cd ../..

# Run static analysis
flutter analyze apps/mobile
flutter analyze apps/admin
flutter analyze packages/shared

# Run the mobile app
cd apps/mobile
flutter run
```

### Firebase Configuration

1. Create a Firebase project
2. Enable **Authentication** (Email/Password + Google)
3. Enable **Cloud Firestore**
4. Deploy security rules: `firebase deploy --only firestore:rules`
5. Deploy indexes: `firebase deploy --only firestore:indexes`
6. Copy `.env.example` to `.env` and fill in your configuration

### Test Credentials

| Role | Email | Password |
|---|---|---|
| Customer | Register freely on the mobile app | `Harshal@12.` |
| Agent | harshalpidurakr.dev@gmail.com | `Harshal@12.` |
| Admin | harshal.pkr@gmail.com | `Harshal@12.` |

> Full setup guide: [`docs/QuickServe_README_Setup_Deployment.md`](docs/QuickServe_README_Setup_Deployment.md)

---

## Documentation

Comprehensive documentation lives in [`docs/`](docs/):

| # | Document | Description |
|---|---|---|
| 1 | [PRD](docs/QuickServe_PRD.md) | Product Requirements Document |
| 2 | [Requirements Checklist](docs/QuickServe_Requirements_Checklist.md) | Traceability matrix |
| 3 | [System Architecture](docs/QuickServe_System_Architecture.md) | Architecture decisions and diagrams |
| 4 | [Database Design](docs/QuickServe_Database_Design.md) | Firestore schema and relationships |
| 5 | [RBAC & Security](docs/QuickServe_RBAC_Security.md) | Role-based access control and Firestore rules |
| 6 | [User Flow Diagram](docs/QuickServe_User_Flow_Diagram.md) | End-to-end user journeys |
| 7 | [Request Lifecycle](docs/QuickServe_Request_Lifecycle_State_Diagram.md) | State machine and transition rules |
| 8 | [UI/UX Wireframes](docs/QuickServe_UI_UX_Wireframes.md) | Screen layouts and interaction patterns |
| 9 | [Testing Plan](docs/QuickServe_Testing_Plan.md) | Testing strategy and coverage |
| 10 | [Setup & Deployment](docs/QuickServe_README_Setup_Deployment.md) | Installation and deployment guide |

---

## Engineering Decisions

### Why Riverpod?

Selected over `Provider` and `BLoC` for its compile-time safety, testability without `BuildContext`, and natural support for derived/computed state (e.g., agent metrics computed from the request stream).

### Why Firebase?

Firebase provides authentication, real-time database, push notifications, and server-side security rules in a single platform — ideal for a multi-role real-time application without a custom backend for core operations.

### Why Repository Pattern?

Repositories encapsulate all Firebase operations and map raw Firebase errors into safe, typed `AppException` subclasses. UI screens never see `FirebaseException` — they receive human-readable error messages. This also makes it possible to swap Firebase for another backend without touching UI code.

### Why a Shared Package?

Entities, validators, lifecycle rules, and theme tokens are consumed by both the mobile app and the admin portal. Centralizing them in `packages/shared` eliminates duplication and ensures consistency. The shared package depends on `cloud_firestore` only for `Timestamp` handling in `fromMap()` methods, keeping the coupling minimal.

### Why GoRouter with StatefulShellRoute?

GoRouter provides URL-based deep linking, declarative redirects for authentication guards, and `StatefulShellRoute` preserves tab state in the Agent's bottom navigation — so switching between Home, Tasks, History, and Profile doesn't lose scroll position or loaded data.

---

## Engineering Challenges Solved

### Role-Based Navigation

A single mobile app serves both Customer and Agent roles. The router dynamically redirects to the correct shell (`/home` vs `/a/home`) based on the user's Firestore profile role, while sharing screens like Request Details between both roles.

### Atomic Request Creation

Creating a request involves five writes in a single Firestore transaction: counter increment, request document, status history entry, audit log, and the service availability check. If any step fails, the entire transaction rolls back.

### Real-Time Sync Across Roles

When an Agent accepts a request, the Customer's tracking screen updates within milliseconds via Firestore snapshot streams. No polling required.

### Firestore Security at Scale

518 lines of security rules enforce ownership, role-based access, field immutability, status transition validity, and input constraints — providing defense-in-depth beyond what the client-side code validates.

### Graceful Error Handling

Every Firebase error is caught at the repository layer and transformed into a typed `AppException` with a user-safe message. The UI never exposes raw Firebase error codes to users.

---

## Known Limitations

- Admin portal is functional but some advanced features (batch operations, analytics export) are planned.
- Payment processing is not implemented (out of scope for this version).
- Image/file attachments for requests are planned but not yet implemented.
- The notification backend runs on Render's free tier, which has cold-start latency.

---

## Author

**Harshal Pidurkar**

- GitHub: [@pharshal0604](https://github.com/pharshal0604)
- Email: harshalpidurkar.dev@gmail.com

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.



