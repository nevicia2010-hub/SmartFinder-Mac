import AppKit
import SmartFinderCore

@MainActor
enum FileDragOperationResolver {
    static func operation(
        for info: NSDraggingInfo,
        sourceURLs: [URL],
        targetDirectoryURL: URL
    ) -> FileTransferOperation? {
        let sourceMask = info.draggingSourceOperationMask
        return FileDragOperationPolicy.operation(
            sourceAllowsCopy: sourceMask.contains(.copy),
            sourceAllowsMove: sourceMask.contains(.move),
            optionKeyDown: NSEvent.modifierFlags.contains(.option),
            sourceAndDestinationAreOnSameVolume: sourceURLs.allSatisfy {
                areOnSameVolume($0, targetDirectoryURL)
            }
        )
    }

    static func dragOperation(_ operation: FileTransferOperation) -> NSDragOperation {
        operation == .copy ? .copy : .move
    }

    private static func areOnSameVolume(_ sourceURL: URL, _ targetURL: URL) -> Bool {
        guard let sourceIdentifier = volumeIdentifier(for: sourceURL),
              let targetIdentifier = volumeIdentifier(for: targetURL) else {
            return false
        }
        return sourceIdentifier == targetIdentifier
    }

    private static func volumeIdentifier(for url: URL) -> AnyHashable? {
        guard let identifier = try? url.resourceValues(forKeys: [.volumeIdentifierKey]).volumeIdentifier else {
            return nil
        }
        return identifier as? AnyHashable
    }
}
