import Foundation

public final class FolderItemCountPipeline: @unchecked Sendable {
    private final class CompletionBox: @unchecked Sendable {
        let callback: (Int?) -> Void

        init(_ callback: @escaping (Int?) -> Void) {
            self.callback = callback
        }
    }

    private struct InFlightRequest {
        let id: UUID
        var completions: [CompletionBox]
    }

    private let cache = NSCache<NSString, NSNumber>()
    private let operationQueue: OperationQueue
    private let lock = NSLock()
    private var inFlightRequests: [String: InFlightRequest] = [:]

    public init(maxConcurrentOperationCount: Int = 2, cacheCountLimit: Int = 2_048) {
        let operationQueue = OperationQueue()
        operationQueue.name = "SmartFinder.FolderItemCountPipeline"
        operationQueue.qualityOfService = .utility
        operationQueue.maxConcurrentOperationCount = max(1, maxConcurrentOperationCount)
        self.operationQueue = operationQueue
        cache.countLimit = max(1, cacheCountLimit)
    }

    public func cachedCount(
        for item: FileItem,
        options: DirectoryLoadOptions = DirectoryLoadOptions()
    ) -> Int? {
        guard item.isDirectory else {
            return nil
        }
        return cache.object(forKey: cacheKey(for: item, options: options))?.intValue
    }

    public func countItems(
        for item: FileItem,
        options: DirectoryLoadOptions = DirectoryLoadOptions(),
        completion: @escaping (Int?) -> Void
    ) {
        guard item.isDirectory else {
            completion(nil)
            return
        }

        let key = cacheKey(for: item, options: options) as String
        if let cached = cache.object(forKey: key as NSString) {
            completion(cached.intValue)
            return
        }

        lock.lock()
        if var inFlight = inFlightRequests[key] {
            inFlight.completions.append(CompletionBox(completion))
            inFlightRequests[key] = inFlight
            lock.unlock()
            return
        }

        let requestID = UUID()
        inFlightRequests[key] = InFlightRequest(
            id: requestID,
            completions: [CompletionBox(completion)]
        )
        lock.unlock()

        operationQueue.addOperation { [weak self] in
            guard let self else {
                return
            }
            let count = try? FolderItemCounter().countItems(in: item.url, options: options)
            self.finishRequest(key: key, requestID: requestID, count: count)
        }
    }

    public func cancelAll() {
        lock.lock()
        inFlightRequests.removeAll()
        lock.unlock()
        operationQueue.cancelAllOperations()
    }

    public func removeAllCachedCounts() {
        cache.removeAllObjects()
    }

    private func finishRequest(key: String, requestID: UUID, count: Int?) {
        lock.lock()
        guard let inFlight = inFlightRequests[key], inFlight.id == requestID else {
            lock.unlock()
            return
        }
        inFlightRequests.removeValue(forKey: key)
        lock.unlock()

        if let count {
            cache.setObject(NSNumber(value: count), forKey: key as NSString)
        }

        DispatchQueue.main.async {
            inFlight.completions.forEach { $0.callback(count) }
        }
    }

    private func cacheKey(for item: FileItem, options: DirectoryLoadOptions) -> NSString {
        let url = item.url.standardizedFileURL.absoluteString
        let modifiedAt = item.modifiedAt.map {
            String($0.timeIntervalSinceReferenceDate.bitPattern, radix: 16)
        } ?? "unknown"
        let hiddenItemsFlag = options.includesHiddenItems ? "1" : "0"
        return "\(url.count):\(url):\(modifiedAt):\(hiddenItemsFlag)" as NSString
    }
}
