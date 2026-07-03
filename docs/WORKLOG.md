# Work Log

## 2026-07-03

### Column View Stability Fix

- Fixed a column-view crash where switching into column view could trigger an AppKit layout exception and leave the window unusable.
- Rebuilt the column-view document area with explicit frame-based column sizing instead of relying on stack-view constraints inside a scroll view.
- Added core coverage for column-view document sizing and column placement.

### External Volume Directory Loading

- Replaced the directory URL enumerator used for top-level folder loading with a lighter content provider based on `contentsOfDirectory(atPath:)`.
- This avoids hangs observed when reading some removable SSD volumes through the heavier Foundation URL enumerator.
- Hidden dotfiles and Finder-hidden entries, including system folders such as `$RECYCLE.BIN` and `System Volume Information`, remain hidden by default.
- Added regression coverage for injected directory content providers and Finder-hidden item filtering.

### Hot-Plug Volume Refresh Fix

- Fixed a sidebar refresh gap where an external SSD inserted while SmartFinder was already open would not appear until the window was closed and reopened.
- Added a mounted-volume sidebar refresh policy covering macOS workspace mount, unmount, and volume rename notifications.
- Main windows now subscribe to those workspace notifications and rebuild the sidebar when the mounted-volume set changes.
- If a volume is unmounted while the current folder is inside that volume, SmartFinder navigates back to the user's home folder before refreshing the sidebar.
- Added regression coverage for the notification names that should trigger a sidebar refresh.

### Version And Packaging

- Next packaged DMG: `SmartFinder-0.8.5.dmg`

## 2026-07-02

### Project Goal

SmartFinder for Mac was created as a lightweight native macOS folder browser for a specific Finder limitation: Finder can show thumbnails, but it does not provide a simple per-file-type rule such as "show real previews for photos and RAW files, but keep PDFs, spreadsheets, archives, and code as clean system icons."

The project intentionally stays in the companion-tool category. It does not try to replace the macOS Desktop, file picker, Spotlight, iCloud Drive, or system "Show in Finder" behavior.

### Main Decisions

- Build a separate Finder-like native window instead of trying to modify Finder internals.
- Use AppKit and Swift Package Manager to keep the app small and easy to build.
- Keep image, RAW photo, and supported video files thumbnail-eligible.
- Keep PDF, Office, archive, audio, code, Markdown, and unknown files on system icons by default.
- Avoid full-disk indexing, recursive folder scanning, and background document thumbnail pre-rendering.
- Keep the visual style familiar to macOS users without copying Finder pixel-for-pixel.
- Support external volumes in the sidebar, including eject buttons.
- Use real Finder color labels for tags where macOS exposes them.
- Localize the interface for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Italian, and Portuguese.

### Implemented Scope

- Finder-like icon view, list view, and lightweight column view.
- Selective thumbnail strategy for photos, RAW files, and videos.
- System default icons for PDFs, Office files, archives, audio, code, Markdown, and unknown files.
- Back, forward, and parent-folder navigation.
- Responsive toolbar with direct view-mode controls on wider windows.
- Sidebar with common locations and mounted volumes.
- Breadcrumb path bar and editable path field.
- Sorting by name, type, size, and modified date, with ascending or descending direction.
- Search within the current folder.
- Quick Look from Space and Command-Y.
- Common file actions: new folder, rename, move to Trash, copy, paste, copy path, compress, reveal in Finder, Get Info, Copy To, Move To, New Text File, and New Markdown File.
- Drag and drop for moving files, with Option-copy behavior.
- Sidebar drop targets for quick moves or copies.
- Context menus for common folder and file actions.
- Status bar with selected file byte size and available disk space.
- Demo folder and screenshot for the GitHub README.
- DMG packaging script and ad-hoc signed local app bundle.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.3.dmg`
- Latest tag: `v0.8.3`
- Minimum supported macOS: macOS 13 Ventura
- GitHub repository: `nevicia2010-hub/SmartFinder-Mac`
- License: MIT

### Verification Completed

- `swift build`
- `swift run SmartFinderCoreTests`
- localization string validation
- package validation through `scripts/check_package.sh`
- manual UI checks through macOS automation and Computer Use after reconnecting the plugin
- GitHub repository visibility, description, topics, README screenshot, release asset, and renamed repository URL

### Known Boundaries

- SmartFinder is not a system Finder replacement.
- It does not control Finder's built-in thumbnail policy.
- RAW thumbnail generation still depends on macOS Quick Look and the RAW codecs available on the current system.
- PDF, Office, archive, audio, code, Markdown, and unknown files are intentionally not rendered as document thumbnails.
- The app is ad-hoc signed and not notarized, so macOS may show a first-launch warning on other machines.
- Search discovery may take time because the repository is new and the original `SmartFinder` name is crowded with unrelated projects.

### Discovery Improvements

- Repository renamed from `SmartFinder` to `SmartFinder-Mac`.
- README title changed to `SmartFinder for Mac`.
- GitHub topics added: `macos`, `finder`, `quicklook`, `thumbnail`, `thumbnails`, `raw-photo`, `file-manager`, `swift`, `appkit`, `finder-alternative`, and `photography`.
- Repository description updated to clarify the selective-thumbnail purpose.
