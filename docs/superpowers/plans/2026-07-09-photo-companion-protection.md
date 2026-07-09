# Photo Companion Protection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep RAW/JPEG/sidecar photography groups together during common SmartFinder file operations.

**Architecture:** Add a focused core policy that expands selected file URLs to same-stem photo companions. Use that policy from `FileOperations` and `FileGridViewController` so copy/move/paste/trash/rename routes share the same behavior.

**Tech Stack:** Swift, Foundation file APIs, AppKit pasteboard/recycle integration, existing SmartFinderCore test executable.

---

### Task 1: Core Companion Policy

**Files:**
- Create: `Sources/SmartFinderCore/PhotoCompanionFilePolicy.swift`
- Modify: `Sources/SmartFinderCoreTests/main.swift`

- [ ] Write failing tests for same-stem RAW/JPEG/XMP expansion and deduplication.
- [ ] Implement extension-based companion lookup with no image decoding.
- [ ] Run `swift run SmartFinderCoreTests` and confirm the new policy passes.

### Task 2: Operation Integration

**Files:**
- Modify: `Sources/SmartFinderCore/FileOperations.swift`
- Modify: `Sources/SmartFinder/FileGridViewController.swift`
- Modify: `Sources/SmartFinderCoreTests/main.swift`

- [ ] Write failing tests for transferring and renaming a photo companion group.
- [ ] Add grouped transfer and grouped rename methods to `FileOperations`.
- [ ] Route SmartFinder copy/move/drop/paste/trash/rename through the group-aware methods.
- [ ] Run `swift run SmartFinderCoreTests` and `swift build`.

### Task 3: Docs And Release

**Files:**
- Modify: `README.md`
- Modify: `docs/WORKLOG.md`
- Modify: `scripts/package.sh`

- [ ] Document photo companion protection and its lightweight performance boundary.
- [ ] Bump package version to `0.8.31`.
- [ ] Package, install, verify, commit, tag, and release.
