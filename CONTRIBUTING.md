# Contributing to QuickServe

Thank you for your interest in QuickServe. This is an internship assignment project, but contributions, feedback, and reviews are welcome.

## Repository Layout

```
quickserve/
├── apps/
│   ├── mobile/       Flutter mobile app (Customer + Agent)
│   └── admin/        Flutter Web admin portal
├── packages/
│   └── shared/       Shared Dart package (models, enums, validators)
├── docs/             Project documentation (PRD, architecture, security, etc.)
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
├── .firebaserc
└── README.md
```

## Getting Started

See [docs/QuickServe_README_Setup_Deployment.md](docs/QuickServe_README_Setup_Deployment.md) for full setup instructions.

## Branch Naming

Use short, descriptive branch names:

- `feature/customer-request-form`
- `feature/agent-status-flow`
- `fix/firestore-rules-denial`
- `chore/emulator-test-data`
- `docs/update-architecture-diagram`

Do not include passwords, tokens, or personal secrets in branch names.

## Commit Message Convention

Follow the [Conventional Commits](https://www.conventionalcommits.org/) style:

- `feat:` — a new feature
- `fix:` — a bug fix
- `chore:` — maintenance, config, tooling
- `docs:` — documentation only
- `test:` — adding or updating tests
- `refactor:` — code change that neither fixes a bug nor adds a feature

Examples:

```
feat: add customer request form validation
fix: restrict customer cancellation transitions
test: add Firestore ownership denial coverage
docs: update RBAC rules explanation
chore: bump Flutter SDK constraint
```

Keep each commit focused on one coherent change.

## Pull Requests

A pull request should include:

- A short summary of the implementation.
- Screens or flows affected.
- Tests run and the environment they ran in.
- Rules and emulator evidence for authorization changes.
- Any known limitation or open question.
- Confirmation that no secrets or generated files were committed.

Keep pull requests focused and reviewable. Do not merge a UI-only authorization change without corresponding Firestore Rules tests when the data boundary is affected.

## Testing

Before opening a pull request:

1. Run `flutter analyze` inside the affected Dart project(s).
2. Run `flutter test` inside the affected Dart project(s).
3. Run Rules tests against the Firebase Emulator Suite if Security Rules changed.

## Security

Never commit:

- Passwords
- Authentication tokens
- API keys
- Private keys or service-account JSON
- Local seed files containing credentials
- Production environment files containing secrets

Use environment variables or ignored local files for anything sensitive. See the RBAC & Security Document for the full policy.

## Code Style

- Follow the settings in `.editorconfig`.
- Use Material 3 for any UI.
- Keep widgets small and composable.
- Share domain logic through `packages/shared`.
- Do not duplicate business rules between the mobile app and the admin portal.

## Questions

Open an issue or reach out through the repository.

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see `LICENSE`).