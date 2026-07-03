import Foundation

public enum FileTemplateKind: Equatable, Sendable {
    case plainText
    case markdown
    case csv
}

public struct FileTemplate: Equatable, Sendable {
    public let kind: FileTemplateKind
    public let titleKey: String
    public let fallbackTitle: String
    public let defaultFileName: String
    public let contents: String

    public init(
        kind: FileTemplateKind,
        titleKey: String,
        fallbackTitle: String,
        defaultFileName: String,
        contents: String
    ) {
        self.kind = kind
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.defaultFileName = defaultFileName
        self.contents = contents
    }
}

public enum FileTemplateCatalog {
    public static let templates: [FileTemplate] = [
        FileTemplate(
            kind: .plainText,
            titleKey: "menu.newTextFile",
            fallbackTitle: "New Text File",
            defaultFileName: "Untitled.txt",
            contents: ""
        ),
        FileTemplate(
            kind: .markdown,
            titleKey: "menu.newMarkdownFile",
            fallbackTitle: "New Markdown File",
            defaultFileName: "Untitled.md",
            contents: "# Notes\n"
        ),
        FileTemplate(
            kind: .csv,
            titleKey: "menu.newCSVFile",
            fallbackTitle: "New CSV File",
            defaultFileName: "Untitled.csv",
            contents: "Column 1,Column 2\n"
        )
    ]

    public static func template(for kind: FileTemplateKind) -> FileTemplate {
        templates.first { $0.kind == kind }!
    }
}
