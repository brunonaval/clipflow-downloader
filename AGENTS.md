# AGENTS.md — ClipFlow Downloader

Rules for all AI-assisted development rounds on this project.

## Scope

- Work in small, incremental changes. One concern per round.
- Do not implement anything not explicitly requested in the current round prompt.
- Do not create intermediate planning documents or analysis files unless requested.

## Dependencies

- Do not add any package to `pubspec.yaml` (dependencies or dev_dependencies) without an explicit instruction in the round prompt.
- Do not update SDK constraints beyond what `flutter create` generated, unless explicitly asked.

## Builds and Execution

- Do not run `flutter build` (release, profile, or any target) unless explicitly asked.
- Do not launch emulators, simulators, or physical device runs unless explicitly asked.
- `dart analyze` and `flutter test` are always safe to run and should be run after code changes.

## Legal and Ethical

- Do not implement any feature that facilitates bypassing DRM, paywalls, authentication, or access controls.
- Do not implement credential or cookie harvesting.
- Do not use, reference, or copy assets, names, icons, or UI patterns from proprietary third-party applications.
- Do not use the name, branding, or visual identity of any commercial product in code, UI, docs, or comments.

## Code Quality

- Always run `dart analyze` after modifying any Dart file. Fix all introduced errors.
- Always run `flutter test` when test files exist or were modified.
- Do not leave debug print statements (`print(...)`) in committed code unless the round explicitly asks for logging.
- Do not add code comments that only restate what the code already says.

## Encoding

- All files must be UTF-8 encoded with no BOM artifacts.
- Before finalizing, verify no mojibake characters were introduced:
  ```
  rg "Ã|Â|ðŸ|â€|â€¢|âœ" README.md docs AGENTS.md lib test pubspec.yaml
  ```

## Git

- Do not commit unless the round prompt explicitly requests a commit.
- Do not push unless the round prompt explicitly requests a push.
- Do not create branches unless the round prompt explicitly requests it.
- Do not modify `.gitconfig` or any global git settings.

## Reporting

End every round with an objective report including:
- Files read, created, modified
- Commands executed and results
- Blockers or warnings
- No padding, no unnecessary summaries of what was already shown
