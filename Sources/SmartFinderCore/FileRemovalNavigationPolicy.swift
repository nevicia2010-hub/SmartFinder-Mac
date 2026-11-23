import Foundation

public enum FileRemovalNavigationPolicy {
    public enum Update: Equatable {
        case none
        case navigate(URL)
        case refreshCurrentFolder
        case refreshColumns([URL])
    }

    public static func updateAfterRemoval(
        removedURLs: [URL], currentFolderURL: URL?, isColumnView: Bool
    ) -> Update {
        if let destination = folderToLoadAfterRemoval(removedURLs: removedURLs, currentFolderURL: currentFolderURL),
           destination != currentFolderURL?.standardizedFileURL {
            return .navigate(destination)
        }

        let affected = FileMetadataRefreshPlan.affectedDirectoryURLs(changedItemURLs: removedURLs)
        switch FileTransferPlan.refreshScope(
            isColumnView: isColumnView, currentFolderURL: currentFolderURL, affectedDirectoryURLs: affected
        ) {
        case .none:
            return .none
        case .currentFolder:
            return .refreshCurrentFolder
        case .visibleColumns:
            return .refreshColumns(affected)
        }
    }

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
            .min { left, right in
                left.path.count < right.path.count
            }

        guard let removedAncestor else {
            return currentFolderURL
        }
        return removedAncestor.deletingLastPathComponent().standardizedFileURL
    }
}
