import AppKit
import QuickLookThumbnailing

public final class ThumbnailPipeline: @unchecked Sendable {
    private final class CompletionBox: @unchecked Sendable {
        let callback: (NSImage?) -> Void

        init(_ callback: @escaping (NSImage?) -> Void) {
            self.callback = callback
        }
    }

    private final class ImageBox: @unchecked Sendable {
        let image: NSImage?

        init(_ image: NSImage?) {
            self.image = image
        }
    }

    private struct InFlightRequest {
        let request: QLThumbnailGenerator.Request
        var completions: [CompletionBox]
    }

    private let generator: QLThumbnailGenerator
    private let cache = NSCache<NSString, NSImage>()
    private let lock = NSLock()
    private var inFlightRequests: [String: InFlightRequest] = [:]

    public init(generator: QLThumbnailGenerator = .shared, memoryLimitMegabytes: Int = 128) {
        self.generator = generator
        cache.totalCostLimit = memoryLimitMegabytes * 1024 * 1024
    }

    public static func isThumbnailEligible(_ category: FileCategory) -> Bool {
        category == .image || category == .video
    }

    public func cachedThumbnail(for url: URL, size: CGSize, scale: CGFloat) -> NSImage? {
        cache.object(forKey: cacheKey(for: url, size: size, scale: scale))
    }

    public func thumbnail(
        for item: FileItem,
        size: CGSize,
        scale: CGFloat,
        completion: @escaping (NSImage?) -> Void
    ) {
        guard Self.isThumbnailEligible(item.category) else {
            completion(nil)
            return
        }

        let key = ThumbnailCachePolicy.cacheKey(
            for: item.url,
            width: size.width,
            height: size.height,
            scale: scale
        )
        if let cached = cache.object(forKey: key as NSString) {
            completion(cached)
            return
        }

        lock.lock()
        if var inFlight = inFlightRequests[key] {
            inFlight.completions.append(CompletionBox(completion))
            inFlightRequests[key] = inFlight
            lock.unlock()
            return
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: size,
            scale: scale,
            representationTypes: .thumbnail
        )
        inFlightRequests[key] = InFlightRequest(
            request: request,
            completions: [CompletionBox(completion)]
        )
        lock.unlock()

        generator.generateBestRepresentation(for: request) { [weak self] representation, error in
            self?.finishRequest(key: key, representation: representation, error: error)
        }
    }

    public func cancelAll() {
        lock.lock()
        let requests = inFlightRequests.values.map(\.request)
        inFlightRequests.removeAll()
        lock.unlock()

        for request in requests {
            generator.cancel(request)
        }
    }

    public func removeAllCachedThumbnails() {
        cache.removeAllObjects()
    }

    private func finishRequest(
        key: String,
        representation: QLThumbnailRepresentation?,
        error: Error?
    ) {
        lock.lock()
        let completions = inFlightRequests.removeValue(forKey: key)?.completions ?? []
        lock.unlock()

        guard !completions.isEmpty else {
            return
        }

        let image = error == nil ? representation?.nsImage : nil
        if let image {
            let cost: Int
            if let cgImage = representation?.cgImage {
                cost = cgImage.width * cgImage.height * 4
            } else {
                cost = ThumbnailCachePolicy.estimatedPixelCost(
                    width: image.size.width,
                    height: image.size.height,
                    scale: 1
                )
            }
            cache.setObject(image, forKey: key as NSString, cost: cost)
        }

        let imageBox = ImageBox(image)
        DispatchQueue.main.async {
            completions.forEach { $0.callback(imageBox.image) }
        }
    }

    private func cacheKey(for url: URL, size: CGSize, scale: CGFloat) -> NSString {
        ThumbnailCachePolicy.cacheKey(
            for: url,
            width: size.width,
            height: size.height,
            scale: scale
        ) as NSString
    }
}
