import Foundation

public enum FileNameDisplayPolicy {
    public static func displayName(for item: FileItem, showsFileExtensions: Bool) -> String {
        guard !showsFileExtensions,
              !item.isDirectory,
              !item.url.pathExtension.isEmpty else {
            return item.name
        }

        let extensionSuffix = ".\(item.url.pathExtension)"
        guard item.name.range(of: extensionSuffix, options: [.caseInsensitive, .anchored, .backwards]) != nil else {
            return item.name
        }

        return String(item.name.dropLast(extensionSuffix.count))
    }
}
