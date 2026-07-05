import Foundation

public enum FileInfoPanelSectionKind: Equatable, Hashable {
    case general
    case nameAndExtension
    case path
    case system
}

public enum FileInfoPanelField: Equatable, Hashable {
    case kind
    case size
    case `where`
    case created
    case modified
    case name
    case `extension`
    case fullPath
    case typeIdentifier
}

public struct FileInfoPanelRow: Equatable, Hashable {
    public let field: FileInfoPanelField
    public let value: String
    public let isCopyable: Bool

    public init(field: FileInfoPanelField, value: String, isCopyable: Bool = false) {
        self.field = field
        self.value = value
        self.isCopyable = isCopyable
    }
}

public struct FileInfoPanelSection: Equatable, Hashable {
    public let kind: FileInfoPanelSectionKind
    public let rows: [FileInfoPanelRow]

    public init(kind: FileInfoPanelSectionKind, rows: [FileInfoPanelRow]) {
        self.kind = kind
        self.rows = rows
    }
}

public struct FileInfoPanelPresentation: Equatable, Hashable {
    public let title: String
    public let selectedCount: Int
    public let representedURL: URL
    public let sections: [FileInfoPanelSection]

    public init(title: String, selectedCount: Int, representedURL: URL, sections: [FileInfoPanelSection]) {
        self.title = title
        self.selectedCount = selectedCount
        self.representedURL = representedURL
        self.sections = sections
    }

    public func row(for field: FileInfoPanelField) -> FileInfoPanelRow? {
        sections.lazy.flatMap(\.rows).first { $0.field == field }
    }
}

public struct FileInfoPanelPresentationBuilder {
    public init() {}

    public func presentation(
        for info: FileInfo,
        selectedCount: Int,
        kindLabel: String,
        sizeLabel: String,
        createdLabel: String?,
        modifiedLabel: String?
    ) -> FileInfoPanelPresentation {
        let parentPath = info.url.deletingLastPathComponent().path
        let title = selectedCount == 1 ? info.name : "\(selectedCount) Items"

        var generalRows = [
            FileInfoPanelRow(field: .kind, value: kindLabel),
            FileInfoPanelRow(field: .size, value: sizeLabel),
            FileInfoPanelRow(field: .where, value: parentPath, isCopyable: true)
        ]
        if let createdLabel {
            generalRows.append(FileInfoPanelRow(field: .created, value: createdLabel))
        }
        if let modifiedLabel {
            generalRows.append(FileInfoPanelRow(field: .modified, value: modifiedLabel))
        }

        var nameRows = [
            FileInfoPanelRow(field: .name, value: info.name, isCopyable: true)
        ]
        if !info.fileExtension.isEmpty {
            nameRows.append(FileInfoPanelRow(field: .extension, value: info.fileExtension))
        }

        let pathRows = [
            FileInfoPanelRow(field: .fullPath, value: info.url.path, isCopyable: true)
        ]

        let systemRows = [
            info.typeIdentifier.map {
                FileInfoPanelRow(field: .typeIdentifier, value: $0, isCopyable: true)
            }
        ].compactMap { $0 }

        var sections = [
            FileInfoPanelSection(kind: .general, rows: generalRows),
            FileInfoPanelSection(kind: .nameAndExtension, rows: nameRows),
            FileInfoPanelSection(kind: .path, rows: pathRows)
        ]
        if !systemRows.isEmpty {
            sections.append(FileInfoPanelSection(kind: .system, rows: systemRows))
        }

        return FileInfoPanelPresentation(
            title: title,
            selectedCount: selectedCount,
            representedURL: info.url,
            sections: sections
        )
    }
}
