import Foundation

public struct MountedVolumeLocation: Hashable {
    public let name: String
    public let url: URL
    public let isEjectable: Bool

    public init(name: String, url: URL, isEjectable: Bool = false) {
        self.name = name
        self.url = url
        self.isEjectable = isEjectable
    }
}

public final class MountedVolumeProvider {
    public init() {}

    public func mountedVolumes() -> [MountedVolumeLocation] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsBrowsableKey
        ]

        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: []
        ) ?? []

        var namesByPath: [String: String] = [:]
        let browsableURLs = urls.filter { url in
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else {
                return false
            }
            if let volumeName = values.volumeName, !volumeName.isEmpty {
                namesByPath[url.path] = volumeName
            }
            return values.volumeIsBrowsable == true
        }

        return Self.locations(from: browsableURLs, namesByPath: namesByPath)
    }

    public static func locations(
        from mountedURLs: [URL],
        namesByPath: [String: String] = [:]
    ) -> [MountedVolumeLocation] {
        var seenPaths = Set<String>()

        return mountedURLs.compactMap { url in
            let standardizedURL = url.standardizedFileURL
            let path = standardizedURL.path
            guard path.hasPrefix("/Volumes/"),
                  path != "/Volumes",
                  !seenPaths.contains(path) else {
                return nil
            }

            seenPaths.insert(path)
            let fallbackName = standardizedURL.lastPathComponent.removingPercentEncoding
                ?? standardizedURL.lastPathComponent
            return MountedVolumeLocation(
                name: namesByPath[path] ?? fallbackName,
                url: standardizedURL,
                isEjectable: true
            )
        }
        .sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
