import Foundation

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

    private func copyName(baseName: String, extensionPart: String, index: Int?) -> String {
        let suffix = index.map { " copy \($0)" } ?? " copy"
        if extensionPart.isEmpty {
            return "\(baseName)\(suffix)"
        }
        return "\(baseName)\(suffix).\(extensionPart)"
    }
}
