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

func temporaryTestDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SmartFinderCoreTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

let fileOperations = FileOperations()
let operationsDirectory = try temporaryTestDirectory()
defer {
    try? FileManager.default.removeItem(at: operationsDirectory)
}

let createdFolder = try fileOperations.createFolder(named: "Shoot", in: operationsDirectory)
expect(
    FileManager.default.fileExists(atPath: createdFolder.path),
    "createFolder should create the requested folder"
)
let createdTextFile = try fileOperations.createFile(named: "notes.txt", contents: "hello", in: operationsDirectory)
let createdText = try String(contentsOf: createdTextFile, encoding: .utf8)
expect(
    createdText == "hello",
    "createFile should write a new text file with the requested contents"
)

let renamedFolder = try fileOperations.rename(createdFolder, to: "Shoot Renamed")
expect(
    renamedFolder.lastPathComponent == "Shoot Renamed" &&
    FileManager.default.fileExists(atPath: renamedFolder.path),
    "rename should move the item to the requested name"
)

let sourceFile = operationsDirectory.appendingPathComponent("photo.jpg")
try "image-data".write(to: sourceFile, atomically: true, encoding: .utf8)
let firstCopy = try fileOperations.copy(sourceFile, toDirectory: operationsDirectory)
let secondCopy = try fileOperations.copy(sourceFile, toDirectory: operationsDirectory)
expect(firstCopy.lastPathComponent == "photo copy.jpg", "first copy should use copy suffix")
expect(secondCopy.lastPathComponent == "photo copy 2.jpg", "second copy should increment copy suffix")
expect(
    FileManager.default.fileExists(atPath: firstCopy.path) &&
    FileManager.default.fileExists(atPath: secondCopy.path),
    "copy should create both unique files"
)

expect(
    fileOperations.uniqueDestinationURL(for: sourceFile, in: operationsDirectory).lastPathComponent == "photo copy 3.jpg",
    "uniqueDestinationURL should skip existing copy names"
)
let moveTargetDirectory = try fileOperations.createFolder(named: "Move Target", in: operationsDirectory)
let movableFile = operationsDirectory.appendingPathComponent("move-me.txt")
try "move-me".write(to: movableFile, atomically: true, encoding: .utf8)
let movedFile = try fileOperations.move(movableFile, toDirectory: moveTargetDirectory)
expect(movedFile.deletingLastPathComponent() == moveTargetDirectory, "move to directory should place the item in the target folder")
expect(!FileManager.default.fileExists(atPath: movableFile.path), "move to directory should remove the source item")
expect(FileManager.default.fileExists(atPath: movedFile.path), "move to directory should create the destination item")
let transferCopySource = operationsDirectory.appendingPathComponent("drag-copy.txt")
try "drag-copy".write(to: transferCopySource, atomically: true, encoding: .utf8)
let transferredCopy = try fileOperations.transfer(transferCopySource, toDirectory: moveTargetDirectory, operation: .copy)
expect(FileManager.default.fileExists(atPath: transferCopySource.path), "copy transfer should preserve the source item")
expect(FileManager.default.fileExists(atPath: transferredCopy.path), "copy transfer should create the destination item")
let transferMoveSource = operationsDirectory.appendingPathComponent("drag-move.txt")
try "drag-move".write(to: transferMoveSource, atomically: true, encoding: .utf8)
let transferredMove = try fileOperations.transfer(transferMoveSource, toDirectory: moveTargetDirectory, operation: .move)
expect(!FileManager.default.fileExists(atPath: transferMoveSource.path), "move transfer should remove the source item")
expect(FileManager.default.fileExists(atPath: transferredMove.path), "move transfer should create the destination item")

let visibleDirectoryFile = operationsDirectory.appendingPathComponent("visible.txt")
let hiddenDirectoryFile = operationsDirectory.appendingPathComponent(".hidden.txt")
let hiddenAttributeDirectory = operationsDirectory.appendingPathComponent("hidden-attribute", isDirectory: true)
try "visible".write(to: visibleDirectoryFile, atomically: true, encoding: .utf8)
try "hidden".write(to: hiddenDirectoryFile, atomically: true, encoding: .utf8)
try FileManager.default.createDirectory(at: hiddenAttributeDirectory, withIntermediateDirectories: false)
let hiddenAttributeResult = hiddenAttributeDirectory.path.withCString { path in
    chflags(path, UInt32(UF_HIDDEN))
}
expect(hiddenAttributeResult == 0, "test setup should mark a directory as Finder-hidden")
let defaultDirectoryNames = try DirectoryStore().loadItems(in: operationsDirectory).map(\.name)
expect(defaultDirectoryNames.contains("visible.txt"), "directory loading should include visible files")
expect(!defaultDirectoryNames.contains(".hidden.txt"), "directory loading should hide dotfiles by default")
expect(!defaultDirectoryNames.contains("hidden-attribute"), "directory loading should hide Finder-hidden items by default")
let hiddenDirectoryNames = try DirectoryStore().loadItems(
    in: operationsDirectory,
    options: DirectoryLoadOptions(includesHiddenItems: true)
).map(\.name)
expect(hiddenDirectoryNames.contains(".hidden.txt"), "directory loading should show hidden files when requested")
expect(hiddenDirectoryNames.contains("hidden-attribute"), "directory loading should show Finder-hidden items when requested")
final class RecordingDirectoryContentProvider: DirectoryContentProviding {
    private(set) var requests: [(path: String, includesHiddenItems: Bool)] = []
    let returnedURLs: [URL]

    init(returnedURLs: [URL]) {
        self.returnedURLs = returnedURLs
    }

    func itemURLs(in folderURL: URL, includesHiddenItems: Bool) throws -> [URL] {
        requests.append((folderURL.path, includesHiddenItems))
        return returnedURLs
    }
}

let injectedListFile = operationsDirectory.appendingPathComponent("provider-item.txt")
try "provider".write(to: injectedListFile, atomically: true, encoding: .utf8)
let recordingProvider = RecordingDirectoryContentProvider(returnedURLs: [injectedListFile])
let injectedStore = DirectoryStore(contentProvider: recordingProvider)
let injectedItems = try injectedStore.loadItems(
    in: operationsDirectory,
    options: DirectoryLoadOptions(includesHiddenItems: true)
)
expect(
    recordingProvider.requests.map(\.path) == [operationsDirectory.path] &&
    recordingProvider.requests.map(\.includesHiddenItems) == [true],
    "directory loading should obtain item URLs through its content provider"
)
expect(
    injectedItems.map(\.name) == ["provider-item.txt"],
    "directory loading should build file items from provider-supplied URLs"
)
let displayNameFile = FileItem(
    url: URL(fileURLWithPath: "/tmp/report.final.pdf"),
    name: "report.final.pdf",
    isDirectory: false,
    category: .document
)
expect(
    FileNameDisplayPolicy.displayName(for: displayNameFile, showsFileExtensions: false) == "report.final",
    "file name display should hide the final extension when requested"
)
expect(
    FileNameDisplayPolicy.displayName(for: displayNameFile, showsFileExtensions: true) == "report.final.pdf",
    "file name display should keep extensions when requested"
)

let mountedVolumeLocations = MountedVolumeProvider.locations(from: [
    URL(fileURLWithPath: "/"),
    URL(fileURLWithPath: "/System/Volumes/VM"),
    URL(fileURLWithPath: "/Volumes/CameraSSD"),
    URL(fileURLWithPath: "/Volumes/Photo Archive")
])

expect(
    mountedVolumeLocations.map(\.name) == ["CameraSSD", "Photo Archive"],
    "mounted volumes should include browsable /Volumes entries only"
)
expect(
    mountedVolumeLocations.map(\.url.path) == ["/Volumes/CameraSSD", "/Volumes/Photo Archive"],
    "mounted volume URLs should preserve /Volumes paths"
)
expect(
    mountedVolumeLocations.allSatisfy(\.isEjectable),
    "mounted /Volumes sidebar entries should expose eject affordances"
)

let volumeRefreshPolicy = MountedVolumeSidebarRefreshPolicy()
expect(
    volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidMountNotification"),
    "mount notifications should refresh the mounted-volume sidebar while the window is open"
)
expect(
    volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidUnmountNotification"),
    "unmount notifications should refresh the mounted-volume sidebar while the window is open"
)
expect(
    volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidRenameVolumeNotification"),
    "volume rename notifications should refresh the mounted-volume sidebar while the window is open"
)
expect(
    !volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidWakeNotification"),
    "unrelated workspace notifications should not refresh the mounted-volume sidebar"
)

let breadcrumbURL = URL(fileURLWithPath: "/Users/bingwang/Pictures/RAW", isDirectory: true)
let breadcrumbComponents = PathBreadcrumb.components(for: breadcrumbURL)
expect(
    breadcrumbComponents.map(\.url.path) == ["/", "/Users", "/Users/bingwang", "/Users/bingwang/Pictures", "/Users/bingwang/Pictures/RAW"],
    "path breadcrumb should expose cumulative parent URLs"
)
expect(
    breadcrumbComponents.map(\.title) == ["/", "Users", "bingwang", "Pictures", "RAW"],
    "path breadcrumb should expose readable component titles"
)
let columnPath = ColumnViewPath.columns(for: breadcrumbURL)
expect(
    columnPath.map(\.folderURL.path) == ["/", "/Users", "/Users/bingwang", "/Users/bingwang/Pictures", "/Users/bingwang/Pictures/RAW"],
    "column view path should load one column for each folder in the current path"
)
expect(
    columnPath.map { $0.selectedURL?.path ?? "" } == ["/Users", "/Users/bingwang", "/Users/bingwang/Pictures", "/Users/bingwang/Pictures/RAW", ""],
    "column view path should select the next folder in each parent column"
)
let columnLayout = ColumnViewLayoutMetrics.layout(columnCount: 3, columnWidth: 260, viewportHeight: 720)
expect(
    columnLayout.documentWidth == 780 && columnLayout.documentHeight == 720,
    "column view layout should size the document to all columns and the visible viewport height"
)
expect(
    columnLayout.columnFrames.map { Int($0.x) } == [0, 260, 520],
    "column view layout should place columns from left to right with stable widths"
)
let emptyColumnLayout = ColumnViewLayoutMetrics.layout(columnCount: 0, columnWidth: 260, viewportHeight: 320)
expect(
    emptyColumnLayout.documentWidth == 260 && emptyColumnLayout.documentHeight == 500,
    "column view layout should keep a minimum document area even before columns are available"
)

let infoFile = operationsDirectory.appendingPathComponent("info.pdf")
try "pdf-data".write(to: infoFile, atomically: true, encoding: .utf8)
let fileInfo = try FileInfoProvider().info(for: infoFile)
expect(fileInfo.name == "info.pdf", "file info should expose display name")
expect(fileInfo.fileExtension == "pdf", "file info should expose file extension")
expect(fileInfo.category == .document, "file info should classify documents")
expect(fileInfo.byteSize == 8, "file info should include byte size")
expect(!fileInfo.isDirectory, "file info should distinguish regular files")

let archiveSource = operationsDirectory.appendingPathComponent("archive-source.txt")
try "archive-me".write(to: archiveSource, atomically: true, encoding: .utf8)
let archiveURL = try fileOperations.compress([archiveSource], in: operationsDirectory)
expect(archiveURL.pathExtension == "zip", "compress should create a zip archive")
expect(FileManager.default.fileExists(atPath: archiveURL.path), "compress should write the archive to disk")
let secondArchiveURL = try fileOperations.compress([archiveSource], in: operationsDirectory)
expect(secondArchiveURL.lastPathComponent != archiveURL.lastPathComponent, "compress should avoid overwriting an existing archive")
let dashedArchiveSource = operationsDirectory.appendingPathComponent("-dash.txt")
try "dash".write(to: dashedArchiveSource, atomically: true, encoding: .utf8)
let dashedArchiveURL = try fileOperations.compress([dashedArchiveSource], in: operationsDirectory)
expect(FileManager.default.fileExists(atPath: dashedArchiveURL.path), "compress should handle names that begin with a dash")

let tagStore = FileTagStore()
let taggedFile = operationsDirectory.appendingPathComponent("tagged.txt")
try "tag-me".write(to: taggedFile, atomically: true, encoding: .utf8)
try tagStore.setTagNames(["Red", "Work"], for: taggedFile)
let writtenTags = try tagStore.tagNames(for: taggedFile)
expect(writtenTags == ["Red", "Work"], "tag store should write and read Finder tags")
try tagStore.clearTags(for: taggedFile)
let clearedTags = try tagStore.tagNames(for: taggedFile)
expect(clearedTags.isEmpty, "tag store should clear Finder tags")
try tagStore.setFinderLabelColor(.red, for: taggedFile)
let redLabelValues = try taggedFile.resourceValues(forKeys: [.labelNumberKey, .tagNamesKey])
expect(redLabelValues.labelNumber == FinderTagColor.red.labelNumber, "tag store should write real Finder color labels")
expect(redLabelValues.tagNames == ["Red"], "red Finder label should be visible through system tag names")
try tagStore.clearFinderLabelColor(for: taggedFile)
let clearedLabelValues = try taggedFile.resourceValues(forKeys: [.labelNumberKey, .tagNamesKey])
expect(clearedLabelValues.labelNumber == 0, "clearing a Finder label should reset the system label number")
let labeledDirectoryFile = operationsDirectory.appendingPathComponent("labeled-directory-item.txt")
try "label-visible".write(to: labeledDirectoryFile, atomically: true, encoding: .utf8)
try tagStore.setFinderLabelColor(.blue, for: labeledDirectoryFile)
let labeledDirectoryItem = try DirectoryStore().loadItems(in: operationsDirectory)
    .first { $0.url.standardizedFileURL.path == labeledDirectoryFile.standardizedFileURL.path }
expect(
    labeledDirectoryItem?.finderLabelNumber == FinderTagColor.blue.labelNumber,
    "directory items should carry Finder label numbers for visible tag indicators"
)
let summaryItems = [
    FileItem(url: URL(fileURLWithPath: "/tmp/a.txt"), name: "a.txt", isDirectory: false, category: .document, byteSize: 10),
    FileItem(url: URL(fileURLWithPath: "/tmp/b.txt"), name: "b.txt", isDirectory: false, category: .document, byteSize: 15),
    FileItem(url: URL(fileURLWithPath: "/tmp/folder", isDirectory: true), name: "folder", isDirectory: true, category: .folder, byteSize: nil)
]
expect(SelectionSummary.totalFileByteSize(for: summaryItems) == 25, "selection summary should total only known file byte sizes")
expect(SelectionSummary.fileNames(for: summaryItems) == ["a.txt", "b.txt", "folder"], "selection summary should expose selected file names")

var navigationHistory = NavigationHistory()
let navA = URL(fileURLWithPath: "/tmp/A", isDirectory: true)
let navB = URL(fileURLWithPath: "/tmp/B", isDirectory: true)
let navC = URL(fileURLWithPath: "/tmp/C", isDirectory: true)
let navD = URL(fileURLWithPath: "/tmp/D", isDirectory: true)
navigationHistory.record(navA)
navigationHistory.record(navB)
navigationHistory.record(navC)
expect(navigationHistory.canGoBack, "history should allow back after recording multiple locations")
expect(!navigationHistory.canGoForward, "history should not allow forward at the newest location")
expect(navigationHistory.goBack() == navB, "first back should return the previous location")
expect(navigationHistory.canGoForward, "history should allow forward after going back")
expect(navigationHistory.goForward() == navC, "forward should return the next location")
expect(navigationHistory.goBack() == navB, "second back should return to the middle location")
navigationHistory.record(navD)
expect(navigationHistory.current == navD, "recording a new location should make it current")
expect(!navigationHistory.canGoForward, "recording a new location after back should clear forward history")

expect(FinderToolbarMetrics.height >= 60, "toolbar should be tall enough to visually match Finder")
expect(FinderToolbarMetrics.buttonWidth >= 44, "toolbar buttons should use Finder-like hit width")
expect(FinderToolbarMetrics.buttonHeight >= 38, "toolbar buttons should use Finder-like hit height")
expect(FinderToolbarMetrics.symbolSize >= 22, "toolbar symbols should not render as tiny icons")
expect(FinderToolbarMetrics.navigationSegmentWidth >= 54, "back and forward segments should have Finder-like visual weight")
expect(FinderToolbarMetrics.fullScreenTopGuard >= 28, "full-screen top guard should keep toolbar below the revealed menu bar")
expect(FinderToolbarMetrics.sidebarWidth >= 220, "sidebar should be close to Finder's visual width")
expect(FinderToolbarMetrics.breadcrumbHeight <= 30, "breadcrumb bar should stay visually compact")
expect(!FinderToolbarMetrics.usesAccentToolbarSymbols, "toolbar symbols should use neutral Finder-like tint instead of accent blue")
expect(FinderToolbarMetrics.usesStatefulToolbarSymbolTint, "toolbar symbols should use bright enabled tint and dim disabled tint")
expect(FinderToolbarMetrics.keepsDisabledNavigationArrowsVisible, "disabled back and forward arrows should remain visible in gray")
expect(FinderToolbarMetrics.showsToolbarButtonLabels, "toolbar operation buttons should show text labels under icons")
expect(FinderToolbarMetrics.labeledButtonHeight >= 52, "labeled toolbar buttons should be tall enough for icon and text")
expect(FinderToolbarMetrics.usesPreferredTextStyles, "interface text should use system preferred text styles where AppKit allows")
expect(FinderToolbarMetrics.viewModeSegmentWidth >= 150, "direct view mode control should have enough width for Finder-like segments")
expect(FinderToolbarMetrics.directViewModeMinimumWindowWidth > 0, "toolbar should define when direct view mode controls are visible")

expect(
    FinderKeyboardShortcut.resolve(keyCode: 33, charactersIgnoringModifiers: "[", modifiers: [.command]) == .goBack,
    "Command-[ should map to back navigation"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 30, charactersIgnoringModifiers: "]", modifiers: [.command]) == .goForward,
    "Command-] should map to forward navigation"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 126, charactersIgnoringModifiers: nil, modifiers: [.command]) == .goUp,
    "Command-Up should map to parent folder navigation"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 125, charactersIgnoringModifiers: nil, modifiers: [.command]) == .openSelection,
    "Command-Down should map to opening the current selection"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 18, charactersIgnoringModifiers: "1", modifiers: [.command]) == .showIconView,
    "Command-1 should map to icon view"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 19, charactersIgnoringModifiers: "2", modifiers: [.command]) == .showListView,
    "Command-2 should map to list view"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 20, charactersIgnoringModifiers: "3", modifiers: [.command]) == .showColumnView,
    "Command-3 should map to column view"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 3, charactersIgnoringModifiers: "f", modifiers: [.command]) == .focusSearch,
    "Command-F should map to search focus"
)
expect(
    FinderKeyboardShortcut.resolve(keyCode: 8, charactersIgnoringModifiers: "c", modifiers: [.command, .option]) == .copyPath,
    "Option-Command-C should map to copying selected paths"
)
let menuSpecs = SmartFinderMenuBarSpecification.menus
expect(
    menuSpecs.map(\.titleKey).contains("menu.view"),
    "menu bar should include a top-level View menu"
)
expect(
    menuSpecs.flatMap(\.items).contains {
        $0.action == .showColumnView &&
        $0.titleKey == "menu.display.columnView" &&
        $0.keyEquivalent == "3" &&
        $0.modifiers == [.command]
    },
    "menu bar should expose Column View with Command-3"
)
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .goBack } &&
    menuSpecs.flatMap(\.items).contains { $0.action == .goForward } &&
    menuSpecs.flatMap(\.items).contains { $0.action == .goUp },
    "menu bar should expose common navigation actions"
)
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .copyPath && $0.modifiers == [.command, .option] },
    "menu bar should expose Copy Path for users who do not know the shortcut"
)

expect(SmartFinderCoreBootstrap.isAvailable, "core module should load")
expect(category("/tmp/photo.jpg") == .image, "jpg should be image")
expect(category("/tmp/photo.HEIC") == .image, "HEIC should be image")
expect(category("/tmp/photo.webp") == .image, "webp should be image")
expect(category("/tmp/photo.dng") == .image, "dng raw should be image")
expect(category("/tmp/photo.CR3") == .image, "CR3 raw should be image")
expect(category("/tmp/photo.nef") == .image, "nef raw should be image")
expect(category("/tmp/photo.arw") == .image, "arw raw should be image")
expect(category("/tmp/photo.raf") == .image, "raf raw should be image")
expect(category("/tmp/photo.rw2") == .image, "rw2 raw should be image")
expect(category("/tmp/photo.orf") == .image, "orf raw should be image")
expect(category("/tmp/photo.pef") == .image, "pef raw should be image")
expect(category("/tmp/photo.srw") == .image, "srw raw should be image")
expect(category("/tmp/photo.x3f") == .image, "x3f raw should be image")
expect(category("/tmp/photo.mef") == .image, "mef raw should be image")
expect(category("/tmp/photo.kdc") == .image, "kdc raw should be image")
expect(category("/tmp/file.pdf") == .document, "pdf should be document")
expect(category("/tmp/notes.md") == .document, "markdown should be treated as a document for user-facing display")
expect(category("/tmp/file.xlsx") == .document, "xlsx should be document")
expect(category("/tmp/file.docx") == .document, "docx should be document")
expect(category("/tmp/file.pptx") == .document, "pptx should be document")
expect(category("/tmp/clip.mov") == .video, "mov should be video")
expect(category("/tmp/clip.mp4") == .video, "mp4 should be video")
expect(category("/tmp/song.mp3") == .audio, "mp3 should be audio")
expect(category("/tmp/song.wav") == .audio, "wav should be audio")
expect(category("/tmp/archive.zip") == .archive, "zip should be archive")
expect(category("/tmp/archive.rar") == .archive, "rar should be archive")
expect(category("/tmp/archive.7z") == .archive, "7z should be archive")
expect(category("/tmp/code.swift") == .code, "swift should be code")
expect(category("/tmp/code.js") == .code, "js should be code")
expect(category("/tmp/folder.jpg", isDirectory: true) == .folder, "directories should win over extension")
expect(ThumbnailPipeline.isThumbnailEligible(.image), "images should be thumbnail eligible")
expect(ThumbnailPipeline.isThumbnailEligible(.video), "videos should be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.document), "documents must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.audio), "audio must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.archive), "archives must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.code), "code must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.folder), "folders must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.other), "other files must not be thumbnail eligible")
expect(IconDisplayPolicy.style(for: .document) == .systemIcon, "documents should keep system default icons")
expect(IconDisplayPolicy.style(for: .audio) == .systemIcon, "audio files should keep system default icons")
expect(IconDisplayPolicy.style(for: .archive) == .systemIcon, "archives should keep system default icons")
expect(IconDisplayPolicy.style(for: .code) == .systemIcon, "code files should keep system default icons")
expect(IconDisplayPolicy.style(for: .other) == .systemIcon, "unknown files should keep system default icons")
let yellowTaggedFolder = FileItem(
    url: URL(fileURLWithPath: "/tmp/yellow-folder", isDirectory: true),
    name: "yellow-folder",
    isDirectory: true,
    category: .folder,
    finderLabelNumber: FinderTagColor.yellow.labelNumber
)
expect(
    IconDisplayPolicy.style(for: yellowTaggedFolder) == .tintedFolder(.yellow),
    "tagged folders should render with the Finder label color applied to the folder icon"
)
let untaggedFolder = FileItem(
    url: URL(fileURLWithPath: "/tmp/plain-folder", isDirectory: true),
    name: "plain-folder",
    isDirectory: true,
    category: .folder
)
expect(IconDisplayPolicy.style(for: untaggedFolder) == .systemIcon, "untagged folders should keep the standard folder icon")
let redTaggedDocument = FileItem(
    url: URL(fileURLWithPath: "/tmp/document.pdf"),
    name: "document.pdf",
    isDirectory: false,
    category: .document,
    finderLabelNumber: FinderTagColor.red.labelNumber
)
expect(IconDisplayPolicy.style(for: redTaggedDocument) == .systemIcon, "tagged files should keep their system type icons")
print("SmartFinderCoreTests passed")
