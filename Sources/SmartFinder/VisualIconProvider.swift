import AppKit
import SmartFinderCore

final class VisualIconProvider {
    private let iconProvider = IconProvider()

    func icon(for item: FileItem, size: CGFloat) -> NSImage {
        switch IconDisplayPolicy.style(for: item.category) {
        case .systemIcon:
            return iconProvider.icon(for: item, size: NSSize(width: size, height: size))
        }
    }
}
