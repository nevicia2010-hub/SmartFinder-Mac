import Foundation

public enum SelectionSummary {
    public static func totalFileByteSize(for items: [FileItem]) -> Int64 {
        items.reduce(Int64(0)) { total, item in
            guard !item.isDirectory, let byteSize = item.byteSize else {
                return total
            }
            return total + byteSize
        }
    }

    public static func fileNames(for items: [FileItem]) -> [String] {
        items.map(\.name)
    }
}
