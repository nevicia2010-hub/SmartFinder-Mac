import Foundation

public enum FileOperationError: Error, LocalizedError {
    case emptyCompressionSelection
    case compressionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyCompressionSelection:
            return "No files were selected for compression."
        case .compressionFailed(let message):
            return message.isEmpty ? "Compression failed." : message
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
        let destinationURL = directoryURL.appendingPathComponent(name, isDirectory: true)
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: false)
        return destinationURL
    }

    @discardableResult
    public func createFile(named name: String, contents: String = "", in directoryURL: URL) throws -> URL {
        let destinationURL = directoryURL.appendingPathComponent(name, isDirectory: false)
        try contents.write(to: destinationURL, atomically: true, encoding: .utf8)
        return destinationURL
    }

    @discardableResult
    public func rename(_ url: URL, to newName: String) throws -> URL {
        let destinationURL = url.deletingLastPathComponent().appendingPathComponent(newName)
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
        let destinationURL = uniqueDestinationURL(for: sourceURL, in: directoryURL)
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

    private func copyName(baseName: String, extensionPart: String, index: Int?) -> String {
        let suffix = index.map { " copy \($0)" } ?? " copy"
        if extensionPart.isEmpty {
            return "\(baseName)\(suffix)"
        }
        return "\(baseName)\(suffix).\(extensionPart)"
    }
}
