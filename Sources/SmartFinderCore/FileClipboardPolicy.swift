import Foundation

public struct FileClipboardMoveClaim: Equatable, Sendable {
    public let marker: String
    public let pasteboardChangeCount: Int
    public let sourcePaths: [String]

    public init(marker: String, pasteboardChangeCount: Int, sourceURLs: [URL]) {
        self.marker = marker
        self.pasteboardChangeCount = pasteboardChangeCount
        self.sourcePaths = Self.normalizedPaths(sourceURLs)
    }

    fileprivate static func normalizedPaths(_ urls: [URL]) -> [String] {
        urls.map { $0.standardizedFileURL.path }.sorted()
    }
}

public enum FileClipboardPolicy {
    public static let operationPasteboardType = "local.smartfinder.file-operation"
    public static let copyMarker = "smartfinder-copy"

    public static func moveMarker(token: String) -> String {
        "smartfinder-move:\(token)"
    }

    public static func operation(
        marker: String?,
        pasteboardChangeCount: Int,
        sourceURLs: [URL],
        trustedMoveClaim: FileClipboardMoveClaim?
    ) -> FileTransferOperation {
        guard let trustedMoveClaim,
              marker == trustedMoveClaim.marker,
              pasteboardChangeCount == trustedMoveClaim.pasteboardChangeCount,
              FileClipboardMoveClaim.normalizedPaths(sourceURLs) == trustedMoveClaim.sourcePaths else {
            return .copy
        }
        return .move
    }
}

public final class FileClipboardSession {
    public private(set) var trustedMoveClaim: FileClipboardMoveClaim?

    public init() {}

    public func recordMove(marker: String, pasteboardChangeCount: Int, sourceURLs: [URL]) {
        trustedMoveClaim = FileClipboardMoveClaim(
            marker: marker,
            pasteboardChangeCount: pasteboardChangeCount,
            sourceURLs: sourceURLs
        )
    }

    public func clear() {
        trustedMoveClaim = nil
    }
}
