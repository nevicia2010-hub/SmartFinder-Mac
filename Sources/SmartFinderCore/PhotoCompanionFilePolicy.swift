import Foundation

public enum PhotoCompanionFilePolicy {
    private static let rawPhotoExtensions: Set<String> = [
        "3fr", "ari", "arw", "bay", "cap", "cr2", "cr3", "crw", "dcr",
        "dng", "eip", "erf", "fff", "iiq", "kdc", "mdc", "mef", "mos",
        "mrw", "nef", "nrw", "orf", "ori", "pef", "raf", "raw", "rwl",
        "rw2", "sr2", "srf", "srw", "x3f"
    ]

    private static let renderedPhotoExtensions: Set<String> = [
        "jpg", "jpeg", "heic", "tif", "tiff"
    ]

    private static let sidecarExtensions: Set<String> = [
        "xmp", "aae", "acr", "dop", "pp3", "on1", "cos"
    ]

    private static var groupExtensions: Set<String> {
        rawPhotoExtensions
            .union(renderedPhotoExtensions)
            .union(sidecarExtensions)
    }

    public static func companionURLs(for url: URL) -> [URL] {
        let sourceExtension = url.pathExtension.lowercased()
        guard groupExtensions.contains(sourceExtension) else {
            return []
        }

        let parentURL = url.deletingLastPathComponent()
        let sourceStem = url.deletingPathExtension().lastPathComponent.lowercased()
        let sourcePath = url.standardizedFileURL.path
        let siblings = (try? FileManager.default.contentsOfDirectory(
            at: parentURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )) ?? []

        return siblings
            .filter { candidate in
                candidate.standardizedFileURL.path != sourcePath &&
                    candidate.deletingPathExtension().lastPathComponent.lowercased() == sourceStem &&
                    groupExtensions.contains(candidate.pathExtension.lowercased()) &&
                    !isDirectory(candidate)
            }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    public static func expandedSourceURLs(for sourceURLs: [URL]) -> [URL] {
        expandedSourceGroups(for: sourceURLs).flatMap { $0 }
    }

    public static func expandedSourceGroups(for sourceURLs: [URL]) -> [[URL]] {
        var groups: [[URL]] = []
        var seenPaths = Set<String>()

        for sourceURL in sourceURLs {
            var group: [URL] = []
            append(sourceURL, to: &group, seenPaths: &seenPaths)
            for companionURL in companionURLs(for: sourceURL) {
                append(companionURL, to: &group, seenPaths: &seenPaths)
            }
            if !group.isEmpty {
                groups.append(group)
            }
        }

        return groups
    }

    private static func append(_ url: URL, to urls: inout [URL], seenPaths: inout Set<String>) {
        let path = url.standardizedFileURL.path
        guard !seenPaths.contains(path) else {
            return
        }
        seenPaths.insert(path)
        urls.append(url)
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}
