---
title: "QuickServe UI/UX Wireframes Document"
author: "Swasiq Technology Internship Program"
date: "17 September 2026"
geometry: margin=0.75in
---

## Introduction

### Purpose

This UI/UX Wireframes Document defines the implementation-ready screen structures, interaction patterns, states, navigation behavior, responsive rules, accessibility guidance, and requirement traceability for QuickServe.

QuickServe is a Service Request Management Application for the Swasiq Technology Internship Program — Health-tech, Nagpur. The assignment is a 5–7 day Full-Stack Mobile Application challenge. Customers create and track service requests through Flutter mobile, Agents manage assigned work through the same mobile client, and Admins manage operations through a Flutter Web portal.

The wireframes are intentionally ASCII-based so they remain readable in Markdown, code review, terminal output, and Word conversion through Pandoc. They describe structure and behavior rather than prescribing a new visual brand, font family, or color-code system.

### Scope

This document covers:

- Customer and Agent Flutter mobile screens.
- Admin Flutter Web screens.
- Material 3 layout and component guidance.
- Riverpod loading, empty, error, and retry states.
- go_router route organization and role protection.
- Request creation fields and status presentation.
- Accessibility, responsive behavior, localization, and formatting.
- Screen-to-requirement traceability.

The document does not introduce another client, backend service, collection, role, status, event, or notification requirement. The finalized technology stack remains Flutter/Dart, Firebase Authentication, Cloud Firestore, Firestore Security Rules, Riverpod, go_router, Material 3, Firebase Emulator Suite, Firebase Spark, and Firebase Hosting where deployment is required.

### Audience

This document is intended for:

- Flutter/Dart developers implementing widgets, routes, providers, repositories, and validation.
- Designers translating the wireframes into Material 3 layouts.
- Test engineers writing widget and integration tests.
- Reviewers evaluating screen completeness, role separation, accessibility, and consistency with the finalized requirements.

### Relationship to companion documents

The Product Requirements Document (PRD) defines the product baseline and finalized screens. The Requirements Checklist / Traceability document defines requirement identifiers and acceptance evidence. The System Architecture Document defines client layers and Firebase data flow. The Database Design Document defines the data fields used by screens. The RBAC & Security Document defines authentication, `users.role`, ownership, assignment, field protection, and Firestore Rules. The User Flow Diagram Document defines user journeys. The Request Lifecycle / State Diagram Document defines the authoritative request state machine.

This document translates those contracts into screen-level layout and interaction guidance. A wireframe does not grant authorization; every repository operation remains subject to Firestore Security Rules.

## Design Principles

### Material 3 and implementation clarity

Use Material 3 components and conventions without introducing a new visual system. The implementation should favor predictable hierarchy, clear primary actions, familiar form controls, and consistent feedback. Widgets should be composable and shared between Customer and Agent mobile experiences where behavior is equivalent.

### Mobile-first and desktop-capable

Design mobile screens for one-handed use, vertical scrolling, clear primary actions, and safe keyboard behavior. Design Admin Web screens for larger widths with navigation rail or side navigation, structured tables, filters, and detail panels. The same information hierarchy must remain understandable on tablet and desktop.

### Role-aware simplicity

Customers should see service discovery, request creation, request tracking, and profile actions. Agents should see the assigned work queue and status actions. Admins should see operational management views. A hidden button is not an authorization boundary; the route and Firestore Rules must also protect the operation.

### Accessibility by default

Use readable labels, semantic controls, sufficient contrast, keyboard access on Web, scalable text, visible focus states, and touch targets large enough for comfortable use. Do not rely on color alone to communicate status or priority.

### Safe error display

Show concise, actionable messages. Do not display passwords, tokens, API keys, secrets, raw Rules expressions, stack traces, or sensitive exception payloads. Map permission-denied to a safe authorization message and offer a valid recovery action where appropriate.

### Required state coverage

Every data-dependent screen must define:

- Loading state.
- Successful content state.
- Empty state.
- Recoverable error state.
- Retry behavior.
- Permission-denied behavior where applicable.

### Lifecycle consistency

Display statuses exactly as lowercase stored values in data and as readable labels in the UI. The finalized stored statuses are `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`. No screen should offer a transition that the lifecycle or Firestore Rules reject.

## Global UX Patterns

### Common application shell

| Client | Shell pattern | Primary navigation |
|---|---|---|
| Flutter mobile | Material 3 `Scaffold` with top app bar and role-aware body | Bottom navigation or compact destination navigation for finalized mobile destinations |
| Flutter Web | Responsive Material 3 navigation rail or side navigation with content area | Admin Dashboard, Admin Request Management, Admin Customer View, Admin Agent View, Admin Activity/Audit View |
| Public/authentication | Centered or constrained form surface | Login, Registration, password reset initiation |

The exact navigation widget may vary with the final Flutter layout, but route names and screen responsibilities must remain consistent with the finalized screen list.

### Typography scale

Use the Material 3 typography scale and keep hierarchy consistent. These are descriptive implementation targets, not new hard requirements:

| Text purpose | Suggested Material 3 style | Usage |
|---|---|---|
| Page title | Headline or title style | Screen title and primary context |
| Section title | Title style | Form or content grouping |
| Body text | Body style, approximately 16 sp | Descriptions, labels, and readable content |
| Supporting text | Body small or label style | Hints, timestamps, helper text |
| Status and priority | Label style with text | Chips and compact metadata |
| Error text | Body small or label style | Inline validation and safe error messages |

Do not hard-code a font family or a custom typography system in the application without an approved design decision.

### Spacing and layout

Use a consistent spacing scale derived from Material 3 layout guidance. A practical implementation can use 8 logical-pixel increments with smaller values for dense metadata and larger values between sections. Keep form fields vertically separated enough that labels and errors are not ambiguous.

### Color usage

Use the Material 3 theme's primary, surface, on-surface, error, and supporting roles. No color codes are prescribed in this document. Status and priority must also be identified with text, labels, or icons so a user does not need color perception to understand the state.

### Iconography

Use Material Icons consistently. Icons supplement text and must not replace an accessible label for a critical action. Destructive or terminal actions require a text label, confirmation where appropriate, and a safe result message.

### Form field conventions

| Field convention | Implementation guidance |
|---|---|
| Label | Persistent visible label; do not rely only on placeholder text |
| Required field | Mark consistently and explain requirements near the field or form header |
| Input type | Use keyboard and control type appropriate to the data |
| Validation | Validate locally before submit and repeat authorization/data validation in repositories and Rules |
| Error message | Place near the field; use concise corrective language |
| Disabled state | Explain why an action is unavailable when the reason is not obvious |
| Submission | Disable duplicate submission while the write is pending |
| Sensitive data | Never request or display passwords except in Firebase Authentication controls; never display tokens or secrets |

### Snackbar and banner patterns

Use an inline error banner for screen-level loading failures and a snackbar for short-lived confirmation such as “Request created” or “Profile updated.” Permission-denied should use a safe message and remain visible long enough to be understood. Critical status changes should also be visible in the request detail timeline.

### Status and priority presentation

| Data | Stored values | Display guidance |
|---|---|---|
| Role | `customer`, `agent`, `admin` | Display labels Customer, Agent, Admin |
| Priority | `low`, `medium`, `high` | Display readable labels Low, Medium, High; preserve lowercase in data |
| Status | `created`, `assigned`, `accepted`, `in_progress`, `completed`, `cancelled` | Display readable text while preserving the lowercase stored value |
| Event | `LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, `DATABASE_ERROR` | Admin activity view may display readable event labels without changing stored values |

## Mobile App Wireframes

The mobile app supports Customer and Agent roles. The same Firebase Authentication session and `users.role` profile resolution determine which role-specific content is shown after login.

### Splash

#### Purpose

Resolve Firebase Authentication session and the `users/{uid}` profile before entering a protected mobile route.

#### Layout description

Use a centered brand/title area with a progress indicator. Avoid showing role-specific data before profile resolution. If resolution fails, show a safe recovery action rather than falling through to a customer screen.

#### UI elements

- QuickServe title.
- Progress indicator.
- Short loading message.
- Optional retry action for recoverable profile/database failure.

#### User actions

- Wait for session resolution.
- Retry when the profile read fails.
- Sign out or return to Login when the profile is missing and the application presents that recovery option.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show centered progress indicator and preserve the session-resolution context. |
| Empty | Not applicable as a normal state; a missing profile is a recovery state. |
| Error | Show a safe profile/session error with Retry or Login recovery. |
| Permission denied | Do not reveal Rules details; route to safe recovery. |

#### ASCII wireframe

```text
+--------------------------------+
|                                |
|            QuickServe          |
|                                |
|          [ progress ]          |
|       Restoring session...     |
|                                |
+--------------------------------+
```

#### Role restrictions

Splash is not a role-specific destination. It must not expose Customer, Agent, or Admin content before valid profile resolution. Admin users are routed to the Web portal after role resolution.

### Login

#### Purpose

Authenticate an existing user with Firebase Authentication email/password and begin role routing.

#### Layout description

Use a constrained form surface with a clear title, email field, password field, primary Login action, Registration link, and password-reset initiation link. Keep the primary action visible above the keyboard when practical.

#### UI elements

- Email field.
- Password field with visibility control.
- Login button.
- Register link.
- Password reset link.
- Inline validation and safe error area.

#### User actions

- Enter email and password.
- Submit Login.
- Open Registration.
- Initiate password reset.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Disable duplicate submission and show progress on Login. |
| Empty | Show the normal form; no empty content state. |
| Error | Show safe invalid-credentials or connection message without revealing account existence unnecessarily. |
| Permission or profile error | Authentication may succeed while profile resolution fails; show safe recovery and do not enter a role route. |

#### ASCII wireframe

```text
+--------------------------------+
|           QuickServe           |
|             Login              |
|                                |
| Email                          |
| [____________________________] |
|                                |
| Password                 [eye] |
| [____________________________] |
|                                |
|          [ Login ]             |
|                                |
| Forgot password?               |
| Create an account              |
|                                |
| [safe error message area]      |
+--------------------------------+
```

#### Role restrictions

Customer, Agent, and Admin users may authenticate. Authentication success does not itself grant a role; the client resolves `users.role` and the protected database operations remain governed by Rules.

### Registration

#### Purpose

Create a Firebase Authentication email/password account and the corresponding customer profile.

#### Layout description

Use a scrollable form with name, email, phone, password, and confirmation controls as required by the finalized authentication implementation. There must be no role selector. The flow creates only a `customer` profile through ordinary self-registration.

#### UI elements

- Name field.
- Email field.
- Phone field.
- Password field.
- Password confirmation field if used by the client validation design.
- Create account button.
- Link back to Login.
- Validation and safe error area.

#### User actions

- Complete the registration form.
- Submit Create account.
- Return to Login.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Disable form submission and show progress. |
| Empty | Show field labels and validation guidance. |
| Error | Show field-level corrections or safe account/profile creation failure. |
| Partial success | If Authentication succeeds but profile creation fails, do not route to protected content until the profile is repaired through the approved recovery path. |

#### ASCII wireframe

```text
+--------------------------------+
| < Back       Registration      |
|                                |
| Name                           |
| [____________________________] |
| Email                          |
| [____________________________] |
| Phone                          |
| [____________________________] |
| Password                       |
| [____________________________] |
| Confirm password               |
| [____________________________] |
|                                |
|       [ Create account ]       |
|                                |
| [validation/error area]        |
+--------------------------------+
```

#### Role restrictions

Self-registration creates only stored role `customer`. The UI must not offer `agent` or `admin` selection, and the database layer must reject self-promotion.

### Home — Customer view

#### Purpose

Provide the Customer with an understandable starting point for service browsing, request creation, request tracking, and profile access.

#### Layout description

Use a top app bar with a role-appropriate greeting or title, a body with primary actions, and bottom navigation or destination controls for Home, Services, My Requests, and Profile as finalized by the application navigation implementation.

#### UI elements

- Greeting or Home title.
- Primary Create Request action.
- Services entry point.
- My Requests entry point.
- Summary of recent or active own requests if included by the finalized product scope.
- Profile destination.

#### User actions

- Browse Services.
- Start Create Request.
- Open My Requests.
- Open Profile.
- Logout through Profile.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show shell and content skeleton while role/profile data resolves. |
| Empty | Explain that no requests exist and offer Create Request. |
| Error | Show safe message with Retry for request summary data. |
| Permission denied | Keep navigation available only for authorized destinations and show safe message. |

#### ASCII wireframe

```text
+--------------------------------+
| QuickServe                 [ ] |
| Hello, Customer                |
+--------------------------------+
|                                |
| Need a service?                |
|      [ Create Request ]        |
|                                |
| [ Services ]   [ My Requests ] |
|                                |
| Recent requests                |
| [ Request card / empty state ] |
|                                |
+--------------------------------+
| Home | Services | Requests | Me|
+--------------------------------+
```

#### Role restrictions

This view is rendered for stored role `customer`. It must not show Agent work-queue actions or Admin operations.

### Home — Agent view

#### Purpose

Provide the Agent with the assigned work queue as the primary authenticated action.

#### Layout description

Use a top app bar with Agent context, a prominent assigned-request queue, status filtering if supported by the finalized query design, and Profile access. The primary action is opening an assigned request, not creating a new customer request.

#### UI elements

- Agent title or greeting.
- Assigned request count or summary if available.
- Assigned request cards.
- Status chips using lowercase stored values behind readable labels.
- Profile destination.
- Empty queue state.

#### User actions

- Open Agent Request Details for an assigned request.
- Refresh the queue.
- View completed work where supported.
- Open Profile and Logout.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show queue skeleton cards. |
| Empty | Explain that no requests are currently assigned. |
| Error | Show safe error banner and Retry. |
| Permission denied | Return to a safe role route and show a safe authorization message. |

#### ASCII wireframe

```text
+--------------------------------+
| QuickServe                 [ ] |
| Agent work queue               |
+--------------------------------+
| [ Refresh ]                    |
|                                |
| Assigned requests              |
| +----------------------------+ |
| | REQ-YYYY-000123            | |
| | Plumbing                   | |
| | status: assigned           | |
| | priority: high            >| |
| +----------------------------+ |
|                                |
| [empty/error state if needed]  |
+--------------------------------+
| Queue                         Me|
+--------------------------------+
```

#### Role restrictions

This view is rendered for stored role `agent`. The queue must be assignment-scoped; an Agent must not see another Agent's requests.

### Services

#### Purpose

Allow a Customer to browse active services and choose a service type for a new request.

#### Layout description

Use a top app bar with a back affordance or route title, a list/grid of service cards, and a clear path to Create Request. Services are AC servicing, Plumbing, Electrical, and Cleaning. The UI should indicate unavailable services without allowing them to be selected for a new request.

#### UI elements

- Service cards or list rows.
- Service name.
- Description.
- Active/inactive presentation if service data includes it.
- Select or Start Request action.
- Loading, empty, and error components.

#### User actions

- Read service information.
- Select an active service.
- Continue to Create Request.
- Retry service loading.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show service-card skeletons. |
| Empty | Explain that no active services are available. |
| Error | Show safe error banner and Retry. |
| Inactive service | Display as unavailable or omit from selectable choices according to the finalized product behavior. |

#### ASCII wireframe

```text
+--------------------------------+
| < Back          Services       |
+--------------------------------+
| Choose a service               |
|                                |
| +----------------------------+ |
| | AC servicing               | |
| | Description...          >  | |
| +----------------------------+ |
| | Plumbing                   | |
| | Description...          >  | |
| +----------------------------+ |
| | Electrical                 | |
| | Description...          >  | |
| +----------------------------+ |
| | Cleaning                   | |
| | Description...          >  | |
| +----------------------------+ |
+--------------------------------+
```

#### Role restrictions

Customer-facing service selection is available to stored role `customer`. Agents and Admins may read services when permitted by Rules but do not use this screen to create customer requests.

### Create Request

#### Purpose

Collect the finalized request fields, validate them, allocate a request code through the repository transaction flow, and create a request beginning in `created` status.

#### Layout description

Use a scrollable form with a clear title, grouped fields, inline validation, priority selection, and a bottom or persistent primary action. On small screens, the keyboard must not cover the active field or submit button.

#### UI elements

- Service type selector: AC servicing, Plumbing, Electrical, Cleaning.
- Description multiline field.
- Preferred date/time control.
- Address multiline field.
- Priority selector with `low`, `medium`, and `high` values.
- Create Request button.
- Validation messages.
- Confirmation state showing `REQ-YYYY-000123` after successful creation.

#### User actions

- Select service type.
- Enter description, preferred date/time, and address.
- Select priority.
- Submit Create Request.
- Review the generated request code.
- Navigate to Request Details after success.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Preserve entered values, disable duplicate submit, and show progress. |
| Empty | Show the unfilled form with clear required-field guidance. |
| Validation error | Place corrective text under the relevant field and focus the first invalid field where possible. |
| Counter conflict | Show safe retry-later or retry message; never show a request as created before confirmation. |
| Database error | Show safe error and preserve entered values when possible. |
| Success | Show request code, `created` status, and a path to Request Details. |

#### ASCII wireframe

```text
+--------------------------------+
| < Back       Create Request    |
+--------------------------------+
| Service type                   |
| [ AC servicing             v ] |
|                                |
| Description                    |
| [____________________________] |
| [____________________________] |
|                                |
| Preferred date/time            |
| [ Select date and time      ]  |
|                                |
| Address                        |
| [____________________________] |
| [____________________________] |
|                                |
| Priority                      |
| ( low ) ( medium ) ( high )    |
|                                |
|       [ Create Request ]       |
| [validation/error area]        |
+--------------------------------+
```

#### Role restrictions

Only stored role `customer` may create a request through this flow. The request must use the authenticated UID as `customerId`, begin with stored status `created`, and receive a request code in the format `REQ-YYYY-000123`.

### My Requests

#### Purpose

Show a Customer's own requests and their current lifecycle state.

#### Layout description

Use a top bar with the screen title, a vertically scrolling list of Request Cards, optional supported filters, and a clear empty state. Each card should expose enough context to select the request without displaying unnecessary private data.

#### UI elements

- Request card with request code.
- Service type.
- Status chip.
- Priority chip.
- Preferred date/time summary.
- Refresh control.
- Empty state.

#### User actions

- Open an owned request.
- Refresh the list.
- Retry a failed query.
- Return to Home or Profile through navigation.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show list skeletons. |
| Empty | Explain that no requests exist and offer Create Request. |
| Error | Show safe error banner and Retry. |
| Permission denied | Show safe message and return to a valid customer route. |

#### ASCII wireframe

```text
+--------------------------------+
| My Requests                 [ ]|
+--------------------------------+
| [ Refresh ]                    |
|                                |
| +----------------------------+ |
| | REQ-YYYY-000123            | |
| | AC servicing               | |
| | status: assigned           | |
| | priority: medium        >  | |
| +----------------------------+ |
|                                |
| +----------------------------+ |
| | REQ-YYYY-000124            | |
| | Cleaning                   | |
| | status: completed          | |
| | priority: low           >  | |
| +----------------------------+ |
+--------------------------------+
```

#### Role restrictions

Only the owning Customer may read the corresponding request through the Customer flow. Cross-customer access must be denied by Firestore Rules even if a document ID is guessed.

### Request Details — Customer

#### Purpose

Show an owned request, its current status, permitted fields, request code, and status timeline. Offer cancellation only when the status is `created` or `assigned`.

#### Layout description

Use a top app bar with a back affordance, a request summary header, status and priority chips, structured details, timeline content, and a bottom action area when cancellation is eligible.

#### UI elements

- Request code.
- Service type.
- Current status chip.
- Priority chip.
- Description.
- Preferred date/time.
- Address.
- Status-history timeline.
- Cancel action only for `created` or `assigned`.
- Cancellation-reason field/dialog when required.

#### User actions

- Review request details.
- Review lifecycle history.
- Cancel an eligible own request.
- Return to My Requests.
- Retry detail or history loading.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show request-summary and timeline skeletons. |
| Empty/not found | Show safe unavailable message; do not disclose another user's record. |
| Error | Show safe error and Retry. |
| Permission denied | Show safe authorization message and return to My Requests. |
| Cancel success | Refresh status and show `cancelled` as terminal. |

#### ASCII wireframe

```text
+--------------------------------+
| < Back       Request Details   |
+--------------------------------+
| REQ-YYYY-000123                |
| AC servicing                   |
| [status: assigned] [medium]    |
+--------------------------------+
| Description                    |
| Customer-provided description  |
| Preferred date/time             |
| Address                        |
+--------------------------------+
| Status history                 |
| o created                      |
| | assigned                     |
|                                |
|       [ Cancel request ]       |
+--------------------------------+
```

#### Role restrictions

The Customer must own the request. Customer cancellation is permitted only for stored status `created` or `assigned`. The screen must not offer cancellation for `accepted`, `in_progress`, `completed`, or `cancelled`.

### Agent Request Details

#### Purpose

Allow the assigned Agent to inspect a request, accept assigned work, progress it through the permitted lifecycle, add safe notes, and view completed work.

#### Layout description

Use a top app bar, request summary, status timeline, operational details, and a contextual bottom action. Show only the status action valid for the current state and role.

#### UI elements

- Request code.
- Service type.
- Current status chip.
- Priority chip.
- Description, preferred date/time, and address as permitted.
- Status-history timeline.
- Accept, Start Work, Complete, or note action according to state.
- Safe validation/error area.

#### User actions

- Open an assigned request.
- Accept when status is `assigned`.
- Move to `in_progress` when status is `accepted`.
- Move to `completed` when status is `in_progress`.
- Add a safe status-history note.
- Review completed work.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show detail and timeline skeletons. |
| Empty/not found | Show safe unavailable message. |
| Error | Show safe error and Retry. |
| Permission denied | Show safe authorization message and return to the Agent queue. |
| Terminal | Show read-only timeline and no outgoing status action. |

#### ASCII wireframe

```text
+--------------------------------+
| < Back   Agent Request Details |
+--------------------------------+
| REQ-YYYY-000123                |
| Plumbing                       |
| [status: accepted] [high]      |
+--------------------------------+
| Description                    |
| Work details                   |
| Preferred date/time             |
| Address                        |
+--------------------------------+
| Timeline                       |
| o created                      |
| | assigned                     |
| | accepted                    |
|                                |
| [ Add note ] [ Start work ]    |
+--------------------------------+
```

#### Role restrictions

Only the assigned Agent may use Agent lifecycle actions for the request. Another Agent must be denied. Customers and Admins use their own role-appropriate screens and permissions.

### Profile

#### Purpose

Show the authenticated user's permitted profile information and provide the Logout action.

#### Layout description

Use a top app bar and a simple form or read/edit surface for permitted profile fields. The role display is informational and must not be editable by the user.

#### UI elements

- Name.
- Email display.
- Phone.
- Role display label: Customer, Agent, or Admin as appropriate.
- Save action for permitted fields.
- Logout action.
- Safe error and confirmation feedback.

#### User actions

- Review profile.
- Edit permitted profile fields.
- Save changes.
- Select Logout.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show profile skeleton or disabled form while profile resolves. |
| Empty | Show a safe missing-profile recovery state, not a self-service role editor. |
| Error | Show safe read/write error and Retry. |
| Permission denied | Preserve current local state and explain that the update was not authorized. |

#### ASCII wireframe

```text
+--------------------------------+
| Profile                        |
+--------------------------------+
| Name                           |
| [____________________________] |
| Email                          |
| [read-only email]             |
| Phone                          |
| [____________________________] |
| Role                           |
| [Customer / Agent / Admin]    |
|                                |
|          [ Save ]              |
|          [ Logout ]            |
| [safe message area]            |
+--------------------------------+
```

#### Role restrictions

Users may update only permitted profile fields. The stored value `users.role` is not editable through Profile and cannot be changed to promote the user.

### Logout — action, not full screen

#### Purpose

End the Firebase Authentication session and return to Login.

#### Layout description

Expose Logout as a clearly labeled action from Profile or the role shell. If confirmation is used, keep it concise and make the destructive consequence clear.

#### UI elements

- Logout action.
- Optional confirmation dialog.
- Progress indicator while signing out.
- Safe error message if sign-out fails.

#### User actions

- Select Logout.
- Confirm or cancel the action.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Disable repeated Logout actions while sign-out is in progress. |
| Empty | Not applicable. |
| Error | Show safe sign-out error and allow retry. |
| Success | Clear role-dependent state and route to Login. |

#### ASCII wireframe

```text
+------------------------------+
|          Profile             |
|                              |
|          [ Logout ]          |
+------------------------------+

Optional confirmation:
+------------------------------+
| Sign out?                    |
| Your session will end.       |
| [Cancel]       [Logout]      |
+------------------------------+
```

#### Role restrictions

Logout is available to authenticated Customer, Agent, and Admin users. It does not change any Firestore data.

## Admin Web Wireframes

The Admin portal is Flutter Web and is available only after Firebase Authentication and `users.role == admin` resolution. All operational reads and writes remain subject to Firestore Security Rules.

### Admin Login

#### Purpose

Authenticate an Admin before portal access.

#### Layout description

Use a centered constrained form on desktop with responsive margins. On narrow widths, the same form becomes a mobile-width column without exposing the customer registration flow as an Admin provisioning path.

#### UI elements

- Email field.
- Password field.
- Admin Login button.
- Safe error area.
- Optional password reset initiation.

#### User actions

- Enter credentials.
- Submit Admin Login.
- Initiate password reset.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Disable duplicate submit and show progress. |
| Empty | Show form. |
| Error | Show safe authentication or role mismatch message. |
| Non-admin profile | Do not enter the Admin portal; route to the correct role experience or safe recovery. |

#### ASCII wireframe

```text
+------------------------------------------------+
|              QuickServe Admin                 |
|                                                |
| Email                                          |
| [____________________________________________] |
| Password                                       |
| [____________________________________________] |
|                                                |
|                 [ Admin Login ]                |
| Forgot password?                               |
| [safe error message area]                      |
+------------------------------------------------+
```

#### Role restrictions

Only a user whose stored role is `admin` may enter the Admin portal. The route and Firestore Rules both enforce this condition.

### Admin Dashboard

#### Purpose

Provide an operational overview and entry points to Admin request, customer, agent, and activity views.

#### Layout description

Use a responsive Admin shell with navigation rail or side navigation, page title, summary cards, and a main content area. Dashboard counts must use permitted finalized data, such as new requests where status is `created`, without introducing a new analytics collection.

#### UI elements

- Admin navigation.
- Page title.
- Operational summary cards.
- New request count where supported.
- Recent activity or request entry points where finalized.
- User menu and Admin Logout action.

#### User actions

- Open Admin Request Management.
- Open Admin Customer View.
- Open Admin Agent View.
- Open Admin Activity/Audit View.
- Logout.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show summary-card skeletons and preserve navigation. |
| Empty | Show zero counts with explanatory labels, not a blank page. |
| Error | Show safe banner and Retry for dashboard reads. |
| Permission denied | Route away from the Admin portal and show safe authorization message. |

#### ASCII wireframe

```text
+---------------------------------------------------------------+
| QuickServe Admin | Dashboard                         [Admin v]|
+------------------+--------------------------------------------+
| Dashboard        | Overview                                   |
| Requests         | +------------+ +------------+ +----------+ |
| Customers        | | New        | | Assigned  | | In work  | |
| Agents           | | created    | | requests  | | requests | |
| Activity/Audit   | +------------+ +------------+ +----------+ |
|                  |                                            |
|                  | Recent operational view                   |
|                  | [ request/activity summary ]              |
+------------------+--------------------------------------------+
```

#### Role restrictions

Admin Dashboard is available only to stored role `admin`. It must not expose secret fields or unrestricted mutation controls.

### Admin Request Management

#### Purpose

Allow Admins to search and filter permitted requests, open request details, assign agents, and perform authorized status actions.

#### Layout description

Use a page title, bounded search/filter controls, a request table or responsive list, and a detail route or side panel. Filters should remain within supported Firestore query behavior and indexes.

#### UI elements

- Search field where supported by the finalized query design.
- Status filter using lowercase values behind readable labels.
- Priority filter using `low`, `medium`, and `high`.
- Service-type filter.
- Request results table/list.
- Request code, service type, status, priority, customer/agent context where permitted.
- Open-details action.
- Loading, empty, and error state components.

#### User actions

- Search supported request fields.
- Apply and clear filters.
- Open request details.
- Assign an Agent.
- Perform permitted status update.
- Retry failed data load.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show table/list skeleton rows. |
| Empty | Explain that no requests match the current filters and offer Clear filters. |
| Error | Show safe banner and Retry. |
| Permission denied | Show safe message and return to Dashboard. |
| — | — |

#### ASCII wireframe

```text
+---------------------------------------------------------------+
| QuickServe Admin | Request Management                         |
+------------------+--------------------------------------------+
| Navigation        | Search [____________________] [Search]     |
|                   | Filters: [status v] [priority v] [Clear]  |
|                   +--------------------------------------------+
|                   | Code           Service   Status   Priority |
|                   | REQ-...        Plumbing   assigned high  > |
|                   | REQ-...        Cleaning   completed low   > |
|                   | [loading / empty / error state]           |
+-------------------+--------------------------------------------+
```

#### Role restrictions

Only Admin may use operational management actions. Search and filter must not create a client-side all-records bypass; reads and writes remain Rules-protected.

### Admin Customer View

#### Purpose

Show permitted customer profiles and customer-related operational context without exposing secrets.

#### Layout description

Use a searchable or bounded list/table with customer name, email, phone where permitted, and safe request summary links if included in the finalized design. Avoid rendering authentication credentials or internal secret values.

#### UI elements

- Customer list/table.
- Name, email, and phone columns where permitted.
- Safe request summary or navigation link where finalized.
- Loading, empty, error, and retry states.

#### User actions

- Browse permitted customers.
- Open permitted customer context.
- Retry or clear supported filters.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show table skeleton rows. |
| Empty | Explain that no customers are available. |
| Error | Show safe banner and Retry. |
| Permission denied | Show safe message and return to Dashboard. |

#### ASCII wireframe

```text
+---------------------------------------------------------------+
| QuickServe Admin | Customers                                  |
+------------------+--------------------------------------------+
| Navigation        | Customers                                  |
|                   | Name             Email              Action  |
|                   | Customer name    user@example...      >   |
|                   | Customer name    user@example...      >   |
|                   | [loading / empty / error state]           |
+-------------------+--------------------------------------------+
```

#### Role restrictions

Only Admin may access this view. The view must display only approved profile and operational fields and never display passwords, tokens, API keys, or secrets.

### Admin Agent View

#### Purpose

Show permitted Agent profiles and safe operational context used for assignment and work oversight.

#### Layout description

Use a bounded list/table with agent identity and safe assignment context. Assignment controls should open from Admin Request Management or a request detail surface rather than creating an unrelated workflow.

#### UI elements

- Agent list/table.
- Name, email, and phone where permitted.
- Safe assignment/work summary where finalized.
- Loading, empty, error, and retry states.

#### User actions

- Browse permitted Agents.
- Open safe Agent context.
- Return to request management.
- Retry or clear supported filters.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show table skeleton rows. |
| Empty | Explain that no Agents are available. |
| Error | Show safe banner and Retry. |
| Permission denied | Show safe message and return to Dashboard. |

#### ASCII wireframe

```text
+---------------------------------------------------------------+
| QuickServe Admin | Agents                                     |
+------------------+--------------------------------------------+
| Navigation        | Agents                                     |
|                   | Name             Email              Work    |
|                   | Agent name       agent@example...     >    |
|                   | Agent name       agent@example...     >    |
|                   | [loading / empty / error state]           |
+-------------------+--------------------------------------------+
```

#### Role restrictions

Only Admin may access this view. A Customer or Agent must not use it to enumerate other accounts. Stored role values remain lowercase in data, and the display label is Agent.

### Admin Activity/Audit View

#### Purpose

Allow Admins to review permitted safe activity and audit records without permitting edits or deletion.

#### Layout description

Use a time-ordered table or list with event, actor role, target type, target ID, result, and timestamp. Event values remain fixed uppercase in stored data: `LOGIN_SUCCESS`, `REQUEST_CREATED`, `REQUEST_ASSIGNED`, `REQUEST_UPDATED`, `AUTHORIZATION_FAILED`, and `DATABASE_ERROR`.

#### UI elements

- Event list/table.
- Event label.
- Actor role display.
- Target type and safe target ID.
- Result.
- Timestamp.
- Optional supported filters.
- Loading, empty, error, and retry states.

#### User actions

- Browse permitted activity.
- Apply supported filters.
- Open safe target context where finalized.
- Retry failed load.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Show activity-row skeletons. |
| Empty | Explain that no activity is available. |
| Error | Show safe banner and Retry. |
| Permission denied | Show safe message and return to Dashboard. |
| — | — |

#### ASCII wireframe

```text
+---------------------------------------------------------------+
| QuickServe Admin | Activity / Audit                          |
+------------------+--------------------------------------------+
| Navigation        | Event              Actor  Target  Result   |
|                   | REQUEST_UPDATED    Admin  request success |
|                   | REQUEST_ASSIGNED   Admin  request success |
|                   | AUTHORIZATION_FAILED Agent request denied |
|                   | [loading / empty / error state]           |
+-------------------+--------------------------------------------+
```

#### Role restrictions

Only Admin may read permitted audit activity. No role may update or delete existing audit records through the client. The view must not render secrets, tokens, passwords, API keys, or raw exception payloads.

### Admin Logout — action

#### Purpose

End the Admin Firebase Authentication session and return to Admin Login.

#### Layout description

Expose Logout from the Admin shell user menu or navigation area. Use a concise confirmation dialog if the finalized interaction requires confirmation.

#### UI elements

- User menu or Logout action.
- Optional confirmation dialog.
- Progress state.
- Safe error message.

#### User actions

- Select Logout.
- Confirm or cancel.

#### Loading, empty, and error states

| State | Behavior |
|---|---|
| Loading | Disable repeated sign-out actions. |
| Empty | Not applicable. |
| Error | Show safe sign-out error and allow retry. |
| Success | Clear role-dependent state and return to Admin Login. |

#### ASCII wireframe

```text
+------------------------------------------------+
| QuickServe Admin                         [ v ] |
|                                                |
| User menu                                      |
|   Dashboard                                    |
|   Logout                                       |
+------------------------------------------------+
```

#### Role restrictions

Logout is available to the authenticated Admin and does not modify Firestore records.

## Reusable Components

| Component | Usage | Required behavior |
|---|---|---|
| Status chip | Request cards, detail headers, Admin tables | Displays readable status while preserving lowercase stored value; never relies on color alone |
| Priority chip | Create Request, request cards, detail headers, Admin tables | Displays Low, Medium, or High with text and accessible semantics |
| Request card | My Requests and Agent queue | Shows request code, service type, status, priority, and a clear navigation affordance |
| Request detail header | Customer and Agent details, Admin request details | Groups request code, service type, status, and priority consistently |
| Status timeline | Customer Request Details, Agent Request Details, Admin detail context | Orders append-only history and exposes safe notes according to role policy |
| Primary action button | Create Request, status action, Login, Admin Login | One dominant action per view; disabled during pending write |
| Secondary action | Back, Clear, Retry, Profile navigation | Lower emphasis and clear labels |
| Empty state | Lists and dashboard areas | Explains why content is empty and offers the next valid action |
| Error banner | Screen-level load and permission errors | Safe message, visible recovery action, no internal Rules or stack details |
| Inline field error | Forms | Appears near the invalid field and explains correction |
| Loading skeleton | Lists, detail views, dashboard tables | Preserves layout while data loads and avoids misleading blank screens |
| Confirmation dialog | Logout, cancellation, status action where required | States the consequence and provides Cancel and Confirm actions |
| Snackbar | Short success or non-blocking feedback | Announces result without replacing persistent detail state |
| Responsive navigation shell | Mobile and Admin Web | Keeps role-appropriate destinations visible without exposing unauthorized screens |

## Navigation Patterns

### go_router route structure

Use route names and guards rather than embedding authorization decisions in arbitrary widgets. The exact Dart file structure may vary, but the route tree should separate public, mobile, and admin destinations.

```text
/public
  /login
  /registration
  /password-reset

/mobile
  /home
  /services
  /create-request
  /my-requests
  /requests/:requestId
  /agent-requests/:requestId
  /profile

/admin
  /login
  /dashboard
  /requests
  /customers
  /agents
  /activity-audit
```

The finalized screen names remain Login, Registration, Home, Services, Create Request, My Requests, Request Details, Agent Request Details, Profile, Admin Login, Admin Dashboard, Admin Request Management, Admin Customer View, Admin Agent View, and Admin Activity/Audit View. Password reset and confirmation dialogs are actions or subflows, not additional finalized product screens.

### Route redirect behavior

| Condition | Redirect behavior |
|---|---|
| No Firebase session on protected route | Login or Admin Login according to requested client entry |
| Session exists, profile loading | Splash or guarded loading state |
| Profile missing | Safe recovery or sign-out; do not infer a role |
| `users.role == customer` | Customer mobile Home and customer routes |
| `users.role == agent` | Agent mobile queue and Agent routes |
| `users.role == admin` | Admin Dashboard and Admin routes |
| Role attempts wrong client route | Redirect to role-appropriate entry route |
| Logout success | Clear providers and return to the correct Login screen |

### Navigation state preservation

Preserve non-sensitive form input when a recoverable network or validation error occurs. Do not persist passwords, tokens, or secrets. Clear role-dependent state on logout and when the authenticated UID changes.

## Responsive Behavior

### Breakpoint guidance

The following are implementation guidance rather than new product requirements. The UI should respond to available width instead of assuming a particular device model.

| Width category | Layout behavior |
|---|---|
| Mobile | Single-column forms, top app bar, bottom or compact navigation, vertically scrolling cards, full-width primary actions |
| Tablet | Wider constrained forms, two-column content where readable, navigation rail where useful, larger request card content |
| Desktop Web | Admin navigation rail or side navigation, multi-column dashboard, table/list plus detail area, keyboard-friendly filters |
| Very wide Web | Constrain reading width, keep tables usable, avoid excessive line length, retain visible navigation and actions |

### Mobile to Web adaptation

- Mobile request cards can become Admin table rows.
- Mobile detail sections can become Admin detail panels.
- Bottom navigation becomes a navigation rail or side navigation on Web.
- Modal forms should remain keyboard accessible and avoid requiring horizontal scrolling.
- Admin tables should provide responsive fallback to stacked rows at narrow widths.

## Accessibility Notes

### Semantics and labels

Every input has a visible label and a semantic field name. Every icon-only control has an accessible label. Status and priority chips expose their text value to assistive technologies.

### Contrast and non-color cues

Text and controls must maintain readable contrast under the selected Material 3 theme. Do not use color as the only distinction between `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`, or between priorities.

### Text scaling

Support system text scaling without clipping critical controls. Long descriptions, addresses, errors, and audit values must wrap or scroll appropriately. Avoid fixed-height containers that hide validation messages.

### Tap and click targets

Interactive mobile controls should have comfortable touch targets and sufficient spacing. Web controls must have visible keyboard focus and logical tab order.

### Keyboard navigation on Web

Admin Web forms, filters, tables, navigation, dialogs, and Logout must be keyboard reachable. Escape should close a dismissible dialog where appropriate. Focus should move predictably after route changes and validation errors.

### Motion and feedback

Progress indicators must not be the only indication of a long-running operation. Respect reduced-motion preferences where supported and ensure that status changes are also conveyed textually.

## Localization and Formatting

### Dates and times

Firestore timestamps remain authoritative. The UI formats preferred date/time and history timestamps using the user's locale and a consistent readable pattern. The implementation must preserve timezone meaning and avoid presenting a local time without context when the distinction matters.

### Request codes

Display request codes exactly in the format `REQ-YYYY-000123`. Do not localize the letters, separators, or zero-padding.

### Status and role labels

Stored values remain lowercase: `customer`, `agent`, `admin`, `created`, `assigned`, `accepted`, `in_progress`, `completed`, and `cancelled`. Display labels may use title case or readable spacing, such as Customer, Agent, Admin, In Progress, and Cancelled.

### Priority labels

Stored values remain `low`, `medium`, and `high`. Display labels are Low, Medium, and High. The UI must not silently change enum values through localization.

### Pluralization

Use locale-aware pluralization for counts such as “1 request” and “2 requests.” Zero states should use an explicit empty-state sentence rather than relying only on a numeric zero.

### Text direction and long content

Fields such as description, address, service name, and audit target values must wrap and remain readable when translated or when users enter longer text. Avoid truncation that hides the meaning of a status or error.

## Screen-to-Requirement Traceability

The following table uses finalized requirement identifiers already established in the Requirements Checklist. TEST-07 and TEST-08 are RBAC cross-references and are not redefined here.

| Screen or action | Role | Requirement ID(s) |
|---|---|---|
| Splash | Customer, Agent | FR-C-01, FR-AUTH-05, NFR-06 |
| Login | Customer, Agent | FR-AUTH-03, FR-AUTH-05, NFR-06 |
| Registration | Customer | FR-AUTH-01, FR-AUTH-02, NFR-02 |
| Home — Customer view | Customer | FR-C-02, FR-AUTH-05 |
| Home — Agent view | Agent | FR-A-01, FR-AUTH-05 |
| Services | Customer | FR-C-03, NFR-06 |
| Create Request | Customer | FR-C-04, FR-C-05, FR-C-06, FR-C-07, FR-C-08, NFR-05 |
| My Requests | Customer | FR-C-09, TEST-07, NFR-06 |
| Request Details | Customer | FR-C-10, FR-C-11, FR-C-12, TEST-07, NFR-01 |
| Agent Request Details | Agent | FR-A-02, FR-A-03, FR-A-04, FR-A-05, FR-A-06, FR-A-07, FR-A-08, TEST-08 |
| Profile | Customer, Agent | FR-C-13, FR-AUTH-04, NFR-06 |
| Logout | Customer, Agent | FR-AUTH-04, FR-AUTH-05 |
| Admin Login | Admin | FR-AD-LOGIN-01, FR-AUTH-03, FR-AUTH-05 |
| Admin Dashboard | Admin | FR-AD-01, FR-AD-02, NFR-06 |
| Admin Request Management | Admin | FR-AD-03, FR-AD-04, FR-AD-05, FR-AD-06, FR-AD-07, NFR-01 |
| Admin Customer View | Admin | FR-AD-08, FR-AD-11, NFR-02 |
| Admin Agent View | Admin | FR-AD-09, FR-AD-11, NFR-02 |
| Admin Activity/Audit View | Admin | FR-AD-10, FR-AD-11, NFR-01, NFR-02 |
| Admin Logout | Admin | FR-AUTH-04, FR-AUTH-05 |

## Open Questions and Assumptions

### Open questions

| ID | Question | UX impact | Default assumption |
|---|---|---|---|
| OQ-01 | Which exact statuses are customer-cancellable? | Controls the Cancel action in Request Details. | `created` and `assigned` only, per PRD Assumption A-03. |
| OQ-02 | Which Admin status actions are operationally permitted? | Controls action visibility in Admin Request Management and detail views. | Display only actions allowed by the finalized RBAC and lifecycle documents. |
| OQ-03 | Is free-text Admin search required, or are supported filters sufficient? | Controls search controls and query behavior. | Use only bounded Firestore-supported search/filter behavior. |
| OQ-04 | Are status-history notes visible to Customers? | Controls timeline content projection. | Follow the finalized PRD and RBAC decision; do not expose notes by assumption. |
| OQ-05 | Is the initial status-history record displayed to users? | Controls timeline empty and initial-state presentation. | Display the finalized history records permitted for the role. |

### Assumptions

| ID | Assumption |
|---|---|
| ASSUMP-01 | The mobile Home screen is role-aware and renders Customer or Agent content after `users.role` resolution. |
| ASSUMP-02 | Admin Request Management opens request details through the finalized Admin Web route without creating a new screen name. |
| ASSUMP-03 | The client uses Riverpod providers for authentication, profile, services, requests, loading, empty, and error state. |
| ASSUMP-04 | go_router responds to Firebase session changes and profile resolution state. |
| ASSUMP-05 | The screen list in this document is final; password reset, confirmation dialogs, and error surfaces are actions or states rather than new product screens. |
| ASSUMP-06 | No client screen displays passwords, tokens, API keys, or secrets. |
| ASSUMP-07 | The Admin Web portal uses supported Firestore queries and does not require a new search service. |
| ASSUMP-08 | The final implementation uses the Firebase Emulator Suite for local UI and authorization integration testing. |

## Glossary

| Term | Definition |
|---|---|
| Agent | User with stored role value `agent`, using Flutter mobile to manage assigned work. |
| Admin | User with stored role value `admin`, using Flutter Web for permitted operations. |
| Customer | User with stored role value `customer`, using Flutter mobile to create and track requests. |
| Empty state | UI state shown when a valid query returns no records. |
| Error banner | Persistent safe message for a screen-level failure with a recovery action. |
| Loading skeleton | Placeholder structure shown while content is loading. |
| Material 3 | Flutter's finalized component and theme system for this project. |
| Request code | Human-readable identifier in the format `REQ-YYYY-000123`. |
| Request card | Reusable compact representation of a request in a list or queue. |
| Role routing | Navigation based on the authenticated user's valid stored value in `users.role`. |
| Status chip | Reusable text-bearing indicator for a request status. |
| Stored value | Lowercase enum value persisted in the application's data contract. |
| Terminal status | `completed` or `cancelled`, with no outgoing lifecycle transition. |

## Appendix A — Mobile Navigation Map {.unnumbered}

```text
[ Splash ]
    |
    v
[ Login ] ----> [ Registration ]
    |
    +----> [ Password reset action ]
    |
    v
[ users.role resolution ]
    |
    +-----------------------------+
    |                             |
 customer                      agent
    |                             |
    v                             v
[ Home ]                       [ Home ]
    |                             |
    +--> [ Services ]             +--> [ Agent Request Details ]
    |         |                   |         |
    |         v                   |         +--> Accept
    +--> [ Create Request ]       |         +--> in_progress
    |         |                   |         +--> completed
    |         v                   |         +--> Add note
    +--> [ My Requests ]          |
              |                   +--> [ Profile ]
              v                             |
       [ Request Details ]                  +--> [ Logout ] --> [ Login ]
              |
              +--> Cancel if status is created or assigned
              |
              +--> [ Profile ]

[ Profile ] --> [ Logout ] --> [ Login ]
```

## Appendix B — Admin Navigation Map {.unnumbered}

```text
[ Admin Login ]
       |
       v
[ users.role == admin ]
       |
       v
[ Admin Dashboard ]
       |
       +--> [ Admin Request Management ]
       |          |
       |          +--> Search / filter
       |          +--> Open request details
       |          +--> Assign Agent
       |          +--> Update permitted status
       |
       +--> [ Admin Customer View ]
       |
       +--> [ Admin Agent View ]
       |
       +--> [ Admin Activity/Audit View ]
       |
       +--> [ Admin Logout ] --> [ Admin Login ]
```

## Appendix C — Screen Inventory {.unnumbered}

| Client | Screen/action | Role | Primary responsibility |
|---|---|---|---|
| Flutter mobile | Splash | Customer, Agent | Resolve session and profile before routing |
| Flutter mobile | Login | Customer, Agent | Authenticate with email/password |
| Flutter mobile | Registration | Customer | Create Firebase account and customer profile |
| Flutter mobile | Home | Customer | Start service and request journeys |
| Flutter mobile | Home | Agent | Present assigned work queue |
| Flutter mobile | Services | Customer | Browse active service types |
| Flutter mobile | Create Request | Customer | Submit finalized request fields |
| Flutter mobile | My Requests | Customer | Read own requests |
| Flutter mobile | Request Details | Customer | Read owned request and eligible cancellation |
| Flutter mobile | Agent Request Details | Agent | Manage assigned request lifecycle |
| Flutter mobile | Profile | Customer, Agent | Read/update permitted profile fields |
| Flutter mobile | Logout action | Customer, Agent | Sign out and return to Login |
| Flutter Web | Admin Login | Admin | Authenticate before portal access |
| Flutter Web | Admin Dashboard | Admin | View operational overview |
| Flutter Web | Admin Request Management | Admin | Search, filter, assign, and update permitted requests |
| Flutter Web | Admin Customer View | Admin | View permitted customer data |
| Flutter Web | Admin Agent View | Admin | View permitted agent data |
| Flutter Web | Admin Activity/Audit View | Admin | View permitted safe activity records |
| Flutter Web | Admin Logout action | Admin | Sign out and return to Admin Login |

## Appendix D — Companion Documentation Set {.unnumbered}

1. PRD (Product Requirements Document) — finalized.
2. Requirements Checklist / Traceability.
3. System Architecture Document.
4. Database Design Document.
5. RBAC & Security Document.
6. User Flow Diagram.
7. Request Lifecycle / State Diagram.
8. UI/UX Wireframes — this document.
9. Testing Plan.
10. README / Setup & Deployment Documentation.
