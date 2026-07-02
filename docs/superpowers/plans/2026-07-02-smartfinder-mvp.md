# SmartFinder MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal runnable macOS Finder Companion that opens a folder, renders a Finder-like icon grid, shows real thumbnails for images, and shows stable type icons for PDFs and office documents.

**Architecture:** Use a Swift Package executable with a programmatic AppKit application because this machine has Swift command line tools but not full Xcode. Keep file classification, directory loading, icon selection, thumbnail generation, and UI controllers in separate files so the thumbnail policy remains testable.

**Tech Stack:** Swift 6.3 toolchain in Swift 5.9 package mode, Swift Package Manager, AppKit, QuickLook, QuickLookThumbnailing, UniformTypeIdentifiers, and a small custom core-test executable because XCTest/Swift Testing are unavailable in the current Command Line Tools environment.

---

## File Structure

- `Package.swift`: SwiftPM executable and test target definition.
- `Sources/SmartFinder/main.swift`: app entry point and CLI path parsing.
- `Sources/SmartFinder/AppDelegate.swift`: application lifecycle and window startup.
- `Sources/SmartFinder/MainWindowController.swift`: main window chrome, toolbar, sidebar placeholder, and status bar.
- `Sources/SmartFinder/FileGridViewController.swift`: AppKit collection view, selection, double-click, keyboard actions, and visible-cell thumbnail requests.
- `Sources/SmartFinder/FileItemCell.swift`: icon cell rendering.
- `Sources/SmartFinder/FileItem.swift`: value model for a file-system item.
- `Sources/SmartFinder/FileClassifier.swift`: UTI and extension-based display category rules.
- `Sources/SmartFinder/DirectoryStore.swift`: directory reading and sorting.
- `Sources/SmartFinder/IconProvider.swift`: folder, document, and system icon lookup.
- `Sources/SmartFinderCore/ThumbnailPipeline.swift`: image-only thumbnail eligibility, async generation, and cache.
- `Sources/SmartFinder/QuickLookController.swift`: Space-key Quick Look bridge.
- `Sources/SmartFinderCoreTests/main.swift`: classification and image-only thumbnail eligibility checks.

## Task 1: Create Swift Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/SmartFinder/main.swift`
- Create: `Sources/SmartFinderCore/Bootstrap.swift`
- Create: `Sources/SmartFinderCoreTests/main.swift`

- [ ] **Step 1: Create the package manifest**

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartFinder",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SmartFinder", targets: ["SmartFinder"])
    ],
    targets: [
        .target(name: "SmartFinderCore"),
        .executableTarget(name: "SmartFinder", dependencies: ["SmartFinderCore"]),
        .executableTarget(name: "SmartFinderCoreTests", dependencies: ["SmartFinderCore"])
    ]
)
```

- [ ] **Step 2: Add a temporary app entry**

```swift
// Sources/SmartFinder/main.swift
print("SmartFinder bootstrap")
```

- [ ] **Step 3: Add a temporary core test executable**

```swift
// Sources/SmartFinderCoreTests/main.swift
import Darwin
import SmartFinderCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

expect(SmartFinderCoreBootstrap.isAvailable, "core module should load")
print("SmartFinderCoreTests passed")
```

- [ ] **Step 4: Verify the package**

Run: `swift run SmartFinderCoreTests`

Expected: build succeeds and the bootstrap check passes.

## Task 2: Add File Classification Core

**Files:**
- Create: `Sources/SmartFinderCore/FileItem.swift`
- Create: `Sources/SmartFinderCore/FileClassifier.swift`
- Modify: `Sources/SmartFinderCoreTests/main.swift`

- [ ] **Step 1: Write classification tests**

```swift
import Darwin
import Foundation
import SmartFinderCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func category(_ path: String, isDirectory: Bool = false) -> FileCategory {
    FileClassifier.category(for: URL(fileURLWithPath: path), isDirectory: isDirectory)
}

expect(category("/tmp/photo.jpg") == .image, "jpg should be image")
expect(category("/tmp/photo.HEIC") == .image, "HEIC should be image")
expect(category("/tmp/photo.webp") == .image, "webp should be image")
expect(category("/tmp/file.pdf") == .document, "pdf should be document")
expect(category("/tmp/file.xlsx") == .document, "xlsx should be document")
expect(category("/tmp/file.docx") == .document, "docx should be document")
expect(category("/tmp/file.pptx") == .document, "pptx should be document")
expect(category("/tmp/folder.jpg", isDirectory: true) == .folder, "directories should win over extension")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift run SmartFinderCoreTests`

Expected: fail because `FileClassifier` does not exist.

- [ ] **Step 3: Implement file model and classifier**

```swift
import Foundation

public struct FileItem: Hashable {
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let category: FileCategory
}
```

```swift
import Foundation

public enum FileCategory: Equatable {
    case folder
    case image
    case document
    case other
}

public enum FileClassifier {
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "webp", "gif", "tiff", "tif", "bmp"]
    private static let documentExtensions: Set<String> = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key"]

    public static func category(for url: URL, isDirectory: Bool) -> FileCategory {
        if isDirectory { return .folder }
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) { return .image }
        if documentExtensions.contains(ext) { return .document }
        return .other
    }
}
```

- [ ] **Step 4: Add thumbnail eligibility tests**

Append these expectations to `Sources/SmartFinderCoreTests/main.swift`:

```swift
expect(ThumbnailPipeline.isThumbnailEligible(.image), "images should be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.document), "documents must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.folder), "folders must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.other), "other files must not be thumbnail eligible")
```

- [ ] **Step 5: Add minimal thumbnail eligibility API**

```swift
public enum ThumbnailPipeline {
    public static func isThumbnailEligible(_ category: FileCategory) -> Bool {
        category == .image
    }
}
```

- [ ] **Step 6: Verify core tests**

Run: `swift run SmartFinderCoreTests`

Expected: all tests pass.

## Task 3: Build Directory and Icon Services

**Files:**
- Create: `Sources/SmartFinder/DirectoryStore.swift`
- Create: `Sources/SmartFinder/IconProvider.swift`

- [ ] **Step 1: Implement directory loading**

```swift
import Foundation

final class DirectoryStore {
    func loadItems(in folderURL: URL) throws -> [FileItem] {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isHiddenKey, .localizedNameKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        )

        return try urls.map { url in
            let values = try url.resourceValues(forKeys: keys)
            let isDirectory = values.isDirectory ?? false
            return FileItem(
                url: url,
                name: values.localizedName ?? url.lastPathComponent,
                isDirectory: isDirectory,
                category: FileClassifier.category(for: url, isDirectory: isDirectory)
            )
        }
        .sorted { left, right in
            if left.isDirectory != right.isDirectory { return left.isDirectory && !right.isDirectory }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
    }
}
```

- [ ] **Step 2: Implement icon lookup**

```swift
import AppKit

final class IconProvider {
    func icon(for item: FileItem) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: item.url.path)
        image.size = NSSize(width: 96, height: 96)
        return image
    }
}
```

- [ ] **Step 3: Verify build**

Run: `swift run SmartFinderCoreTests`

Expected: all tests pass.

## Task 4: Implement Image-Only Thumbnail Pipeline

**Files:**
- Replace: `Sources/SmartFinderCore/ThumbnailPipeline.swift`

- [ ] **Step 1: Replace minimal enum with service class**

```swift
import AppKit
import QuickLookThumbnailing

final class ThumbnailPipeline {
    private let generator = QLThumbnailGenerator.shared
    private let cache = NSCache<NSURL, NSImage>()
    private let queue = OperationQueue()

    init(memoryLimitMegabytes: Int = 256) {
        cache.totalCostLimit = memoryLimitMegabytes * 1024 * 1024
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .userInitiated
    }

    static func isThumbnailEligible(_ category: FileCategory) -> Bool {
        category == .image
    }

    func cachedThumbnail(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func thumbnail(for item: FileItem, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        guard Self.isThumbnailEligible(item.category) else {
            completion(nil)
            return
        }

        if let cached = cachedThumbnail(for: item.url) {
            completion(cached)
            return
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail
        )

        queue.addOperation { [generator, cache] in
            generator.generateBestRepresentation(for: request) { representation, error in
                guard error == nil, let image = representation?.nsImage else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                let cost = Int(size.width * size.height * 4)
                cache.setObject(image, forKey: item.url as NSURL, cost: cost)
                DispatchQueue.main.async { completion(image) }
            }
        }
    }
}
```

- [ ] **Step 2: Verify tests**

Run: `swift run SmartFinderCoreTests`

Expected: all tests pass, proving documents remain ineligible.

## Task 5: Build Finder-Like Icon Grid

**Files:**
- Create: `Sources/SmartFinder/FileItemCell.swift`
- Create: `Sources/SmartFinder/FileGridViewController.swift`

- [ ] **Step 1: Implement collection view cell**

```swift
import AppKit

final class FileItemCell: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("FileItemCell")

    private let iconView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 128, height: 150))
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleField.alignment = .center
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.font = .systemFont(ofSize: 12)
        titleField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iconView)
        view.addSubview(titleField)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
            titleField.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        ])
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.selectedControlColor.withAlphaComponent(0.25).cgColor : NSColor.clear.cgColor
        }
    }

    func configure(name: String, image: NSImage) {
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        iconView.image = image
        titleField.stringValue = name
    }
}
```

- [ ] **Step 2: Implement collection view controller**

Create a controller that loads `FileItem` values, shows icons immediately, asks `ThumbnailPipeline` only for image thumbnails, opens folders on double click, opens files with `NSWorkspace`, and forwards Space to Quick Look.

- [ ] **Step 3: Verify build**

Run: `swift build`

Expected: build succeeds.

## Task 6: Build Main App Window

**Files:**
- Replace: `Sources/SmartFinder/main.swift`
- Create: `Sources/SmartFinder/AppDelegate.swift`
- Create: `Sources/SmartFinder/MainWindowController.swift`
- Create: `Sources/SmartFinder/QuickLookController.swift`

- [ ] **Step 1: Replace bootstrap entry with NSApplication startup**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
```

- [ ] **Step 2: Implement app delegate**

Open the path passed with `--path`, or default to the user's home directory.

- [ ] **Step 3: Implement window controller**

Create a 1100x760 window with a left sidebar, toolbar row, grid content, and status bar.

- [ ] **Step 4: Implement Quick Look controller**

Bridge selected URLs into `QLPreviewPanelDataSource` and `QLPreviewPanelDelegate`.

- [ ] **Step 5: Verify app launches**

Run: `swift run SmartFinder --path "$HOME/Downloads"`

Expected: native macOS window opens and renders the chosen folder.

## Task 7: Verification and Cleanup

**Files:**
- Modify as needed: implementation files above.
- Create: `README.md`

- [ ] **Step 1: Run unit tests**

Run: `swift run SmartFinderCoreTests`

Expected: all tests pass.

- [ ] **Step 2: Run app manually**

Run: `swift run SmartFinder --path "$HOME/Downloads"`

Expected: images show thumbnails; PDFs and office documents show type icons; double-click opens files or enters folders; Space opens Quick Look.

- [ ] **Step 3: Add README**

Document build, test, run commands, and the first-version scope.

- [ ] **Step 4: Confirm all files are contained**

Run: `rg --files`

Expected: all project files live under `work/SmartFinder`.

## Self-Review

- Spec coverage: the plan covers the first implementation milestone: open folder, icon grid, image thumbnails only, document type icons, double-click open, and Space Quick Look.
- Deferred spec items: rename, Trash, copy/paste, Finder service, menu bar integration, and recursive search are intentionally outside the first implementation milestone.
- Placeholder scan: no `TBD` or `TODO` placeholders are intended.
- Type consistency: `FileItem`, `FileCategory`, `FileClassifier`, and `ThumbnailPipeline.isThumbnailEligible` are introduced before UI code depends on them.
