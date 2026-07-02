import Foundation

public struct NavigationHistory {
    private var entries: [URL] = []
    private var index = -1

    public init() {}

    public var current: URL? {
        guard entries.indices.contains(index) else {
            return nil
        }
        return entries[index]
    }

    public var canGoBack: Bool {
        index > 0
    }

    public var canGoForward: Bool {
        index >= 0 && index < entries.count - 1
    }

    public mutating func record(_ url: URL) {
        if current == url {
            return
        }
        if index < entries.count - 1 {
            entries.removeLast(entries.count - index - 1)
        }
        entries.append(url)
        index = entries.count - 1
    }

    public mutating func goBack() -> URL? {
        guard canGoBack else {
            return nil
        }
        index -= 1
        return current
    }

    public mutating func goForward() -> URL? {
        guard canGoForward else {
            return nil
        }
        index += 1
        return current
    }
}
