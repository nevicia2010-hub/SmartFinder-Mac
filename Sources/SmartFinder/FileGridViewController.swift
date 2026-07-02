import AppKit
import SmartFinderCore

enum FileSortMode: Equatable {
    case name
    case type
    case size
    case modified
}

enum FileViewMode: Equatable {
    case icon
    case list
}

protocol SmartCollectionViewKeyDelegate: AnyObject {
    func smartCollectionViewDidPressSpace()
    func smartCollectionViewDidPressCommandA()
    func smartCollectionViewDidDoubleClick()
    func smartCollectionViewDidPressReturn()
    func smartCollectionViewDidPressCopy()
    func smartCollectionViewDidPressPaste()
    func smartCollectionViewDidPressRefresh()
    func smartCollectionViewDidPressNewFolder()
    func smartCollectionViewDidPressMoveToTrash()
    func smartCollectionViewDidPressGetInfo()
    func smartCollectionViewDidRightClick(event: NSEvent)
}

final class SmartCollectionView: NSCollectionView {
    weak var keyDelegate: SmartCollectionViewKeyDelegate?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == 49 {
            keyDelegate?.smartCollectionViewDidPressSpace()
            return
        }
        if event.keyCode == 36 {
            keyDelegate?.smartCollectionViewDidPressReturn()
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            keyDelegate?.smartCollectionViewDidPressMoveToTrash()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "a" {
            keyDelegate?.smartCollectionViewDidPressCommandA()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "c" {
            keyDelegate?.smartCollectionViewDidPressCopy()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "v" {
            keyDelegate?.smartCollectionViewDidPressPaste()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            keyDelegate?.smartCollectionViewDidPressRefresh()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "i" {
            keyDelegate?.smartCollectionViewDidPressGetInfo()
            return
        }
        if flags.contains(.command),
           flags.contains(.shift),
           event.charactersIgnoringModifiers?.lowercased() == "n" {
            keyDelegate?.smartCollectionViewDidPressNewFolder()
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            keyDelegate?.smartCollectionViewDidDoubleClick()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        keyDelegate?.smartCollectionViewDidRightClick(event: event)
    }
}

final class SmartTableView: NSTableView {
    weak var keyDelegate: SmartCollectionViewKeyDelegate?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if event.keyCode == 49 {
            keyDelegate?.smartCollectionViewDidPressSpace()
            return
        }
        if event.keyCode == 36 {
            keyDelegate?.smartCollectionViewDidPressReturn()
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            keyDelegate?.smartCollectionViewDidPressMoveToTrash()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "a" {
            keyDelegate?.smartCollectionViewDidPressCommandA()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "c" {
            keyDelegate?.smartCollectionViewDidPressCopy()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "v" {
            keyDelegate?.smartCollectionViewDidPressPaste()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            keyDelegate?.smartCollectionViewDidPressRefresh()
            return
        }
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "i" {
            keyDelegate?.smartCollectionViewDidPressGetInfo()
            return
        }
        if flags.contains(.command),
           flags.contains(.shift),
           event.charactersIgnoringModifiers?.lowercased() == "n" {
            keyDelegate?.smartCollectionViewDidPressNewFolder()
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            keyDelegate?.smartCollectionViewDidDoubleClick()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        keyDelegate?.smartCollectionViewDidRightClick(event: event)
    }
}

final class FileGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSTableViewDataSource, NSTableViewDelegate, SmartCollectionViewKeyDelegate {
    var onOpenFolder: ((URL) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let directoryStore = DirectoryStore()
    private let fileOperations = FileOperations()
    private let fileInfoProvider = FileInfoProvider()
    private let visualIconProvider = VisualIconProvider()
    private let thumbnailPipeline = ThumbnailPipeline()
    private let quickLookController = QuickLookController()
    private let collectionView = SmartCollectionView()
    private let tableView = SmartTableView()
    private let collectionScrollView = NSScrollView()
    private let tableScrollView = NSScrollView()

    private var currentFolderURL: URL?
    private var allItems: [FileItem] = []
    private var displayedItems: [FileItem] = []
    private var filterText = ""
    private var iconSize: CGFloat = 96
    private var sortMode: FileSortMode = .name
    private var viewMode: FileViewMode = .icon

    override func loadView() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = itemSize(forIconSize: iconSize)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.keyDelegate = self
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColors = [.controlBackgroundColor]
        collectionView.register(FileItemCell.self, forItemWithIdentifier: FileItemCell.reuseIdentifier)

        collectionScrollView.hasVerticalScroller = true
        collectionScrollView.hasHorizontalScroller = false
        collectionScrollView.drawsBackground = true
        collectionScrollView.documentView = collectionView

        configureTableView()
        tableScrollView.hasVerticalScroller = true
        tableScrollView.hasHorizontalScroller = false
        tableScrollView.drawsBackground = true
        tableScrollView.documentView = tableView
        tableScrollView.isHidden = true

        let container = NSView()
        collectionScrollView.translatesAutoresizingMaskIntoConstraints = false
        tableScrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(collectionScrollView)
        container.addSubview(tableScrollView)
        NSLayoutConstraint.activate([
            collectionScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            collectionScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            tableScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            tableScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(firstResponderForCurrentViewMode())
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyDelegate = self
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.backgroundColor = .controlBackgroundColor
        tableView.rowHeight = 30
        tableView.intercellSpacing = NSSize(width: 0, height: 2)

        addTableColumn(identifier: "name", titleKey: "toolbar.sort.name", fallback: "Name", width: 320)
        addTableColumn(identifier: "type", titleKey: "toolbar.sort.type", fallback: "Type", width: 110)
        addTableColumn(identifier: "size", titleKey: "toolbar.sort.size", fallback: "Size", width: 100)
        addTableColumn(identifier: "modified", titleKey: "toolbar.sort.modified", fallback: "Modified", width: 160)
    }

    private func addTableColumn(identifier: String, titleKey: String, fallback: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = L10n.string(titleKey, fallback: fallback)
        column.width = width
        column.minWidth = 70
        column.resizingMask = .userResizingMask
        tableView.addTableColumn(column)
    }

    func load(folderURL: URL) {
        currentFolderURL = folderURL
        allItems = []
        displayedItems = []
        reloadViews()
        updateStatus(prefix: L10n.string("status.loading", fallback: "Loading"))

        DispatchQueue.global(qos: .userInitiated).async { [directoryStore] in
            let result = Result { try directoryStore.loadItems(in: folderURL) }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.currentFolderURL == folderURL else {
                    return
                }
                switch result {
                case .success(let items):
                    self.allItems = items
                    self.applyCurrentFilter()
                case .failure(let error):
                    self.allItems = []
                    self.displayedItems = []
                    self.reloadViews()
                    self.onStatusChange?(
                        L10n.format(
                            "error.cannotReadFolder",
                            fallback: "Cannot read folder: %@",
                            error.localizedDescription
                        )
                    )
                }
            }
        }
    }

    func refresh() {
        guard let currentFolderURL else {
            return
        }
        load(folderURL: currentFolderURL)
    }

    func setIconSize(_ newSize: CGFloat) {
        iconSize = min(max(newSize, 64), 180)
        if let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout {
            layout.itemSize = itemSize(forIconSize: iconSize)
            layout.invalidateLayout()
        }
        collectionView.reloadData()
    }

    func applyFilter(_ text: String) {
        filterText = text
        applyCurrentFilter()
    }

    func setSortMode(_ mode: FileSortMode) {
        sortMode = mode
        applyCurrentFilter()
    }

    func setViewMode(_ mode: FileViewMode) {
        let selectedURLSet = Set(selectedItems().map(\.url))
        viewMode = mode
        collectionScrollView.isHidden = mode != .icon
        tableScrollView.isHidden = mode != .list
        reloadViews()
        select(urls: selectedURLSet)
        view.window?.makeFirstResponder(firstResponderForCurrentViewMode())
        updateStatus()
    }

    func currentViewMode() -> FileViewMode {
        viewMode
    }

    func selectedURLs() -> [URL] {
        selectedItems().map(\.url)
    }

    func selectedItemCount() -> Int {
        selectedItems().count
    }

    func currentFolder() -> URL? {
        currentFolderURL
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        displayedItems.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateStatus()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard displayedItems.indices.contains(row),
              let tableColumn else {
            return nil
        }

        let item = displayedItems[row]
        switch tableColumn.identifier.rawValue {
        case "name":
            let cell = tableCell(identifier: "nameCell", includesIcon: true)
            cell.textField?.stringValue = item.name
            let icon = NSWorkspace.shared.icon(forFile: item.url.path)
            icon.size = NSSize(width: 18, height: 18)
            cell.imageView?.image = icon
            return cell
        case "type":
            let cell = tableCell(identifier: "typeCell", includesIcon: false)
            cell.textField?.stringValue = typeLabel(for: item)
            return cell
        case "size":
            let cell = tableCell(identifier: "sizeCell", includesIcon: false)
            if item.isDirectory {
                cell.textField?.stringValue = "--"
            } else if let byteSize = item.byteSize {
                cell.textField?.stringValue = byteFormatter.string(fromByteCount: byteSize)
            } else {
                cell.textField?.stringValue = "--"
            }
            return cell
        case "modified":
            let cell = tableCell(identifier: "modifiedCell", includesIcon: false)
            cell.textField?.stringValue = item.modifiedAt.map { listDateFormatter.string(from: $0) } ?? "--"
            return cell
        default:
            return nil
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = displayedItems[indexPath.item]
        let cell = collectionView.makeItem(withIdentifier: FileItemCell.reuseIdentifier, for: indexPath) as! FileItemCell
        let subtitle = subtitle(for: item)
        let fallbackIcon = visualIconProvider.icon(for: item, size: iconSize)

        if let cached = thumbnailPipeline.cachedThumbnail(for: item.url) {
            cell.configure(name: item.name, subtitle: subtitle, image: cached, representedURL: item.url, iconSize: iconSize)
        } else {
            cell.configure(name: item.name, subtitle: subtitle, image: fallbackIcon, representedURL: item.url, iconSize: iconSize)
        }

        if ThumbnailPipeline.isThumbnailEligible(item.category) {
            thumbnailPipeline.thumbnail(for: item, size: CGSize(width: iconSize, height: iconSize)) { [weak self, weak cell] image in
                guard let self,
                      let image,
                      cell?.representedObject as? URL == item.url else {
                    return
                }
                cell?.configure(name: item.name, subtitle: subtitle, image: image, representedURL: item.url, iconSize: self.iconSize)
            }
        }

        return cell
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        updateStatus()
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        updateStatus()
    }

    func smartCollectionViewDidPressSpace() {
        let urls = selectedItems().map(\.url)
        if !urls.isEmpty {
            quickLookController.preview(urls: urls)
        }
    }

    func smartCollectionViewDidPressCommandA() {
        switch viewMode {
        case .icon:
            let allIndexPaths = Set(displayedItems.indices.map { IndexPath(item: $0, section: 0) })
            collectionView.selectionIndexPaths = allIndexPaths
        case .list:
            tableView.selectRowIndexes(IndexSet(integersIn: 0..<displayedItems.count), byExtendingSelection: false)
        }
        updateStatus()
    }

    func smartCollectionViewDidDoubleClick() {
        openSelection()
    }

    func smartCollectionViewDidPressReturn() {
        renameSelection()
    }

    func smartCollectionViewDidPressCopy() {
        copySelectionToPasteboard()
    }

    func smartCollectionViewDidPressPaste() {
        pasteIntoCurrentFolder()
    }

    func smartCollectionViewDidPressRefresh() {
        refresh()
    }

    func smartCollectionViewDidPressNewFolder() {
        createFolder()
    }

    func smartCollectionViewDidPressMoveToTrash() {
        moveSelectedToTrash()
    }

    func smartCollectionViewDidPressGetInfo() {
        showInfoForSelection()
    }

    func smartCollectionViewDidRightClick(event: NSEvent) {
        switch viewMode {
        case .icon:
            let point = collectionView.convert(event.locationInWindow, from: nil)
            if let indexPath = collectionView.indexPathForItem(at: point),
               !collectionView.selectionIndexPaths.contains(indexPath) {
                collectionView.selectionIndexPaths = [indexPath]
                updateStatus()
            }

            contextMenu().popUp(positioning: nil, at: point, in: collectionView)
        case .list:
            let point = tableView.convert(event.locationInWindow, from: nil)
            let row = tableView.row(at: point)
            if row >= 0, !tableView.selectedRowIndexes.contains(row) {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                updateStatus()
            }

            contextMenu().popUp(positioning: nil, at: point, in: tableView)
        }
    }

    func createFolder() {
        guard let currentFolderURL else {
            return
        }

        let defaultName = L10n.string("dialog.newFolder.defaultName", fallback: "Untitled Folder")
        guard let folderName = promptForName(
            title: L10n.string("dialog.newFolder.title", fallback: "New Folder"),
            message: L10n.string("dialog.newFolder.message", fallback: "Enter a name for the new folder."),
            defaultValue: defaultName
        ) else {
            return
        }

        do {
            try fileOperations.createFolder(named: folderName, in: currentFolderURL)
            refresh()
        } catch {
            showOperationError(error)
        }
    }

    func renameSelection() {
        guard let item = selectedItems().first else {
            return
        }

        guard let newName = promptForName(
            title: L10n.string("dialog.rename.title", fallback: "Rename"),
            message: L10n.string("dialog.rename.message", fallback: "Enter a new name."),
            defaultValue: item.name
        ), newName != item.name else {
            return
        }

        do {
            try fileOperations.rename(item.url, to: newName)
            refresh()
        } catch {
            showOperationError(error)
        }
    }

    func moveSelectedToTrash() {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            return
        }

        NSWorkspace.shared.recycle(urls) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.showOperationError(error)
                }
                self?.refresh()
            }
        }
    }

    func copySelectionToPasteboard() {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
    }

    func copySelectedPathsToPasteboard() {
        let paths = selectedItems().map(\.url.path)
        guard !paths.isEmpty else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(paths.joined(separator: "\n"), forType: .string)
    }

    func compressSelection() {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty, let currentFolderURL else {
            return
        }

        updateStatus(prefix: L10n.string("status.compressing", fallback: "Compressing"))
        DispatchQueue.global(qos: .userInitiated).async { [fileOperations] in
            let result = Result { try fileOperations.compress(urls, in: currentFolderURL) }
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                switch result {
                case .success:
                    self.refresh()
                case .failure(let error):
                    self.showOperationError(error)
                    self.updateStatus()
                }
            }
        }
    }

    func showInfoForSelection() {
        let urls = selectedItems().map(\.url)
        guard let firstURL = urls.first else {
            return
        }

        do {
            let info = try fileInfoProvider.info(for: firstURL)
            showInfoAlert(info: info, selectedCount: urls.count)
        } catch {
            showOperationError(error)
        }
    }

    func pasteIntoCurrentFolder() {
        guard let currentFolderURL else {
            return
        }

        let objects = NSPasteboard.general.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [NSURL] ?? []
        let urls = objects.map { $0 as URL }.filter(\.isFileURL)

        guard !urls.isEmpty else {
            return
        }

        do {
            for url in urls {
                try fileOperations.copy(url, toDirectory: currentFolderURL)
            }
            refresh()
        } catch {
            showOperationError(error)
        }
    }

    func revealSelectionInFinder() {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            if let currentFolderURL {
                NSWorkspace.shared.activateFileViewerSelecting([currentFolderURL])
            }
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func openSelection() {
        guard let item = selectedItems().first else {
            return
        }

        if item.isDirectory {
            onOpenFolder?(item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    @objc private func openSelectedItemFromMenu() {
        openSelection()
    }

    @objc private func quickLookFromMenu() {
        quickLookSelection()
    }

    func quickLookSelection() {
        smartCollectionViewDidPressSpace()
    }

    @objc private func createFolderFromMenu() {
        createFolder()
    }

    @objc private func renameFromMenu() {
        renameSelection()
    }

    @objc private func moveToTrashFromMenu() {
        moveSelectedToTrash()
    }

    @objc private func copyFromMenu() {
        copySelectionToPasteboard()
    }

    @objc private func copyPathFromMenu() {
        copySelectedPathsToPasteboard()
    }

    @objc private func compressFromMenu() {
        compressSelection()
    }

    @objc private func getInfoFromMenu() {
        showInfoForSelection()
    }

    @objc private func pasteFromMenu() {
        pasteIntoCurrentFolder()
    }

    @objc private func revealInFinderFromMenu() {
        revealSelectionInFinder()
    }

    private func applyCurrentFilter() {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            displayedItems = sortedItems(allItems)
        } else {
            displayedItems = sortedItems(allItems.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            })
        }
        reloadViews()
        updateStatus()
    }

    private func sortedItems(_ items: [FileItem]) -> [FileItem] {
        items.sorted { left, right in
            if left.isDirectory != right.isDirectory {
                return left.isDirectory && !right.isDirectory
            }

            switch sortMode {
            case .name:
                return compareByName(left, right)
            case .type:
                let leftType = typeSortKey(left)
                let rightType = typeSortKey(right)
                if leftType != rightType {
                    return leftType.localizedStandardCompare(rightType) == .orderedAscending
                }
                return compareByName(left, right)
            case .size:
                if let leftSize = left.byteSize, let rightSize = right.byteSize, leftSize != rightSize {
                    return leftSize < rightSize
                }
                if left.byteSize != nil && right.byteSize == nil {
                    return true
                }
                if left.byteSize == nil && right.byteSize != nil {
                    return false
                }
                return compareByName(left, right)
            case .modified:
                if let leftDate = left.modifiedAt, let rightDate = right.modifiedAt, leftDate != rightDate {
                    return leftDate > rightDate
                }
                if left.modifiedAt != nil && right.modifiedAt == nil {
                    return true
                }
                if left.modifiedAt == nil && right.modifiedAt != nil {
                    return false
                }
                return compareByName(left, right)
            }
        }
    }

    private func compareByName(_ left: FileItem, _ right: FileItem) -> Bool {
        left.name.localizedStandardCompare(right.name) == .orderedAscending
    }

    private func typeSortKey(_ item: FileItem) -> String {
        if item.isDirectory {
            return "0-folder"
        }
        let ext = item.url.pathExtension.lowercased()
        if !ext.isEmpty {
            return ext
        }
        return categoryLabel(for: item)
    }

    private func selectedItems() -> [FileItem] {
        switch viewMode {
        case .icon:
            return collectionView.selectionIndexPaths
                .sorted { $0.item < $1.item }
                .compactMap { indexPath in
                    guard displayedItems.indices.contains(indexPath.item) else {
                        return nil
                    }
                    return displayedItems[indexPath.item]
                }
        case .list:
            return tableView.selectedRowIndexes
                .sorted()
                .compactMap { row in
                    guard displayedItems.indices.contains(row) else {
                        return nil
                    }
                    return displayedItems[row]
                }
        }
    }

    private func contextMenu() -> NSMenu {
        let menu = NSMenu()
        let hasSelection = !selectedItems().isEmpty

        menu.addItem(menuItem("menu.open", fallback: "Open", action: #selector(openSelectedItemFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.quickLook", fallback: "Quick Look", action: #selector(quickLookFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.getInfo", fallback: "Get Info", action: #selector(getInfoFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.newFolder", fallback: "New Folder", action: #selector(createFolderFromMenu), enabled: currentFolderURL != nil))
        menu.addItem(menuItem("menu.rename", fallback: "Rename", action: #selector(renameFromMenu), enabled: selectedItems().count == 1))
        menu.addItem(menuItem("menu.moveToTrash", fallback: "Move to Trash", action: #selector(moveToTrashFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.copy", fallback: "Copy", action: #selector(copyFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyPath", fallback: "Copy Path", action: #selector(copyPathFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.compress", fallback: "Compress", action: #selector(compressFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.paste", fallback: "Paste", action: #selector(pasteFromMenu), enabled: currentFolderURL != nil))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.revealInFinder", fallback: "Reveal in Finder", action: #selector(revealInFinderFromMenu), enabled: hasSelection || currentFolderURL != nil))

        return menu
    }

    private func menuItem(_ key: String, fallback: String, action: Selector, enabled: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: L10n.string(key, fallback: fallback), action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        return item
    }

    private func tableCell(identifier: String, includesIcon: Bool) -> NSTableCellView {
        let cellIdentifier = NSUserInterfaceItemIdentifier(identifier)
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView {
            return cell
        }

        let cell = NSTableCellView()
        cell.identifier = cellIdentifier

        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.font = FinderFonts.tableCell
        cell.textField = label
        cell.addSubview(label)

        if includesIcon {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.imageScaling = .scaleProportionallyDown
            cell.imageView = imageView
            cell.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 18),
                imageView.heightAnchor.constraint(equalToConstant: 18),

                label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        }

        return cell
    }

    private func reloadViews() {
        collectionView.reloadData()
        tableView.reloadData()
    }

    private func select(urls: Set<URL>) {
        collectionView.selectionIndexPaths = []
        tableView.deselectAll(nil)
        guard !urls.isEmpty else {
            return
        }

        let indexes = displayedItems.enumerated().compactMap { index, item in
            urls.contains(item.url) ? index : nil
        }

        switch viewMode {
        case .icon:
            collectionView.selectionIndexPaths = Set(indexes.map { IndexPath(item: $0, section: 0) })
        case .list:
            tableView.selectRowIndexes(IndexSet(indexes), byExtendingSelection: false)
        }
    }

    private func firstResponderForCurrentViewMode() -> NSResponder {
        switch viewMode {
        case .icon:
            return collectionView
        case .list:
            return tableView
        }
    }

    private func showInfoAlert(info: FileInfo, selectedCount: Int) {
        let alert = NSAlert()
        alert.messageText = selectedCount == 1
            ? info.name
            : L10n.format("dialog.info.multipleTitle", fallback: "%d Items", selectedCount)
        alert.informativeText = infoText(for: info, selectedCount: selectedCount)
        alert.addButton(withTitle: L10n.string("dialog.ok", fallback: "OK"))
        alert.runModal()
        view.window?.makeFirstResponder(firstResponderForCurrentViewMode())
    }

    private func infoText(for info: FileInfo, selectedCount: Int) -> String {
        var lines: [String] = []
        if selectedCount > 1 {
            lines.append(L10n.format("info.selection", fallback: "Selection: %d items", selectedCount))
        }

        lines.append("\(L10n.string("info.kind", fallback: "Kind")): \(kindLabel(for: info))")
        lines.append("\(L10n.string("info.size", fallback: "Size")): \(sizeLabel(for: info))")
        if !info.fileExtension.isEmpty {
            lines.append("\(L10n.string("info.extension", fallback: "Extension")): \(info.fileExtension)")
        }
        lines.append("\(L10n.string("info.where", fallback: "Where")): \(info.url.deletingLastPathComponent().path)")
        if let createdAt = info.createdAt {
            lines.append("\(L10n.string("info.created", fallback: "Created")): \(listDateFormatter.string(from: createdAt))")
        }
        if let modifiedAt = info.modifiedAt {
            lines.append("\(L10n.string("info.modified", fallback: "Modified")): \(listDateFormatter.string(from: modifiedAt))")
        }
        return lines.joined(separator: "\n")
    }

    private func kindLabel(for info: FileInfo) -> String {
        let item = FileItem(
            url: info.url,
            name: info.name,
            isDirectory: info.isDirectory,
            category: info.category,
            byteSize: info.byteSize,
            modifiedAt: info.modifiedAt
        )
        return typeLabel(for: item)
    }

    private func sizeLabel(for info: FileInfo) -> String {
        guard !info.isDirectory, let byteSize = info.byteSize else {
            return "--"
        }
        return byteFormatter.string(fromByteCount: byteSize)
    }

    private func promptForName(title: String, message: String, defaultValue: String) -> String? {
        guard let window = view.window else {
            return nil
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: L10n.string("dialog.ok", fallback: "OK"))
        alert.addButton(withTitle: L10n.string("dialog.cancel", fallback: "Cancel"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.stringValue = defaultValue
        alert.accessoryView = textField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            window.makeFirstResponder(collectionView)
            return nil
        }

        window.makeFirstResponder(collectionView)
        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func showOperationError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    private func itemSize(forIconSize iconSize: CGFloat) -> NSSize {
        NSSize(width: max(112, iconSize + 36), height: iconSize + 72)
    }

    private func subtitle(for item: FileItem) -> String {
        let label = typeLabel(for: item)
        guard !item.isDirectory, let byteSize = item.byteSize else {
            return label
        }
        return "\(label) - \(byteFormatter.string(fromByteCount: byteSize))"
    }

    private func typeLabel(for item: FileItem) -> String {
        let ext = item.url.pathExtension.uppercased()
        if !item.isDirectory && !ext.isEmpty {
            return ext
        }
        return categoryLabel(for: item)
    }

    private func categoryLabel(for item: FileItem) -> String {
        categoryLabel(for: item.category)
    }

    private func categoryLabel(for category: FileCategory) -> String {
        switch category {
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

    private var byteFormatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter
    }

    private var listDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private func updateStatus(prefix: String? = nil) {
        let selectedCount = selectedItems().count
        let itemText = L10n.itemCount(displayedItems.count)
        let selectionText = selectedCount > 0 ? L10n.selectedCount(selectedCount) : ""
        if let prefix {
            onStatusChange?("\(prefix) \(itemText)\(selectionText)")
        } else {
            onStatusChange?("\(itemText)\(selectionText)")
        }
    }
}
