import Foundation

public struct FileRenameNavigationPlan: Equatable, Sendable {
    public let folderURL: URL
    public let selectedURL: URL?

    public init(folderURL: URL, selectedURL: URL?) {
        self.folderURL = folderURL
        self.selectedURL = selectedURL
    }
}

public enum FileRenameNavigationPolicy {
    public static func navigationPlanAfterRename(
        originalURL: URL,
        renamedURL: URL,
        renamedItemIsDirectory: Bool,
        currentFolderURL: URL?
    ) -> FileRenameNavigationPlan? {
        guard let folderURL = folderToLoadAfterRename(
            originalURL: originalURL,
            renamedURL: renamedURL,
            renamedItemIsDirectory: renamedItemIsDirectory,
            currentFolderURL: currentFolderURL
        ) else {
            return nil
        }

        let standardizedFolderURL = folderURL.standardizedFileURL
        let standardizedRenamedURL = renamedURL.standardizedFileURL
        let selectedURL = standardizedRenamedURL.deletingLastPathComponent() == standardizedFolderURL
            ? standardizedRenamedURL
            : nil
        return FileRenameNavigationPlan(folderURL: standardizedFolderURL, selectedURL: selectedURL)
    }

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
