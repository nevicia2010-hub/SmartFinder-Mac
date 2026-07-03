# SmartFinder for Mac

A lightweight macOS Finder companion for selective thumbnails: real previews for photos and RAW files, clean system icons for documents, archives, and code.

SmartFinder is a native macOS folder browser for people who want Finder-like navigation with more predictable thumbnails.

Finder can show file previews, but it does not offer a simple rule like "show thumbnails for photos, but keep PDFs, spreadsheets, archives, and code as clean system icons." SmartFinder fills that gap. It makes image, RAW photo, and video-heavy folders easier to scan while keeping mixed work folders lightweight and readable.

SmartFinder is not a system Finder replacement. It does not replace the Desktop, file picker, Spotlight, iCloud Drive, or "Show in Finder" behavior. It is a companion window for folders where Finder's thumbnail behavior gets in the way.

Requires macOS 13 Ventura or later.

![SmartFinder demo icon view](docs/screenshots/smartfinder-demo.png)

The demo folder used for this screenshot is included at `demo/SmartFinderDemoFiles`.

## What It Is For

- Browse photo and RAW folders with real visual thumbnails.
- Keep PDF, Office, archive, audio, code, and unknown files as familiar macOS system icons.
- Work through external SSDs, camera-card dumps, project folders, and mixed document folders without asking macOS to render every document page.
- Use familiar Finder-style actions: open folders, go back and forward, sort, tag, Quick Look, copy paths, compress files, reveal items in Finder, and move files between folders.
- Keep memory and GPU use lower by avoiding a full-disk indexer and by not pre-rendering every document thumbnail.

## What It Does

- Image and supported RAW photo files show real thumbnails.
- Video files are thumbnail-eligible, so supported formats can show a first-frame preview.
- PDF and office documents show system type icons instead of generated content thumbnails.
- Common document, audio, archive, code, and unknown files keep their macOS system default icons.
- Folders show folder icons.
- Unknown files show system type icons.
- File tiles include a compact type/size subtitle, such as `PDF - 2.4 MB` or `CR3 - 28 MB`.
- The toolbar can sort the current folder by name, type, size, or modified date.
- Back and forward are integrated as a Finder-style segmented navigation control, with a separate Up button.
- The back/forward navigation control uses a larger SmartFinder-sized hit area without copying Finder pixel-for-pixel.
- Back and forward arrows remain visible in gray when unavailable, then brighten when that direction becomes available.
- Finder-like toolbar menus provide display presets, grouping/sorting, system sharing, real Finder color tags, and common file actions.
- Windows Explorer-style convenience toggles are available for hidden items, file name extensions, and item selection checkboxes.
- A lightweight details pane can show selected item metadata without generating document thumbnails.
- The Actions menu includes Copy To, Move To, New Text File, New Markdown File, and New CSV File for common folder work.
- The tag menu writes real Finder color labels instead of text-only tags; tagged folders use the matching folder icon color, while tagged files keep their system icons with a compact color indicator.
- The window uses a Finder-like full-height sidebar, transparent titlebar, compact breadcrumb row, and neutral toolbar symbols.
- Toolbar symbols now follow Finder-like availability states: enabled controls are bright, while unavailable controls are dimmed.
- Toolbar operation buttons show compact text labels under their icons for easier scanning.
- The macOS menu bar exposes common file, edit, view, navigation, and sort actions for users who do not remember shortcuts.
- The toolbar shows direct Finder-style view mode segments when the window is wide enough, and falls back to the Display menu when space is tight.
- Main interface fonts use AppKit preferred text styles where available, so text follows macOS system text choices more naturally.
- Mounted volumes in the sidebar include an eject button.
- Toolbar buttons use larger Finder-like hit areas and symbol sizes.
- In full screen, the custom toolbar keeps a top guard so the revealed macOS menu bar does not cover the controls.
- Mounted external volumes appear in the Finder-style sidebar and refresh automatically when disks are mounted, unmounted, or renamed.
- Icon view, list view, and lightweight column view are available from the Display menu.
- Column view follows the current path through parent folders and opens child columns with system icons only, avoiding document thumbnail generation.
- Column view adapts each column width to the visible file names, with a clamp to keep very long names from consuming the whole window.
- A path breadcrumb bar lets you jump directly to parent folders.
- Common window operations are available: refresh, new folder, rename, move to Trash, copy/paste, copy path, compress, reveal in Finder, Get Info, context menu, editable path field, and icon-size control.
- Drag and drop supports Finder-style file moves by default and copies when holding Option.
- Sidebar locations accept dragged files for quick move/copy into common folders or mounted volumes.
- Context menus include New Folder, New Text File, New Markdown File, New CSV File, Copy Name, Copy Path, Copy Parent Path, and Copy as Shell Path.
- The status bar shows selected file byte size and available disk space without recursively scanning folders.
- Quick Look works with Space and Command-Y for the current selection.
- Finder-style keyboard shortcuts include back/forward, parent folder, open selection, view switching, search focus, copy path, refresh, Get Info, and new folder.
- Sorting supports name, type, size, modified date, plus ascending or descending direction.
- The interface follows the system language for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Italian, and Portuguese.
- Double-click opens files or enters folders.
- Space opens Quick Look for the current selection.

## Requirements

- macOS 13 Ventura or later. macOS 12 Monterey and older are not supported.
- Apple Swift command line tools.
- Full Xcode is not required for the current Swift Package build.

## Build

```bash
swift build
```

## Test Core Rules

This environment does not expose `XCTest` or Swift `Testing`, so core tests run as a small executable:

```bash
swift run SmartFinderCoreTests
```

## Run

```bash
swift run SmartFinder --path "$HOME/Downloads"
```

If `--path` is omitted, SmartFinder opens the user's home folder.

## Package as a macOS App

```bash
./scripts/package.sh
```

The script creates:

- `.build/package/SmartFinder.app`
- `dist/SmartFinder-0.8.8.dmg`

The app is ad-hoc signed for local use. It is not Apple Developer ID signed or notarized, so macOS may show the standard warning the first time it is opened on another machine.

## Install from DMG

Open `dist/SmartFinder-0.8.8.dmg`, then drag `SmartFinder.app` to `Applications`.

## RAW Photo Files

SmartFinder treats common RAW photo extensions as thumbnail-eligible image files, including DNG, CR2, CR3, NEF, ARW, RAF, RW2, ORF, PEF, SRW, X3F, MEF, KDC, and related camera formats.

Thumbnail generation still depends on macOS Quick Look and the RAW codecs available on the current system. If macOS cannot decode a specific RAW file, SmartFinder falls back to the normal system type icon.

## Preview Strategy

SmartFinder is intentionally selective about content thumbnails:

- Photos, RAW files, and supported videos can use real Quick Look thumbnails.
- PDF, Office, audio, archive, code, and unknown files stay lightweight and readable with macOS system icons plus type/size subtitles.
- This keeps large mixed folders easier to scan without asking macOS to render every document page.
- List view uses metadata and system icons only; it does not run the thumbnail pipeline.
- Column view uses metadata and system icons only; it does not run the thumbnail pipeline.
- The details pane uses file metadata and system icons, so it does not start a heavy preview database.
- Toolbar menus are created on demand and operate on the current folder or current selection; SmartFinder does not run a full-disk indexer or pre-render document thumbnails.
- Status size totals only selected regular files with known byte sizes; folders are not recursively scanned in the background.

## Localizations

SmartFinder currently includes UI localizations for:

- English
- Simplified Chinese
- Traditional Chinese
- Japanese
- Korean
- German
- French
- Spanish
- Italian
- Portuguese

## License

MIT License. See `LICENSE`.

## Current Scope

This is not a system Finder replacement or a pixel-perfect Finder clone. It does not replace the Desktop, file picker, Spotlight, iCloud Drive, or "Show in Finder" behavior. It is a separate native window for folders where Finder's thumbnail behavior is inconvenient.
