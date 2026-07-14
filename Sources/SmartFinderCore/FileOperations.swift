import Foundation

public enum FileOperationError: Error, LocalizedError {
    case emptyCompressionSelection
    case compressionFailed(String)
    case destinationExists(String)
    case transactionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyCompressionSelection:
            return "No files were selected for compression."
        case .compressionFailed(let message):
            return message.isEmpty ? "Compression failed." : message
        case .destinationExists(let path):
            return "A destination file already exists: \(path)"
        case .transactionFailed(let message):
            return message
        }
    }
}

public enum FileTransferOperation: Equatable, Sendable {
    case copy
    case move
}

public final class FileOperations {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    @discardableResult
    public func createFolder(named name: String, in directoryURL: URL) throws -> URL {
        let destinationURL = try destinationURL(named: name, in: directoryURL, isDirectory: true)
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: false)
        return destinationURL
    }

    @discardableResult
    public func createFile(named name: String, contents: String = "", in directoryURL: URL) throws -> URL {
        let destinationURL = try destinationURL(named: name, in: directoryURL, isDirectory: false)
        try contents.write(to: destinationURL, atomically: true, encoding: .utf8)
        return destinationURL
    }

    @discardableResult
    public func createFile(fromTemplate kind: FileTemplateKind, in directoryURL: URL) throws -> URL {
        let template = FileTemplateCatalog.template(for: kind)
        let destinationURL = uniqueFileURL(named: template.defaultFileName, in: directoryURL)
        try template.contents.write(to: destinationURL, atomically: true, encoding: .utf8)
        return destinationURL
    }

    @discardableResult
    public func rename(_ url: URL, to newName: String) throws -> URL {
        let destinationURL = try destinationURL(
            named: newName,
            in: url.deletingLastPathComponent(),
            isDirectory: false
        )
        try fileManager.moveItem(at: url, to: destinationURL)
        return destinationURL
    }

    @discardableResult
    public func copy(_ sourceURL: URL, toDirectory directoryURL: URL) throws -> URL {
        let destinationURL = uniqueDestinationURL(for: sourceURL, in: directoryURL)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    @discardableResult
    public func move(_ sourceURL: URL, toDirectory directoryURL: URL) throws -> URL {
        let destinationURL = uniqueMoveDestinationURL(for: sourceURL, in: directoryURL)
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    @discardableResult
    public func transfer(_ sourceURL: URL, toDirectory directoryURL: URL, operation: FileTransferOperation) throws -> URL {
        switch operation {
        case .copy:
            return try copy(sourceURL, toDirectory: directoryURL)
        case .move:
            return try move(sourceURL, toDirectory: directoryURL)
        }
    }

    @discardableResult
    public func transferPhotoCompanionGroup(
        _ sourceURLs: [URL],
        toDirectory directoryURL: URL,
        operation: FileTransferOperation
    ) throws -> [URL] {
        let groups = PhotoCompanionFilePolicy.expandedSourceGroups(for: sourceURLs)
        let plan = plannedTransferMutations(
            for: groups,
            toDirectory: directoryURL,
            operation: operation
        )
        return try execute(plan, operation: operation)
    }

    @discardableResult
    public func renamePhotoCompanionGroup(_ url: URL, to newName: String) throws -> [URL] {
        let sourceURLs = PhotoCompanionFilePolicy.expandedSourceURLs(for: [url])
        let parentURL = url.deletingLastPathComponent()
        let primaryDestinationURL = try destinationURL(named: newName, in: parentURL, isDirectory: false)
        let newBaseName = primaryDestinationURL.deletingPathExtension().lastPathComponent

        let renamePairs: [(source: URL, destination: URL)] = sourceURLs.map { sourceURL in
            if sourceURL.standardizedFileURL == url.standardizedFileURL {
                return (sourceURL, primaryDestinationURL)
            }
            let destinationURL = parentURL
                .appendingPathComponent(newBaseName)
                .appendingPathExtension(sourceURL.pathExtension)
            return (sourceURL, destinationURL)
        }

        var destinationPaths = Set<String>()
        for pair in renamePairs {
            let sourcePath = pair.source.standardizedFileURL.path
            let destinationPath = pair.destination.standardizedFileURL.path
            guard !destinationPaths.contains(destinationPath) else {
                throw FileOperationError.destinationExists(destinationPath)
            }
            destinationPaths.insert(destinationPath)

            if sourcePath != destinationPath, fileManager.fileExists(atPath: destinationPath) {
                throw FileOperationError.destinationExists(destinationPath)
            }
        }

        let plan = renamePairs.map { PlannedMutation(source: $0.source, destination: $0.destination) }
        return try execute(plan, operation: .move)
    }

    @discardableResult
    public func compress(_ sourceURLs: [URL], in directoryURL: URL) throws -> URL {
        guard !sourceURLs.isEmpty else {
            throw FileOperationError.emptyCompressionSelection
        }

        let archiveURL = uniqueArchiveURL(for: sourceURLs, in: directoryURL)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = directoryURL
        process.arguments = ["-qry", archiveURL.path, "--"] + sourceURLs.map(\.lastPathComponent)

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw FileOperationError.compressionFailed(message)
        }

        return archiveURL
    }

    public func uniqueDestinationURL(for sourceURL: URL, in directoryURL: URL) -> URL {
        let extensionPart = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directoryURL.appendingPathComponent(copyName(baseName: baseName, extensionPart: extensionPart, index: nil))
        var index = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent(copyName(baseName: baseName, extensionPart: extensionPart, index: index))
            index += 1
        }

        return candidate
    }

    public func uniqueMoveDestinationURL(for sourceURL: URL, in directoryURL: URL) -> URL {
        let originalName = sourceURL.lastPathComponent
        let originalCandidate = directoryURL.appendingPathComponent(originalName)
        guard fileManager.fileExists(atPath: originalCandidate.path) else {
            return originalCandidate
        }
        return uniqueDestinationURL(for: sourceURL, in: directoryURL)
    }

    public func uniqueArchiveURL(for sourceURLs: [URL], in directoryURL: URL) -> URL {
        let baseName: String
        if sourceURLs.count == 1 {
            let source = sourceURLs[0]
            if source.pathExtension.isEmpty {
                baseName = source.lastPathComponent
            } else {
                baseName = source.deletingPathExtension().lastPathComponent
            }
        } else {
            baseName = "Archive"
        }

        var candidate = directoryURL.appendingPathComponent("\(baseName).zip")
        var index = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directoryURL.appendingPathComponent("\(baseName) \(index).zip")
            index += 1
        }
        return candidate
    }

    public func uniqueFileURL(named fileName: String, in directoryURL: URL) -> URL {
        let sourceURL = URL(fileURLWithPath: fileName)
        let extensionPart = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directoryURL.appendingPathComponent(fileName)
        var index = 2

        while fileManager.fileExists(atPath: candidate.path) {
            let candidateName: String
            if extensionPart.isEmpty {
                candidateName = "\(baseName) \(index)"
            } else {
                candidateName = "\(baseName) \(index).\(extensionPart)"
            }
            candidate = directoryURL.appendingPathComponent(candidateName)
            index += 1
        }

        return candidate
    }

    private func copyName(baseName: String, extensionPart: String, index: Int?) -> String {
        let suffix = index.map { " copy \($0)" } ?? " copy"
        if extensionPart.isEmpty {
            return "\(baseName)\(suffix)"
        }
        return "\(baseName)\(suffix).\(extensionPart)"
    }

    private struct PlannedMutation {
        let source: URL
        let destination: URL
    }

    private func destinationURL(named name: String, in directoryURL: URL, isDirectory: Bool) throws -> URL {
        let validatedName = try FileNameValidationPolicy.validatedName(name)
        let standardizedDirectory = directoryURL.standardizedFileURL
        let destinationURL = standardizedDirectory.appendingPathComponent(
            validatedName,
            isDirectory: isDirectory
        )
        guard destinationURL.deletingLastPathComponent().standardizedFileURL == standardizedDirectory else {
            throw FileNameValidationError.pathSeparator
        }
        return destinationURL
    }

    private func plannedTransferMutations(
        for groups: [[URL]],
        toDirectory directoryURL: URL,
        operation: FileTransferOperation
    ) -> [PlannedMutation] {
        let targetDirectory = directoryURL.standardizedFileURL
        var reservedDestinationPaths = Set<String>()
        var mutations: [PlannedMutation] = []

        for group in groups {
            if operation == .move,
               group.allSatisfy({ $0.deletingLastPathComponent().standardizedFileURL == targetDirectory }) {
                continue
            }

            var suffixAttempt = operation == .copy ? 1 : 0
            while true {
                let candidates = group.map { sourceURL in
                    PlannedMutation(
                        source: sourceURL,
                        destination: transferDestination(
                            for: sourceURL,
                            in: targetDirectory,
                            suffixAttempt: suffixAttempt
                        )
                    )
                }
                let canUseCandidates = candidates.allSatisfy { mutation in
                    let destinationPath = mutation.destination.standardizedFileURL.path
                    return !reservedDestinationPaths.contains(destinationPath) &&
                        !fileManager.fileExists(atPath: destinationPath)
                }

                if canUseCandidates {
                    mutations.append(contentsOf: candidates)
                    reservedDestinationPaths.formUnion(
                        candidates.map { $0.destination.standardizedFileURL.path }
                    )
                    break
                }

                suffixAttempt = suffixAttempt == 0 ? 1 : suffixAttempt + 1
            }
        }

        return mutations
    }

    private func transferDestination(for sourceURL: URL, in directoryURL: URL, suffixAttempt: Int) -> URL {
        guard suffixAttempt > 0 else {
            return directoryURL.appendingPathComponent(sourceURL.lastPathComponent)
        }
        let extensionPart = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let index = suffixAttempt == 1 ? nil : suffixAttempt
        return directoryURL.appendingPathComponent(
            copyName(baseName: baseName, extensionPart: extensionPart, index: index)
        )
    }

    private func execute(
        _ mutations: [PlannedMutation],
        operation: FileTransferOperation
    ) throws -> [URL] {
        var completed: [PlannedMutation] = []

        do {
            for mutation in mutations {
                switch operation {
                case .copy:
                    try fileManager.copyItem(at: mutation.source, to: mutation.destination)
                case .move:
                    try fileManager.moveItem(at: mutation.source, to: mutation.destination)
                }
                completed.append(mutation)
            }
            return mutations.map(\.destination)
        } catch {
            let rollbackErrors = rollback(completed, operation: operation)
            var message = "The file operation failed and completed items were rolled back: \(error.localizedDescription)"
            if !rollbackErrors.isEmpty {
                message += " Rollback also failed: \(rollbackErrors.joined(separator: "; "))"
            }
            throw FileOperationError.transactionFailed(message)
        }
    }

    private func rollback(
        _ completed: [PlannedMutation],
        operation: FileTransferOperation
    ) -> [String] {
        var errors: [String] = []
        for mutation in completed.reversed() {
            do {
                switch operation {
                case .copy:
                    try fileManager.removeItem(at: mutation.destination)
                case .move:
                    try fileManager.moveItem(at: mutation.destination, to: mutation.source)
                }
            } catch {
                errors.append(error.localizedDescription)
            }
        }
        return errors
    }
}
