import Foundation

public protocol DirectoryContentProviding {
    func itemURLs(in folderURL: URL, includesHiddenItems: Bool) throws -> [URL]
}

public final class FileManagerDirectoryContentProvider: DirectoryContentProviding {
    public init() {}

    public func itemURLs(in folderURL: URL, includesHiddenItems: Bool) throws -> [URL] {
        let names = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
        return names.compactMap { name in
            let url = folderURL.appendingPathComponent(name)
            guard !includesHiddenItems else { return url }
            if name.hasPrefix(".") { return nil }
            if (try? url.resourceValues(forKeys: [.isHiddenKey]).isHidden) == true { return nil }
            return url
        }
    }
}

public struct DirectoryLoadOptions: Equatable, Hashable, Sendable {
    public let includesHiddenItems: Bool

    public init(includesHiddenItems: Bool = false) {
        self.includesHiddenItems = includesHiddenItems
    }
}

public final class DirectoryStore {
    private let contentProvider: DirectoryContentProviding

    public init(contentProvider: DirectoryContentProviding = FileManagerDirectoryContentProvider()) {
        self.contentProvider = contentProvider
    }

    public func loadItems(in folderURL: URL, options: DirectoryLoadOptions = DirectoryLoadOptions()) throws -> [FileItem] {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isHiddenKey,
            .localizedNameKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .labelNumberKey
        ]

        let urls = try contentProvider.itemURLs(
            in: folderURL,
            includesHiddenItems: options.includesHiddenItems
        )

        return try urls.map { url in
            let values = try url.resourceValues(forKeys: keys)
            let isDirectory = values.isDirectory ?? false
            return FileItem(
                url: url,
                name: values.localizedName ?? url.lastPathComponent,
                isDirectory: isDirectory,
                category: FileClassifier.category(for: url, isDirectory: isDirectory),
                byteSize: values.fileSize.map(Int64.init),
                modifiedAt: values.contentModificationDate,
                finderLabelNumber: values.labelNumber ?? 0
            )
        }
        .sorted { left, right in
            if left.isDirectory != right.isDirectory {
                return left.isDirectory && !right.isDirectory
            }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }
    }
}
