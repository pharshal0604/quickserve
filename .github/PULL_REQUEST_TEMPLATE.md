# Pull Request

## Summary

Briefly describe what this pull request does and why.

## Scope of Change

- [ ] Mobile app (`apps/mobile`)
- [ ] Admin web portal (`apps/admin`)
- [ ] Shared Dart package (`packages/shared`)
- [ ] Firestore Rules or indexes
- [ ] Documentation (`docs/`)
- [ ] Repository configuration (CI, gitignore, editorconfig, etc.)

## Type of Change

- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `chore` — maintenance, config, tooling
- [ ] `docs` — documentation only
- [ ] `test` — adding or updating tests
- [ ] `refactor` — code change that neither fixes a bug nor adds a feature

## Affected Screens or Flows

List any UI screens, user flows, or API paths this change touches.

- Example: `apps/mobile/lib/screens/create_request_screen.dart`
- Example: `firestore.rules` — customer cancellation branch

## Tests Run

Describe how this change was tested and in what environment.

- [ ] `flutter analyze` — passed
- [ ] `flutter test` — passed
- [ ] `flutter test integration_test` — passed (if applicable)
- [ ] Firestore Rules tests against the Emulator Suite — passed (if applicable)
- [ ] Manual UI walkthrough — completed

Include the exact commands you ran and the environment (Flutter version, emulator version, OS).

## Firestore Rules and Security

If this PR touches `firestore.rules`, `firestore.indexes.json`, or any Firestore access pattern, provide:

- Summary of rule changes.
- Direct allow/deny test results from the Emulator Suite.
- Confirmation that no client-side UI change alone authorizes a new operation.

If no rules changes, write: **N/A**.

## Known Limitations

List any known gaps, TODOs, or follow-up work that is deliberately out of scope for this PR.

If none, write: **None**.

## Secrets Check

Confirm:

- [ ] No passwords, tokens, API keys, or service-account JSON committed.
- [ ] No `.env` files or local seed files with credentials committed.
- [ ] `.gitignore` still excludes all local-only files.
- [ ] No generated build output or `.dart_tool` folders added.

## Related Issues

Closes #
References #

## Checklist

- [ ] My code follows the project's `.editorconfig` and `CONTRIBUTING.md`.
- [ ] I have performed a self-review of my changes.
- [ ] I have commented complex code where necessary.
- [ ] I have updated documentation if behavior changed.
- [ ] I have added or updated tests where practical.
- [ ] My commits follow the Conventional Commits style.