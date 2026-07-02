# SmartFinder

SmartFinder is a small macOS Finder Companion focused on predictable icon-view browsing. It follows familiar macOS patterns, but it is not a pixel-perfect Finder clone.

The first version opens a folder in a Finder-like icon grid:

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
- The tag menu writes real Finder color labels instead of text-only tags; tagged folders use the matching folder icon color, while tagged files keep their system icons with a compact color indicator.
- The window uses a Finder-like full-height sidebar, transparent titlebar, compact breadcrumb row, and neutral toolbar symbols.
- Toolbar symbols now follow Finder-like availability states: enabled controls are bright, while unavailable controls are dimmed.
- Toolbar operation buttons show compact text labels under their icons for easier scanning.
- Main interface fonts use AppKit preferred text styles where available, so text follows macOS system text choices more naturally.
- Mounted volumes in the sidebar include an eject button.
- Toolbar buttons use larger Finder-like hit areas and symbol sizes.
- In full screen, the custom toolbar keeps a top guard so the revealed macOS menu bar does not cover the controls.
- Mounted external volumes appear in the Finder-style sidebar.
- Icon view and list view are both available from the Display menu.
- A path breadcrumb bar lets you jump directly to parent folders.
- Common window operations are available: refresh, new folder, rename, move to Trash, copy/paste, copy path, compress, reveal in Finder, Get Info, context menu, editable path field, and icon-size control.
- The interface follows the system language for English, Simplified Chinese, Traditional Chinese, Japanese, Korean, German, French, Spanish, Italian, and Portuguese.
- Double-click opens files or enters folders.
- Space opens Quick Look for the current selection.

## Requirements

- macOS with Apple Swift command line tools.
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
- `dist/SmartFinder-0.5.6.dmg`

The app is ad-hoc signed for local use. It is not Apple Developer ID signed or notarized, so macOS may show the standard warning the first time it is opened on another machine.

## Install from DMG

Open `dist/SmartFinder-0.5.6.dmg`, then drag `SmartFinder.app` to `Applications`.

## RAW Photo Files

SmartFinder treats common RAW photo extensions as thumbnail-eligible image files, including DNG, CR2, CR3, NEF, ARW, RAF, RW2, ORF, PEF, SRW, X3F, MEF, KDC, and related camera formats.

Thumbnail generation still depends on macOS Quick Look and the RAW codecs available on the current system. If macOS cannot decode a specific RAW file, SmartFinder falls back to the normal system type icon.

## Preview Strategy

SmartFinder is intentionally selective about content thumbnails:

- Photos, RAW files, and supported videos can use real Quick Look thumbnails.
- PDF, Office, audio, archive, code, and unknown files stay lightweight and readable with macOS system icons plus type/size subtitles.
- This keeps large mixed folders easier to scan without asking macOS to render every document page.
- List view uses metadata and system icons only; it does not run the thumbnail pipeline.
- Toolbar menus are created on demand and operate on the current folder or current selection; SmartFinder does not run a full-disk indexer or pre-render document thumbnails.

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
