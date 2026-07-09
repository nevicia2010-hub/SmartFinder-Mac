import Foundation

public enum FileDropTargetPolicy {
    public static func targetDirectory(
        defaultDirectoryURL: URL?,
        hitItemURL: URL?,
        hitItemIsDirectory: Bool
    ) -> URL? {
        if hitItemIsDirectory, let hitItemURL {
            return hitItemURL.standardizedFileURL
        }
        return defaultDirectoryURL?.standardizedFileURL
    }
}
