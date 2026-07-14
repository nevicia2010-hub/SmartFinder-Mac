import Foundation

public enum ThumbnailCachePolicy {
    public static func estimatedPixelCost(width: Double, height: Double, scale: Double) -> Int {
        let pixelWidth = max(0, width * scale)
        let pixelHeight = max(0, height * scale)
        return Int((pixelWidth * pixelHeight * 4).rounded(.up))
    }

    public static func cacheKey(
        for url: URL,
        width: Double,
        height: Double,
        scale: Double
    ) -> String {
        let pixelWidth = Int((max(0, width) * max(0, scale)).rounded(.up))
        let pixelHeight = Int((max(0, height) * max(0, scale)).rounded(.up))
        return "\(url.standardizedFileURL.path)|\(pixelWidth)x\(pixelHeight)"
    }
}
