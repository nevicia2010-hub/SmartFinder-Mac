import AppKit
import SmartFinderCore

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

final class FileGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, SmartCollectionViewKeyDelegate {
    var onOpenFolder: ((URL) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let directoryStore = DirectoryStore()
    private let fileOperations = FileOperations()
    private let iconProvider = IconProvider()
    private let thumbnailPipeline = ThumbnailPipeline()
    private let quickLookController = QuickLookController()
    private let collectionView = SmartCollectionView()

    private var currentFolderURL: URL?
    private var allItems: [FileItem] = []
    private var displayedItems: [FileItem] = []
    private var filterText = ""
    private var iconSize: CGFloat = 96

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

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.documentView = collectionView
        view = scrollView
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(collectionView)
    }

    func load(folderURL: URL) {
        currentFolderURL = folderURL
        allItems = []
        displayedItems = []
        collectionView.reloadData()
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
                    self.collectionView.reloadData()
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

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = displayedItems[indexPath.item]
        let cell = collectionView.makeItem(withIdentifier: FileItemCell.reuseIdentifier, for: indexPath) as! FileItemCell
        let fallbackIcon = iconProvider.icon(for: item)

        if let cached = thumbnailPipeline.cachedThumbnail(for: item.url) {
            cell.configure(name: item.name, image: cached, representedURL: item.url, iconSize: iconSize)
        } else {
            cell.configure(name: item.name, image: fallbackIcon, representedURL: item.url, iconSize: iconSize)
        }

        if ThumbnailPipeline.isThumbnailEligible(item.category) {
            thumbnailPipeline.thumbnail(for: item, size: CGSize(width: iconSize, height: iconSize)) { [weak cell] image in
                guard let image, cell?.representedObject as? URL == item.url else {
                    return
                }
                cell?.configure(name: item.name, image: image, representedURL: item.url, iconSize: self.iconSize)
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
        let allIndexPaths = Set(displayedItems.indices.map { IndexPath(item: $0, section: 0) })
        collectionView.selectionIndexPaths = allIndexPaths
        updateStatus()
    }

    func smartCollectionViewDidDoubleClick() {
        openSelectedItem()
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

    func smartCollectionViewDidRightClick(event: NSEvent) {
        let point = collectionView.convert(event.locationInWindow, from: nil)
        if let indexPath = collectionView.indexPathForItem(at: point),
           !collectionView.selectionIndexPaths.contains(indexPath) {
            collectionView.selectionIndexPaths = [indexPath]
            updateStatus()
        }

        contextMenu().popUp(positioning: nil, at: point, in: collectionView)
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

    private func openSelectedItem() {
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
        openSelectedItem()
    }

    @objc private func quickLookFromMenu() {
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

    @objc private func pasteFromMenu() {
        pasteIntoCurrentFolder()
    }

    @objc private func revealInFinderFromMenu() {
        revealSelectionInFinder()
    }

    private func applyCurrentFilter() {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            displayedItems = allItems
        } else {
            displayedItems = allItems.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }
        collectionView.reloadData()
        updateStatus()
    }

    private func selectedItems() -> [FileItem] {
        collectionView.selectionIndexPaths
            .sorted { $0.item < $1.item }
            .compactMap { indexPath in
                guard displayedItems.indices.contains(indexPath.item) else {
                    return nil
                }
                return displayedItems[indexPath.item]
            }
    }

    private func contextMenu() -> NSMenu {
        let menu = NSMenu()
        let hasSelection = !selectedItems().isEmpty

        menu.addItem(menuItem("menu.open", fallback: "Open", action: #selector(openSelectedItemFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.quickLook", fallback: "Quick Look", action: #selector(quickLookFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.newFolder", fallback: "New Folder", action: #selector(createFolderFromMenu), enabled: currentFolderURL != nil))
        menu.addItem(menuItem("menu.rename", fallback: "Rename", action: #selector(renameFromMenu), enabled: selectedItems().count == 1))
        menu.addItem(menuItem("menu.moveToTrash", fallback: "Move to Trash", action: #selector(moveToTrashFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.copy", fallback: "Copy", action: #selector(copyFromMenu), enabled: hasSelection))
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
        NSSize(width: max(104, iconSize + 32), height: iconSize + 54)
    }

    private func updateStatus(prefix: String? = nil) {
        let selectedCount = collectionView.selectionIndexPaths.count
        let itemText = L10n.itemCount(displayedItems.count)
        let selectionText = selectedCount > 0 ? L10n.selectedCount(selectedCount) : ""
        if let prefix {
            onStatusChange?("\(prefix) \(itemText)\(selectionText)")
        } else {
            onStatusChange?("\(itemText)\(selectionText)")
        }
    }
}
