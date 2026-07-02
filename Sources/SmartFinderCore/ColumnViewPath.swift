import Foundation

public struct ColumnViewColumn: Equatable, Sendable {
    public let folderURL: URL
    public let selectedURL: URL?

    public init(folderURL: URL, selectedURL: URL?) {
        self.folderURL = folderURL
        self.selectedURL = selectedURL
    }
}

public enum ColumnViewPath {
    public static func columns(for focusedFolderURL: URL) -> [ColumnViewColumn] {
        let urls = PathBreadcrumb.components(for: focusedFolderURL).map(\.url)
        return urls.enumerated().map { index, folderURL in
            ColumnViewColumn(
                folderURL: folderURL,
                selectedURL: urls.indices.contains(index + 1) ? urls[index + 1] : nil
            )
        }
    }
}
