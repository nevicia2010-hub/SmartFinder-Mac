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
expect(category("/tmp/folder.jpg", isDirectory: true) == .folder, "directories should win over extension")
expect(category("/tmp/archive.zip") == .other, "zip should be other")
expect(ThumbnailPipeline.isThumbnailEligible(.image), "images should be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.document), "documents must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.folder), "folders must not be thumbnail eligible")
expect(!ThumbnailPipeline.isThumbnailEligible(.other), "other files must not be thumbnail eligible")
print("SmartFinderCoreTests passed")
