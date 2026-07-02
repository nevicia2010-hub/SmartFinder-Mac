import Foundation

public enum IconDisplayStyle: Equatable {
    case systemIcon
    case tintedFolder(FinderTagColor)
}

public enum IconDisplayPolicy {
    public static func style(for category: FileCategory) -> IconDisplayStyle {
        .systemIcon
    }

    public static func style(for item: FileItem) -> IconDisplayStyle {
        guard item.category == .folder,
              let tagColor = FinderTagColor(rawValue: item.finderLabelNumber) else {
            return .systemIcon
        }
        return .tintedFolder(tagColor)
    }
}
