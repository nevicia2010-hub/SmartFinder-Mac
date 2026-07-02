import AppKit

final class MainWindowController: NSWindowController, NSSearchFieldDelegate {
    private let gridController = FileGridViewController()
    private let pathField = NSTextField(labelWithString: "")
    private let statusField = NSTextField(labelWithString: "")
    private let searchField = NSSearchField()
    private let backButton = NSButton(title: "Back", target: nil, action: nil)
    private let forwardButton = NSButton(title: "Forward", target: nil, action: nil)
    private let upButton = NSButton(title: "Up", target: nil, action: nil)

    private var sidebarURLs: [URL] = []
    private var history: [URL] = []
    private var historyIndex = -1

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
            sidebar.widthAnchor.constraint(equalToConstant: 190),

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
        searchField.delegate = self
        searchField.placeholderString = "Search current folder"

        let stack = NSStackView(views: [backButton, forwardButton, upButton, pathField, searchField])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        pathField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchField.widthAnchor.constraint(equalToConstant: 220).isActive = true
        return stack
    }

    private func makeSidebar() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let locations = sidebarLocations()
        sidebarURLs = locations.map(\.url)

        for (index, location) in locations.enumerated() {
            let button = NSButton(title: location.name, target: self, action: #selector(openSidebarLocation(_:)))
            button.bezelStyle = .inline
            button.alignment = .left
            button.tag = index
            button.widthAnchor.constraint(equalToConstant: 160).isActive = true
            stack.addArrangedSubview(button)
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

    private func sidebarLocations() -> [(name: String, url: URL)] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        func first(_ directory: FileManager.SearchPathDirectory) -> URL? {
            fileManager.urls(for: directory, in: .userDomainMask).first
        }

        return [
            ("Home", home),
            ("Desktop", first(.desktopDirectory) ?? home),
            ("Downloads", first(.downloadsDirectory) ?? home),
            ("Documents", first(.documentDirectory) ?? home),
            ("Pictures", first(.picturesDirectory) ?? home)
        ]
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
        gridController.applyFilter(searchField.stringValue)
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
