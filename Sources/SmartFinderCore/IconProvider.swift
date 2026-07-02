import AppKit

public final class IconProvider {
    public init() {}

    public func icon(for item: FileItem, size: NSSize = NSSize(width: 96, height: 96)) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: item.url.path)
        image.size = size
        return image
    }
}
