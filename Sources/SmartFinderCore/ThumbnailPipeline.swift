import AppKit
import QuickLookThumbnailing

public final class ThumbnailPipeline {
    private let generator: QLThumbnailGenerator
    private let cache = NSCache<NSURL, NSImage>()

    public init(generator: QLThumbnailGenerator = .shared, memoryLimitMegabytes: Int = 256) {
        self.generator = generator
        cache.totalCostLimit = memoryLimitMegabytes * 1024 * 1024
    }

    public static func isThumbnailEligible(_ category: FileCategory) -> Bool {
        category == .image
    }

    public func cachedThumbnail(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    public func thumbnail(for item: FileItem, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        guard Self.isThumbnailEligible(item.category) else {
            completion(nil)
            return
        }

        if let cached = cachedThumbnail(for: item.url) {
            completion(cached)
            return
        }

        let request = QLThumbnailGenerator.Request(
            fileAt: item.url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail
        )

        generator.generateBestRepresentation(for: request) { [cache] representation, error in
            guard error == nil, let image = representation?.nsImage else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let cost = Int(size.width * size.height * 4)
            cache.setObject(image, forKey: item.url as NSURL, cost: cost)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
