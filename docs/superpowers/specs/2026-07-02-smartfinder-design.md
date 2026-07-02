# SmartFinder Design

## Goal

Build a macOS Finder Companion focused on one missing Finder rule: image files should show real thumbnails, while PDF and office-style documents should show stable type icons instead of generated content previews.

This is not a replacement for Finder as a system service. It is a separate macOS app/window that users open when they want predictable icon-view browsing.

## Non-Goals

- Do not replace the macOS Finder process.
- Do not replace the Desktop, file picker, Spotlight, iCloud Drive, or "Show in Finder" system behavior.
- Do not patch Quick Look, IconServices, or private Finder internals.
- Do not generate content thumbnails for PDF, Word, Excel, PowerPoint, Pages, Numbers, or Keynote files.
- Do not build a dual-pane power file manager in the first version.

## Product Shape

The app presents a Finder-like icon view:

- Left sidebar with common locations: Desktop, Downloads, Documents, Pictures, Home, and user-pinned folders.
- Top toolbar with Back, Forward, Up, current path, search field, and icon-size control.
- Main file area as an icon grid.
- Bottom status text showing item count and selection count.

The first version should feel like Finder icon view, not a media library or a commander-style file manager.

## Thumbnail Rules

The renderer classifies files by Uniform Type Identifier when available, falling back to extension only when needed.

- Directories use folder icons.
- Image files show real thumbnails. Initial supported types: jpg, jpeg, png, heic, webp, gif, tiff, bmp.
- PDF and office documents show type icons only. Initial supported types: pdf, doc, docx, xls, xlsx, ppt, pptx, pages, numbers, key.
- Unknown files use system type icons.

Only image files enter the thumbnail generation pipeline. Document files never call Quick Look thumbnail generation.

## Core Interactions

- Double-click folder: open folder in the current window.
- Double-click file: open with the system default app through NSWorkspace.
- Space: open Quick Look preview for the selected file or files.
- Return: rename the selected item.
- Delete or Cmd-Backspace: move selected items to Trash.
- Cmd-C and Cmd-V: copy and paste files.
- Arrow keys: move selection through the grid.
- Cmd-A: select all items in the current folder.
- Search field: filter the current folder first; recursive search can come later.

## System Integration

Version one should support normal app launch from Dock or Spotlight.

Finder-style integration is useful but secondary:

- A Finder service or share extension can add "Open in SmartFinder" for selected folders.
- A menu bar item can quickly open common directories.
- A global shortcut can be added later if the first app experience is solid.

## Architecture

Use Swift with a SwiftUI/AppKit mix.

- SwiftUI: app shell, toolbar, sidebar, settings, and simple dialogs.
- AppKit NSCollectionView: icon grid, selection behavior, keyboard navigation, and drag support.
- FileManager: directory reads, rename, copy, move, and delete operations.
- NSWorkspace: default app opening, system icons, Trash operations, and file metadata.
- QuickLook: preview panel for Space key.
- QuickLookThumbnailing: image thumbnails only.

## Main Components

- AppState: current window state, navigation history, selection, and settings.
- DirectoryStore: reads directory contents and watches for changes.
- FileClassifier: maps URLs to display categories such as folder, image, document, and unknown.
- ThumbnailPipeline: lazily generates thumbnails only for visible image files.
- IconProvider: returns stable folder, document, and system type icons.
- FileOperations: copy, paste, rename, move to Trash, and open.
- QuickLookController: bridges selected files to the macOS Quick Look panel.

## Resource Policy

The thumbnail system must be conservative from the first version.

- Generate thumbnails only for visible and near-visible grid cells.
- Limit concurrent thumbnail work to 2-4 tasks.
- Use an in-memory thumbnail cache with a configurable cap, initially 256 MB.
- Cancel thumbnail requests for cells that scroll far away.
- Store thumbnails at display size, not original image size.
- Never decode PDF or office documents for thumbnails.
- Avoid heavy blur, transparency, animation, or Electron-style web rendering.

Target behavior:

- Idle CPU near zero.
- Normal folders around 150-400 MB memory.
- Large image folders capped below 800 MB memory.
- Smooth scrolling should take priority over finishing every thumbnail immediately.

## Error Handling

- Permission errors show an inline empty state with a button to reveal the folder in Finder.
- Deleted or moved files disappear from the grid after the directory watcher reports changes.
- Failed image thumbnail generation falls back to a system image type icon.
- Failed file operations show a native alert with the affected path and error message.
- Large directories should remain responsive while loading, with incremental rendering.

## Testing Strategy

Start with focused local verification rather than broad automation.

- Unit tests for FileClassifier using representative filenames and UTIs.
- Unit tests for thumbnail eligibility to confirm documents never enter the thumbnail pipeline.
- Manual test folders containing images, PDFs, Office files, folders, aliases, and unknown files.
- Manual stress test with 5,000+ image files to check memory cap and scrolling.
- Manual Quick Look test for selected images, PDFs, and office documents.

## First Implementation Milestone

Create a minimal app that can:

- Open a chosen folder.
- Render an icon grid.
- Show image thumbnails only for image files.
- Show type icons for PDFs and office files.
- Open files and folders on double click.
- Preview selected items with Space.

File mutation operations, Finder service integration, and menu bar integration can follow after the browsing core is stable.
