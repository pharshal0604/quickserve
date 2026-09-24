# QuickServe

A production-oriented home-service platform built with **Flutter**, **Firebase**, and **Riverpod**.

> **Customer App** Â· **Agent App** Â· **Admin Portal**

[Screenshots](#-screenshots) Â· [Architecture](#-architecture) Â· [Features](#-features) Â· [Setup](#-setup)

---

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                  QUICKSERVE                     â”‚
â”‚                                                 â”‚
â”‚   Customer  â†’  Browse Â· Request Â· Track         â”‚
â”‚        â†“                                        â”‚
â”‚   Agent     â†’  Accept Â· Work Â· Complete         â”‚
â”‚        â†“                                        â”‚
â”‚   Admin     â†’  Manage Â· Monitor Â· Configure     â”‚
â”‚                                                 â”‚
â”‚   Flutter + Riverpod + GoRouter + Firebase      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## ðŸ“‹ Project Overview

QuickServe is a multi-role service request management system designed for home-service businesses. It connects **Customers** who need services (AC repair, plumbing, electrical work, etc.) with **Agents** who perform the work, supervised by **Admins** who manage operations.

The system is built as a **Flutter monorepo** with a shared Dart package, and uses **Firebase** for authentication, real-time database, push notifications, and security rules.

### User Roles

| Role | Description |
|------|-------------|
| **Customer** | Creates service requests, tracks progress, receives real-time updates |
| **Agent** | Receives assignments, accepts/starts/completes work, views history |
| **Admin** | Manages agents, services, customers, and monitors all requests |

---

## ðŸ“± Screenshots

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

## âœ¨ Features

### Feature Matrix

| Feature | Customer | Agent | Admin |
|---------|:--------:|:-----:|:-----:|
| Email + Google Authentication | âœ… | âœ… | âœ… |
| Service browsing | âœ… | â€” | âœ… |
| Create service request | âœ… | â€” | âœ… |
| Real-time request tracking | âœ… | âœ… | âœ… |
| Cancel request | âœ… | â€” | âœ… |
| Accept assigned request | â€” | âœ… | âœ… |
| Start / Complete work | â€” | âœ… | âœ… |
| Request history | âœ… | âœ… | âœ… |
| Push notifications (FCM) | âœ… | âœ… | âœ… |
| Profile management | âœ… | âœ… | âœ… |
| Agent management | â€” | â€” | âœ… |
| Service management | â€” | â€” | âœ… |
| Customer management | â€” | â€” | âœ… |
| Dashboard analytics | â€” | âœ… | âœ… |
| Dark mode | âœ… | âœ… | â€” |
| Audit logging | â€” | â€” | âœ… |

### Key Technical Features

- **Atomic Firestore Transactions** â€” Request status transitions, counter increments, audit logs, and status history are all written in a single Firestore transaction. No partial writes.
- **Request Lifecycle State Machine** â€” Strict server-side and client-side validation of status transitions (`created â†’ assigned â†’ accepted â†’ in_progress â†’ completed`). Invalid transitions are rejected at both the code layer and Firestore Security Rules.
- **Yearly Request Codes** â€” Auto-incrementing human-readable codes (e.g., `REQ-2026-0001`) generated atomically via a Firestore counter document.
- **Real-time Streams** â€” All request lists and details use Firestore `snapshots()` streams. When an Agent accepts a request, the Customer's UI updates instantly.
- **Push Notifications** â€” FCM tokens are stored per-user. A Node.js backend on Render sends push notifications on status changes.
- **Centralized Design System** â€” All colors, spacing, typography, radii, shadows, and component themes live in a shared Dart package. Zero hardcoded values in UI screens.

---

## ðŸ— Architecture

The application follows a **layered architecture** separating presentation, domain, and data concerns so that UI components never directly depend on Firebase implementations.

```
                    PRESENTATION
                         â”‚
               Flutter Widgets + Riverpod
                         â”‚
                         â–¼
                      DOMAIN
                         â”‚
              Entities Â· Validators Â· Lifecycle
                         â”‚
                         â–¼
                       DATA
                         â”‚
              Repository Implementations
                         â”‚
                         â–¼
                     FIREBASE
              â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
              â”‚          â”‚           â”‚
            Auth    Firestore      FCM
```

### Why This Architecture?

- **Presentation** layer uses `ConsumerWidget` / `ConsumerStatefulWidget` and reads state via Riverpod providers. Screens never import `cloud_firestore` or `firebase_auth`.
- **Data** layer contains repository classes that encapsulate all Firebase operations and map Firebase errors to safe, user-facing `AppException` subclasses.
- **Domain** layer (shared package) contains pure Dart entities, validators, lifecycle rules, and constants with zero Flutter or Firebase dependencies. It is consumed by both the mobile app and the admin portal.

### State Management

| Concern | Tool |
|---------|------|
| Authentication state | `StreamProvider<User?>` (Firebase Auth) |
| User profile | `FutureProvider<shared.User?>` |
| Request lists | `StreamProvider` (Firestore snapshots) |
| Agent metrics | Derived `Provider` (computed from request stream) |
| Navigation | GoRouter with `StatefulShellRoute` |
| Theme | `shared` package `AppTheme.light()` / `AppTheme.dark()` |

---

## ðŸ”’ Security

### Firebase Authentication
- Email/password and Google Sign-In
- Role resolved from Firestore `users/{uid}.role` after authentication

### Firestore Security Rules (518 lines)

The security rules enforce:

| Rule | Description |
|------|-------------|
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

## ðŸ›  Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.47 Â· Dart 3.13 |
| **State Management** | Riverpod |
| **Navigation** | GoRouter (StatefulShellRoute for persistent bottom nav) |
| **Backend** | Firebase Auth Â· Cloud Firestore Â· Firebase Cloud Messaging |
| **Push Notifications** | Node.js backend on Render + FCM |
| **Cloud Functions** | Firebase Cloud Functions (TypeScript) |
| **Admin Portal** | Flutter Web with Riverpod + GoRouter |
| **Design System** | Material 3 Â· Centralized theme package |
| **CI/CD** | GitHub Actions (analyze + format + test) |
| **Monorepo** | Dart workspace with shared package |

---

## ðŸ“ Project Structure

```
quickserve/
â”‚
â”œâ”€â”€ apps/
â”‚   â”œâ”€â”€ mobile/                    Flutter mobile app (Customer + Agent)
â”‚   â”‚   â””â”€â”€ lib/
â”‚   â”‚       â”œâ”€â”€ config/
â”‚   â”‚       â”‚   â”œâ”€â”€ routes/        GoRouter configuration
â”‚   â”‚       â”‚   â””â”€â”€ theme/         Re-exports from shared package
â”‚   â”‚       â”œâ”€â”€ core/
â”‚   â”‚       â”‚   â””â”€â”€ error/         AppException hierarchy + Firebase error mapping
â”‚   â”‚       â”œâ”€â”€ features/
â”‚   â”‚       â”‚   â”œâ”€â”€ agent/         Agent dashboard, requests, history
â”‚   â”‚       â”‚   â”œâ”€â”€ auth/          Login, register, password reset
â”‚   â”‚       â”‚   â”œâ”€â”€ home/          Customer + Agent home screens
â”‚   â”‚       â”‚   â”œâ”€â”€ profile/       Profile view/edit, settings, notifications
â”‚   â”‚       â”‚   â”œâ”€â”€ requests/      Create, track, cancel, details
â”‚   â”‚       â”‚   â””â”€â”€ services/      Service catalog browsing
â”‚   â”‚       â””â”€â”€ shared/
â”‚   â”‚           â””â”€â”€ widgets/       Reusable UI components
â”‚   â”‚
â”‚   â””â”€â”€ admin/                     Flutter Web admin portal
â”‚       â””â”€â”€ lib/
â”‚           â”œâ”€â”€ config/            Routes + injection container
â”‚           â””â”€â”€ features/          Dashboard, agents, customers, requests, services
â”‚
â”œâ”€â”€ packages/
â”‚   â””â”€â”€ shared/                    Pure Dart shared package
â”‚       â””â”€â”€ lib/
â”‚           â”œâ”€â”€ constants/         Collection names, enums, status colors
â”‚           â”œâ”€â”€ entities/          Domain entities (User, Request, Service, AuditLog)
â”‚           â”œâ”€â”€ models/            fromMap/toMap data models
â”‚           â”œâ”€â”€ theme/             AppColors, AppSpacing, AppTheme, AppRadius
â”‚           â”œâ”€â”€ utils/             Lifecycle rules, request codes, error types
â”‚           â””â”€â”€ validators/        Input validation (name, phone, address, etc.)
â”‚
â”œâ”€â”€ firebase/
â”‚   â””â”€â”€ firestore/
â”‚       â”œâ”€â”€ rules/                 firestore.rules (518 lines)
â”‚       â””â”€â”€ indexes/               Composite index definitions
â”‚
â”œâ”€â”€ functions/                     Firebase Cloud Functions (TypeScript)
â”œâ”€â”€ custom_backend/                Node.js notification server (Render)
â”‚
â”œâ”€â”€ docs/                          Project documentation (10 documents)
â”‚
â”œâ”€â”€ .github/
â”‚   â”œâ”€â”€ workflows/flutter_ci.yml   CI: analyze + format + test
â”‚   â”œâ”€â”€ ISSUE_TEMPLATE/
â”‚   â””â”€â”€ PULL_REQUEST_TEMPLATE.md
â”‚
â”œâ”€â”€ LICENSE                        MIT
â”œâ”€â”€ CODE_OF_CONDUCT.md
â”œâ”€â”€ CONTRIBUTING.md
â””â”€â”€ README.md
```

---

## ðŸ”„ Application Flow

### Customer Flow

```
Authentication
      â†“
Customer Home
      â†“
Browse Services
      â†“
Create Request
      â†“
Review & Confirm
      â†“
Track Request (real-time)
      â†“
Service Completed / Cancelled
```

### Agent Flow

```
Authentication
      â†“
Agent Dashboard (metrics + upcoming tasks)
      â†“
Assigned Requests
      â†“
Request Details
      â†“
Accept Request â†’ Start Work â†’ Complete Work
      â†“
History
```

### Admin Flow

```
Authentication
      â†“
Admin Dashboard
      â†“
Manage: Users Â· Agents Â· Services Â· Requests
      â†“
Activity Logs Â· Settings
```

### Request Lifecycle State Machine

```
           â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
           â”‚                                      â”‚
     â”Œâ”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”     â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”
     â”‚  created   â”‚â”€â”€â”€â”€â–¶â”‚ assigned â”‚â”€â”€â”€â”€â–¶â”‚  accepted  â”‚
     â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜     â””â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”˜
           â”‚                                    â”‚
           â”‚                              â”Œâ”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”
           â”‚                              â”‚ in_progress â”‚
           â”‚                              â””â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”˜
           â”‚                                    â”‚
     â”Œâ”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”                      â”Œâ”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”
     â”‚ cancelled  â”‚                      â”‚ completed  â”‚
     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                      â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

Transition rules are enforced at three levels:
1. **Dart code** â€” `shared/utils/lifecycle.dart`
2. **Repository layer** â€” Transaction-level validation
3. **Firestore Security Rules** â€” Server-side enforcement

---

## ðŸŽ¨ Design System

The design system is centralized in `packages/shared/lib/theme/` and consumed by both the mobile app and admin portal:

| Token | File | Examples |
|-------|------|---------|
| Colors | `app_colors.dart` | `AppColors.primary`, `AppColors.success`, `AppColors.mintSurface` |
| Spacing | `app_spacing.dart` | `AppSpacing.sm` (8), `AppSpacing.md` (12), `AppSpacing.lg` (16) |
| Typography | `app_theme.dart` | Centralized `TextTheme` with consistent weights and sizes |
| Radii | `app_radius.dart` | `AppRadius.sm`, `AppRadius.lg`, `AppRadius.xl` |
| Shadows | `app_shadows.dart` | Semantic elevation shadows |
| Breakpoints | `app_breakpoints.dart` | Responsive layout breakpoints |

### Reusable Components (`shared/widgets/`)

- `StatusPill` â€” Color-coded request status chips
- `SectionHeader` â€” Consistent section titles with optional actions
- `CustomerBottomNav` / `AgentShellScreen` â€” Role-specific navigation
- `HomeBackScope` â€” Android back-button handling for tab navigation

---

## âœ… Quality

### CI/CD Pipeline

GitHub Actions runs on every push and PR to `main`:

```yaml
flutter pub get â†’ dart format --set-exit-if-changed â†’ flutter analyze â†’ flutter test
```

Matrix strategy runs the pipeline across `apps/mobile`, `apps/admin`, and `packages/shared`.

### Verification

```bash
flutter analyze       # Static analysis
flutter test          # Unit and widget tests
flutter build apk     # Release build verification
```

---

## ðŸš€ Setup

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

> Full setup guide: [`docs/QuickServe_README_Setup_Deployment.md`](docs/QuickServe_README_Setup_Deployment.md)

---

## ðŸ“– Documentation

Comprehensive documentation lives in [`docs/`](docs/):

| # | Document | Description |
|---|----------|-------------|
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

## ðŸ§  Engineering Decisions

### Why Riverpod?

Selected over `Provider` and `BLoC` for its compile-time safety, testability without `BuildContext`, and natural support for derived/computed state (e.g., agent metrics computed from the request stream).

### Why Firebase?

Firebase provides authentication, real-time database, push notifications, and server-side security rules in a single platform â€” ideal for a multi-role real-time application without a custom backend for core operations.

### Why Repository Pattern?

Repositories encapsulate all Firebase operations and map raw Firebase errors into safe, typed `AppException` subclasses. UI screens never see `FirebaseException` â€” they receive human-readable error messages. This also makes it possible to swap Firebase for another backend without touching UI code.

### Why a Shared Package?

Entities, validators, lifecycle rules, and theme tokens are consumed by both the mobile app and the admin portal. Centralizing them in `packages/shared` eliminates duplication and ensures consistency. The shared package depends on `cloud_firestore` only for `Timestamp` handling in `fromMap()` methods, keeping the coupling minimal.

### Why GoRouter with StatefulShellRoute?

GoRouter provides URL-based deep linking, declarative redirects for authentication guards, and `StatefulShellRoute` preserves tab state in the Agent's bottom navigation â€” so switching between Home, Tasks, History, and Profile doesn't lose scroll position or loaded data.

---

## ðŸ”§ Engineering Challenges Solved

### Role-Based Navigation

A single mobile app serves both Customer and Agent roles. The router dynamically redirects to the correct shell (`/home` vs `/a/home`) based on the user's Firestore profile role, while sharing screens like Request Details between both roles.

### Atomic Request Creation

Creating a request involves five writes in a single Firestore transaction: counter increment, request document, status history entry, audit log, and the service availability check. If any step fails, the entire transaction rolls back.

### Real-Time Sync Across Roles

When an Agent accepts a request, the Customer's tracking screen updates within milliseconds via Firestore snapshot streams. No polling required.

### Firestore Security at Scale

518 lines of security rules enforce ownership, role-based access, field immutability, status transition validity, and input constraints â€” providing defense-in-depth beyond what the client-side code validates.

### Graceful Error Handling

Every Firebase error is caught at the repository layer and transformed into a typed `AppException` with a user-safe message. The UI never exposes raw Firebase error codes to users.

---

## âš ï¸ Known Limitations

- Admin portal is functional but some advanced features (batch operations, analytics export) are planned.
- Payment processing is not implemented (out of scope for this version).
- Image/file attachments for requests are planned but not yet implemented.
- The notification backend runs on Render's free tier, which has cold-start latency.

---

## ðŸ‘¤ Author

**Harshal Pidurkar**

- GitHub: [@pharshal0604](https://github.com/pharshal0604)
- Email: harshalpidurkar.dev@gmail.com

---

## ðŸ“œ License

This project is licensed under the MIT License â€” see the [LICENSE](LICENSE) file for details.

