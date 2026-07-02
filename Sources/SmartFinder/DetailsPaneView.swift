import AppKit
import SmartFinderCore

final class DetailsPaneView: NSVisualEffectView {
    private let iconView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")
    private let subtitleField = NSTextField(labelWithString: "")
    private let bodyField = NSTextField(labelWithString: "")
    private let byteFormatter = ByteCountFormatter()
    private let dateFormatter = DateFormatter()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .sidebar
        blendingMode = .withinWindow
        state = .active
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(selection: [FileItem]) {
        guard let item = selection.first else {
            iconView.image = nil
            titleField.stringValue = L10n.string("details.empty.title", fallback: "No Selection")
            subtitleField.stringValue = L10n.string("details.empty.subtitle", fallback: "Select an item to view details.")
            bodyField.stringValue = ""
            return
        }

        if selection.count > 1 {
            iconView.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: nil)
            titleField.stringValue = L10n.format("details.multiple.title", fallback: "%d Items", selection.count)
            subtitleField.stringValue = L10n.string("details.multiple.subtitle", fallback: "Multiple selection")
            bodyField.stringValue = selection.map(\.name).prefix(8).joined(separator: "\n")
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 96, height: 96)
        iconView.image = icon
        titleField.stringValue = item.name
        subtitleField.stringValue = kindLabel(for: item)
        bodyField.stringValue = detailsText(for: item)
    }

    private func setup() {
        byteFormatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        byteFormatter.countStyle = .file
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleField.font = FinderFonts.toolbarTitle
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.alignment = .center
        titleField.translatesAutoresizingMaskIntoConstraints = false

        subtitleField.font = FinderFonts.iconSubtitle
        subtitleField.textColor = .secondaryLabelColor
        subtitleField.alignment = .center
        subtitleField.translatesAutoresizingMaskIntoConstraints = false

        bodyField.font = FinderFonts.status
        bodyField.textColor = .secondaryLabelColor
        bodyField.maximumNumberOfLines = 0
        bodyField.lineBreakMode = .byWordWrapping
        bodyField.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [iconView, titleField, subtitleField, bodyField])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
            titleField.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            subtitleField.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            bodyField.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        update(selection: [])
    }

    private func detailsText(for item: FileItem) -> String {
        var lines: [String] = []
        lines.append("\(L10n.string("info.kind", fallback: "Kind")): \(kindLabel(for: item))")
        if let byteSize = item.byteSize, !item.isDirectory {
            lines.append("\(L10n.string("info.size", fallback: "Size")): \(byteFormatter.string(fromByteCount: byteSize))")
        }
        if !item.url.pathExtension.isEmpty {
            lines.append("\(L10n.string("info.extension", fallback: "Extension")): \(item.url.pathExtension.lowercased())")
        }
        if let modifiedAt = item.modifiedAt {
            lines.append("\(L10n.string("info.modified", fallback: "Modified")): \(dateFormatter.string(from: modifiedAt))")
        }
        lines.append("\(L10n.string("info.where", fallback: "Where")): \(item.url.deletingLastPathComponent().path)")
        return lines.joined(separator: "\n")
    }

    private func kindLabel(for item: FileItem) -> String {
        if item.isDirectory {
            return L10n.string("category.folder", fallback: "Folder")
        }

        let ext = item.url.pathExtension.uppercased()
        if !ext.isEmpty {
            return ext
        }

        switch item.category {
        case .folder:
            return L10n.string("category.folder", fallback: "Folder")
        case .image:
            return L10n.string("category.image", fallback: "Image")
        case .video:
            return L10n.string("category.video", fallback: "Video")
        case .audio:
            return L10n.string("category.audio", fallback: "Audio")
        case .document:
            return L10n.string("category.document", fallback: "Document")
        case .archive:
            return L10n.string("category.archive", fallback: "Archive")
        case .code:
            return L10n.string("category.code", fallback: "Code")
        case .other:
            return L10n.string("category.file", fallback: "File")
        }
    }
}
