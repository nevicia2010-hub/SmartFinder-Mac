# SmartFinder

SmartFinder is a small macOS Finder Companion focused on predictable icon-view browsing.

The first version opens a folder in a Finder-like icon grid:

- Image files show real thumbnails.
- PDF and office documents show system type icons instead of generated content thumbnails.
- Folders show folder icons.
- Unknown files show system type icons.
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

## Current Scope

This is not a system Finder replacement. It does not replace the Desktop, file picker, Spotlight, iCloud Drive, or "Show in Finder" behavior. It is a separate native window for folders where Finder's thumbnail behavior is inconvenient.
