# Photo Inspector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade SmartFinder's right-side details pane into a lightweight photography inspector for mainstream image and RAW metadata.

**Architecture:** Extend `PhotoMetadataSummary` as the core parser for ImageIO dictionaries, then render those fields in `DetailsPaneView`. Reuse the existing details pane visibility state and menu entry, adding a close callback in the pane itself.

**Tech Stack:** Swift, AppKit, ImageIO, SmartFinderCore tests, SwiftPM packaging.

---

### Task 1: Extend Photo Metadata Parsing

**Files:**
- Modify: `Sources/SmartFinderCore/PhotoMetadataSummary.swift`
- Modify: `Sources/SmartFinderCoreTests/main.swift`

- [ ] Add failing expectations for capture date, exposure compensation, white balance, color space, GPS coordinate, and Maps URL.
- [ ] Implement the new fields using ImageIO-style `{Exif}`, `{TIFF}`, and `{GPS}` dictionaries.
- [ ] Run `swift run SmartFinderCoreTests` and confirm the metadata tests pass.

### Task 2: Upgrade Right Details Pane

**Files:**
- Modify: `Sources/SmartFinder/DetailsPaneView.swift`
- Modify: `Sources/SmartFinder/MainWindowController.swift`

- [ ] Add a header row with localized title text and a close button callback.
- [ ] Group normal file fields separately from photography fields.
- [ ] Show an Open in Maps button when GPS data is available.
- [ ] Keep metadata loading limited to the single selected item path.

### Task 3: Localization, Docs, Version, Package

**Files:**
- Modify: `Sources/SmartFinder/Resources/*/Localizable.strings`
- Modify: `README.md`
- Modify: `docs/WORKLOG.md`
- Modify: `scripts/package.sh`

- [ ] Add localization keys for photo inspector labels.
- [ ] Document mainstream ImageIO-backed RAW/photo metadata support.
- [ ] Bump package version to `0.8.30`.
- [ ] Run tests, build, package, install, and create the release.
