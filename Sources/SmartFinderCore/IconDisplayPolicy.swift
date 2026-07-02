import Foundation

public enum IconDisplayStyle: Equatable {
    case systemIcon
}

public enum IconDisplayPolicy {
    public static func style(for category: FileCategory) -> IconDisplayStyle {
        .systemIcon
    }
}
