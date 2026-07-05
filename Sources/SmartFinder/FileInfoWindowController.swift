import AppKit
import SmartFinderCore

final class FileInfoWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    private struct OpenWithApplication {
        let name: String
        let url: URL
    }

    private let presentation: FileInfoPanelPresentation
    private let icon: NSImage
    private let openWithApplications: [OpenWithApplication]
    private var copyableValues: [String] = []
    private weak var openWithPopUpButton: NSPopUpButton?

    init(presentation: FileInfoPanelPresentation, icon: NSImage) {
        self.presentation = presentation
        self.icon = icon
        self.openWithApplications = Self.applications(toOpen: presentation.representedURL)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.format("info.windowTitle", fallback: "%@ Info", presentation.title)
        window.representedURL = presentation.representedURL
        window.minSize = NSSize(width: 460, height: 420)

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
        root.alignment = .width
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 14, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(makeHeaderView())
        root.addArrangedSubview(makeSeparator())
        root.addArrangedSubview(makeSectionsView())
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
            iconView.widthAnchor.constraint(equalToConstant: 58),
            iconView.heightAnchor.constraint(equalToConstant: 58)
        ])

        let titleField = NSTextField(wrappingLabelWithString: presentation.title)
        titleField.font = .systemFont(ofSize: 16, weight: .semibold)
        titleField.lineBreakMode = .byWordWrapping
        titleField.maximumNumberOfLines = 2

        let modifiedText = presentation.row(for: .modified).map {
            "\(L10n.string("info.modified", fallback: "Modified")): \($0.value)"
        }
        let subtitle = modifiedText ?? presentation.row(for: .kind)?.value ?? ""
        let subtitleField = NSTextField(labelWithString: subtitle)
        subtitleField.font = .systemFont(ofSize: 12)
        subtitleField.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [titleField, subtitleField])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let sizeField = NSTextField(labelWithString: presentation.row(for: .size)?.value ?? "")
        sizeField.font = .systemFont(ofSize: 15, weight: .semibold)
        sizeField.alignment = .right
        sizeField.setContentCompressionResistancePriority(.required, for: .horizontal)

        let header = NSStackView(views: [iconView, textStack, spacer, sizeField])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12
        header.translatesAutoresizingMaskIntoConstraints = false

        return header
    }

    private func makeSectionsView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .width
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, section) in presentation.sections.enumerated() {
            if index > 0 {
                stack.addArrangedSubview(makeSeparator())
            }
            stack.addArrangedSubview(makeSectionView(section))
        }

        return stack
    }

    private func makeSectionView(_ section: FileInfoPanelSection) -> NSView {
        if section.kind == .openWith {
            return makeOpenWithSectionView(section)
        }

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
        sectionStack.alignment = .width
        sectionStack.spacing = 7
        sectionStack.edgeInsets = NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        sectionStack.translatesAutoresizingMaskIntoConstraints = false

        return sectionStack
    }

    private func makeOpenWithSectionView(_ section: FileInfoPanelSection) -> NSView {
        let titleField = NSTextField(labelWithString: title(for: section.kind))
        titleField.font = .systemFont(ofSize: 13, weight: .semibold)

        let popUpButton = NSPopUpButton()
        popUpButton.target = self
        popUpButton.action = #selector(openWithApplicationChanged(_:))
        popUpButton.translatesAutoresizingMaskIntoConstraints = false
        popUpButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true
        configureOpenWithMenu(popUpButton)
        openWithPopUpButton = popUpButton

        let openButton = NSButton(
            title: L10n.string("info.openWithButton", fallback: "Open"),
            target: self,
            action: #selector(openWithSelectedApplication)
        )
        openButton.bezelStyle = .rounded
        openButton.isEnabled = !openWithApplications.isEmpty

        let rowStack = NSStackView(views: [makeFieldLabel(.defaultApplication), popUpButton, openButton])
        rowStack.orientation = .horizontal
        rowStack.alignment = .centerY
        rowStack.spacing = 10

        let helpField = NSTextField(labelWithString: L10n.string("info.openWithHelp", fallback: "Choose an app to open this file."))
        helpField.font = .systemFont(ofSize: 11.5)
        helpField.textColor = .secondaryLabelColor

        let sectionStack = NSStackView(views: [titleField, rowStack, helpField])
        sectionStack.orientation = .vertical
        sectionStack.alignment = .width
        sectionStack.spacing = 7
        sectionStack.edgeInsets = NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return sectionStack
    }

    private func makeRowView(_ row: FileInfoPanelRow) -> NSView {
        let labelField = makeFieldLabel(row.field)

        let valueField = NSTextField(wrappingLabelWithString: row.value)
        valueField.font = .systemFont(ofSize: 12.8)
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

        return rowStack
    }

    private func makeFieldLabel(_ field: FileInfoPanelField) -> NSTextField {
        let labelField = NSTextField(labelWithString: "\(label(for: field)):")
        labelField.font = .systemFont(ofSize: 12.5, weight: .semibold)
        labelField.textColor = .secondaryLabelColor
        labelField.alignment = .right
        labelField.translatesAutoresizingMaskIntoConstraints = false
        labelField.widthAnchor.constraint(equalToConstant: 112).isActive = true
        return labelField
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
        case .openWith:
            return L10n.string("info.section.openWith", fallback: "Open With")
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
        case .defaultApplication:
            return L10n.string("info.defaultApplication", fallback: "Application")
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

    @objc private func openWithApplicationChanged(_ sender: NSPopUpButton) {}

    @objc private func openWithSelectedApplication() {
        guard let selectedApp = selectedOpenWithApplication() else {
            NSWorkspace.shared.open(presentation.representedURL)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open(
            [presentation.representedURL],
            withApplicationAt: selectedApp.url,
            configuration: configuration
        )
    }

    @objc private func closeWindow() {
        window?.close()
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func configureOpenWithMenu(_ popUpButton: NSPopUpButton) {
        popUpButton.removeAllItems()
        guard !openWithApplications.isEmpty else {
            popUpButton.addItem(withTitle: L10n.string("info.noApplications", fallback: "No application found"))
            popUpButton.isEnabled = false
            return
        }

        for app in openWithApplications {
            popUpButton.addItem(withTitle: app.name)
            popUpButton.lastItem?.representedObject = app.url
            let icon = NSWorkspace.shared.icon(forFile: app.url.path)
            icon.size = NSSize(width: 16, height: 16)
            popUpButton.lastItem?.image = icon
        }
    }

    private func selectedOpenWithApplication() -> OpenWithApplication? {
        guard let selectedURL = openWithPopUpButton?.selectedItem?.representedObject as? URL else {
            return nil
        }
        return openWithApplications.first { $0.url == selectedURL }
    }

    private static func applications(toOpen fileURL: URL) -> [OpenWithApplication] {
        let workspace = NSWorkspace.shared
        let defaultURL = workspace.urlForApplication(toOpen: fileURL)
        var urls = workspace.urlsForApplications(toOpen: fileURL)
        if let defaultURL, !urls.contains(defaultURL) {
            urls.insert(defaultURL, at: 0)
        }

        var seen = Set<URL>()
        let apps = urls.compactMap { appURL -> OpenWithApplication? in
            let standardizedURL = appURL.standardizedFileURL
            guard !seen.contains(standardizedURL) else {
                return nil
            }
            seen.insert(standardizedURL)
            return OpenWithApplication(name: applicationName(for: standardizedURL), url: standardizedURL)
        }

        return apps.sorted { lhs, rhs in
            if lhs.url == defaultURL {
                return true
            }
            if rhs.url == defaultURL {
                return false
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private static func applicationName(for url: URL) -> String {
        if let bundleName = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return FileManager.default.displayName(atPath: url.path)
    }
}
