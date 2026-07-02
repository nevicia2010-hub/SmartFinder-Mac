import Foundation

public struct FileItem: Hashable {
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let category: FileCategory
    public let byteSize: Int64?
    public let modifiedAt: Date?
    public let finderLabelNumber: Int

    public init(
        url: URL,
        name: String,
        isDirectory: Bool,
        category: FileCategory,
        byteSize: Int64? = nil,
        modifiedAt: Date? = nil,
        finderLabelNumber: Int = 0
    ) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.category = category
        self.byteSize = byteSize
        self.modifiedAt = modifiedAt
        self.finderLabelNumber = finderLabelNumber
    }
}
