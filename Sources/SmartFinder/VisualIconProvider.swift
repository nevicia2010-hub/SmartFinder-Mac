import AppKit
import SmartFinderCore

final class VisualIconProvider {
    private let iconProvider = IconProvider()

    func icon(for item: FileItem, size: CGFloat) -> NSImage {
        switch IconDisplayPolicy.style(for: item) {
        case .systemIcon:
            return iconProvider.icon(for: item, size: NSSize(width: size, height: size))
        case .tintedFolder(let color):
            let image = iconProvider.icon(for: item, size: NSSize(width: size, height: size))
            return tintedFolderIcon(image, color: color, size: NSSize(width: size, height: size))
        }
    }

    private func tintedFolderIcon(_ baseImage: NSImage, color: FinderTagColor, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        folderTintColor(for: color).withAlphaComponent(0.86).setFill()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        NSColor.black.withAlphaComponent(0.08).setFill()
        NSRect(origin: .zero, size: size).fill(using: .multiply)
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func folderTintColor(for color: FinderTagColor) -> NSColor {
        switch color {
        case .gray:
            return NSColor.systemGray
        case .green:
            return NSColor.systemGreen
        case .purple:
            return NSColor.systemPurple
        case .blue:
            return NSColor.systemBlue
        case .yellow:
            return NSColor.systemYellow
        case .red:
            return NSColor.systemRed
        case .orange:
            return NSColor.systemOrange
        }
    }
}
