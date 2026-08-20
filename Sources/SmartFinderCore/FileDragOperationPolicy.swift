import Foundation

public enum FileDragSourceContext: Equatable, Sendable {
    case insideApplication
    case outsideApplication
}

public enum FileDragSourceOperation: Equatable, Sendable {
    case copy
    case move
    case delete
}

public enum FileDragOperationPolicy {
    public static func sourceOperations(for context: FileDragSourceContext) -> [FileDragSourceOperation] {
        switch context {
        case .insideApplication:
            return [.copy, .move]
        case .outsideApplication:
            return [.copy, .move, .delete]
        }
    }

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
