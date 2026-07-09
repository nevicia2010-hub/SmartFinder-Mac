import Foundation

public enum FileRenameNavigationPolicy {
    public static func folderToLoadAfterRename(
        originalURL: URL,
        renamedURL: URL,
        renamedItemIsDirectory: Bool,
        currentFolderURL: URL?
    ) -> URL? {
        guard let currentFolderURL = currentFolderURL?.standardizedFileURL else {
            return nil
        }
        guard renamedItemIsDirectory else {
            return currentFolderURL
        }

        let originalURL = originalURL.standardizedFileURL
        let currentPath = currentFolderURL.path
        let originalPath = originalURL.path
        if currentPath == originalPath || currentPath.hasPrefix(originalPath + "/") {
            return originalURL.deletingLastPathComponent().standardizedFileURL
        }

        return currentFolderURL
    }
}
