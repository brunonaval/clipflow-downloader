# ClipFlow Downloader — Development Roadmap

## Phase 1 — Base Flutter Desktop (current)

- [x] Flutter project created for Windows, macOS, Linux
- [x] Minimal home screen scaffold
- [x] Project documentation (README, legal, workflow, AGENTS)
- [x] Git repository initialized
- [ ] Analysis and tests passing cleanly

## Phase 2 — Desktop Shell UI

- [ ] App window with fixed minimum size
- [ ] Top toolbar / menu bar
- [ ] URL input field (paste link)
- [ ] Download queue list area (empty state)
- [ ] Status bar at the bottom
- Visual style: clean, functional desktop app — no proprietary branding

## Phase 3 — Mock Download Queue

- [ ] Download item model (url, title, status, progress)
- [ ] Queue state management (simple, no external packages initially)
- [ ] Add item to queue via URL input
- [ ] Fake progress simulation for UI validation
- [ ] Cancel / remove item from queue

## Phase 4 — Download Engine Integration (yt-dlp)

- [ ] Evaluate flutter_process or direct Process.run approach
- [ ] Locate or bundle yt-dlp binary
- [ ] Execute yt-dlp with --no-playlist, output path, format selection
- [ ] Parse yt-dlp progress output and feed into queue model
- [ ] Handle errors: unavailable, geo-blocked, format unsupported
- Only for content the user is authorized to download

## Phase 5 — FFmpeg Integration

- [ ] Locate or bundle FFmpeg binary
- [ ] Post-process: merge audio+video streams when needed
- [ ] Format conversion (optional, user-selected)
- [ ] Thumbnail extraction (optional)

## Phase 6 — History and Local Settings

- [ ] Persist download history to local JSON/SQLite
- [ ] Settings screen: default output folder, default format, default quality
- [ ] Clear history action
- [ ] Open output folder shortcut

## Phase 7 — Desktop Packaging

- [ ] Windows: MSIX or NSIS installer
- [ ] macOS: .app bundle / DMG
- [ ] Linux: AppImage or .deb
- [ ] App icon (original, not derived from any proprietary app)
- [ ] Version stamping from pubspec.yaml
