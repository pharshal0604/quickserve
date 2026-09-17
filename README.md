# QuickServe

Service Request Management Application — internship assignment for the Swasiq Technology Internship Program (Health-tech, Nagpur).

## Documentation

Full documentation lives in [`docs/`](docs/):

| # | Document |
|---|---|
| 1 | [PRD](docs/QuickServe_PRD.md) |
| 2 | [Requirements Checklist / Traceability](docs/QuickServe_Requirements_Checklist.md) |
| 3 | [System Architecture](docs/QuickServe_System_Architecture.md) |
| 4 | [Database Design](docs/QuickServe_Database_Design.md) |
| 5 | [RBAC & Security](docs/QuickServe_RBAC_Security.md) |
| 6 | [User Flow Diagram](docs/QuickServe_User_Flow_Diagram.md) |
| 7 | [Request Lifecycle / State Diagram](docs/QuickServe_Request_Lifecycle_State_Diagram.md) |
| 8 | [UI/UX Wireframes](docs/QuickServe_UI_UX_Wireframes.md) |
| 9 | [Testing Plan](docs/QuickServe_Testing_Plan.md) |
| 10 | [Setup & Deployment Guide](docs/QuickServe_README_Setup_Deployment.md) |

DOCX versions of every document are in the same `docs/` folder.

## Repository Structure

```
quickserve/
├── apps/
│   ├── mobile/       Flutter mobile app (Customer + Agent)
│   └── admin/        Flutter Web admin portal (planned)
├── packages/
│   └── shared/       Shared Dart package (planned)
├── docs/             Project documentation
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
├── .gitignore
└── README.md
```

## Tech Stack

- Flutter + Dart (mobile and web)
- Firebase Authentication, Cloud Firestore, Firestore Security Rules
- Riverpod, go_router, Material 3
- Firebase Emulator Suite for local development

## Setup

See [`docs/QuickServe_README_Setup_Deployment.md`](docs/QuickServe_README_Setup_Deployment.md) for full setup, emulator, and deployment instructions.

## Program

Swasiq Technology Internship Program — Health-tech, Nagpur