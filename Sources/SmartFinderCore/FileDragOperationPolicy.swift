import Foundation

public enum FileDragOperationPolicy {
    public static let sourceOperations: [FileTransferOperation] = [.copy, .move]

    public static func operation(
        sourceAllowsCopy: Bool,
        sourceAllowsMove: Bool,
        optionKeyDown: Bool,
        sourceAndDestinationAreOnSameVolume: Bool
    ) -> FileTransferOperation? {
        if optionKeyDown, sourceAllowsCopy {
            return .copy
        }
        if sourceAndDestinationAreOnSameVolume, sourceAllowsMove {
            return .move
        }
        if sourceAllowsCopy {
            return .copy
        }
        return nil
    }
}
