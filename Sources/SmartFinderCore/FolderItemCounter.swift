import Foundation

public final class FolderItemCounter {
    private let contentProvider: DirectoryContentProviding

    public init(contentProvider: DirectoryContentProviding = FileManagerDirectoryContentProvider()) {
        self.contentProvider = contentProvider
    }

    public func countItems(
        in folderURL: URL,
        options: DirectoryLoadOptions = DirectoryLoadOptions()
    ) throws -> Int {
        try contentProvider.itemURLs(
            in: folderURL,
            includesHiddenItems: options.includesHiddenItems
        ).count
    }
}
