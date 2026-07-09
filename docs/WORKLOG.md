# Work Log

## 2026-07-09

### Trash Navigation Fix

- Fixed a column-view bug where right-clicking a folder could navigate into that folder before moving it to Trash.
- After a successful Trash operation, SmartFinder now detects when the current folder is the removed folder or one of its descendants and loads the removed folder's parent instead.
- Unaffected Trash operations still refresh the current folder normally.
- Added core coverage for post-removal navigation decisions.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.22.dmg`
- Latest tag: `v0.8.22`

### Multi-Selection Drag Fix

- Preserved multi-selection when starting a drag from an already selected file or folder, so the drag pasteboard keeps all selected items instead of collapsing to one item.
- Kept Command and Shift clicks on their normal selection-changing behavior.
- Enabled multi-selection in column view tables and made column-view selection actions read every selected row in the active column.
- Column navigation still opens a folder on single selection; multi-selection now stays in place for batch dragging.
- Added core coverage for the drag-selection preservation rule.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.21.dmg`
- Latest tag: `v0.8.21`

### Folder Drop Target Fix

- Improved in-window drag-and-drop so dropping folder A onto folder B targets folder B even when AppKit reports the proposed drop as an insertion position.
- Applied the same hit-tested folder target rule to icon view, list view, and column view.
- Default drag still moves the item into the target folder; Option-drag still copies.
- Added core coverage for the folder-drop target rule so regular files and empty space continue targeting the current folder.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.20.dmg`
- Latest tag: `v0.8.20`

### Context Menu Open With

- Added a Finder-style Open With submenu to the file context menu for a single selected file.
- The submenu lists macOS applications that can open the selected file, using the default handler first.
- Added an `Other...` entry so users can choose an app bundle manually, such as Photoshop for a PDF, without changing the system default application.
- Kept the action unavailable for folders, empty selection, and multi-selection to avoid ambiguous opens.
- Added core coverage for the single-file Open With availability rule and localized the new menu item across all bundled languages.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.19.dmg`
- Latest tag: `v0.8.19`

## 2026-07-07

### Column View Creation Target Fix

- Changed column-view creation actions so New Folder, New Text File, New Markdown File, and New CSV File target the column the user is working in.
- Right-clicking a column now makes that column's represented folder the creation target.
- Toolbar, menu bar, and shortcut creation actions use the last interacted column when column view is active, falling back to the current folder outside column view.
- Added core coverage for creation target selection so contextual column targets win over the current rightmost folder.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.18.dmg`
- Latest tag: `v0.8.18`

## 2026-07-06

### Column Drag Local Refresh Fix

- Replaced the column-view post-drag whole-browser reload with a local visible-column refresh.
- Dragging files or folders in column view now reloads only directories affected by the transfer, keeping the rest of the column stack mounted in place.
- Added transfer refresh-scope coverage so column-view transfers choose visible-column updates while icon/list views still reload the current folder only when it changed.
- This reduces the visible flash after drag-and-drop without returning to the stale-path behavior fixed in `0.8.16`.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.17.dmg`
- Latest tag: `v0.8.17`

### Column Drag Move Semantics Fix

- Fixed a drag-and-drop bug where moving a file or folder could incorrectly create a destination named with `copy`.
- Root cause: the move path reused the copy destination-name helper, so a normal move behaved like "keep both" copy naming instead of preserving the original item name.
- Added transfer planning coverage that removes duplicate source URLs from a single drag operation so one drop cannot move the same item twice.
- Changed transfer refresh handling so successful column-view moves refresh the visible column path after the operation instead of leaving stale rows pointing to old paths.
- This is not a macOS drag-and-drop limitation; the issue was in SmartFinder's transfer naming and refresh logic.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.16.dmg`
- Latest tag: `v0.8.16`

## 2026-07-05

### File Drag Source Fix

- Fixed an interaction bug where dragging files or folders from SmartFinder's browser area did not start reliably.
- The browser already registered file URL drop types, but the icon view, list view, and column view were not explicitly configured as drag sources.
- Added shared drag-source policy coverage requiring both move and Option-drag copy operations.
- Applied that drag-source policy to the icon collection view, the list table view, and every column-view table.
- The existing drop/transfer path remains unchanged: normal drag moves files, Option-drag copies files, and invalid folder drops such as dropping a folder into itself are still rejected.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.15.dmg`
- Latest tag: `v0.8.15`

### Get Info Alignment Fix

- Reworked the Get Info section layout so section titles stay left-aligned and detail rows sit under a consistent Finder-style indent.
- Changed field labels from right-aligned to leading-aligned to avoid awkward localized text blocks in Chinese and other languages.
- Added a trailing content margin so copy buttons, paths, and type identifiers do not touch the right edge of the window.
- Split the Open With controls into a selectable application row plus a separate action row so the buttons do not force the panel wider than the window.
- Added core layout metrics coverage to guard the alignment and margin rules without adding runtime thumbnail, memory, or GPU work.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.14.dmg`
- Latest tag: `v0.8.14`

### Get Info Default Application Changes

- Added a Finder-style `Change All...` action to the Get Info Open With section.
- Selecting an application in the Open With pop-up still only changes the selected app in the panel.
- The `Open` button still opens the current file once with the selected application.
- The new `Change All...` button asks for confirmation and then uses macOS LaunchServices to make the selected application the default handler for that file content type.
- The button is enabled only when SmartFinder knows both the file content type identifier and the selected application's bundle identifier.
- Added localized confirmation, success, and error messages across all existing UI languages.
- Added core policy coverage for when default application changes should be available.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.13.dmg`
- Latest tag: `v0.8.13`

### Get Info Layout And Open With

- Tightened the Get Info window layout so sections start directly under the header without the large blank gap seen in the first Finder-style attempt.
- Reworked the header into a compact icon, name, modified-date, and size layout closer to macOS Get Info while keeping SmartFinder's own styling.
- Replaced loose row stacks with a more stable label/value layout and smaller spacing.
- Added an Open With section that lists applications macOS reports as able to open the selected file.
- Added an Open button that opens the selected file with the chosen application without changing the system default for that file type.
- Added localized labels for the Open With controls across all existing UI languages.

### Version And Packaging

- Current released DMG: `SmartFinder-0.8.12.dmg`
- Latest tag: `v0.8.12`

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
