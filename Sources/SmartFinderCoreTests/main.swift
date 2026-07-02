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
expect(category("/tmp/file.xlsx") == .document, "xlsx should be document")
expect(category("/tmp/file.docx") == .document, "docx should be document")
expect(category("/tmp/file.pptx") == .document, "pptx should be document")
expect(category("/tmp/clip.mov") == .video, "mov should be video")
expect(category("/tmp/clip.mp4") == .video, "mp4 should be video")
expect(category("/tmp/song.mp3") == .audio, "mp3 should be audio")
expect(category("/tmp/song.wav") == .audio, "wav should be audio")
expect(category("/tmp/archive.zip") == .archive, "zip should be archive")
expect(category("/tmp/archive.rar") == .archive, "rar should be archive")
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
print("SmartFinderCoreTests passed")
