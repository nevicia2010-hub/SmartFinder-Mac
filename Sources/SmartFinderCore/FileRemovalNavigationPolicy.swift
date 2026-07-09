import Foundation

public enum FileRemovalNavigationPolicy {
    public static func folderToLoadAfterRemoval(removedURLs: [URL], currentFolderURL: URL?) -> URL? {
        guard let currentFolderURL = currentFolderURL?.standardizedFileURL else {
            return nil
        }

        let currentPath = currentFolderURL.path
        let removedAncestor = removedURLs
            .map(\.standardizedFileURL)
            .filter { removedURL in
                let removedPath = removedURL.path
                return currentPath == removedPath || currentPath.hasPrefix(removedPath + "/")
            }
            .max { left, right in
                left.path.count < right.path.count
            }

        guard let removedAncestor else {
            return currentFolderURL
        }
        return removedAncestor.deletingLastPathComponent().standardizedFileURL
    }
}
