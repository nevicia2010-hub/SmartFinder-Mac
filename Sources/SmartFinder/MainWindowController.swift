import AppKit
import SmartFinderCore

private final class FinderToolbarButton: NSButton {
    private let symbolName: String
    private let fallbackTitle: String
    private weak var captionField: NSTextField?

    init(symbolName: String, fallbackTitle: String, target: AnyObject?, action: Selector) {
        self.symbolName = symbolName
        self.fallbackTitle = fallbackTitle
        super.init(frame: .zero)

        self.target = target
        self.action = action
        toolTip = fallbackTitle
        bezelStyle = .texturedRounded
        alignment = .center
        title = ""
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyUpOrDown
        refreshImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isEnabled: Bool {
        didSet {
            refreshImage()
            updateCaptionColor()
        }
    }

    func attachCaption(_ field: NSTextField) {
        captionField = field
        updateCaptionColor()
    }

    private func refreshImage() {
        if let image = Self.symbol(symbolName, description: fallbackTitle, enabled: isEnabled) {
            self.image = image
            title = ""
            imagePosition = .imageOnly
        } else {
            image = nil
            title = fallbackTitle
            imagePosition = .noImage
        }
    }

    private func updateCaptionColor() {
        captionField?.textColor = isEnabled ? .secondaryLabelColor : .disabledControlTextColor
    }

    static func symbol(_ symbolName: String, description: String, enabled: Bool) -> NSImage? {
        let color: NSColor = enabled ? .labelColor : .disabledControlTextColor
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(hierarchicalColor: color))
        image?.size = NSSize(
            width: CGFloat(FinderToolbarMetrics.symbolSize),
            height: CGFloat(FinderToolbarMetrics.symbolSize)
        )
        image?.isTemplate = false
        return image
    }
}

final class MainWindowController: NSWindowController, NSSearchFieldDelegate, NSWindowDelegate {
    private let gridController = FileGridViewController()
    private let mountedVolumeProvider = MountedVolumeProvider()
    private let pathField = NSTextField(string: "")
    private let statusField = NSTextField(labelWithString: "")
    private let searchField = NSSearchField()
    private let iconSizeSlider = NSSlider(value: 96, minValue: 64, maxValue: 180, target: nil, action: nil)
    private let fileTagStore = FileTagStore()
    private let backForwardControl = NSSegmentedControl()
    private let breadcrumbStack = NSStackView()
    private let toolbarTitleField = NSTextField(labelWithString: "")
    private let detailsPane = DetailsPaneView()
    private lazy var shareButton = toolbarIconButton(
        symbolName: "square.and.arrow.up",
        fallbackTitle: L10n.string("toolbar.share", fallback: "Share"),
        action: #selector(shareSelection(_:))
    )
    private lazy var tagButton = toolbarIconButton(
        symbolName: "tag",
        fallbackTitle: L10n.string("toolbar.tags", fallback: "Tags"),
        action: #selector(showTagMenu(_:))
    )
    private lazy var upButton = toolbarIconButton(
        symbolName: "chevron.up",
        fallbackTitle: L10n.string("button.up", fallback: "Up"),
        action: #selector(goUp)
    )

    private var sidebarURLs: [URL] = []
    private var breadcrumbURLs: [URL] = []
    private var navigationHistory = NavigationHistory()
    private var currentSortMode: FileSortMode = .name
    private var currentViewMode: FileViewMode = .icon
    private var activeSharingPicker: NSSharingServicePicker?
    private var toolbarTopConstraint: NSLayoutConstraint?
    private var detailsPaneWidthConstraint: NSLayoutConstraint?
    private weak var sidebarStack: NSStackView?
    private var detailsPaneVisible = false

    private struct SidebarLocation {
        let name: String
        let url: URL
        let icon: NSImage
        let isEjectable: Bool
    }

    init(startURL: URL) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SmartFinder"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        super.init(window: window)
        window.delegate = self

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
            self?.updateSelectionToolbarButtons()
        }
        gridController.onSelectionChange = { [weak self] items in
            self?.detailsPane.update(selection: items)
        }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let toolbar = makeToolbar()
        let breadcrumbBar = makeBreadcrumbBar()
        let rightPane = NSView()
        let sidebar = makeSidebar()
        let statusBar = makeStatusBar()

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        breadcrumbBar.translatesAutoresizingMaskIntoConstraints = false
        rightPane.translatesAutoresizingMaskIntoConstraints = false
        sidebar.translatesAutoresizingMaskIntoConstraints = false
        gridController.view.translatesAutoresizingMaskIntoConstraints = false
        detailsPane.translatesAutoresizingMaskIntoConstraints = false
        statusBar.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(sidebar)
        contentView.addSubview(rightPane)
        rightPane.addSubview(toolbar)
        rightPane.addSubview(breadcrumbBar)
        rightPane.addSubview(gridController.view)
        rightPane.addSubview(detailsPane)
        rightPane.addSubview(statusBar)

        let toolbarTopConstraint = toolbar.topAnchor.constraint(equalTo: rightPane.topAnchor)
        self.toolbarTopConstraint = toolbarTopConstraint
        let detailsPaneWidthConstraint = detailsPane.widthAnchor.constraint(equalToConstant: 0)
        self.detailsPaneWidthConstraint = detailsPaneWidthConstraint
        detailsPane.isHidden = true

        NSLayoutConstraint.activate([
            sidebar.topAnchor.constraint(equalTo: contentView.topAnchor),
            sidebar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sidebar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.sidebarWidth)),

            rightPane.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            rightPane.leadingAnchor.constraint(equalTo: sidebar.trailingAnchor),
            rightPane.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rightPane.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            toolbarTopConstraint,
            toolbar.leadingAnchor.constraint(equalTo: rightPane.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: rightPane.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.height)),

            breadcrumbBar.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            breadcrumbBar.leadingAnchor.constraint(equalTo: rightPane.leadingAnchor),
            breadcrumbBar.trailingAnchor.constraint(equalTo: rightPane.trailingAnchor),
            breadcrumbBar.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.breadcrumbHeight)),

            statusBar.leadingAnchor.constraint(equalTo: rightPane.leadingAnchor),
            statusBar.trailingAnchor.constraint(equalTo: rightPane.trailingAnchor),
            statusBar.bottomAnchor.constraint(equalTo: rightPane.bottomAnchor),
            statusBar.heightAnchor.constraint(equalToConstant: 28),

            gridController.view.topAnchor.constraint(equalTo: breadcrumbBar.bottomAnchor),
            gridController.view.leadingAnchor.constraint(equalTo: rightPane.leadingAnchor),
            gridController.view.trailingAnchor.constraint(equalTo: detailsPane.leadingAnchor),
            gridController.view.bottomAnchor.constraint(equalTo: statusBar.topAnchor),

            detailsPane.topAnchor.constraint(equalTo: breadcrumbBar.bottomAnchor),
            detailsPane.trailingAnchor.constraint(equalTo: rightPane.trailingAnchor),
            detailsPane.bottomAnchor.constraint(equalTo: statusBar.topAnchor),
            detailsPaneWidthConstraint
        ])
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        setFullScreenToolbarGuard(true)
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        setFullScreenToolbarGuard(true)
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        setFullScreenToolbarGuard(false)
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        setFullScreenToolbarGuard(false)
    }

    private func setFullScreenToolbarGuard(_ enabled: Bool) {
        toolbarTopConstraint?.constant = enabled ? CGFloat(FinderToolbarMetrics.fullScreenTopGuard) : 0
        window?.contentView?.layoutSubtreeIfNeeded()
    }

    private func makeToolbar() -> NSView {
        configureBackForwardControl()

        pathField.lineBreakMode = .byTruncatingMiddle
        pathField.font = FinderFonts.toolbarField
        pathField.isEditable = true
        pathField.isSelectable = true
        pathField.bezelStyle = .roundedBezel
        pathField.target = self
        pathField.action = #selector(openPathFromField)

        searchField.delegate = self
        searchField.placeholderString = L10n.string("search.placeholder", fallback: "Search current folder")

        toolbarTitleField.font = FinderFonts.toolbarTitle
        toolbarTitleField.textColor = .labelColor
        toolbarTitleField.lineBreakMode = .byTruncatingMiddle
        toolbarTitleField.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let displayButton = toolbarIconButton(
            symbolName: "square.grid.2x2",
            fallbackTitle: L10n.string("toolbar.display", fallback: "Display"),
            action: #selector(showDisplayMenu(_:))
        )
        let groupButton = toolbarIconButton(
            symbolName: "rectangle.grid.1x2",
            fallbackTitle: L10n.string("toolbar.group", fallback: "Group"),
            action: #selector(showGroupMenu(_:))
        )
        let actionButton = toolbarIconButton(
            symbolName: "ellipsis.circle",
            fallbackTitle: L10n.string("toolbar.actions", fallback: "Actions"),
            action: #selector(showActionMenu(_:))
        )

        iconSizeSlider.target = self
        iconSizeSlider.action = #selector(iconSizeChanged(_:))
        iconSizeSlider.toolTip = L10n.string("toolbar.iconSize", fallback: "Icon Size")
        iconSizeSlider.widthAnchor.constraint(equalToConstant: 104).isActive = true

        let flexibleSpacer = NSView()
        flexibleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let navigationControl = toolbarLabeledControl(
            backForwardControl,
            label: L10n.string("toolbar.navigation", fallback: "Back / Forward")
        )

        let stack = NSStackView(views: [
            navigationControl,
            toolbarLabeledButton(upButton, label: L10n.string("button.up", fallback: "Up")),
            toolbarTitleField,
            flexibleSpacer,
            toolbarLabeledButton(displayButton, label: L10n.string("toolbar.display", fallback: "Display")),
            toolbarLabeledButton(groupButton, label: L10n.string("toolbar.group", fallback: "Group")),
            toolbarLabeledButton(shareButton, label: L10n.string("toolbar.share", fallback: "Share")),
            toolbarLabeledButton(tagButton, label: L10n.string("toolbar.tags", fallback: "Tags")),
            toolbarLabeledButton(actionButton, label: L10n.string("toolbar.actions", fallback: "Actions")),
            searchField,
            iconSizeSlider
        ])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        pathField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pathField.font = FinderFonts.toolbarField
        pathField.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.buttonHeight)).isActive = true
        searchField.widthAnchor.constraint(equalToConstant: 220).isActive = true
        searchField.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.buttonHeight)).isActive = true

        let container = NSVisualEffectView()
        container.material = .headerView
        container.blendingMode = .withinWindow
        container.state = .active
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        updateSelectionToolbarButtons()
        return container
    }

    private func makeBreadcrumbBar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .contentBackground
        container.blendingMode = .withinWindow
        container.state = .active

        breadcrumbStack.orientation = .horizontal
        breadcrumbStack.alignment = .centerY
        breadcrumbStack.spacing = 2
        breadcrumbStack.edgeInsets = NSEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        breadcrumbStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(breadcrumbStack)
        NSLayoutConstraint.activate([
            breadcrumbStack.topAnchor.constraint(equalTo: container.topAnchor),
            breadcrumbStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            breadcrumbStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            breadcrumbStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func configureBackForwardControl() {
        backForwardControl.segmentCount = 2
        backForwardControl.trackingMode = .momentary
        backForwardControl.segmentStyle = .texturedRounded
        backForwardControl.target = self
        backForwardControl.action = #selector(backForwardChanged(_:))
        backForwardControl.toolTip = L10n.string("toolbar.navigation", fallback: "Back / Forward")
        backForwardControl.setToolTip(L10n.string("button.back", fallback: "Back"), forSegment: 0)
        backForwardControl.setToolTip(L10n.string("button.forward", fallback: "Forward"), forSegment: 1)
        backForwardControl.setImage(
            toolbarSymbol("chevron.left", description: L10n.string("button.back", fallback: "Back"), enabled: false),
            forSegment: 0
        )
        backForwardControl.setImage(
            toolbarSymbol("chevron.right", description: L10n.string("button.forward", fallback: "Forward"), enabled: false),
            forSegment: 1
        )
        backForwardControl.setWidth(CGFloat(FinderToolbarMetrics.navigationSegmentWidth), forSegment: 0)
        backForwardControl.setWidth(CGFloat(FinderToolbarMetrics.navigationSegmentWidth), forSegment: 1)
        backForwardControl.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.navigationSegmentWidth * 2)).isActive = true
        backForwardControl.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.buttonHeight)).isActive = true
    }

    private func toolbarIconButton(symbolName: String, fallbackTitle: String, action: Selector) -> NSButton {
        let button = FinderToolbarButton(symbolName: symbolName, fallbackTitle: fallbackTitle, target: self, action: action)
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(FinderToolbarMetrics.buttonWidth)).isActive = true
        button.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.buttonHeight)).isActive = true
        return button
    }

    private func toolbarLabeledButton(_ button: NSButton, label: String) -> NSView {
        toolbarLabeledControl(button, label: label)
    }

    private func toolbarLabeledControl(_ control: NSView, label: String) -> NSView {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = FinderFonts.toolbarButtonLabel
        labelField.textColor = .secondaryLabelColor
        labelField.alignment = .center
        labelField.lineBreakMode = .byTruncatingTail
        labelField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stack = NSStackView(views: [control, labelField])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 1
        stack.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let minimumWidth = max(
            CGFloat(FinderToolbarMetrics.buttonWidth),
            control == backForwardControl ? CGFloat(FinderToolbarMetrics.navigationSegmentWidth * 2) : 0
        )
        stack.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
        stack.heightAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.labeledButtonHeight)).isActive = true
        if let toolbarButton = control as? FinderToolbarButton {
            toolbarButton.attachCaption(labelField)
        }
        return stack
    }

    private func toolbarSymbol(_ symbolName: String, description: String, enabled: Bool = true) -> NSImage? {
        FinderToolbarButton.symbol(symbolName, description: description, enabled: enabled)
    }

    private func tagColorImage(for color: FinderTagColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 12, height: 12))
        image.lockFocus()
        finderTagSwatchColor(for: color).setFill()
        NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 10, height: 10)).fill()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private func finderTagSwatchColor(for color: FinderTagColor) -> NSColor {
        switch color {
        case .gray:
            return NSColor.systemGray
        case .green:
            return NSColor.systemGreen
        case .purple:
            return NSColor.systemPurple
        case .blue:
            return NSColor.systemBlue
        case .yellow:
            return NSColor.systemYellow
        case .red:
            return NSColor.systemRed
        case .orange:
            return NSColor.systemOrange
        }
    }

    private func popUp(_ menu: NSMenu, from sender: NSButton) {
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 2), in: sender)
    }

    private func menuItem(
        _ key: String,
        fallback: String,
        action: Selector,
        enabled: Bool = true,
        state: NSControl.StateValue = .off
    ) -> NSMenuItem {
        let item = NSMenuItem(title: L10n.string(key, fallback: fallback), action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        item.state = state
        return item
    }

    private func tagColorMenuItem(_ color: FinderTagColor, enabled: Bool) -> NSMenuItem {
        let item = menuItem(
            tagColorLocalizationKey(for: color),
            fallback: tagColorFallbackName(for: color),
            action: #selector(applyTagColorFromMenu(_:)),
            enabled: enabled
        )
        item.representedObject = color.labelNumber
        item.image = tagColorImage(for: color)
        return item
    }

    private func tagColorLocalizationKey(for color: FinderTagColor) -> String {
        switch color {
        case .gray:
            return "menu.tags.gray"
        case .green:
            return "menu.tags.green"
        case .purple:
            return "menu.tags.purple"
        case .blue:
            return "menu.tags.blue"
        case .yellow:
            return "menu.tags.yellow"
        case .red:
            return "menu.tags.red"
        case .orange:
            return "menu.tags.orange"
        }
    }

    private func tagColorFallbackName(for color: FinderTagColor) -> String {
        switch color {
        case .gray:
            return "Gray"
        case .green:
            return "Green"
        case .purple:
            return "Purple"
        case .blue:
            return "Blue"
        case .yellow:
            return "Yellow"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        }
    }

    private func sortMenuItem(_ key: String, fallback: String, mode: FileSortMode, action: Selector) -> NSMenuItem {
        menuItem(
            key,
            fallback: fallback,
            action: action,
            state: currentSortMode == mode ? .on : .off
        )
    }

    private func makeSidebar() -> NSView {
        let container = NSVisualEffectView()
        container.material = .sidebar
        container.blendingMode = .behindWindow
        container.state = .active

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(
            top: CGFloat(FinderToolbarMetrics.sidebarTopInset),
            left: 12,
            bottom: 12,
            right: 12
        )
        stack.translatesAutoresizingMaskIntoConstraints = false
        sidebarStack = stack

        populateSidebar(stack)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        return container
    }

    private func populateSidebar(_ stack: NSStackView) {
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
    }

    private func reloadSidebar() {
        guard let sidebarStack else {
            return
        }
        for view in sidebarStack.arrangedSubviews {
            sidebarStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        populateSidebar(sidebarStack)
    }

    private func addSidebarHeader(_ title: String, to stack: NSStackView) {
        let field = NSTextField(labelWithString: title.uppercased(with: Locale.current))
        field.font = FinderFonts.sidebarHeader
        field.textColor = .secondaryLabelColor
        field.alignment = .left
        field.translatesAutoresizingMaskIntoConstraints = false
        field.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.sidebarContentWidth)).isActive = true
        stack.addArrangedSubview(field)
    }

    private func addSidebarSpacer(to stack: NSStackView, height: CGFloat) {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        spacer.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.sidebarContentWidth)).isActive = true
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
        button.font = FinderFonts.sidebarRow
        button.lineBreakMode = .byTruncatingTail
        button.tag = index
        button.setButtonType(.momentaryChange)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 26).isActive = true

        if location.isEjectable {
            let row = NSView()
            row.translatesAutoresizingMaskIntoConstraints = false

            let ejectButton = NSButton(title: "", target: self, action: #selector(ejectSidebarVolume(_:)))
            ejectButton.toolTip = L10n.string("sidebar.eject", fallback: "Eject")
            ejectButton.bezelStyle = .inline
            ejectButton.isBordered = false
            ejectButton.imagePosition = .imageOnly
            ejectButton.image = NSImage(systemSymbolName: "eject", accessibilityDescription: L10n.string("sidebar.eject", fallback: "Eject"))
            ejectButton.imageScaling = .scaleProportionallyDown
            ejectButton.tag = index
            ejectButton.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(button)
            row.addSubview(ejectButton)

            NSLayoutConstraint.activate([
                row.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.sidebarContentWidth)),
                row.heightAnchor.constraint(equalToConstant: 26),

                button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                button.topAnchor.constraint(equalTo: row.topAnchor),
                button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                button.trailingAnchor.constraint(equalTo: ejectButton.leadingAnchor, constant: -2),

                ejectButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                ejectButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                ejectButton.widthAnchor.constraint(equalToConstant: 24),
                ejectButton.heightAnchor.constraint(equalToConstant: 24)
            ])
            stack.addArrangedSubview(row)
        } else {
            button.widthAnchor.constraint(equalToConstant: CGFloat(FinderToolbarMetrics.sidebarContentWidth)).isActive = true
            stack.addArrangedSubview(button)
        }
    }

    private func makeStatusBar() -> NSView {
        let container = NSView()
        statusField.font = FinderFonts.status
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
            return SidebarLocation(name: volume.name, url: volume.url, icon: icon, isEjectable: volume.isEjectable)
        }
    }

    private func sidebarLocation(_ name: String, _ url: URL, _ symbolName: String) -> SidebarLocation {
        let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: name)
            ?? NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 18, height: 18)
        return SidebarLocation(name: name, url: url, icon: icon, isEjectable: false)
    }

    private func navigate(to url: URL, recordHistory: Bool) {
        if recordHistory {
            navigationHistory.record(url)
        }
        pathField.stringValue = url.path
        toolbarTitleField.stringValue = title(for: url)
        updateBreadcrumbs(for: url)
        searchField.stringValue = ""
        gridController.applyFilter("")
        gridController.load(folderURL: url)
        updateNavigationButtons()
    }

    private func title(for url: URL) -> String {
        let name = url.lastPathComponent
        return name.isEmpty ? url.path : name
    }

    private func updateBreadcrumbs(for url: URL) {
        for view in breadcrumbStack.arrangedSubviews {
            breadcrumbStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let components = PathBreadcrumb.components(for: url)
        breadcrumbURLs = components.map(\.url)

        for (index, component) in components.enumerated() {
            if index > 0 {
                let separator = NSTextField(labelWithString: ">")
                separator.font = FinderFonts.breadcrumb
                separator.textColor = .tertiaryLabelColor
                breadcrumbStack.addArrangedSubview(separator)
            }

            let button = NSButton(title: component.title, target: self, action: #selector(openBreadcrumb(_:)))
            button.bezelStyle = .inline
            button.isBordered = false
            button.font = FinderFonts.breadcrumb
            button.lineBreakMode = .byTruncatingMiddle
            button.alignment = .center
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            button.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true
            breadcrumbStack.addArrangedSubview(button)
        }
    }

    private func updateNavigationButtons() {
        let canGoBack = navigationHistory.canGoBack
        let canGoForward = navigationHistory.canGoForward
        let canGoUp = !pathField.stringValue.isEmpty && pathField.stringValue != "/"

        backForwardControl.setEnabled(true, forSegment: 0)
        backForwardControl.setEnabled(true, forSegment: 1)
        backForwardControl.setImage(
            toolbarSymbol("chevron.left", description: L10n.string("button.back", fallback: "Back"), enabled: canGoBack),
            forSegment: 0
        )
        backForwardControl.setImage(
            toolbarSymbol("chevron.right", description: L10n.string("button.forward", fallback: "Forward"), enabled: canGoForward),
            forSegment: 1
        )
        upButton.isEnabled = canGoUp
    }

    private func updateSelectionToolbarButtons() {
        let hasSelection = gridController.selectedItemCount() > 0
        shareButton.isEnabled = hasSelection
        tagButton.isEnabled = hasSelection
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

    @objc private func backForwardChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            goBack()
        case 1:
            goForward()
        default:
            break
        }
    }

    @objc private func showDisplayMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(menuItem(
            "menu.display.iconView",
            fallback: "Icon View",
            action: #selector(useIconView),
            state: currentViewMode == .icon ? .on : .off
        ))
        menu.addItem(menuItem(
            "menu.display.listView",
            fallback: "List View",
            action: #selector(useListView),
            state: currentViewMode == .list ? .on : .off
        ))
        menu.addItem(menuItem(
            "menu.display.columnView",
            fallback: "Column View",
            action: #selector(useColumnView),
            state: currentViewMode == .column ? .on : .off
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.display.smallIcons", fallback: "Small Icons", action: #selector(useSmallIcons)))
        menu.addItem(menuItem("menu.display.mediumIcons", fallback: "Medium Icons", action: #selector(useMediumIcons)))
        menu.addItem(menuItem("menu.display.largeIcons", fallback: "Large Icons", action: #selector(useLargeIcons)))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem(
            "menu.display.hiddenItems",
            fallback: "Hidden Items",
            action: #selector(toggleHiddenItems),
            state: gridController.includesHiddenItemsEnabled() ? .on : .off
        ))
        menu.addItem(menuItem(
            "menu.display.fileExtensions",
            fallback: "File Name Extensions",
            action: #selector(toggleFileExtensions),
            state: gridController.showsFileExtensionsEnabled() ? .on : .off
        ))
        menu.addItem(menuItem(
            "menu.display.itemCheckboxes",
            fallback: "Item Checkboxes",
            action: #selector(toggleItemCheckboxes),
            state: gridController.showsSelectionCheckboxesEnabled() ? .on : .off
        ))
        menu.addItem(menuItem(
            "menu.display.detailsPane",
            fallback: "Details Pane",
            action: #selector(toggleDetailsPane),
            state: detailsPaneVisible ? .on : .off
        ))
        popUp(menu, from: sender)
    }

    @objc private func showGroupMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(sortMenuItem("toolbar.sort.name", fallback: "Name", mode: .name, action: #selector(sortByName)))
        menu.addItem(sortMenuItem("toolbar.sort.type", fallback: "Type", mode: .type, action: #selector(sortByType)))
        menu.addItem(sortMenuItem("toolbar.sort.size", fallback: "Size", mode: .size, action: #selector(sortBySize)))
        menu.addItem(sortMenuItem("toolbar.sort.modified", fallback: "Modified", mode: .modified, action: #selector(sortByModified)))
        popUp(menu, from: sender)
    }

    @objc private func showTagMenu(_ sender: NSButton) {
        let hasSelection = gridController.selectedItemCount() > 0
        let menu = NSMenu()
        menu.addItem(tagColorMenuItem(.red, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.orange, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.yellow, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.green, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.blue, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.purple, enabled: hasSelection))
        menu.addItem(tagColorMenuItem(.gray, enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.tags.clear", fallback: "Clear Tags", action: #selector(clearTags), enabled: hasSelection))
        popUp(menu, from: sender)
    }

    @objc private func showActionMenu(_ sender: NSButton) {
        let hasSelection = gridController.selectedItemCount() > 0
        let canPaste = gridController.currentFolder() != nil
        let menu = NSMenu()
        menu.addItem(menuItem("menu.open", fallback: "Open", action: #selector(openSelectionFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.quickLook", fallback: "Quick Look", action: #selector(quickLookSelectionFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.getInfo", fallback: "Get Info", action: #selector(getInfoFromToolbar), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.newFolder", fallback: "New Folder", action: #selector(createFolder), enabled: canPaste))
        menu.addItem(menuItem("menu.newTextFile", fallback: "New Text File", action: #selector(createTextFileFromToolbar), enabled: canPaste))
        menu.addItem(menuItem("menu.newMarkdownFile", fallback: "New Markdown File", action: #selector(createMarkdownFileFromToolbar), enabled: canPaste))
        menu.addItem(menuItem("menu.rename", fallback: "Rename", action: #selector(renameSelectionFromToolbar), enabled: gridController.selectedItemCount() == 1))
        menu.addItem(menuItem("menu.moveToTrash", fallback: "Move to Trash", action: #selector(moveSelectionToTrashFromToolbar), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.copy", fallback: "Copy", action: #selector(copySelectionFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyTo", fallback: "Copy To...", action: #selector(copySelectionToFolderFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.moveTo", fallback: "Move To...", action: #selector(moveSelectionToFolderFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyPath", fallback: "Copy Path", action: #selector(copyPathFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.compress", fallback: "Compress", action: #selector(compressSelectionFromToolbar), enabled: hasSelection))
        menu.addItem(menuItem("menu.paste", fallback: "Paste", action: #selector(pasteIntoFolderFromToolbar), enabled: canPaste))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.revealInFinder", fallback: "Reveal in Finder", action: #selector(revealInFinder), enabled: hasSelection || canPaste))
        popUp(menu, from: sender)
    }

    @objc private func shareSelection(_ sender: NSButton) {
        let urls = gridController.selectedURLs()
        guard !urls.isEmpty else {
            NSSound.beep()
            return
        }
        activeSharingPicker = NSSharingServicePicker(items: urls)
        activeSharingPicker?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    @objc private func useSmallIcons() {
        setIconSizePreset(72)
    }

    @objc private func useMediumIcons() {
        setIconSizePreset(96)
    }

    @objc private func useLargeIcons() {
        setIconSizePreset(144)
    }

    @objc private func useIconView() {
        setViewMode(.icon)
    }

    @objc private func useListView() {
        setViewMode(.list)
    }

    @objc private func useColumnView() {
        setViewMode(.column)
    }

    private func setIconSizePreset(_ size: Double) {
        iconSizeSlider.doubleValue = size
        gridController.setIconSize(CGFloat(size))
    }

    private func setViewMode(_ mode: FileViewMode) {
        currentViewMode = mode
        gridController.setViewMode(mode)
    }

    @objc private func toggleHiddenItems() {
        gridController.setIncludesHiddenItems(!gridController.includesHiddenItemsEnabled())
    }

    @objc private func toggleFileExtensions() {
        gridController.setShowsFileExtensions(!gridController.showsFileExtensionsEnabled())
    }

    @objc private func toggleItemCheckboxes() {
        gridController.setShowsSelectionCheckboxes(!gridController.showsSelectionCheckboxesEnabled())
    }

    @objc private func toggleDetailsPane() {
        setDetailsPaneVisible(!detailsPaneVisible)
    }

    private func setDetailsPaneVisible(_ visible: Bool) {
        detailsPaneVisible = visible
        detailsPane.isHidden = !visible
        detailsPaneWidthConstraint?.constant = visible ? 260 : 0
        window?.contentView?.layoutSubtreeIfNeeded()
    }

    @objc private func sortByName() {
        setSortMode(.name)
    }

    @objc private func sortByType() {
        setSortMode(.type)
    }

    @objc private func sortBySize() {
        setSortMode(.size)
    }

    @objc private func sortByModified() {
        setSortMode(.modified)
    }

    private func setSortMode(_ mode: FileSortMode) {
        currentSortMode = mode
        gridController.setSortMode(mode)
    }

    @objc private func applyTagColorFromMenu(_ sender: NSMenuItem) {
        guard
            let labelNumber = sender.representedObject as? Int,
            let color = FinderTagColor(rawValue: labelNumber)
        else {
            NSSound.beep()
            return
        }
        applyFinderLabelColor(color)
    }

    @objc private func clearTags() {
        let urls = gridController.selectedURLs()
        guard !urls.isEmpty else {
            NSSound.beep()
            return
        }
        do {
            for url in urls {
                try fileTagStore.clearTags(for: url)
            }
            gridController.refresh()
        } catch {
            showOperationError(error)
        }
    }

    private func applyFinderLabelColor(_ color: FinderTagColor) {
        do {
            for url in gridController.selectedURLs() {
                try fileTagStore.setFinderLabelColor(color, for: url)
            }
            gridController.refresh()
        } catch {
            showOperationError(error)
        }
    }

    private func showOperationError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    @objc private func openSelectionFromToolbar() {
        gridController.openSelection()
    }

    @objc private func quickLookSelectionFromToolbar() {
        gridController.quickLookSelection()
    }

    @objc private func renameSelectionFromToolbar() {
        gridController.renameSelection()
    }

    @objc private func moveSelectionToTrashFromToolbar() {
        gridController.moveSelectedToTrash()
    }

    @objc private func copySelectionToFolderFromToolbar() {
        guard let targetURL = chooseDestinationFolder() else {
            return
        }
        gridController.copySelection(toDirectory: targetURL)
    }

    @objc private func moveSelectionToFolderFromToolbar() {
        guard let targetURL = chooseDestinationFolder() else {
            return
        }
        gridController.moveSelection(toDirectory: targetURL)
    }

    @objc private func copySelectionFromToolbar() {
        gridController.copySelectionToPasteboard()
    }

    @objc private func copyPathFromToolbar() {
        gridController.copySelectedPathsToPasteboard()
    }

    @objc private func compressSelectionFromToolbar() {
        gridController.compressSelection()
    }

    @objc private func getInfoFromToolbar() {
        gridController.showInfoForSelection()
    }

    @objc private func pasteIntoFolderFromToolbar() {
        gridController.pasteIntoCurrentFolder()
    }

    @objc private func createTextFileFromToolbar() {
        gridController.createTextFile(named: uniqueTimestampedName(prefix: "Untitled", extensionPart: "txt"))
    }

    @objc private func createMarkdownFileFromToolbar() {
        gridController.createTextFile(named: uniqueTimestampedName(prefix: "Untitled", extensionPart: "md"), contents: "# Notes\n")
    }

    private func chooseDestinationFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.string("dialog.chooseFolder.prompt", fallback: "Choose")
        panel.message = L10n.string("dialog.chooseFolder.message", fallback: "Choose a destination folder.")
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func uniqueTimestampedName(prefix: String, extensionPart: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(prefix)-\(formatter.string(from: Date())).\(extensionPart)"
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
        guard let url = navigationHistory.goBack() else {
            return
        }
        navigate(to: url, recordHistory: false)
    }

    @objc private func goForward() {
        guard let url = navigationHistory.goForward() else {
            return
        }
        navigate(to: url, recordHistory: false)
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

    @objc private func openBreadcrumb(_ sender: NSButton) {
        guard breadcrumbURLs.indices.contains(sender.tag) else {
            return
        }
        navigate(to: breadcrumbURLs[sender.tag], recordHistory: true)
    }

    @objc private func ejectSidebarVolume(_ sender: NSButton) {
        guard sidebarURLs.indices.contains(sender.tag) else {
            return
        }

        let volumeURL = sidebarURLs[sender.tag]
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { try NSWorkspace.shared.unmountAndEjectDevice(at: volumeURL) }
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                if case .failure(let error) = result {
                    self.showOperationError(error)
                    return
                }
                if self.currentPathIsInside(volumeURL) {
                    let home = FileManager.default.homeDirectoryForCurrentUser
                    self.navigate(to: home, recordHistory: true)
                }
                self.reloadSidebar()
            }
        }
    }

    private func currentPathIsInside(_ volumeURL: URL) -> Bool {
        let currentPath = NSString(string: pathField.stringValue).standardizingPath
        let volumePath = volumeURL.standardizedFileURL.path
        return currentPath == volumePath || currentPath.hasPrefix(volumePath + "/")
    }
}
