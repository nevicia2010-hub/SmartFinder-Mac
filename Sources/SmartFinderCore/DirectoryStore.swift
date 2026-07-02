import Foundation

public final class DirectoryStore {
    public init() {}

    public func loadItems(in folderURL: URL) throws -> [FileItem] {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isHiddenKey,
            .localizedNameKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .labelNumberKey
        ]

        let urls = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
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
