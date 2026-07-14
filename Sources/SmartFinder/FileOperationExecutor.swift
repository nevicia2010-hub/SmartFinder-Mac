import Foundation
import SmartFinderCore

enum FileOperationExecutionResult: Sendable {
    case success([URL])
    case failure(String)
}

enum BackgroundOperationResult<Value: Sendable>: Sendable {
    case success(Value)
    case failure(String)
}

enum FolderSizeExecutionResult: Sendable {
    case success(FolderSizeResult)
    case cancelled
    case failure(String)
}

struct FileOperationExecutionError: Error, LocalizedError, Sendable {
    let message: String

    var errorDescription: String? {
        message
    }
}

actor FileOperationExecutor {
    func transfer(
        _ sourceURLs: [URL],
        toDirectory directoryURL: URL,
        operation: FileTransferOperation
    ) -> FileOperationExecutionResult {
        do {
            let transferredURLs = try FileOperations().transferPhotoCompanionGroup(
                sourceURLs,
                toDirectory: directoryURL,
                operation: operation
            )
            return .success(transferredURLs)
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
