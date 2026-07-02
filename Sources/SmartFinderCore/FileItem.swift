import Foundation

public struct FileItem: Hashable {
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let category: FileCategory

    public init(url: URL, name: String, isDirectory: Bool, category: FileCategory) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.category = category
    }
}
