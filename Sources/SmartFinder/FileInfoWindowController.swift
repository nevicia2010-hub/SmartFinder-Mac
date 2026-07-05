import AppKit
import SmartFinderCore

final class FileInfoWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private let presentation: FileInfoPanelPresentation
    private let icon: NSImage
    private var copyableValues: [String] = []

    init(presentation: FileInfoPanelPresentation, icon: NSImage) {
        self.presentation = presentation
        self.icon = icon

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.format("info.windowTitle", fallback: "%@ Info", presentation.title)
        window.representedURL = presentation.representedURL
        window.minSize = NSSize(width: 420, height: 420)

        super.init(window: window)

        window.delegate = self
        window.contentView = makeContentView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func makeContentView() -> NSView {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 14, right: 18)
        root.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(makeHeaderView())
        root.addArrangedSubview(makeSeparator())
        root.addArrangedSubview(makeSectionsScrollView())
        root.addArrangedSubview(makeFooterView())

        let contentView = NSView()
        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        return contentView
    }

    private func makeHeaderView() -> NSView {
        let iconView = NSImageView(image: icon)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 72),
            iconView.heightAnchor.constraint(equalToConstant: 72)
        ])

        let titleField = NSTextField(wrappingLabelWithString: presentation.title)
        titleField.font = .systemFont(ofSize: 20, weight: .semibold)
        titleField.lineBreakMode = .byWordWrapping
        titleField.maximumNumberOfLines = 2

        let subtitle = presentation.row(for: .kind)?.value ?? ""
        let subtitleField = NSTextField(labelWithString: subtitle)
        subtitleField.font = .systemFont(ofSize: 13)
        subtitleField.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleField, subtitleField])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let header = NSStackView(views: [iconView, textStack])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 16
        header.translatesAutoresizingMaskIntoConstraints = false
        header.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true

        return header
    }

    private func makeSectionsScrollView() -> NSScrollView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        stack.translatesAutoresizingMaskIntoConstraints = false

        for section in presentation.sections {
            stack.addArrangedSubview(makeSectionView(section))
        }

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.documentView = stack
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        return scrollView
    }

    private func makeSectionView(_ section: FileInfoPanelSection) -> NSView {
        let titleField = NSTextField(labelWithString: title(for: section.kind))
        titleField.font = .systemFont(ofSize: 13, weight: .semibold)
        titleField.textColor = .labelColor

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 8
        for row in section.rows {
            rowsStack.addArrangedSubview(makeRowView(row))
        }

        let sectionStack = NSStackView(views: [titleField, rowsStack])
        sectionStack.orientation = .vertical
        sectionStack.alignment = .leading
        sectionStack.spacing = 8
        sectionStack.translatesAutoresizingMaskIntoConstraints = false
        sectionStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true

        return sectionStack
    }

    private func makeRowView(_ row: FileInfoPanelRow) -> NSView {
        let labelField = NSTextField(labelWithString: label(for: row.field))
        labelField.font = .systemFont(ofSize: 12)
        labelField.textColor = .secondaryLabelColor
        labelField.alignment = .right
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.widthAnchor.constraint(equalToConstant: 118).isActive = true

        let valueField = NSTextField(wrappingLabelWithString: row.value)
        valueField.font = .systemFont(ofSize: 12.5)
        valueField.textColor = .labelColor
        valueField.isSelectable = true
        valueField.lineBreakMode = .byWordWrapping
        valueField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rowStack = NSStackView(views: [labelField, valueField])
        rowStack.orientation = .horizontal
        rowStack.alignment = .firstBaseline
        rowStack.spacing = 10
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        if row.isCopyable {
            let button = NSButton(
                image: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil) ?? NSImage(),
                target: self,
                action: #selector(copyRowValue(_:))
            )
            copyableValues.append(row.value)
            button.tag = copyableValues.count - 1
            button.title = ""
            button.bezelStyle = .texturedRounded
            button.imagePosition = .imageOnly
            button.toolTip = L10n.string("info.copyValue", fallback: "Copy value")
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 28),
                button.heightAnchor.constraint(equalToConstant: 24)
            ])
            rowStack.addArrangedSubview(button)
        }

        rowStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true
        return rowStack
    }

    private func makeFooterView() -> NSView {
        let copyPathButton = NSButton(
            title: L10n.string("info.copyPath", fallback: "Copy Path"),
            target: self,
            action: #selector(copyFullPath)
        )
        copyPathButton.bezelStyle = .rounded

        let revealButton = NSButton(
            title: L10n.string("menu.revealInFinder", fallback: "Reveal in Finder"),
            target: self,
            action: #selector(revealInFinder)
        )
        revealButton.bezelStyle = .rounded

        let closeButton = NSButton(
            title: L10n.string("dialog.close", fallback: "Close"),
            target: self,
            action: #selector(closeWindow)
        )
        closeButton.bezelStyle = .rounded

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let footer = NSStackView(views: [copyPathButton, revealButton, spacer, closeButton])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = 8
        footer.translatesAutoresizingMaskIntoConstraints = false
        footer.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true

        return footer
    }

    private func makeSeparator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true
        return separator
    }

    private func title(for section: FileInfoPanelSectionKind) -> String {
        switch section {
        case .general:
            return L10n.string("info.section.general", fallback: "General")
        case .nameAndExtension:
            return L10n.string("info.section.nameAndExtension", fallback: "Name & Extension")
        case .path:
            return L10n.string("info.section.path", fallback: "Path")
        case .system:
            return L10n.string("info.section.system", fallback: "System")
        }
    }

    private func label(for field: FileInfoPanelField) -> String {
        switch field {
        case .kind:
            return L10n.string("info.kind", fallback: "Kind")
        case .size:
            return L10n.string("info.size", fallback: "Size")
        case .where:
            return L10n.string("info.where", fallback: "Where")
        case .created:
            return L10n.string("info.created", fallback: "Created")
        case .modified:
            return L10n.string("info.modified", fallback: "Modified")
        case .name:
            return L10n.string("info.name", fallback: "Name")
        case .extension:
            return L10n.string("info.extension", fallback: "Extension")
        case .fullPath:
            return L10n.string("info.fullPath", fallback: "Full Path")
        case .typeIdentifier:
            return L10n.string("info.typeIdentifier", fallback: "Type Identifier")
        }
    }

    @objc private func copyRowValue(_ sender: NSButton) {
        guard copyableValues.indices.contains(sender.tag) else {
            return
        }
        copy(copyableValues[sender.tag])
    }

    @objc private func copyFullPath() {
        copy(presentation.representedURL.path)
    }

    @objc private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([presentation.representedURL])
    }

    @objc private func closeWindow() {
        window?.close()
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
