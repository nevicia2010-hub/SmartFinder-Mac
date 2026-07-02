import Foundation

public enum FinderTagColor: Int, CaseIterable, Sendable {
    case gray = 1
    case green = 2
    case purple = 3
    case blue = 4
    case yellow = 5
    case red = 6
    case orange = 7

    public var labelNumber: Int {
        rawValue
    }
}

public final class FileTagStore {
    public init() {}

    public func tagNames(for url: URL) throws -> [String] {
        let values = try url.resourceValues(forKeys: [.tagNamesKey])
        return values.tagNames ?? []
    }

    public func setTagNames(_ names: [String], for url: URL) throws {
        try (url as NSURL).setResourceValue(names, forKey: .tagNamesKey)
    }

    public func clearTags(for url: URL) throws {
        try setTagNames([], for: url)
    }

    public func finderLabelNumber(for url: URL) throws -> Int {
        let values = try url.resourceValues(forKeys: [.labelNumberKey])
        return values.labelNumber ?? 0
    }

    public func setFinderLabelColor(_ color: FinderTagColor, for url: URL) throws {
        var itemURL = url
        var values = URLResourceValues()
        values.labelNumber = color.labelNumber
        try itemURL.setResourceValues(values)
    }

    public func clearFinderLabelColor(for url: URL) throws {
        var itemURL = url
        var values = URLResourceValues()
        values.labelNumber = 0
        try itemURL.setResourceValues(values)
    }
}
