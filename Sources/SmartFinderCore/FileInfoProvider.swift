import Foundation

public struct FileInfo: Equatable, Hashable {
    public let url: URL
    public let name: String
    public let fileExtension: String
    public let isDirectory: Bool
    public let category: FileCategory
    public let byteSize: Int64?
    public let createdAt: Date?
    public let modifiedAt: Date?
    public let typeIdentifier: String?

    public init(
        url: URL,
        name: String,
        fileExtension: String,
        isDirectory: Bool,
        category: FileCategory,
        byteSize: Int64?,
        createdAt: Date?,
        modifiedAt: Date?,
        typeIdentifier: String?
    ) {
        self.url = url
        self.name = name
        self.fileExtension = fileExtension
        self.isDirectory = isDirectory
        self.category = category
        self.byteSize = byteSize
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.typeIdentifier = typeIdentifier
    }
}

public final class FileInfoProvider {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func info(for url: URL) throws -> FileInfo {
        let keys: Set<URLResourceKey> = [
            .localizedNameKey,
            .isDirectoryKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .typeIdentifierKey
        ]

        var isDirectory: ObjCBool = false
        _ = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        let values = try url.resourceValues(forKeys: keys)
        let resolvedIsDirectory = values.isDirectory == true || isDirectory.boolValue

        return FileInfo(
            url: url,
            name: values.localizedName ?? url.lastPathComponent,
            fileExtension: url.pathExtension.lowercased(),
            isDirectory: resolvedIsDirectory,
            category: FileClassifier.category(for: url, isDirectory: resolvedIsDirectory),
            byteSize: values.fileSize.map(Int64.init),
            createdAt: values.creationDate,
            modifiedAt: values.contentModificationDate,
            typeIdentifier: values.typeIdentifier
        )
    }
}
