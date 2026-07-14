# SmartFinder for Mac

A free, open-source macOS Finder companion for selective thumbnails: real previews for photos and RAW files, clean system icons for documents, archives, and code.

SmartFinder is a native macOS folder browser for people who want Finder-like navigation with more predictable thumbnails. It is MIT-licensed and built as a small personal utility, not a commercial file manager.

Finder can show file previews, but it does not offer a simple rule like "show thumbnails for photos, but keep PDFs, spreadsheets, archives, and code as clean system icons." SmartFinder fills that gap. It makes image, RAW photo, and video-heavy folders easier to scan while keeping mixed work folders lightweight and readable.

SmartFinder is not a system Finder replacement. It does not replace the Desktop, file picker, Spotlight, iCloud Drive, or "Show in Finder" behavior. It is a companion window for folders where Finder's thumbnail behavior gets in the way.

Requires macOS 13 Ventura or later on Apple Silicon Macs.

## Security Notice

SmartFinder is free and open source. The downloadable app is ad-hoc signed for local distribution, but it is not Apple Developer ID signed or Apple-notarized. On first launch, macOS Gatekeeper may show the standard "unidentified developer" warning. Right-click `SmartFinder.app` and choose Open, or allow it in System Settings > Privacy & Security.

中文说明：SmartFinder 是免费开源工具，目前没有进行 Apple 官方公证。首次打开时 macOS 可能会提示无法验证开发者。请右键点击 `SmartFinder.app` 选择“打开”，或在“系统设置 > 隐私与安全性”中允许打开。

![SmartFinder demo icon view](docs/screenshots/smartfinder-demo.png)

The demo folder used for this screenshot is included at `demo/SmartFinderDemoFiles`.

## What It Is For

- Browse photo and RAW folders with real visual thumbnails.
- Keep common RAW/JPEG/sidecar groups together during everyday file organization.
- Keep PDF, Office, archive, audio, code, and unknown files as familiar macOS system icons.
- Work through external SSDs, camera-card dumps, project folders, and mixed document folders without asking macOS to render every document page.
- Check one or a few photo or RAW files quickly in the right-side photo info pane without launching Bridge or Lightroom.
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
- A lightweight right-side info pane can show selected item metadata and photo EXIF/GPS basics without generating document thumbnails; ImageIO metadata is read on a utility task so large RAW selections do not block the window.
- Photo info includes capture date, camera model, lens, pixel dimensions, resolution, ISO, focal length, aperture, shutter speed, exposure compensation, white balance, color space, and GPS when available.
- GPS-tagged photos can be opened in Apple Maps from the info pane.
- Photo companion protection keeps same-stem RAW, rendered image, and sidecar files together for copy, move, drag/drop, paste, move to Trash, and rename operations.
- The Actions menu includes Copy To, Move To, New Text File, New Markdown File, and New CSV File for common folder work.
- The tag menu writes real Finder color labels instead of text-only tags; tagged folders use the matching folder icon color, while tagged files keep their system icons with a compact color indicator.
- The window uses a Finder-like full-height sidebar, transparent titlebar, compact breadcrumb row, and neutral toolbar symbols.
- Toolbar symbols now follow Finder-like availability states: enabled controls are bright, while unavailable controls are dimmed.
- Toolbar operation buttons show compact text labels under their icons for easier scanning.
- The macOS menu bar exposes common file, edit, view, navigation, and sort actions for users who do not remember shortcuts.
- The toolbar shows direct Finder-style view mode segments when the window is wide enough, and falls back to the Display menu when space is tight.
- Main interface fonts use AppKit preferred text styles where available, so text follows macOS system text choices more naturally.
- Mounted volumes in the sidebar include an eject button.
- Mounted-volume eject actions report started, succeeded, and failed states in the status bar.
- Toolbar buttons use larger Finder-like hit areas and symbol sizes.
- In full screen, the custom toolbar keeps a top guard so the revealed macOS menu bar does not cover the controls.
- Mounted external volumes appear in the Finder-style sidebar and refresh automatically when disks are mounted, unmounted, or renamed.
- Icon view, list view, and lightweight column view are available from the Display menu.
- Column view follows the current path through parent folders and opens child columns with system icons only, avoiding document thumbnail generation.
- Column view adapts each column width to the visible file names, with a clamp to keep very long names from consuming the whole window.
- A path breadcrumb bar lets you jump directly to parent folders.
- Common window operations are available: refresh, new folder, Finder-style rename, move to Trash, copy/paste, copy path, compress, reveal in Finder, Get Info, context menu, editable path field, and icon-size control.
- Rename supports clicking an already selected item name to edit in place; regular files select only the base name by default so the extension is preserved unless you intentionally edit it.
- Folder size is available on demand for a selected folder and can be cancelled while running.
- A dual-pane mode can be opened from the Display menu for drag-and-drop file moves without loading the second pane at startup.
- Drag and drop moves files on the same volume, copies across volumes, and copies when holding Option. Copy-only drag sources are never silently converted into moves.
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

- Apple Silicon Mac, such as M1, M2, M3, or newer.
- macOS 13 Ventura or later. macOS 12 Monterey and older are not supported.
- Intel Macs are not a supported target for the downloadable build. The project may be adapted from source, but Intel behavior is untested.
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
- `dist/SmartFinder-0.8.33.dmg`

The app is ad-hoc signed for local use. See Security Notice above for the first-launch Gatekeeper warning on other Macs.

## Install from DMG

Open `dist/SmartFinder-0.8.33.dmg`, then drag `SmartFinder.app` to `Applications`.

## RAW Photo Files

SmartFinder treats common RAW photo extensions as thumbnail-eligible image files, including DNG, CR2, CR3, NEF, ARW, RAF, RW2, ORF, PEF, SRW, X3F, MEF, KDC, and related camera formats.

Thumbnail generation still depends on macOS Quick Look and the RAW codecs available on the current system. If macOS cannot decode a specific RAW file, SmartFinder falls back to the normal system type icon.

Photo metadata is read through macOS ImageIO. SmartFinder focuses on mainstream camera files and does not bundle third-party RAW decoders. If macOS cannot read a proprietary or unusual RAW file, SmartFinder shows the available basic file metadata and skips missing camera fields.

Photo companion protection is file-name based. When SmartFinder operates on a known photo file such as `IMG_0001.CR3`, it checks the same folder for known same-stem companions such as `IMG_0001.JPG`, `IMG_0001.HEIC`, `IMG_0001.XMP`, `IMG_0001.AAE`, `IMG_0001.ACR`, `IMG_0001.DOP`, `IMG_0001.PP3`, `IMG_0001.ON1`, or `IMG_0001.COS`. Matching companions are included in copy, move, drag/drop, paste, move to Trash, and rename operations. This does not decode images, inspect whole folders in the background, or create a photo catalog.

Batch copy, move, and companion-file rename operations use a transaction-style plan. A companion group receives one shared collision suffix, and completed steps are rolled back if a later step fails. File and folder names are validated as single path components before creation or rename.

## Preview Strategy

SmartFinder is intentionally selective about content thumbnails:

- Photos, RAW files, and supported videos can use real Quick Look thumbnails.
- The in-memory thumbnail cache is size- and Retina-scale-aware, capped at 128 MB by default, and cancels obsolete requests when the folder, view, or icon size changes.
- PDF, Office, audio, archive, code, and unknown files stay lightweight and readable with macOS system icons plus type/size subtitles.
- This keeps large mixed folders easier to scan without asking macOS to render every document page.
- List view uses metadata and system icons only; it does not run the thumbnail pipeline.
- Column view uses metadata and system icons only; it does not run the thumbnail pipeline.
- Hidden column-view tables are released when switching to icon or list view and rebuilt on demand, so large directory columns do not stay resident in memory.
- The info pane uses file metadata, system icons, and selected-file photo metadata only when the pane is visible, so it does not start a heavy preview database.
- Photo companion protection checks sibling file names only during explicit file operations; it does not create a background index.
- Toolbar menus are created on demand and operate on the current folder or current selection; SmartFinder does not run a full-disk indexer or pre-render document thumbnails.
- Status size totals only selected regular files with known byte sizes; folders are not recursively scanned in the background.
- Folder size calculations are manual, cancellable, and run only for the selected folder.
- Dual-pane mode is off by default; the secondary pane loads a folder only when the user opens the mode.

## Localizations

SmartFinder currently includes UI localizations for the following system languages. The app follows the current macOS language where a translation is available:

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
