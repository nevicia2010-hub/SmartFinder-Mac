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

expect(
    FileRenameInputPolicy.editableNameRange(forName: "草帽山极光.mp4", isDirectory: false) == NSRange(location: 0, length: 5),
    "file rename editing should select the base name and preserve the extension by default"
)
expect(
    FileRenameInputPolicy.editableNameRange(forName: "archive.tar.gz", isDirectory: false) == NSRange(location: 0, length: 11),
    "file rename editing should preserve only the last extension by default"
)
expect(
    FileRenameInputPolicy.editableNameRange(forName: "README", isDirectory: false) == NSRange(location: 0, length: 6),
    "extensionless file rename editing should select the full name"
)
expect(
    FileRenameInputPolicy.editableNameRange(forName: ".gitignore", isDirectory: false) == NSRange(location: 0, length: 10),
    "hidden extensionless file rename editing should select the full name"
)
expect(
    FileRenameInputPolicy.editableNameRange(forName: "Project.photoslibrary", isDirectory: true) == NSRange(location: 0, length: 21),
    "folder rename editing should select the full displayed folder name"
)

expect(FileNameValidationPolicy.isValid("夏季照片 01"), "normal Unicode file names should remain valid")
expect(!FileNameValidationPolicy.isValid("../escaped"), "file names must not escape through a parent path component")
expect(!FileNameValidationPolicy.isValid("nested/name"), "file names must not contain a path separator")
expect(!FileNameValidationPolicy.isValid("."), "the current-directory path component must not be accepted as a file name")
expect(!FileNameValidationPolicy.isValid(".."), "the parent-directory path component must not be accepted as a file name")
expect(!FileNameValidationPolicy.isValid("legacy:name"), "Finder-incompatible colon names must be rejected")

let invalidRenameDirectory = try fileOperations.createFolder(named: "Invalid Rename", in: operationsDirectory)
let invalidRenameSource = try fileOperations.createFile(named: "inside.txt", contents: "inside", in: invalidRenameDirectory)
var invalidRenameWasRejected = false
do {
    _ = try fileOperations.rename(invalidRenameSource, to: "../escaped.txt")
} catch {
    invalidRenameWasRejected = true
}
expect(invalidRenameWasRejected, "rename must reject a name that resolves outside the current folder")
expect(FileManager.default.fileExists(atPath: invalidRenameSource.path), "a rejected rename must leave the source file in place")
expect(
    !FileManager.default.fileExists(atPath: operationsDirectory.appendingPathComponent("escaped.txt").path),
    "a rejected rename must not create an escaped destination"
)

expect(
    FileDragOperationPolicy.operation(
        sourceAllowsCopy: true,
        sourceAllowsMove: false,
        optionKeyDown: false,
        sourceAndDestinationAreOnSameVolume: true
    ) == .copy,
    "a copy-only drag source must never be converted into a move"
)
expect(
    FileDragOperationPolicy.operation(
        sourceAllowsCopy: true,
        sourceAllowsMove: true,
        optionKeyDown: false,
        sourceAndDestinationAreOnSameVolume: true
    ) == .move,
    "same-volume file drags should move when the source allows moving"
)
expect(
    FileDragOperationPolicy.operation(
        sourceAllowsCopy: true,
        sourceAllowsMove: true,
        optionKeyDown: false,
        sourceAndDestinationAreOnSameVolume: false
    ) == .copy,
    "cross-volume file drags should copy by default"
)
expect(
    FileDragOperationPolicy.operation(
        sourceAllowsCopy: false,
        sourceAllowsMove: true,
        optionKeyDown: false,
        sourceAndDestinationAreOnSameVolume: false
    ) == nil,
    "cross-volume move-only drags should be rejected"
)
expect(
    FileDragOperationPolicy.operation(
        sourceAllowsCopy: true,
        sourceAllowsMove: true,
        optionKeyDown: true,
        sourceAndDestinationAreOnSameVolume: true
    ) == .copy,
    "holding Option should request a copy"
)

let clipboardSourceURLs = [URL(fileURLWithPath: "/tmp/clipboard-a.txt")]
let clipboardMoveMarker = FileClipboardPolicy.moveMarker(token: "trusted-token")
let clipboardMoveClaim = FileClipboardMoveClaim(
    marker: clipboardMoveMarker,
    pasteboardChangeCount: 42,
    sourceURLs: clipboardSourceURLs
)
expect(
    FileClipboardPolicy.operation(
        marker: clipboardMoveMarker,
        pasteboardChangeCount: 42,
        sourceURLs: clipboardSourceURLs,
        trustedMoveClaim: clipboardMoveClaim
    ) == .move,
    "an unchanged SmartFinder cut claim should paste as a move"
)
expect(
    FileClipboardPolicy.operation(
        marker: clipboardMoveMarker,
        pasteboardChangeCount: 43,
        sourceURLs: clipboardSourceURLs,
        trustedMoveClaim: clipboardMoveClaim
    ) == .copy,
    "a clipboard rewritten by another process must fall back to copy"
)
expect(
    FileClipboardPolicy.operation(
        marker: "move",
        pasteboardChangeCount: 42,
        sourceURLs: clipboardSourceURLs,
        trustedMoveClaim: clipboardMoveClaim
    ) == .copy,
    "an arbitrary public clipboard marker must not trigger a move"
)

let currentRequestID = UUID()
let staleRequestID = UUID()
let requestURL = URL(fileURLWithPath: "/tmp/request", isDirectory: true)
expect(
    LatestRequestPolicy.shouldApply(
        requestID: currentRequestID,
        currentRequestID: currentRequestID,
        requestedURL: requestURL,
        currentURL: requestURL
    ),
    "the latest request for the current URL should be applied"
)
expect(
    !LatestRequestPolicy.shouldApply(
        requestID: staleRequestID,
        currentRequestID: currentRequestID,
        requestedURL: requestURL,
        currentURL: requestURL
    ),
    "an older request must not overwrite a newer load of the same URL"
)

expect(
    ThumbnailCachePolicy.estimatedPixelCost(width: 180, height: 180, scale: 2) == 518_400,
    "Retina thumbnail cache cost must include the backing scale squared"
)
expect(
    ThumbnailCachePolicy.cacheKey(
        for: URL(fileURLWithPath: "/tmp/photo.jpg"),
        width: 96,
        height: 96,
        scale: 2
    ) != ThumbnailCachePolicy.cacheKey(
        for: URL(fileURLWithPath: "/tmp/photo.jpg"),
        width: 180,
        height: 180,
        scale: 2
    ),
    "thumbnail cache keys must distinguish requested pixel sizes"
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
expect(movedFile.lastPathComponent == "move-me.txt", "move to directory should keep the original item name when there is no collision")
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

let photoGroupDirectory = operationsDirectory.appendingPathComponent("photo-group", isDirectory: true)
let photoGroupTargetDirectory = operationsDirectory.appendingPathComponent("photo-group-target", isDirectory: true)
try FileManager.default.createDirectory(at: photoGroupDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: photoGroupTargetDirectory, withIntermediateDirectories: true)
let rawPhotoURL = photoGroupDirectory.appendingPathComponent("IMG_1001.CR3")
let renderedPhotoURL = photoGroupDirectory.appendingPathComponent("IMG_1001.JPG")
let xmpSidecarURL = photoGroupDirectory.appendingPathComponent("IMG_1001.XMP")
let acrSidecarURL = photoGroupDirectory.appendingPathComponent("IMG_1001.ACR")
let unrelatedRawURL = photoGroupDirectory.appendingPathComponent("IMG_1002.CR3")
try "raw".write(to: rawPhotoURL, atomically: true, encoding: .utf8)
try "jpg".write(to: renderedPhotoURL, atomically: true, encoding: .utf8)
try "xmp".write(to: xmpSidecarURL, atomically: true, encoding: .utf8)
try "acr".write(to: acrSidecarURL, atomically: true, encoding: .utf8)
try "other".write(to: unrelatedRawURL, atomically: true, encoding: .utf8)

let photoCompanionURLs = PhotoCompanionFilePolicy.companionURLs(for: rawPhotoURL)
expect(
    photoCompanionURLs.map(\.lastPathComponent).sorted() == ["IMG_1001.ACR", "IMG_1001.JPG", "IMG_1001.XMP"],
    "photo companion lookup should include same-stem rendered and sidecar files including ACR"
)
expect(
    PhotoCompanionFilePolicy.expandedSourceURLs(for: [rawPhotoURL, renderedPhotoURL])
        .map(\.lastPathComponent)
        .sorted() == ["IMG_1001.ACR", "IMG_1001.CR3", "IMG_1001.JPG", "IMG_1001.XMP"],
    "photo companion expansion should deduplicate selected group members"
)

let movedPhotoGroup = try fileOperations.transferPhotoCompanionGroup(
    [rawPhotoURL],
    toDirectory: photoGroupTargetDirectory,
    operation: .move
)
expect(
    movedPhotoGroup.map(\.lastPathComponent).sorted() == ["IMG_1001.ACR", "IMG_1001.CR3", "IMG_1001.JPG", "IMG_1001.XMP"],
    "group move should return all moved photo companion files"
)
expect(
    ["IMG_1001.ACR", "IMG_1001.CR3", "IMG_1001.JPG", "IMG_1001.XMP"].allSatisfy {
        FileManager.default.fileExists(atPath: photoGroupTargetDirectory.appendingPathComponent($0).path)
    },
    "group move should keep RAW, rendered image, and sidecar together"
)
expect(
    FileManager.default.fileExists(atPath: unrelatedRawURL.path),
    "group move should leave unrelated same-extension photos behind"
)

let renamedPhotoGroup = try fileOperations.renamePhotoCompanionGroup(
    photoGroupTargetDirectory.appendingPathComponent("IMG_1001.CR3"),
    to: "Keeper.CR3"
)
expect(
    renamedPhotoGroup.map(\.lastPathComponent).sorted() == ["Keeper.ACR", "Keeper.CR3", "Keeper.JPG", "Keeper.XMP"],
    "group rename should apply the new base name to same-stem companions"
)
expect(
    ["Keeper.ACR", "Keeper.CR3", "Keeper.JPG", "Keeper.XMP"].allSatisfy {
        FileManager.default.fileExists(atPath: photoGroupTargetDirectory.appendingPathComponent($0).path)
    },
    "group rename should preserve companion extensions"
)

let collisionSourceDirectory = operationsDirectory.appendingPathComponent("photo-collision-source", isDirectory: true)
let collisionTargetDirectory = operationsDirectory.appendingPathComponent("photo-collision-target", isDirectory: true)
try FileManager.default.createDirectory(at: collisionSourceDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: collisionTargetDirectory, withIntermediateDirectories: true)
for fileName in ["IMG_2001.CR3", "IMG_2001.JPG", "IMG_2001.XMP"] {
    try fileName.write(
        to: collisionSourceDirectory.appendingPathComponent(fileName),
        atomically: true,
        encoding: .utf8
    )
}
try "existing".write(
    to: collisionTargetDirectory.appendingPathComponent("IMG_2001.JPG"),
    atomically: true,
    encoding: .utf8
)
let collisionMoveResult = try fileOperations.transferPhotoCompanionGroup(
    [collisionSourceDirectory.appendingPathComponent("IMG_2001.CR3")],
    toDirectory: collisionTargetDirectory,
    operation: .move
)
expect(
    collisionMoveResult.map(\.lastPathComponent).sorted() == ["IMG_2001 copy.CR3", "IMG_2001 copy.JPG", "IMG_2001 copy.XMP"],
    "a photo group collision should apply one shared suffix to every companion"
)

let rollbackSourceDirectory = operationsDirectory.appendingPathComponent("rollback-source", isDirectory: true)
let rollbackTargetDirectory = operationsDirectory.appendingPathComponent("rollback-target", isDirectory: true)
try FileManager.default.createDirectory(at: rollbackSourceDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: rollbackTargetDirectory, withIntermediateDirectories: true)
let rollbackExistingSource = rollbackSourceDirectory.appendingPathComponent("first.txt")
let rollbackMissingSource = rollbackSourceDirectory.appendingPathComponent("missing.txt")
try "first".write(to: rollbackExistingSource, atomically: true, encoding: .utf8)
var transactionFailedAsExpected = false
do {
    _ = try fileOperations.transferPhotoCompanionGroup(
        [rollbackExistingSource, rollbackMissingSource],
        toDirectory: rollbackTargetDirectory,
        operation: .move
    )
} catch {
    transactionFailedAsExpected = true
}
expect(transactionFailedAsExpected, "a missing member should fail the complete transfer transaction")
expect(
    FileManager.default.fileExists(atPath: rollbackExistingSource.path),
    "a failed multi-item move must roll an already moved file back to its source"
)
expect(
    !FileManager.default.fileExists(atPath: rollbackTargetDirectory.appendingPathComponent("first.txt").path),
    "a failed multi-item move must not leave a partial destination behind"
)

let duplicateDragURLs = FileTransferPlan.uniqueSourceURLs([
    transferMoveSource,
    transferMoveSource,
    transferCopySource
])
expect(
    duplicateDragURLs == [transferMoveSource, transferCopySource],
    "drag transfer planning should ignore duplicate source URLs so one drop cannot move the same item twice"
)
expect(
    FileTransferPlan.affectedDirectoryURLs(
        sourceURLs: [transferredMove],
        targetDirectoryURL: operationsDirectory
    ) == [moveTargetDirectory.standardizedFileURL, operationsDirectory.standardizedFileURL],
    "drag transfer planning should mark both source and target folders as stale after a move"
)
expect(
    FileTransferPlan.refreshScope(
        isColumnView: true,
        currentFolderURL: moveTargetDirectory,
        affectedDirectoryURLs: [moveTargetDirectory, operationsDirectory]
    ) == .visibleColumns,
    "column-view transfers should refresh visible columns instead of reloading the whole browser"
)
expect(
    FileTransferPlan.refreshScope(
        isColumnView: false,
        currentFolderURL: operationsDirectory,
        affectedDirectoryURLs: [moveTargetDirectory, operationsDirectory]
    ) == .currentFolder,
    "icon and list transfers should reload the current folder only when that folder changed"
)
expect(
    FileTransferPlan.refreshScope(
        isColumnView: false,
        currentFolderURL: operationsDirectory,
        affectedDirectoryURLs: [moveTargetDirectory]
    ) == .none,
    "icon and list transfers should skip reloads when the current folder did not change"
)
let metadataChangedFile = operationsDirectory.appendingPathComponent("metadata-file.txt")
expect(
    FileMetadataRefreshPlan.affectedDirectoryURLs(changedItemURLs: [metadataChangedFile]) == [operationsDirectory.standardizedFileURL],
    "metadata refresh should mark the changed item's parent directory as affected"
)
expect(
    FileMetadataRefreshPlan.refreshScope(
        isColumnView: true,
        currentFolderURL: operationsDirectory,
        affectedDirectoryURLs: [operationsDirectory]
    ) == .visibleColumns,
    "column-view metadata refresh should update visible columns without rebuilding the whole browser"
)
expect(
    FileMetadataRefreshPlan.refreshScope(
        isColumnView: false,
        currentFolderURL: operationsDirectory,
        affectedDirectoryURLs: [operationsDirectory]
    ) == .currentFolder,
    "icon and list metadata refresh should update the current folder when it is affected"
)
let deletedFolder = operationsDirectory.appendingPathComponent("Deleted Folder", isDirectory: true)
let deletedChildFolder = deletedFolder.appendingPathComponent("Child", isDirectory: true)
expect(
    FileRemovalNavigationPolicy.folderToLoadAfterRemoval(
        removedURLs: [deletedFolder],
        currentFolderURL: deletedFolder
    ) == operationsDirectory.standardizedFileURL,
    "removing the currently loaded folder should navigate back to its parent"
)
expect(
    FileRemovalNavigationPolicy.folderToLoadAfterRemoval(
        removedURLs: [deletedFolder],
        currentFolderURL: deletedChildFolder
    ) == operationsDirectory.standardizedFileURL,
    "removing an ancestor of the current folder should navigate back to the removed folder's parent"
)
expect(
    FileRemovalNavigationPolicy.folderToLoadAfterRemoval(
        removedURLs: [deletedFolder],
        currentFolderURL: operationsDirectory
    ) == operationsDirectory.standardizedFileURL,
    "removing a child item should keep the current folder loaded"
)
let originalRenamedFolder = operationsDirectory.appendingPathComponent("Folder Before Rename", isDirectory: true)
let newRenamedFolder = operationsDirectory.appendingPathComponent("Folder After Rename", isDirectory: true)
let renamedChildFolder = originalRenamedFolder.appendingPathComponent("Child", isDirectory: true)
expect(
    FileRenameNavigationPolicy.folderToLoadAfterRename(
        originalURL: originalRenamedFolder,
        renamedURL: newRenamedFolder,
        renamedItemIsDirectory: true,
        currentFolderURL: originalRenamedFolder
    ) == operationsDirectory.standardizedFileURL,
    "renaming the currently loaded folder should return to its parent instead of opening the renamed folder"
)
expect(
    FileRenameNavigationPolicy.folderToLoadAfterRename(
        originalURL: originalRenamedFolder,
        renamedURL: newRenamedFolder,
        renamedItemIsDirectory: true,
        currentFolderURL: renamedChildFolder
    ) == operationsDirectory.standardizedFileURL,
    "renaming an ancestor of the current folder should return to the renamed folder's parent"
)
expect(
    FileRenameNavigationPolicy.folderToLoadAfterRename(
        originalURL: originalRenamedFolder,
        renamedURL: newRenamedFolder,
        renamedItemIsDirectory: true,
        currentFolderURL: operationsDirectory
    ) == operationsDirectory.standardizedFileURL,
    "renaming a child folder should keep the current folder loaded"
)
expect(
    FileRenameNavigationPolicy.folderToLoadAfterRename(
        originalURL: operationsDirectory.appendingPathComponent("note.txt"),
        renamedURL: operationsDirectory.appendingPathComponent("renamed-note.txt"),
        renamedItemIsDirectory: false,
        currentFolderURL: operationsDirectory
    ) == operationsDirectory.standardizedFileURL,
    "renaming a file should keep the current folder loaded"
)

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
let symlinkTargetDirectory = try fileOperations.createFolder(named: "Symlink Target", in: operationsDirectory)
let symlinkDirectory = operationsDirectory.appendingPathComponent("Macintosh HD")
try FileManager.default.createSymbolicLink(at: symlinkDirectory, withDestinationURL: symlinkTargetDirectory)
let symlinkDirectoryItem = try DirectoryStore().loadItems(
    in: operationsDirectory,
    options: DirectoryLoadOptions(includesHiddenItems: true)
).first { $0.url == symlinkDirectory }
expect(
    symlinkDirectoryItem?.isDirectory == true,
    "directory loading should treat symbolic links that resolve to folders as folders"
)
let symlinkDirectoryInfo = try FileInfoProvider().info(for: symlinkDirectory)
expect(
    symlinkDirectoryInfo.isDirectory,
    "file info should treat symbolic links that resolve to folders as folders"
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
], namesByPath: [
    "/": "Macintosh HD"
])

expect(
    mountedVolumeLocations.map(\.name) == ["Macintosh HD", "CameraSSD", "Photo Archive"],
    "mounted volumes should include the local system disk plus browsable /Volumes entries"
)
expect(
    mountedVolumeLocations.map(\.url.path) == ["/", "/Volumes/CameraSSD", "/Volumes/Photo Archive"],
    "mounted volume URLs should preserve the local root and /Volumes paths"
)
expect(
    mountedVolumeLocations.map(\.isEjectable) == [false, true, true],
    "the local system disk should not expose eject while external /Volumes entries should"
)
expect(
    VolumeEjectFeedback.message(for: .started, volumeName: "CameraSSD") == "Ejecting CameraSSD...",
    "eject feedback should announce when a volume eject starts"
)
expect(
    VolumeEjectFeedback.message(for: .succeeded, volumeName: "CameraSSD") == "Ejected CameraSSD",
    "eject feedback should announce when a volume eject succeeds"
)
expect(
    VolumeEjectFeedback.message(for: .failed(errorDescription: "Busy"), volumeName: "CameraSSD") == "Could not eject CameraSSD: Busy",
    "eject feedback should include failure details"
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
    volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceWillUnmountNotification"),
    "will-unmount notifications should refresh the mounted-volume sidebar before installer disk images disappear"
)
expect(
    volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidRenameVolumeNotification"),
    "volume rename notifications should refresh the mounted-volume sidebar while the window is open"
)
expect(
    volumeRefreshPolicy.sidebarRefreshPasses(forNotificationNamed: "NSWorkspaceDidUnmountNotification").map(\.delay) == [0, 0.4, 1.2],
    "disk-image unmount notifications should schedule immediate and delayed sidebar refresh passes"
)
expect(
    volumeRefreshPolicy.sidebarRefreshPasses(forNotificationNamed: "NSWorkspaceDidWakeNotification").isEmpty,
    "unrelated workspace notifications should not schedule sidebar refresh passes"
)
expect(
    !volumeRefreshPolicy.shouldRefreshSidebar(forNotificationNamed: "NSWorkspaceDidWakeNotification"),
    "unrelated workspace notifications should not refresh the mounted-volume sidebar"
)

let appearanceRefreshPolicy = AppearanceRefreshPolicy()
expect(
    appearanceRefreshPolicy.shouldRefreshAppearance(forNotificationNamed: "AppleInterfaceThemeChangedNotification"),
    "system interface theme changes should refresh visible SmartFinder window colors"
)
expect(
    !appearanceRefreshPolicy.shouldRefreshAppearance(forNotificationNamed: "NSWorkspaceDidMountNotification"),
    "unrelated system notifications should not refresh SmartFinder window colors"
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
let volumeRootURL = URL(fileURLWithPath: "/Volumes/lavoro", isDirectory: true)
let volumeChildURL = volumeRootURL.appendingPathComponent("01_2026_工作资料", isDirectory: true)
let anchoredColumnPath = ColumnViewPath.columns(for: volumeChildURL, rootURL: volumeRootURL)
expect(
    anchoredColumnPath.map(\.folderURL.path) == ["/Volumes/lavoro", "/Volumes/lavoro/01_2026_工作资料"],
    "column view path should start at the selected sidebar source instead of showing technical parent folders"
)
expect(
    anchoredColumnPath.map { $0.selectedURL?.path ?? "" } == ["/Volumes/lavoro/01_2026_工作资料", ""],
    "anchored column view path should select the next folder within the sidebar source"
)
let replacedColumnNames = ColumnViewSelectionUpdate.replaceTrailingColumns(
    in: ["root", "Users", "old-home", "old-child"],
    selectedColumnIndex: 1,
    selectedColumn: "Users-selected",
    nextColumn: "bingwang"
)
expect(
    replacedColumnNames == ["root", "Users-selected", "bingwang"],
    "column view selection should preserve left columns and replace stale right-side columns"
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
let adaptiveColumnWidths = ColumnViewWidthMetrics.widths(
    forColumnTextWidths: [
        [80, 140],
        [420],
        []
    ],
    minimumColumnWidth: 220,
    maximumColumnWidth: 360,
    textPadding: 58
)
expect(
    adaptiveColumnWidths == [220, 360, 220],
    "column view widths should expand for long names, clamp at a maximum, and keep empty columns usable"
)
let adaptiveColumnLayout = ColumnViewLayoutMetrics.layout(columnWidths: adaptiveColumnWidths, viewportHeight: 600)
expect(
    adaptiveColumnLayout.documentWidth == 800 &&
    adaptiveColumnLayout.columnFrames.map { Int($0.x) } == [0, 220, 580],
    "column view layout should place variable-width columns without overlap"
)

let infoFile = operationsDirectory.appendingPathComponent("info.pdf")
try "pdf-data".write(to: infoFile, atomically: true, encoding: .utf8)
let fileInfo = try FileInfoProvider().info(for: infoFile)
expect(fileInfo.name == "info.pdf", "file info should expose display name")
expect(fileInfo.fileExtension == "pdf", "file info should expose file extension")
expect(fileInfo.category == .document, "file info should classify documents")
expect(fileInfo.byteSize == 8, "file info should include byte size")
expect(!fileInfo.isDirectory, "file info should distinguish regular files")
let infoPanelPresentation = FileInfoPanelPresentationBuilder().presentation(
    for: fileInfo,
    selectedCount: 1,
    kindLabel: "PDF",
    sizeLabel: "8 bytes",
    createdLabel: "Created label",
    modifiedLabel: "Modified label"
)
expect(infoPanelPresentation.title == "info.pdf", "info panel presentation should use the item name as the single-item title")
expect(
    infoPanelPresentation.sections.map(\.kind) == [.general, .nameAndExtension, .path, .system],
    "info panel presentation should expose Finder-style sections"
)
expect(
    infoPanelPresentation.row(for: .kind)?.value == "PDF" &&
    infoPanelPresentation.row(for: .size)?.value == "8 bytes" &&
    infoPanelPresentation.row(for: .where)?.value == operationsDirectory.path,
    "info panel general section should include kind, size, and parent location"
)
expect(
    infoPanelPresentation.row(for: .name)?.value == "info.pdf" &&
    infoPanelPresentation.row(for: .extension)?.value == "pdf",
    "info panel name section should include the file name and extension"
)
expect(
    infoPanelPresentation.row(for: .fullPath)?.value == infoFile.path &&
    infoPanelPresentation.row(for: .fullPath)?.isCopyable == true,
    "info panel path section should include a copyable full path"
)
let infoPanelPresentationWithOpenWith = FileInfoPanelPresentationBuilder().presentation(
    for: fileInfo,
    selectedCount: 1,
    kindLabel: "PDF",
    sizeLabel: "8 bytes",
    createdLabel: nil,
    modifiedLabel: nil,
    defaultApplicationName: "Preview"
)
expect(
    infoPanelPresentationWithOpenWith.sections.map(\.kind).contains(.openWith),
    "info panel presentation should expose an Open With section for selectable applications"
)
expect(
    infoPanelPresentationWithOpenWith.row(for: .defaultApplication)?.value == "Preview",
    "info panel Open With section should include the current default application name"
)
expect(
    FileInfoPanelLayoutMetrics.sectionTitleLeading == 0,
    "info panel section titles should stay left-aligned instead of drifting to the trailing edge"
)
expect(
    FileInfoPanelLayoutMetrics.rowLeading > FileInfoPanelLayoutMetrics.sectionTitleLeading,
    "info panel detail rows should be indented under Finder-style section titles"
)
expect(
    FileInfoPanelLayoutMetrics.fieldLabelAlignment == .leading,
    "info panel field labels should be leading-aligned so localized labels do not look right-justified"
)
expect(
    FileInfoPanelLayoutMetrics.contentTrailingInset >= 20,
    "info panel content should keep a visible trailing margin instead of touching the window edge"
)
expect(
    OpenWithMenuPolicy.canShowOpenWith(selectedItemCount: 1, selectedItemIsDirectory: false),
    "Open With should be available for a single selected file"
)
expect(
    !OpenWithMenuPolicy.canShowOpenWith(selectedItemCount: 0, selectedItemIsDirectory: false),
    "Open With should not be available when nothing is selected"
)
expect(
    !OpenWithMenuPolicy.canShowOpenWith(selectedItemCount: 2, selectedItemIsDirectory: false),
    "Open With should not be available for multiple selected items"
)
expect(
    !OpenWithMenuPolicy.canShowOpenWith(selectedItemCount: 1, selectedItemIsDirectory: true),
    "Open With should not be available for folders"
)
let defaultApplicationChangePolicy = DefaultApplicationChangePolicy()
expect(
    defaultApplicationChangePolicy.canChangeDefaultApplication(
        contentTypeIdentifier: "public.mpeg-4",
        applicationBundleIdentifier: "com.apple.QuickTimePlayerX"
    ),
    "default application changes should be available when both a content type and app bundle identifier are known"
)
expect(
    !defaultApplicationChangePolicy.canChangeDefaultApplication(
        contentTypeIdentifier: nil,
        applicationBundleIdentifier: "com.apple.QuickTimePlayerX"
    ),
    "default application changes should be disabled when the file content type is unknown"
)
expect(
    !defaultApplicationChangePolicy.canChangeDefaultApplication(
        contentTypeIdentifier: "public.mpeg-4",
        applicationBundleIdentifier: nil
    ),
    "default application changes should be disabled when the selected app bundle identifier is unknown"
)
let photoMetadata = PhotoMetadataSummary(properties: [
    "PixelWidth": 8192,
    "PixelHeight": 5464,
    "{TIFF}": [
        "Make": "Canon",
        "Model": "EOS R5",
        "DateTime": "2026:07:09 09:12:13",
        "XResolution": 300,
        "YResolution": 300
    ],
    "{Exif}": [
        "DateTimeOriginal": "2026:07:08 18:22:41",
        "LensModel": "RF24-70mm F2.8 L IS USM",
        "ISOSpeedRatings": [400],
        "FocalLength": 50.0,
        "FNumber": 2.8,
        "ExposureTime": 0.005,
        "ExposureBiasValue": -0.3333333,
        "WhiteBalance": 1,
        "ColorSpace": 1
    ],
    "{GPS}": [
        "Latitude": 45.4642,
        "LatitudeRef": "N",
        "Longitude": 9.19,
        "LongitudeRef": "E"
    ]
])
expect(photoMetadata.captureDate == "2026:07:08 18:22:41", "photo metadata should prefer original capture date")
expect(photoMetadata.camera == "Canon EOS R5", "photo metadata should combine camera make and model")
expect(photoMetadata.lens == "RF24-70mm F2.8 L IS USM", "photo metadata should expose lens model")
expect(photoMetadata.pixelDimensions == "8192 x 5464", "photo metadata should expose pixel dimensions")
expect(photoMetadata.resolution == "300 x 300 dpi", "photo metadata should expose image resolution when available")
expect(photoMetadata.iso == "ISO 400", "photo metadata should expose ISO")
expect(photoMetadata.focalLength == "50 mm", "photo metadata should format focal length")
expect(photoMetadata.aperture == "f/2.8", "photo metadata should format aperture")
expect(photoMetadata.shutterSpeed == "1/200 s", "photo metadata should format shutter speed")
expect(photoMetadata.exposureCompensation == "-0.3 EV", "photo metadata should format exposure compensation")
expect(photoMetadata.whiteBalance == "Manual", "photo metadata should map white balance mode")
expect(photoMetadata.colorSpace == "sRGB", "photo metadata should map color space")
expect(photoMetadata.gpsCoordinate == "45.464200, 9.190000", "photo metadata should format GPS coordinates")
expect(
    photoMetadata.mapsURL?.absoluteString == "http://maps.apple.com/?ll=45.464200,9.190000",
    "photo metadata should expose an Apple Maps URL for GPS coordinates"
)

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
let firstTemplateFile = try fileOperations.createFile(fromTemplate: .plainText, in: operationsDirectory)
let secondTemplateFile = try fileOperations.createFile(fromTemplate: .plainText, in: operationsDirectory)
let csvTemplateFile = try fileOperations.createFile(fromTemplate: .csv, in: operationsDirectory)
let csvTemplateContents = try String(contentsOf: csvTemplateFile, encoding: .utf8)
expect(firstTemplateFile.lastPathComponent == "Untitled.txt", "text template should create a predictable default file name")
expect(secondTemplateFile.lastPathComponent == "Untitled 2.txt", "text template should avoid overwriting existing template files")
expect(
    csvTemplateContents == "Column 1,Column 2\n",
    "csv template should write starter csv contents"
)
expect(
    FileTemplateCatalog.templates.map(\.kind) == [.plainText, .markdown, .csv],
    "file template catalog should expose text, markdown, and csv templates"
)
let columnFolderCreationTarget = FileCreationTargetPolicy.targetDirectory(
    currentFolderURL: URL(fileURLWithPath: "/tmp/rightmost", isDirectory: true),
    contextualFolderURL: URL(fileURLWithPath: "/tmp/parent-column", isDirectory: true)
)
expect(
    columnFolderCreationTarget?.path == "/tmp/parent-column",
    "file creation should target the column or folder where the user opened the context menu"
)
let defaultFolderCreationTarget = FileCreationTargetPolicy.targetDirectory(
    currentFolderURL: URL(fileURLWithPath: "/tmp/rightmost", isDirectory: true),
    contextualFolderURL: nil
)
expect(
    defaultFolderCreationTarget?.path == "/tmp/rightmost",
    "file creation should fall back to the current folder when there is no contextual column target"
)
expect(
    FileCreationTargetPolicy.targetDirectory(currentFolderURL: nil, contextualFolderURL: nil) == nil,
    "file creation should be unavailable without any known target folder"
)
expect(
    FileDragOperationPolicy.sourceOperations.contains(.move),
    "file browser drag sources should allow moving files and folders inside SmartFinder"
)
expect(
    FileDragOperationPolicy.sourceOperations.contains(.copy),
    "file browser drag sources should allow Option-drag copying files and folders inside SmartFinder"
)
expect(
    FileDragOperationPolicy.sourceOperations.count == 2,
    "file browser drag sources should expose only copy and move operations"
)
let dropDefaultDirectory = URL(fileURLWithPath: "/tmp/drop-default", isDirectory: true)
let dropFolderItem = dropDefaultDirectory.appendingPathComponent("Folder B", isDirectory: true)
let dropFileItem = dropDefaultDirectory.appendingPathComponent("note.txt", isDirectory: false)
expect(
    FileDropTargetPolicy.targetDirectory(
        defaultDirectoryURL: dropDefaultDirectory,
        hitItemURL: dropFolderItem,
        hitItemIsDirectory: true
    ) == dropFolderItem.standardizedFileURL,
    "dropping on a folder item should target that folder even when AppKit proposes an insertion drop"
)
expect(
    FileDropTargetPolicy.targetDirectory(
        defaultDirectoryURL: dropDefaultDirectory,
        hitItemURL: dropFileItem,
        hitItemIsDirectory: false
    ) == dropDefaultDirectory.standardizedFileURL,
    "dropping on a regular file should keep the current folder as the target"
)
expect(
    FileDropTargetPolicy.targetDirectory(
        defaultDirectoryURL: dropDefaultDirectory,
        hitItemURL: nil,
        hitItemIsDirectory: false
    ) == dropDefaultDirectory.standardizedFileURL,
    "dropping on empty browser space should target the current folder"
)
expect(
    SelectionDragPreservationPolicy.shouldPreserveSelection(
        clickedItemIsSelected: true,
        selectedItemCount: 3,
        usesSelectionModifier: false
    ),
    "dragging from an already selected item should preserve the multi-selection"
)
expect(
    !SelectionDragPreservationPolicy.shouldPreserveSelection(
        clickedItemIsSelected: false,
        selectedItemCount: 3,
        usesSelectionModifier: false
    ),
    "clicking an unselected item should allow the browser to replace the selection"
)
expect(
    !SelectionDragPreservationPolicy.shouldPreserveSelection(
        clickedItemIsSelected: true,
        selectedItemCount: 1,
        usesSelectionModifier: false
    ),
    "single selection does not need preservation before dragging"
)
expect(
    !SelectionDragPreservationPolicy.shouldPreserveSelection(
        clickedItemIsSelected: true,
        selectedItemCount: 3,
        usesSelectionModifier: true
    ),
    "Command or Shift clicks should keep their normal selection-changing behavior"
)

let pathFormatURLs = [
    URL(fileURLWithPath: "/Volumes/Photo Archive/Test File.txt"),
    URL(fileURLWithPath: "/tmp/simple.md")
]
expect(
    CopyPathFormatter.strings(for: pathFormatURLs, format: .fullPath) == [
        "/Volumes/Photo Archive/Test File.txt",
        "/tmp/simple.md"
    ],
    "copy path formatter should expose full paths"
)
expect(
    CopyPathFormatter.strings(for: pathFormatURLs, format: .parentDirectory) == [
        "/Volumes/Photo Archive",
        "/tmp"
    ],
    "copy path formatter should expose parent directories"
)
expect(
    CopyPathFormatter.strings(for: pathFormatURLs, format: .shellEscapedPath) == [
        "'/Volumes/Photo Archive/Test File.txt'",
        "/tmp/simple.md"
    ],
    "copy path formatter should shell-escape paths with spaces for Terminal use"
)

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
let sizeRoot = try fileOperations.createFolder(named: "Size Root", in: operationsDirectory)
let sizeChild = try fileOperations.createFolder(named: "Nested", in: sizeRoot)
try "12345".write(to: sizeRoot.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
try "1234567".write(to: sizeChild.appendingPathComponent("b.txt"), atomically: true, encoding: .utf8)
let folderSizeResult = try FolderSizeCalculator().calculateSize(of: sizeRoot)
expect(folderSizeResult.byteSize == 12, "folder size calculator should total nested regular files on demand")
expect(folderSizeResult.fileCount == 2, "folder size calculator should count nested files")
expect(folderSizeResult.folderCount == 1, "folder size calculator should count nested folders")
let folderSizeCancellation = FolderSizeCancellationToken()
folderSizeCancellation.cancel()
do {
    _ = try FolderSizeCalculator().calculateSize(of: sizeRoot, cancellationToken: folderSizeCancellation)
    expect(false, "folder size calculation should throw after cancellation")
} catch FolderSizeCalculationError.cancelled {
    expect(true, "folder size calculation should support cancellation")
}

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
    IconLabelLayoutPolicy.titleFontSize(forIconSize: 64) == 12,
    "small icon labels should keep Finder-like compact title text"
)
expect(
    IconLabelLayoutPolicy.titleFontSize(forIconSize: 180) == 14,
    "large icon labels should scale title text modestly with icon size"
)
expect(
    IconLabelLayoutPolicy.maximumTitleLineCount == 2,
    "icon labels should allow long names to wrap to two lines"
)
expect(
    IconLabelLayoutPolicy.itemHeight(forIconSize: 180) >= 180 + 88,
    "large icon cells should reserve enough height for wrapped names and subtitles"
)

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
expect(
    FinderKeyboardShortcut.resolve(keyCode: 7, charactersIgnoringModifiers: "x", modifiers: [.command]) == .cut,
    "Command-X should map to cutting selected files for Windows-style move paste"
)
expect(
    FileClipboardPolicy.operation(
        marker: FileClipboardPolicy.copyMarker,
        pasteboardChangeCount: 0,
        sourceURLs: [],
        trustedMoveClaim: nil
    ) == .copy &&
    FileClipboardPolicy.operation(
        marker: nil,
        pasteboardChangeCount: 0,
        sourceURLs: [],
        trustedMoveClaim: nil
    ) == .copy,
    "file clipboard policy should default untrusted and copy markers to copy operations"
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
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .cut && $0.keyEquivalent == "x" && $0.modifiers == [.command] },
    "menu bar should expose Cut with Command-X for Windows-style file moves"
)
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .newCSVFile },
    "menu bar should expose the csv file template"
)
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .copyParentPath } &&
    menuSpecs.flatMap(\.items).contains { $0.action == .copyShellPath },
    "menu bar should expose enhanced copy-path formats"
)
expect(
    menuSpecs.flatMap(\.items).contains { $0.action == .calculateFolderSize } &&
    menuSpecs.flatMap(\.items).contains { $0.action == .dualPane },
    "menu bar should expose on-demand folder size and dual pane controls"
)
expect(
    DualPanePolicy.shouldLoadSecondaryPane(wasVisible: false, isVisible: true, hasLoadedSecondaryPane: false),
    "dual pane should load the secondary pane only when first opened"
)
expect(
    !DualPanePolicy.shouldLoadSecondaryPane(wasVisible: false, isVisible: false, hasLoadedSecondaryPane: false) &&
    !DualPanePolicy.shouldLoadSecondaryPane(wasVisible: true, isVisible: true, hasLoadedSecondaryPane: true),
    "dual pane should avoid background secondary loading"
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
