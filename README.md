# ClipFlow Downloader

A Flutter Desktop application for managing downloads of authorized media content.

## About

ClipFlow Downloader is a desktop interface built with Flutter, targeting Windows, macOS, and Linux. The goal is to provide a clean, modern desktop UI for managing media download queues.

**The download engine will be defined and integrated in a future development phase.** This repository currently contains the project structure, base UI scaffold, and documentation.

## Legal Usage

This application is intended **only** for downloading content you are authorized to download, including:

- Your own content
- Content with explicit permission from the rights holder
- Public domain material
- Creative Commons licensed content (where the license permits downloading/redistribution)
- Content where the platform explicitly permits downloading

**This tool must not be used to:**

- Bypass DRM (Digital Rights Management) protection
- Bypass paywalls or subscription restrictions
- Download content without authorization
- Circumvent authentication or access controls
- Collect cookies, passwords, or credentials in any unauthorized manner

See [docs/legal_usage.md](docs/legal_usage.md) for full details.

## Requirements

- Flutter 3.x (stable channel)
- Dart 3.x
- Target platform: Windows, macOS, or Linux

## Getting Started

```bash
# Install dependencies
flutter pub get

# Analyze code
dart analyze

# Run tests
flutter test

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux
```

## Project Structure

```
lib/
  main.dart         # App entry point and home screen
docs/
  roadmap.md        # Development phases
  legal_usage.md    # Permitted and prohibited uses
  codex_workflow.md # Incremental development workflow rules
AGENTS.md           # Rules for AI-assisted development rounds
```

## Development

This project is developed in small, incremental rounds. See [docs/codex_workflow.md](docs/codex_workflow.md) and [AGENTS.md](AGENTS.md) for workflow guidelines.
