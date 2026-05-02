# ClipFlow Downloader — Codex Development Workflow

This project is developed in small, focused incremental rounds using AI-assisted coding (Codex / Claude Code).

## Round Structure

Every development round must follow this sequence:

### 1. Confirm Branch

```bash
git branch
git status --short
```

If there are uncommitted changes not belonging to the current task, stop and report before proceeding.

### 2. Confirm Directory

```bash
pwd
```

All changes must remain within the project directory. Never modify files outside it.

### 3. Make Minimal Changes

- Implement only what the current round explicitly asks for.
- Do not add dependencies, features, or refactors beyond the round scope.
- Do not add external packages without an explicit prompt instruction.
- Do not run release builds or emulators.

### 4. Run Analysis

After any change to Dart code:

```bash
dart analyze
```

Fix all errors and warnings before proceeding. Warnings are acceptable only if already present in the unmodified project and are not introduced by this round's changes.

### 5. Run Tests

If test files exist or were modified:

```bash
flutter test
```

All tests must pass before the round is considered complete.

### 6. Verify Encoding

Before finalizing, verify no mojibake or encoding artifacts were introduced:

```bash
rg "Ã|Â|ðŸ|â€|â€¢|âœ" README.md docs AGENTS.md lib test pubspec.yaml
```

All documentation and source files must be valid UTF-8 with no encoding artifacts.

### 7. Report

End every round with a concise, objective report listing:

- Files read
- Files created or modified
- Commands executed and their outcomes
- Any blockers encountered
- Next suggested step (optional)

## Commit Policy

**Do not commit unless the round prompt explicitly requests a commit.**

When a commit is requested, use a single, descriptive commit message in English. Never amend published commits.

## Scope Discipline

If the round prompt is ambiguous about scope, do the minimum interpretation. When in doubt, do less and report.
