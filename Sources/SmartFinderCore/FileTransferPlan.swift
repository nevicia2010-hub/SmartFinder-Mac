import Foundation

public enum FileTransferRefreshScope: Equatable, Sendable {
    case none
    case currentFolder
    case visibleColumns
}

public enum FileTransferPlan {
    public static func uniqueSourceURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { url in
            let path = url.standardizedFileURL.path
            guard !seen.contains(path) else {
                return false
            }
            seen.insert(path)
            return true
        }
    }

    public static func affectedDirectoryURLs(sourceURLs: [URL], targetDirectoryURL: URL) -> [URL] {
        uniqueSourceURLs(sourceURLs)
            .map { $0.deletingLastPathComponent().standardizedFileURL }
            .appendingUnique(targetDirectoryURL.standardizedFileURL)
    }

    public static func refreshScope(
        isColumnView: Bool,
        currentFolderURL: URL?,
        affectedDirectoryURLs: [URL]
    ) -> FileTransferRefreshScope {
        guard !affectedDirectoryURLs.isEmpty else {
            return .none
        }
        if isColumnView {
            return .visibleColumns
        }
        guard let currentFolderURL = currentFolderURL?.standardizedFileURL else {
            return .none
        }
        return affectedDirectoryURLs.map(\.standardizedFileURL).contains(currentFolderURL)
            ? .currentFolder
            : .none
    }
}

private extension Array where Element == URL {
    func appendingUnique(_ url: URL) -> [URL] {
        var result = self
        if !result.contains(url) {
            result.append(url)
        }
        return result
    }
}
