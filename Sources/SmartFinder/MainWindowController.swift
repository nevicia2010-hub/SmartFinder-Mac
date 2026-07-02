import AppKit
import SmartFinderCore

final class MainWindowController: NSWindowController, NSSearchFieldDelegate {
    private let gridController = FileGridViewController()
    private let mountedVolumeProvider = MountedVolumeProvider()
    private let pathField = NSTextField(string: "")
    private let statusField = NSTextField(labelWithString: "")
    private let searchField = NSSearchField()
    private let iconSizeSlider = NSSlider(value: 96, minValue: 64, maxValue: 180, target: nil, action: nil)
    private let backButton = NSButton(title: L10n.string("button.back", fallback: "Back"), target: nil, action: nil)
    private let forwardButton = NSButton(title: L10n.string("button.forward", fallback: "Forward"), target: nil, action: nil)
    private let upButton = NSButton(title: L10n.string("button.up", fallback: "Up"), target: nil, action: nil)

    private var sidebarURLs: [URL] = []
    private var history: [URL] = []
    private var historyIndex = -1

    private struct SidebarLocation {
        let name: String
        let url: URL
        let icon: NSImage
    }

    init(startURL: URL) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SmartFinder"
        super.init(window: window)

        setupContent()
        navigate(to: startURL, recordHistory: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent() {
        guard let window else {
            return
        }

        gridController.onOpenFolder = { [weak self] url in
            self?.navigate(to: url, recordHistory: true)
        }
        gridController.onStatusChange = { [weak self] status in
            self?.statusField.stringValue = status
        }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let toolbar = makeToolbar()
        let body = NSView()
        let sidebar = makeSidebar()
        let statusBar = makeStatusBar()

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        gridController.view.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(toolbar)
        contentView.addSubview(body)
        contentView.addSubview(statusBar)
        body.addSubview(sidebar)
        body.addSubview(gridController.view)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            body.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: statusBar.topAnchor),

            statusBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 28),

            sidebar.topAnchor.constraint(equalTo: body.topAnchor),
            sidebar.leadingAnchor.constraint(equalTo: body.leadingAnchor),
            sidebar.bottomAnchor.constraint(equalTo: body.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 210),

            gridController.view.topAnchor.constraint(equalTo: body.topAnchor),
            gridController.view.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            gridController.view.trailingAnchor.constraint(equalTo: body.trailingAnchor),
            gridController.view.bottomAnchor.constraint(equalTo: body.bottomAnchor)
        ])
    }

    private func makeToolbar() -> NSView {
        backButton.target = self
        backButton.action = #selector(goBack)
        forwardButton.target = self
        forwardButton.action = #selector(goForward)
        upButton.target = self
        upButton.action = #selector(goUp)

        pathField.lineBreakMode = .byTruncatingMiddle
        pathField.font = .systemFont(ofSize: 12)
        pathField.isEditable = true
        pathField.isSelectable = true
        pathField.bezelStyle = .roundedBezel
        pathField.target = self
        pathField.action = #selector(openPathFromField)

        searchField.delegate = self
        searchField.placeholderString = L10n.string("search.placeholder", fallback: "Search current folder")

        let refreshButton = toolbarIconButton(
            symbolName: "arrow.clockwise",
            fallbackTitle: L10n.string("toolbar.refresh", fallback: "Refresh"),
            action: #selector(refreshCurrentFolder)
        )
        let newFolderButton = toolbarIconButton(
            symbolName: "folder.badge.plus",
            fallbackTitle: L10n.string("toolbar.newFolder", fallback: "New Folder"),
            action: #selector(createFolder)
        )
        let revealButton = toolbarIconButton(
            symbolName: "finder",
            fallbackTitle: L10n.string("toolbar.revealInFinder", fallback: "Reveal in Finder"),
            action: #selector(revealInFinder)
        )

        iconSizeSlider.target = self
        iconSizeSlider.action = #selector(iconSizeChanged(_:))
        iconSizeSlider.toolTip = L10n.string("toolbar.iconSize", fallback: "Icon Size")
        iconSizeSlider.widthAnchor.constraint(equalToConstant: 110).isActive = true

        let stack = NSStackView(views: [
            backButton,
            forwardButton,
            upButton,
            refreshButton,
            newFolderButton,
            revealButton,
            pathField,
            searchField,
            iconSizeSlider
        ])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        pathField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchField.widthAnchor.constraint(equalToConstant: 220).isActive = true
        return stack
    }

    private func toolbarIconButton(symbolName: String, fallbackTitle: String, action: Selector) -> NSButton {
        let button = NSButton(title: "", target: self, action: action)
        button.toolTip = fallbackTitle
        button.bezelStyle = .texturedRounded
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: fallbackTitle)
        if button.image == nil {
            button.title = fallbackTitle
            button.imagePosition = .noImage
        }
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        return button
    }

    private func makeSidebar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .sidebar
        container.blendingMode = .withinWindow
        container.state = .active

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false

        sidebarURLs = []

        addSidebarHeader(
            L10n.string("sidebar.favorites", fallback: "Favorites"),
            to: stack
        )
        for location in standardSidebarLocations() {
            addSidebarButton(for: location, to: stack)
        }

        let mountedVolumes = mountedVolumeLocations()
        if !mountedVolumes.isEmpty {
            addSidebarSpacer(to: stack, height: 8)
            addSidebarHeader(
                L10n.string("sidebar.volumes", fallback: "Volumes"),
                to: stack
            )
            for location in mountedVolumes {
                addSidebarButton(for: location, to: stack)
            }
        }

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        return container
    }

    private func addSidebarHeader(_ title: String, to stack: NSStackView) {
        let field = NSTextField(labelWithString: title.uppercased(with: Locale.current))
        field.font = .systemFont(ofSize: 11, weight: .semibold)
        field.textColor = .secondaryLabelColor
        field.alignment = .left
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: 188).isActive = true
        stack.addArrangedSubview(field)
    }

    private func addSidebarSpacer(to stack: NSStackView, height: CGFloat) {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        spacer.widthAnchor.constraint(equalToConstant: 188).isActive = true
        stack.addArrangedSubview(spacer)
    }

    private func addSidebarButton(for location: SidebarLocation, to stack: NSStackView) {
        let index = sidebarURLs.count
        sidebarURLs.append(location.url)

        let button = NSButton(title: location.name, target: self, action: #selector(openSidebarLocation(_:)))
        button.image = location.icon
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleProportionallyDown
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.alignment = .left
        button.font = .systemFont(ofSize: 13)
        button.lineBreakMode = .byTruncatingTail
        button.tag = index
        button.setButtonType(.momentaryChange)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 188).isActive = true
        button.heightAnchor.constraint(equalToConstant: 26).isActive = true
        stack.addArrangedSubview(button)
    }

    private func makeStatusBar() -> NSView {
        let container = NSView()
        statusField.font = .systemFont(ofSize: 12)
        statusField.textColor = .secondaryLabelColor
        statusField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusField)
        NSLayoutConstraint.activate([
            statusField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            statusField.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func standardSidebarLocations() -> [SidebarLocation] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        func first(_ directory: FileManager.SearchPathDirectory) -> URL? {
            fileManager.urls(for: directory, in: .userDomainMask).first
        }

        return [
            sidebarLocation(L10n.string("sidebar.home", fallback: "Home"), home, "house"),
            sidebarLocation(L10n.string("sidebar.desktop", fallback: "Desktop"), first(.desktopDirectory) ?? home, "desktopcomputer"),
            sidebarLocation(L10n.string("sidebar.downloads", fallback: "Downloads"), first(.downloadsDirectory) ?? home, "arrow.down.circle"),
            sidebarLocation(L10n.string("sidebar.documents", fallback: "Documents"), first(.documentDirectory) ?? home, "doc.text"),
            sidebarLocation(L10n.string("sidebar.pictures", fallback: "Pictures"), first(.picturesDirectory) ?? home, "photo")
        ]
    }

    private func mountedVolumeLocations() -> [SidebarLocation] {
        mountedVolumeProvider.mountedVolumes().map { volume in
            let icon = NSWorkspace.shared.icon(forFile: volume.url.path)
            icon.size = NSSize(width: 18, height: 18)
            return SidebarLocation(name: volume.name, url: volume.url, icon: icon)
        }
    }

    private func sidebarLocation(_ name: String, _ url: URL, _ symbolName: String) -> SidebarLocation {
        let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: name)
            ?? NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 18, height: 18)
        return SidebarLocation(name: name, url: url, icon: icon)
    }

    private func navigate(to url: URL, recordHistory: Bool) {
        if recordHistory {
            if historyIndex < history.count - 1 {
                history.removeLast(history.count - historyIndex - 1)
            }
            history.append(url)
            historyIndex = history.count - 1
        }
        pathField.stringValue = url.path
        searchField.stringValue = ""
        gridController.applyFilter("")
        gridController.load(folderURL: url)
        updateNavigationButtons()
    }

    private func updateNavigationButtons() {
        backButton.isEnabled = historyIndex > 0
        forwardButton.isEnabled = historyIndex >= 0 && historyIndex < history.count - 1
        upButton.isEnabled = !pathField.stringValue.isEmpty && pathField.stringValue != "/"
    }

    func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSSearchField === searchField {
            gridController.applyFilter(searchField.stringValue)
        }
    }

    @objc private func refreshCurrentFolder() {
        gridController.refresh()
    }

    @objc private func createFolder() {
        gridController.createFolder()
    }

    @objc private func revealInFinder() {
        gridController.revealSelectionInFinder()
    }

    @objc private func iconSizeChanged(_ sender: NSSlider) {
        gridController.setIconSize(CGFloat(sender.doubleValue))
    }

    @objc private func openPathFromField() {
        let path = NSString(string: pathField.stringValue).expandingTildeInPath
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            let alert = NSAlert()
            alert.messageText = L10n.string("error.invalidPath.title", fallback: "Cannot Open Path")
            alert.informativeText = L10n.format(
                "error.invalidPath.message",
                fallback: "The folder does not exist: %@",
                path
            )
            alert.runModal()
            return
        }
        navigate(to: URL(fileURLWithPath: path, isDirectory: true), recordHistory: true)
    }

    @objc private func goBack() {
        guard historyIndex > 0 else {
            return
        }
        historyIndex -= 1
        navigate(to: history[historyIndex], recordHistory: false)
    }

    @objc private func goForward() {
        guard historyIndex < history.count - 1 else {
            return
        }
        historyIndex += 1
        navigate(to: history[historyIndex], recordHistory: false)
    }

    @objc private func goUp() {
        let currentPath = pathField.stringValue
        guard !currentPath.isEmpty, currentPath != "/" else {
            return
        }
        let parent = URL(fileURLWithPath: currentPath).deletingLastPathComponent()
        navigate(to: parent, recordHistory: true)
    }

    @objc private func openSidebarLocation(_ sender: NSButton) {
        guard sidebarURLs.indices.contains(sender.tag) else {
            return
        }
        navigate(to: sidebarURLs[sender.tag], recordHistory: true)
    }
}
