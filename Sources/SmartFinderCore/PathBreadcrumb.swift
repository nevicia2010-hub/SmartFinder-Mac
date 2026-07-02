import Foundation

public struct PathBreadcrumbComponent: Equatable, Hashable {
    public let title: String
    public let url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public enum PathBreadcrumb {
    public static func components(for url: URL) -> [PathBreadcrumbComponent] {
        let path = url.standardizedFileURL.path
        let root = PathBreadcrumbComponent(title: "/", url: URL(fileURLWithPath: "/", isDirectory: true))
        guard path != "/" else {
            return [root]
        }

        var components = [root]
        var cumulativePath = ""
        for part in path.split(separator: "/").map(String.init) {
            cumulativePath += "/\(part)"
            components.append(
                PathBreadcrumbComponent(
                    title: part,
                    url: URL(fileURLWithPath: cumulativePath, isDirectory: true)
                )
            )
        }
        return components
    }
}
