import Foundation

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
