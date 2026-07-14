import Foundation

public enum FileInfoPanelFieldLabelAlignment: Equatable, Sendable {
    case leading
    case trailing
}

public enum FileInfoPanelLayoutMetrics {
    public static let contentInset: Double = 20
    public static let contentTrailingInset: Double = 24
    public static let sectionTitleLeading: Double = 0
    public static let rowLeading: Double = 28
    public static let fieldLabelWidth: Double = 96
    public static let rowSpacing: Double = 10
    public static let sectionVerticalPadding: Double = 10
    public static let sectionTitleRowSpacing: Double = 8
    public static let fieldLabelAlignment: FileInfoPanelFieldLabelAlignment = .leading
}
