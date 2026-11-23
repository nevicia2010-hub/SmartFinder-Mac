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
    public static func columns(for focusedFolderURL: URL, rootURL: URL? = nil) -> [ColumnViewColumn] {
        let urls = pathURLs(for: focusedFolderURL, rootURL: rootURL)
        return urls.enumerated().map { index, folderURL in
            ColumnViewColumn(
                folderURL: folderURL,
                selectedURL: urls.indices.contains(index + 1) ? urls[index + 1] : nil
            )
        }
    }

    private static func pathURLs(for focusedFolderURL: URL, rootURL: URL?) -> [URL] {
        let focusedURL = focusedFolderURL.standardizedFileURL
        guard let rootURL = rootURL?.standardizedFileURL,
              contains(url: focusedURL, in: rootURL) else {
            return PathBreadcrumb.components(for: focusedURL).map(\.url)
        }

        let focusedPath = focusedURL.path
        let rootPath = rootURL.path
        guard focusedPath != rootPath else {
            return [rootURL]
        }

        var urls = [rootURL]
        var currentURL = rootURL
        let relativePath = focusedPath.dropFirst(rootPath == "/" ? 1 : rootPath.count + 1)
        for part in relativePath.split(separator: "/") {
            currentURL.appendPathComponent(String(part), isDirectory: true)
            urls.append(currentURL)
        }
        return urls
    }

    private static func contains(url: URL, in rootURL: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let rootPath = rootURL.standardizedFileURL.path
        return rootPath == "/" || path == rootPath || path.hasPrefix(rootPath + "/")
    }
}
