# Work Log

## 2026-07-05

### Finder-Like Get Info Window

- Replaced the previous modal `NSAlert` Get Info display with a separate non-modal information window.
- Added a tested core presentation model for Finder-style information sections: General, Name & Extension, Path, and System.
- The new window shows a larger system icon, the selected item name, kind, size, parent location, dates, name, extension, full path, and type identifier when available.
- Copy affordances were added for path-style fields, plus footer actions for Copy Path, Reveal in Finder, and Close.
- The window is created only when Get Info is requested and uses existing file metadata and system icons; it does not start thumbnail generation, recursive folder scans, or a persistent inspector process.
- Added localized labels for the new Get Info window in all existing UI languages.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.11.dmg`
- Latest tag: `v0.8.11`

## 2026-07-03

### Disk Image Sidebar Refresh Fix

- Fixed a sidebar refresh gap observed after opening and exiting macOS installer disk images.
- Added `NSWorkspaceWillUnmountNotification` to the mounted-volume refresh policy so SmartFinder reacts before virtual installer volumes disappear.
- Changed mounted-volume notifications to schedule immediate and delayed sidebar refresh passes at 0, 0.4, and 1.2 seconds.
- This keeps refresh work event-driven and avoids background scanning while giving macOS time to settle the mounted-volume list after DMG attach/detach operations.
- Added core regression coverage for installer-style will-unmount notifications and delayed refresh scheduling.

### Public Documentation Audit

- Reviewed the live GitHub repository README, release notes, repository description, and localization resources.
- Clarified the public tool definition: SmartFinder is a free, open-source Finder companion, MIT-licensed, and not a commercial file manager.
- Added a bilingual first-launch security notice explaining that the app is ad-hoc signed, not Apple Developer ID signed, and not Apple-notarized.
- Confirmed the README explains the core purpose, selective thumbnail strategy, Finder boundary, system requirements, supported UI languages, packaging, and resource-use approach.
- Confirmed all UI localization files parse correctly and share the same key set across English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Italian, and Portuguese.

### Convenience Pass Two

- Added status-bar feedback for mounted-volume eject actions, including started, succeeded, and failed states.
- Extended the details pane with selected-photo EXIF basics such as camera, lens, dimensions, ISO, focal length, aperture, and shutter speed.
- Kept photo metadata reads gated behind the visible details pane so normal browsing does not read metadata for every selection.
- Added on-demand, cancellable folder-size calculation for a single selected folder.
- Added a default-off dual-pane mode for drag-and-drop folder work; the secondary pane loads only when the mode is opened.
- Added localizations and core coverage for eject feedback, photo metadata parsing, folder-size calculation/cancellation, and dual-pane loading policy.

### Community Feature Pass

- Added adaptive column widths so column view expands for visible long file names while clamping very long names to avoid swallowing the full window.
- Added a small file-template catalog and wired New Text File, New Markdown File, and New CSV File through toolbar, context menu, and menu bar actions.
- Added enhanced path copying: full path, parent path, and shell-escaped path for Terminal use.
- Added localizations for the new template and path-copy menu items across all existing UI languages.
- Added core coverage for adaptive column sizing, template creation with collision-safe names, CSV contents, and copy-path formatting.

### Column View Local Navigation

- Changed column-view folder selection to update the right-side columns in place instead of running a full folder reload.
- The path field, title, breadcrumb, and history still update when a folder is selected in column view.
- This avoids the visible whole-window flash caused by clearing all items before loading the selected folder.
- Added core coverage for replacing stale right-side columns while preserving the left-side column stack.

### System Appearance Refresh

- Added a lightweight system appearance refresh path for automatic light/dark mode changes.
- SmartFinder now listens for macOS interface theme changes and effective appearance updates on the main window.
- The refresh only reapplies visible UI colors, toolbar symbols, active cells, lists, columns, and the details pane; it does not rescan folders or regenerate thumbnails.

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

- Current released DMG: `SmartFinder-0.8.10.dmg`
- Latest tag: `v0.8.10`

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
- Common file actions: new folder, rename, move to Trash, copy, paste, copy path, copy parent path, copy shell path, compress, reveal in Finder, Get Info, Copy To, Move To, New Text File, New Markdown File, and New CSV File.
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
