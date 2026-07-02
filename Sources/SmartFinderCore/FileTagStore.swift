import Foundation

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
}
