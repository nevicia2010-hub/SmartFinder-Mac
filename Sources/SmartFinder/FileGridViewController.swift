import AppKit
import SmartFinderCore
import UniformTypeIdentifiers

enum FileSortMode: Equatable {
    case name
    case type
    case size
    case modified
}

enum FileSortDirection: Equatable {
    case ascending
    case descending
}

enum FileViewMode: Equatable {
    case icon
    case list
    case column
}

@MainActor
protocol SmartCollectionViewKeyDelegate: AnyObject {
    func smartCollectionViewDidPressShortcut(_ shortcut: FinderKeyboardShortcut)
    func smartCollectionViewDidPressSpace()
    func smartCollectionViewDidPressCommandA()
    func smartCollectionViewDidDoubleClick()
    func smartCollectionViewDidPressReturn()
    func smartCollectionViewDidPressCut()
    func smartCollectionViewDidPressCopy()
    func smartCollectionViewDidPressPaste()
    func smartCollectionViewDidPressRefresh()
    func smartCollectionViewDidPressNewFolder()
    func smartCollectionViewDidPressMoveToTrash()
    func smartCollectionViewDidPressGetInfo()
    func smartCollectionViewDidRightClick(event: NSEvent)
    func smartCollectionViewDidRequestInlineRename(indexPath: IndexPath, event: NSEvent)
    func smartTableView(_ tableView: NSTableView, didRequestInlineRenameForRow row: Int, event: NSEvent)
}

final class SmartCollectionView: NSCollectionView {
    weak var keyDelegate: SmartCollectionViewKeyDelegate?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if let shortcut = FinderKeyboardShortcut.resolve(event: event) {
            keyDelegate?.smartCollectionViewDidPressShortcut(shortcut)
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let preservedSelection = selectionToPreserveForDrag(event)
        let inlineRenameIndexPath = inlineRenameCandidateIndexPath(for: event)
        super.mouseDown(with: event)
        if let preservedSelection {
            selectionIndexPaths = preservedSelection
        }
        if let inlineRenameIndexPath {
            requestInlineRenameIfStillSelected(indexPath: inlineRenameIndexPath, event: event)
        }
        if event.clickCount == 2 {
            keyDelegate?.smartCollectionViewDidDoubleClick()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        keyDelegate?.smartCollectionViewDidRightClick(event: event)
    }

    @objc func copy(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCopy()
    }

    @objc func cut(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCut()
    }

    @objc func paste(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressPaste()
    }

    @objc override func selectAll(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCommandA()
    }

    private func selectionToPreserveForDrag(_ event: NSEvent) -> Set<IndexPath>? {
        guard event.clickCount == 1 else {
            return nil
        }
        let point = convert(event.locationInWindow, from: nil)
        guard let indexPath = indexPathForItem(at: point),
              SelectionDragPreservationPolicy.shouldPreserveSelection(
                  clickedItemIsSelected: selectionIndexPaths.contains(indexPath),
                  selectedItemCount: selectionIndexPaths.count,
                  usesSelectionModifier: event.usesSelectionModifier
              ) else {
            return nil
        }
        return selectionIndexPaths
    }

    private func inlineRenameCandidateIndexPath(for event: NSEvent) -> IndexPath? {
        guard event.clickCount == 1,
              !event.usesSelectionModifier,
              selectionIndexPaths.count == 1 else {
            return nil
        }

        let point = convert(event.locationInWindow, from: nil)
        guard let indexPath = indexPathForItem(at: point),
              selectionIndexPaths.contains(indexPath) else {
            return nil
        }
        return indexPath
    }

    private func requestInlineRenameIfStillSelected(indexPath: IndexPath, event: NSEvent) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self,
                  self.window?.firstResponder === self,
                  NSEvent.pressedMouseButtons == 0,
                  self.selectionIndexPaths == [indexPath] else {
                return
            }
            self.keyDelegate?.smartCollectionViewDidRequestInlineRename(indexPath: indexPath, event: event)
        }
    }
}

final class SmartTableView: NSTableView {
    weak var keyDelegate: SmartCollectionViewKeyDelegate?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if let shortcut = FinderKeyboardShortcut.resolve(event: event) {
            keyDelegate?.smartCollectionViewDidPressShortcut(shortcut)
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let preservedSelection = selectionToPreserveForDrag(event)
        let inlineRenameRow = inlineRenameCandidateRow(for: event)
        super.mouseDown(with: event)
        if let preservedSelection {
            selectRowIndexes(preservedSelection, byExtendingSelection: false)
        }
        if let inlineRenameRow {
            requestInlineRenameIfStillSelected(row: inlineRenameRow, event: event)
        }
        if event.clickCount == 2 {
            keyDelegate?.smartCollectionViewDidDoubleClick()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        keyDelegate?.smartCollectionViewDidRightClick(event: event)
    }

    @objc func copy(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCopy()
    }

    @objc func cut(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCut()
    }

    @objc func paste(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressPaste()
    }

    @objc override func selectAll(_ sender: Any?) {
        keyDelegate?.smartCollectionViewDidPressCommandA()
    }

    private func selectionToPreserveForDrag(_ event: NSEvent) -> IndexSet? {
        guard event.clickCount == 1 else {
            return nil
        }
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        guard row >= 0,
              SelectionDragPreservationPolicy.shouldPreserveSelection(
                  clickedItemIsSelected: selectedRowIndexes.contains(row),
                  selectedItemCount: selectedRowIndexes.count,
                  usesSelectionModifier: event.usesSelectionModifier
              ) else {
            return nil
        }
        return selectedRowIndexes
    }

    private func inlineRenameCandidateRow(for event: NSEvent) -> Int? {
        guard event.clickCount == 1,
              !event.usesSelectionModifier,
              selectedRowIndexes.count == 1 else {
            return nil
        }

        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        guard row >= 0,
              selectedRowIndexes.contains(row) else {
            return nil
        }
        return row
    }

    private func requestInlineRenameIfStillSelected(row: Int, event: NSEvent) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self,
                  self.window?.firstResponder === self,
                  NSEvent.pressedMouseButtons == 0,
                  self.selectedRowIndexes == IndexSet(integer: row) else {
                return
            }
            self.keyDelegate?.smartTableView(self, didRequestInlineRenameForRow: row, event: event)
        }
    }
}

private extension NSEvent {
    var usesSelectionModifier: Bool {
        modifierFlags.contains(.command) || modifierFlags.contains(.shift)
    }
}

final class FileGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, SmartCollectionViewKeyDelegate {
    var onOpenFolder: ((URL) -> Void)?
    var onColumnFolderChange: ((URL) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onSelectionChange: (([FileItem]) -> Void)?
    var onKeyboardShortcut: ((FinderKeyboardShortcut) -> Bool)?

    private let directoryStore = DirectoryStore()
    private let fileOperations = FileOperations()
    private let fileInfoProvider = FileInfoProvider()
    private let visualIconProvider = VisualIconProvider()
    private let thumbnailPipeline = ThumbnailPipeline()
    private let quickLookController = QuickLookController()
    private let fileClipboardSession: FileClipboardSession
    private let fileOperationExecutor: FileOperationExecutor
    private let collectionView = SmartCollectionView()
    private let tableView = SmartTableView()
    private let collectionScrollView = NSScrollView()
    private let tableScrollView = NSScrollView()
    private let columnScrollView = NSScrollView()
    private let columnDocumentView = NSView()

    private struct ColumnFolder {
        let url: URL
        let items: [FileItem]
        let selectedURL: URL?
    }

    private struct OpenWithApplication {
        let name: String
        let url: URL
    }

    private var currentFolderURL: URL?
    private var allItems: [FileItem] = []
    private var displayedItems: [FileItem] = []
    private var columnFolders: [ColumnFolder] = []
    private var columnTables: [SmartTableView] = []
    private var columnRootURL: URL?
    private var columnNavigationToken = UUID()
    private var directoryLoadToken = UUID()
    private var filterText = ""
    private var iconSize: CGFloat = 96
    private var sortMode: FileSortMode = .name
    private var sortDirection: FileSortDirection = .ascending
    private var viewMode: FileViewMode = .icon
    private var includesHiddenItems = false
    private var showsFileExtensions = true
    private var showsSelectionCheckboxes = false
    private var suppressColumnSelectionChange = false
    private var activeColumnIndexForCreation: Int?
    private var contextualCreationDirectoryURL: URL?
    private var folderSizeCancellationToken: FolderSizeCancellationToken?
    private var infoWindowControllers: [FileInfoWindowController] = []
    private weak var inlineRenameField: NSTextField?
    private var inlineRenameItem: FileItem?

    init(
        fileClipboardSession: FileClipboardSession = FileClipboardSession(),
        fileOperationExecutor: FileOperationExecutor = FileOperationExecutor()
    ) {
        self.fileClipboardSession = fileClipboardSession
        self.fileOperationExecutor = fileOperationExecutor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        configureFileDragging(for: collectionView)

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
        configureColumnView()

        let container = NSView()
        collectionScrollView.translatesAutoresizingMaskIntoConstraints = false
        tableScrollView.translatesAutoresizingMaskIntoConstraints = false
        columnScrollView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(collectionScrollView)
        container.addSubview(tableScrollView)
        container.addSubview(columnScrollView)
        NSLayoutConstraint.activate([
            collectionScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            collectionScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            tableScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            tableScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            columnScrollView.topAnchor.constraint(equalTo: container.topAnchor),
            columnScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            columnScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            columnScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
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
        configureFileDragging(for: tableView)

        addTableColumn(identifier: "selectionCheckbox", titleKey: "", fallback: "", width: 34)
        addTableColumn(identifier: "name", titleKey: "toolbar.sort.name", fallback: "Name", width: 320)
        addTableColumn(identifier: "type", titleKey: "toolbar.sort.type", fallback: "Type", width: 110)
        addTableColumn(identifier: "size", titleKey: "toolbar.sort.size", fallback: "Size", width: 100)
        addTableColumn(identifier: "modified", titleKey: "toolbar.sort.modified", fallback: "Modified", width: 160)
        updateTableCheckboxColumnVisibility()
    }

    private func configureColumnView() {
        columnScrollView.hasVerticalScroller = false
        columnScrollView.hasHorizontalScroller = true
        columnScrollView.drawsBackground = true
        columnScrollView.backgroundColor = .controlBackgroundColor
        columnScrollView.documentView = columnDocumentView
        columnScrollView.isHidden = true
    }

    private func configureFileDragging(for collectionView: NSCollectionView) {
        collectionView.registerForDraggedTypes([.fileURL])
        collectionView.setDraggingSourceOperationMask(fileDragSourceOperationMask(), forLocal: true)
        collectionView.setDraggingSourceOperationMask(fileDragSourceOperationMask(), forLocal: false)
    }

    private func configureFileDragging(for tableView: NSTableView) {
        tableView.registerForDraggedTypes([.fileURL])
        tableView.setDraggingSourceOperationMask(fileDragSourceOperationMask(), forLocal: true)
        tableView.setDraggingSourceOperationMask(fileDragSourceOperationMask(), forLocal: false)
    }

    private func fileDragSourceOperationMask() -> NSDragOperation {
        FileDragOperationPolicy.sourceOperations.reduce([]) { mask, operation in
            switch operation {
            case .copy:
                return mask.union(.copy)
            case .move:
                return mask.union(.move)
            }
        }
    }

    private func addTableColumn(identifier: String, titleKey: String, fallback: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
        column.title = titleKey.isEmpty ? fallback : L10n.string(titleKey, fallback: fallback)
        column.width = width
        column.minWidth = identifier == "selectionCheckbox" ? width : 70
        column.resizingMask = identifier == "selectionCheckbox" ? [] : .userResizingMask
        tableView.addTableColumn(column)
    }

    func load(folderURL: URL) {
        thumbnailPipeline.cancelAll()
        columnNavigationToken = UUID()
        let requestID = UUID()
        directoryLoadToken = requestID
        currentFolderURL = folderURL
        allItems = []
        displayedItems = []
        columnFolders = []
        reloadViews()
        updateStatus(prefix: L10n.string("status.loading", fallback: "Loading"))

        let options = DirectoryLoadOptions(includesHiddenItems: includesHiddenItems)
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                do {
                    return BackgroundOperationResult.success(
                        try DirectoryStore().loadItems(in: folderURL, options: options)
                    )
                } catch {
                    return BackgroundOperationResult<[FileItem]>.failure(error.localizedDescription)
                }
            }.value
            guard let self,
                  LatestRequestPolicy.shouldApply(
                    requestID: requestID,
                    currentRequestID: self.directoryLoadToken,
                    requestedURL: folderURL,
                    currentURL: self.currentFolderURL
                  ) else {
                return
            }
            switch result {
            case .success(let items):
                self.allItems = items
                self.applyCurrentFilter()
                if self.viewMode == .column {
                    self.rebuildColumnView(for: folderURL)
                }
            case .failure(let message):
                self.allItems = []
                self.displayedItems = []
                self.columnFolders = []
                self.reloadViews()
                self.onStatusChange?(
                    L10n.format(
                        "error.cannotReadFolder",
                        fallback: "Cannot read folder: %@",
                        message
                    )
                )
            }
        }
    }

    func refresh() {
        guard let currentFolderURL else {
            return
        }
        load(folderURL: currentFolderURL)
    }

    func setColumnRootURL(_ url: URL?) {
        columnRootURL = url?.standardizedFileURL
    }

    func setIconSize(_ newSize: CGFloat) {
        thumbnailPipeline.cancelAll()
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

    func setSortDirection(_ direction: FileSortDirection) {
        sortDirection = direction
        applyCurrentFilter()
    }

    func setViewMode(_ mode: FileViewMode) {
        let selectedURLSet = Set(selectedItems().map(\.url))
        let isLeavingColumnView = viewMode == .column && mode != .column
        if mode != .icon {
            thumbnailPipeline.cancelAll()
        }
        viewMode = mode
        if mode != .column {
            activeColumnIndexForCreation = nil
            contextualCreationDirectoryURL = nil
        }
        if isLeavingColumnView {
            clearColumnView()
        }
        collectionScrollView.isHidden = mode != .icon
        tableScrollView.isHidden = mode != .list
        columnScrollView.isHidden = mode != .column
        if mode == .column, let currentFolderURL {
            rebuildColumnView(for: currentFolderURL)
        }
        reloadViews()
        select(urls: selectedURLSet)
        view.window?.makeFirstResponder(firstResponderForCurrentViewMode())
        updateStatus()
    }

    func setIncludesHiddenItems(_ includesHiddenItems: Bool) {
        guard self.includesHiddenItems != includesHiddenItems else {
            return
        }
        self.includesHiddenItems = includesHiddenItems
        refresh()
    }

    func includesHiddenItemsEnabled() -> Bool {
        includesHiddenItems
    }

    func setShowsFileExtensions(_ showsFileExtensions: Bool) {
        guard self.showsFileExtensions != showsFileExtensions else {
            return
        }
        self.showsFileExtensions = showsFileExtensions
        reloadViews()
    }

    func showsFileExtensionsEnabled() -> Bool {
        showsFileExtensions
    }

    func setShowsSelectionCheckboxes(_ showsSelectionCheckboxes: Bool) {
        guard self.showsSelectionCheckboxes != showsSelectionCheckboxes else {
            return
        }
        self.showsSelectionCheckboxes = showsSelectionCheckboxes
        updateTableCheckboxColumnVisibility()
        reloadViews()
    }

    func showsSelectionCheckboxesEnabled() -> Bool {
        showsSelectionCheckboxes
    }

    func refreshAppearance() {
        collectionView.backgroundColors = [.controlBackgroundColor]
        collectionScrollView.backgroundColor = .controlBackgroundColor
        tableView.backgroundColor = .controlBackgroundColor
        tableScrollView.backgroundColor = .controlBackgroundColor
        columnScrollView.backgroundColor = .controlBackgroundColor

        for item in collectionView.visibleItems() {
            (item as? FileItemCell)?.refreshAppearance()
        }

        tableView.reloadData()
        for table in columnTables {
            table.backgroundColor = .controlBackgroundColor
            table.reloadData()
        }
        view.needsDisplay = true
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

    func selectedFolderCount() -> Int {
        selectedItems().filter(\.isDirectory).count
    }

    func hasSingleSelectedFolder() -> Bool {
        let items = selectedItems()
        return items.count == 1 && items[0].isDirectory
    }

    func isFolderSizeCalculationRunning() -> Bool {
        folderSizeCancellationToken != nil
    }

    func currentFolder() -> URL? {
        currentFolderURL
    }

    func refreshMetadata(for changedItemURLs: [URL]) {
        let affectedDirectories = FileMetadataRefreshPlan.affectedDirectoryURLs(changedItemURLs: changedItemURLs)
        guard !affectedDirectories.isEmpty else {
            return
        }

        switch FileMetadataRefreshPlan.refreshScope(
            isColumnView: viewMode == .column,
            currentFolderURL: currentFolderURL,
            affectedDirectoryURLs: affectedDirectories
        ) {
        case .none:
            break
        case .currentFolder, .visibleColumns:
            refreshItemMetadata(for: changedItemURLs)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === self.tableView {
            return displayedItems.count
        }
        guard let columnIndex = columnIndex(for: tableView) else {
            return 0
        }
        return itemsForColumn(at: columnIndex).count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let changedTable = notification.object as? NSTableView else {
            updateStatus()
            return
        }

        if changedTable === tableView {
            updateVisibleTableCheckboxStates()
            updateStatus()
            return
        }

        guard let columnIndex = columnIndex(for: changedTable),
              !suppressColumnSelectionChange else {
            updateStatus()
            return
        }
        handleColumnSelection(in: changedTable, columnIndex: columnIndex)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView !== self.tableView {
            return columnTableCell(for: tableView, row: row)
        }

        guard displayedItems.indices.contains(row),
              let tableColumn else {
            return nil
        }

        let item = displayedItems[row]
        switch tableColumn.identifier.rawValue {
        case "selectionCheckbox":
            let button = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleSelectionCheckboxFromTable(_:)))
            button.tag = row
            button.state = tableView.selectedRowIndexes.contains(row) ? .on : .off
            button.alignment = .center
            return button
        case "name":
            let cell = tableCell(identifier: "nameCell", includesIcon: true)
            cell.textField?.stringValue = displayName(for: item)
            cell.imageView?.image = visualIconProvider.icon(for: item, size: 18)
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

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let items: [FileItem]
        if tableView === self.tableView {
            items = displayedItems
        } else if let columnIndex = columnIndex(for: tableView) {
            items = itemsForColumn(at: columnIndex)
        } else {
            return nil
        }

        guard items.indices.contains(row) else {
            return nil
        }
        return items[row].url as NSURL
    }

    func tableView(
        _ tableView: NSTableView,
        draggingSession session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        [.copy, .move]
    }

    func tableView(
        _ tableView: NSTableView,
        validateDrop info: NSDraggingInfo,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableView.DropOperation
    ) -> NSDragOperation {
        if let hit = tableHitItem(for: tableView, draggingInfo: info),
           hit.item.isDirectory {
            tableView.setDropRow(hit.row, dropOperation: .on)
        }

        guard let targetURL = dropTargetDirectory(for: tableView, draggingInfo: info, row: row, dropOperation: dropOperation),
              canAcceptDrop(info, toDirectory: targetURL),
              let operation = transferOperation(
                for: info,
                sourceURLs: fileURLs(from: info.draggingPasteboard),
                targetDirectoryURL: targetURL
              ) else {
            return []
        }
        return FileDragOperationResolver.dragOperation(operation)
    }

    func tableView(
        _ tableView: NSTableView,
        acceptDrop info: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> Bool {
        guard let targetURL = dropTargetDirectory(for: tableView, draggingInfo: info, row: row, dropOperation: dropOperation) else {
            return false
        }
        return performDrop(info, toDirectory: targetURL)
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        guard displayedItems.indices.contains(indexPath.item) else {
            return nil
        }
        return displayedItems[indexPath.item].url as NSURL
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        draggingSession session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        [.copy, .move]
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        validateDrop draggingInfo: NSDraggingInfo,
        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
    ) -> NSDragOperation {
        if let hit = collectionHitItem(for: collectionView, draggingInfo: draggingInfo),
           hit.item.isDirectory {
            proposedDropIndexPath.pointee = hit.indexPath as NSIndexPath
            proposedDropOperation.pointee = .on
        }

        guard let targetURL = collectionDropTargetDirectory(
            for: collectionView,
            draggingInfo: draggingInfo,
            proposedIndexPath: proposedDropIndexPath.pointee as IndexPath?,
            dropOperation: proposedDropOperation.pointee
        ), canAcceptDrop(draggingInfo, toDirectory: targetURL),
           let operation = transferOperation(
            for: draggingInfo,
            sourceURLs: fileURLs(from: draggingInfo.draggingPasteboard),
            targetDirectoryURL: targetURL
           ) else {
            return []
        }
        return FileDragOperationResolver.dragOperation(operation)
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        acceptDrop draggingInfo: NSDraggingInfo,
        indexPath: IndexPath,
        dropOperation: NSCollectionView.DropOperation
    ) -> Bool {
        guard let targetURL = collectionDropTargetDirectory(
            for: collectionView,
            draggingInfo: draggingInfo,
            proposedIndexPath: indexPath,
            dropOperation: dropOperation
        ) else {
            return false
        }
        return performDrop(draggingInfo, toDirectory: targetURL)
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = displayedItems[indexPath.item]
        let cell = collectionView.makeItem(withIdentifier: FileItemCell.reuseIdentifier, for: indexPath) as! FileItemCell
        let displayName = displayName(for: item)
        let subtitle = subtitle(for: item)
        let fallbackIcon = visualIconProvider.icon(for: item, size: iconSize)
        let thumbnailSize = CGSize(width: iconSize, height: iconSize)
        let thumbnailScale = view.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2

        if let cached = thumbnailPipeline.cachedThumbnail(
            for: item.url,
            size: thumbnailSize,
            scale: thumbnailScale
        ) {
            cell.configure(
                name: displayName,
                subtitle: subtitle,
                image: cached,
                representedURL: item.url,
                iconSize: iconSize,
                finderLabelNumber: item.finderLabelNumber,
                showsSelectionCheckbox: showsSelectionCheckboxes,
                onCheckboxToggle: { [weak self] url in
                    self?.toggleSelection(for: url)
                }
            )
        } else {
            cell.configure(
                name: displayName,
                subtitle: subtitle,
                image: fallbackIcon,
                representedURL: item.url,
                iconSize: iconSize,
                finderLabelNumber: item.finderLabelNumber,
                showsSelectionCheckbox: showsSelectionCheckboxes,
                onCheckboxToggle: { [weak self] url in
                    self?.toggleSelection(for: url)
                }
            )
        }

        if ThumbnailPipeline.isThumbnailEligible(item.category) {
            thumbnailPipeline.thumbnail(
                for: item,
                size: thumbnailSize,
                scale: thumbnailScale
            ) { [weak self, weak cell] image in
                guard let self,
                      let image,
                      cell?.representedObject as? URL == item.url else {
                    return
                }
                cell?.configure(
                    name: displayName,
                    subtitle: subtitle,
                    image: image,
                    representedURL: item.url,
                    iconSize: self.iconSize,
                    finderLabelNumber: item.finderLabelNumber,
                    showsSelectionCheckbox: self.showsSelectionCheckboxes,
                    onCheckboxToggle: { [weak self] url in
                        self?.toggleSelection(for: url)
                    }
                )
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

    func smartCollectionViewDidPressShortcut(_ shortcut: FinderKeyboardShortcut) {
        switch shortcut {
        case .quickLook:
            smartCollectionViewDidPressSpace()
        case .renameSelection:
            smartCollectionViewDidPressReturn()
        case .moveToTrash:
            smartCollectionViewDidPressMoveToTrash()
        case .selectAll:
            smartCollectionViewDidPressCommandA()
        case .cut:
            smartCollectionViewDidPressCut()
        case .copy:
            smartCollectionViewDidPressCopy()
        case .paste:
            smartCollectionViewDidPressPaste()
        case .refresh:
            smartCollectionViewDidPressRefresh()
        case .getInfo:
            smartCollectionViewDidPressGetInfo()
        case .newFolder:
            smartCollectionViewDidPressNewFolder()
        case .openSelection:
            openSelection()
        case .copyPath:
            copySelectedPathsToPasteboard()
        case .goBack, .goForward, .goUp, .showIconView, .showListView, .showColumnView, .focusSearch:
            _ = onKeyboardShortcut?(shortcut)
        }
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
        case .column:
            guard let lastTable = columnTables.last,
                  let columnIndex = columnIndex(for: lastTable) else {
                break
            }
            lastTable.selectRowIndexes(
                IndexSet(integersIn: 0..<itemsForColumn(at: columnIndex).count),
                byExtendingSelection: false
            )
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

    func smartCollectionViewDidPressCut() {
        cutSelectionToPasteboard()
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
            contextualCreationDirectoryURL = nil
            activeColumnIndexForCreation = nil
            let point = collectionView.convert(event.locationInWindow, from: nil)
            if let indexPath = collectionView.indexPathForItem(at: point),
               !collectionView.selectionIndexPaths.contains(indexPath) {
                collectionView.selectionIndexPaths = [indexPath]
                updateStatus()
            }

            contextMenu().popUp(positioning: nil, at: point, in: collectionView)
        case .list:
            contextualCreationDirectoryURL = nil
            activeColumnIndexForCreation = nil
            let point = tableView.convert(event.locationInWindow, from: nil)
            let row = tableView.row(at: point)
            if row >= 0, !tableView.selectedRowIndexes.contains(row) {
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                updateStatus()
            }

            contextMenu().popUp(positioning: nil, at: point, in: tableView)
        case .column:
            guard let target = columnTable(atWindowPoint: event.locationInWindow) else {
                return
            }
            activeColumnIndexForCreation = columnIndex(for: target)
            contextualCreationDirectoryURL = activeColumnDirectoryURL()

            let point = target.convert(event.locationInWindow, from: nil)
            let row = target.row(at: point)
            if row >= 0, !target.selectedRowIndexes.contains(row) {
                target.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                updateStatus()
            }

            contextMenu().popUp(positioning: nil, at: point, in: target)
        }
    }

    func smartCollectionViewDidRequestInlineRename(indexPath: IndexPath, event: NSEvent) {
        guard displayedItems.indices.contains(indexPath.item),
              selectedItems().count == 1,
              let cell = collectionView.item(at: indexPath) as? FileItemCell,
              cell.containsTitle(atWindowPoint: event.locationInWindow) else {
            return
        }

        beginInlineRename(
            item: displayedItems[indexPath.item],
            in: collectionView,
            frame: cell.titleEditingFrame(in: collectionView),
            alignment: .center,
            font: FinderFonts.iconTitle(forIconSize: iconSize)
        )
    }

    func smartTableView(_ tableView: NSTableView, didRequestInlineRenameForRow row: Int, event: NSEvent) {
        guard selectedItems().count == 1,
              let item = item(in: tableView, row: row),
              let textField = nameTextField(in: tableView, row: row, event: event) else {
            return
        }

        beginInlineRename(
            item: item,
            in: tableView,
            frame: textField.convert(textField.bounds.insetBy(dx: -4, dy: -2), to: tableView),
            alignment: .left,
            font: FinderFonts.tableCell
        )
    }

    func createFolder() {
        guard let targetDirectoryURL = creationTargetDirectoryURL() else {
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
            try fileOperations.createFolder(named: folderName, in: targetDirectoryURL)
            refreshAfterCreatingItem(in: targetDirectoryURL)
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
            defaultValue: item.name,
            selectedRange: FileRenameInputPolicy.editableNameRange(forName: item.name, isDirectory: item.isDirectory)
        ), newName != item.name else {
            return
        }

        rename(item, to: newName)
    }

    func moveSelectedToTrash() {
        let urls = PhotoCompanionFilePolicy.expandedSourceURLs(for: selectedItems().map(\.url))
        guard !urls.isEmpty else {
            return
        }
        let folderToLoadAfterRemoval = FileRemovalNavigationPolicy.folderToLoadAfterRemoval(
            removedURLs: urls,
            currentFolderURL: currentFolderURL
        )

        NSWorkspace.shared.recycle(urls) { [weak self] _, error in
            let errorMessage = error?.localizedDescription
            Task { @MainActor [weak self] in
                if let errorMessage {
                    self?.showOperationError(FileOperationExecutionError(message: errorMessage))
                    self?.refresh()
                    return
                }
                if let folderToLoadAfterRemoval {
                    self?.load(folderURL: folderToLoadAfterRemoval)
                } else {
                    self?.refresh()
                }
            }
        }
    }

    func copySelectionToPasteboard() {
        writeSelectedFileURLsToPasteboard(operation: .copy)
    }

    func cutSelectionToPasteboard() {
        writeSelectedFileURLsToPasteboard(operation: .move)
    }

    private func writeSelectedFileURLsToPasteboard(operation: FileTransferOperation) {
        let urls = PhotoCompanionFilePolicy.expandedSourceURLs(for: selectedItems().map(\.url))
        guard !urls.isEmpty else {
            return
        }

        let pasteboard = NSPasteboard.general
        let marker: String
        switch operation {
        case .copy:
            marker = FileClipboardPolicy.copyMarker
            fileClipboardSession.clear()
        case .move:
            marker = FileClipboardPolicy.moveMarker(token: UUID().uuidString)
        }
        pasteboard.clearContents()
        let wroteURLs = pasteboard.writeObjects(urls as [NSURL])
        let wroteMarker = pasteboard.setString(
            marker,
            forType: NSPasteboard.PasteboardType(FileClipboardPolicy.operationPasteboardType)
        )
        guard wroteURLs, wroteMarker else {
            fileClipboardSession.clear()
            return
        }
        if operation == .move {
            fileClipboardSession.recordMove(
                marker: marker,
                pasteboardChangeCount: pasteboard.changeCount,
                sourceURLs: urls
            )
        }
    }

    func copySelectedPathsToPasteboard() {
        copySelectedPathsToPasteboard(format: .fullPath)
    }

    func copySelectedParentPathsToPasteboard() {
        copySelectedPathsToPasteboard(format: .parentDirectory)
    }

    func copySelectedShellPathsToPasteboard() {
        copySelectedPathsToPasteboard(format: .shellEscapedPath)
    }

    private func copySelectedPathsToPasteboard(format: CopyPathFormat) {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(CopyPathFormatter.joinedString(for: urls, format: format), forType: .string)
    }

    func copySelectedNamesToPasteboard() {
        let names = SelectionSummary.fileNames(for: selectedItems())
        guard !names.isEmpty else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(names.joined(separator: "\n"), forType: .string)
    }

    func copySelection(toDirectory directoryURL: URL) {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            return
        }
        transfer(urls, toDirectory: directoryURL, operation: .copy)
    }

    func moveSelection(toDirectory directoryURL: URL) {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty else {
            return
        }
        transfer(urls, toDirectory: directoryURL, operation: .move)
    }

    @discardableResult
    func transfer(
        _ urls: [URL],
        toDirectory directoryURL: URL,
        operation: FileTransferOperation,
        completion: ((Bool) -> Void)? = nil
    ) -> Bool {
        let targetURL = directoryURL.standardizedFileURL
        let sourceURLs = FileTransferPlan.uniqueSourceURLs(urls).filter { sourceURL in
            operation != .move || sourceURL.deletingLastPathComponent().standardizedFileURL != targetURL
        }
        guard !sourceURLs.isEmpty else {
            completion?(false)
            return false
        }

        let affectedDirectories = FileTransferPlan.affectedDirectoryURLs(
            sourceURLs: sourceURLs,
            targetDirectoryURL: targetURL
        )
        let executor = fileOperationExecutor
        Task { [weak self] in
            let result = await executor.transfer(sourceURLs, toDirectory: targetURL, operation: operation)
            guard let self else {
                return
            }
            self.refreshAfterTransfer(affectedDirectories: affectedDirectories)
            switch result {
            case .success:
                completion?(true)
            case .failure(let message):
                self.showOperationError(FileOperationExecutionError(message: message))
                completion?(false)
            }
        }
        return true
    }

    func createFile(fromTemplate kind: FileTemplateKind) {
        guard let targetDirectoryURL = creationTargetDirectoryURL() else {
            return
        }

        do {
            try fileOperations.createFile(fromTemplate: kind, in: targetDirectoryURL)
            refreshAfterCreatingItem(in: targetDirectoryURL)
        } catch {
            showOperationError(error)
        }
    }

    func createTextFile(named name: String, contents: String = "") {
        guard let targetDirectoryURL = creationTargetDirectoryURL() else {
            return
        }

        do {
            try fileOperations.createFile(named: name, contents: contents, in: targetDirectoryURL)
            refreshAfterCreatingItem(in: targetDirectoryURL)
        } catch {
            showOperationError(error)
        }
    }

    private func creationTargetDirectoryURL() -> URL? {
        FileCreationTargetPolicy.targetDirectory(
            currentFolderURL: activeColumnDirectoryURL() ?? currentFolderURL,
            contextualFolderURL: contextualCreationDirectoryURL
        )
    }

    private func activeColumnDirectoryURL() -> URL? {
        guard viewMode == .column,
              let activeColumnIndexForCreation,
              columnFolders.indices.contains(activeColumnIndexForCreation) else {
            return nil
        }
        return columnFolders[activeColumnIndexForCreation].url
    }

    private func refreshAfterCreatingItem(in directoryURL: URL) {
        contextualCreationDirectoryURL = nil
        if viewMode == .column {
            refreshAffectedColumnFolders([directoryURL])
        } else {
            refresh()
        }
    }

    private func refreshAfterRename(originalURL: URL, renamedURL: URL, itemWasDirectory: Bool) {
        let folderToLoad = FileRenameNavigationPolicy.folderToLoadAfterRename(
            originalURL: originalURL,
            renamedURL: renamedURL,
            renamedItemIsDirectory: itemWasDirectory,
            currentFolderURL: currentFolderURL
        )

        guard let folderToLoad else {
            refresh()
            return
        }

        if folderToLoad.standardizedFileURL == currentFolderURL?.standardizedFileURL {
            refresh()
        } else {
            load(folderURL: folderToLoad)
        }
    }

    private func rename(_ item: FileItem, to newName: String) {
        do {
            let renamedURL = try fileOperations.renamePhotoCompanionGroup(item.url, to: newName).first
                ?? fileOperations.rename(item.url, to: newName)
            refreshAfterRename(originalURL: item.url, renamedURL: renamedURL, itemWasDirectory: item.isDirectory)
        } catch {
            showOperationError(error)
        }
    }

    private func refreshAfterTransfer(affectedDirectories: [URL]) {
        switch FileTransferPlan.refreshScope(
            isColumnView: viewMode == .column,
            currentFolderURL: currentFolderURL,
            affectedDirectoryURLs: affectedDirectories
        ) {
        case .none:
            break
        case .currentFolder:
            refresh()
        case .visibleColumns:
            refreshAffectedColumnFolders(affectedDirectories)
        }
    }

    private func refreshAffectedColumnFolders(_ affectedDirectories: [URL]) {
        let affectedPaths = Set(affectedDirectories.map { $0.standardizedFileURL.path })
        guard !affectedPaths.isEmpty else {
            return
        }

        let options = DirectoryLoadOptions(includesHiddenItems: includesHiddenItems)
        var reloadedIndexes: [Int] = []

        for index in columnFolders.indices {
            let folder = columnFolders[index]
            let folderURL = folder.url.standardizedFileURL
            guard affectedPaths.contains(folderURL.path) else {
                continue
            }

            let items = (try? directoryStore.loadItems(in: folder.url, options: options)) ?? []
            let visibleItems: [FileItem]
            if folderURL == currentFolderURL?.standardizedFileURL {
                allItems = items
                updateDisplayedItems()
                visibleItems = displayedItems
            } else {
                visibleItems = sortedItems(items)
            }

            columnFolders[index] = ColumnFolder(
                url: folder.url,
                items: visibleItems,
                selectedURL: folder.selectedURL
            )
            reloadedIndexes.append(index)
        }

        for index in reloadedIndexes where columnTables.indices.contains(index) {
            updateColumnTableHeight(at: index)
            columnTables[index].reloadData()
        }

        selectColumnPathRows()
        updateStatus()
    }

    private func refreshItemMetadata(for urls: [URL]) {
        let labelNumbersByPath = Dictionary(
            uniqueKeysWithValues: FileTransferPlan.uniqueSourceURLs(urls).map { url in
                (url.standardizedFileURL.path, finderLabelNumber(for: url))
            }
        )
        guard !labelNumbersByPath.isEmpty else {
            return
        }

        allItems = allItems.map { item in
            itemWithUpdatedFinderLabelNumber(item, labelNumbersByPath: labelNumbersByPath)
        }
        displayedItems = displayedItems.map { item in
            itemWithUpdatedFinderLabelNumber(item, labelNumbersByPath: labelNumbersByPath)
        }
        columnFolders = columnFolders.map { folder in
            ColumnFolder(
                url: folder.url,
                items: folder.items.map { item in
                    itemWithUpdatedFinderLabelNumber(item, labelNumbersByPath: labelNumbersByPath)
                },
                selectedURL: folder.selectedURL
            )
        }

        reloadRowsForMetadataChanges(paths: Set(labelNumbersByPath.keys))
        updateStatus()
    }

    private func finderLabelNumber(for url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.labelNumberKey]).labelNumber) ?? 0
    }

    private func itemWithUpdatedFinderLabelNumber(
        _ item: FileItem,
        labelNumbersByPath: [String: Int]
    ) -> FileItem {
        guard let labelNumber = labelNumbersByPath[item.url.standardizedFileURL.path] else {
            return item
        }
        return FileItem(
            url: item.url,
            name: item.name,
            isDirectory: item.isDirectory,
            category: item.category,
            byteSize: item.byteSize,
            modifiedAt: item.modifiedAt,
            finderLabelNumber: labelNumber
        )
    }

    private func reloadRowsForMetadataChanges(paths: Set<String>) {
        switch viewMode {
        case .icon:
            let indexPaths = displayedItems.enumerated().compactMap { index, item in
                paths.contains(item.url.standardizedFileURL.path) ? IndexPath(item: index, section: 0) : nil
            }
            if !indexPaths.isEmpty {
                collectionView.reloadItems(at: Set(indexPaths))
            }
        case .list:
            let rowIndexes = displayedItems.enumerated().compactMap { index, item in
                paths.contains(item.url.standardizedFileURL.path) ? index : nil
            }
            if !rowIndexes.isEmpty {
                tableView.reloadData(
                    forRowIndexes: IndexSet(rowIndexes),
                    columnIndexes: IndexSet(integersIn: 0..<tableView.numberOfColumns)
                )
            }
        case .column:
            for (columnIndex, table) in columnTables.enumerated() {
                let rowIndexes = itemsForColumn(at: columnIndex).enumerated().compactMap { index, item in
                    paths.contains(item.url.standardizedFileURL.path) ? index : nil
                }
                if !rowIndexes.isEmpty {
                    table.reloadData(
                        forRowIndexes: IndexSet(rowIndexes),
                        columnIndexes: IndexSet(integersIn: 0..<table.numberOfColumns)
                    )
                }
            }
        }
    }

    private func updateColumnTableHeight(at index: Int) {
        guard columnTables.indices.contains(index) else {
            return
        }

        let table = columnTables[index]
        let viewportHeight = table.enclosingScrollView?.contentSize.height ?? table.frame.height
        let tableHeight = max(viewportHeight, CGFloat(itemsForColumn(at: index).count) * 33)
        table.setFrameSize(NSSize(width: table.frame.width, height: tableHeight))
    }

    private func performDrop(_ info: NSDraggingInfo, toDirectory directoryURL: URL) -> Bool {
        let urls = fileURLs(from: info.draggingPasteboard)
        guard !urls.isEmpty,
              let operation = transferOperation(
                for: info,
                sourceURLs: urls,
                targetDirectoryURL: directoryURL
              ) else {
            return false
        }
        return transfer(urls, toDirectory: directoryURL, operation: operation)
    }

    private func canAcceptDrop(_ info: NSDraggingInfo, toDirectory directoryURL: URL) -> Bool {
        let urls = fileURLs(from: info.draggingPasteboard)
        guard !urls.isEmpty else {
            return false
        }

        let targetPath = directoryURL.resolvingSymlinksInPath().standardizedFileURL.path
        if urls.contains(where: { sourceURL in
            let sourcePath = sourceURL.resolvingSymlinksInPath().standardizedFileURL.path
            return targetPath == sourcePath || targetPath.hasPrefix(sourcePath + "/")
        }) {
            return false
        }

        guard let operation = transferOperation(
            for: info,
            sourceURLs: urls,
            targetDirectoryURL: directoryURL
        ) else {
            return false
        }

        if operation == .move,
           urls.allSatisfy({
               $0.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL.path == targetPath
           }) {
            return false
        }

        return true
    }

    private func transferOperation(
        for info: NSDraggingInfo,
        sourceURLs: [URL],
        targetDirectoryURL: URL
    ) -> FileTransferOperation? {
        FileDragOperationResolver.operation(
            for: info,
            sourceURLs: sourceURLs,
            targetDirectoryURL: targetDirectoryURL
        )
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [NSURL] ?? []
        return objects.map { $0 as URL }.filter(\.isFileURL)
    }

    private func collectionDropTargetDirectory(
        for collectionView: NSCollectionView,
        draggingInfo: NSDraggingInfo,
        proposedIndexPath: IndexPath?,
        dropOperation: NSCollectionView.DropOperation
    ) -> URL? {
        let hitItem = collectionHitItem(for: collectionView, draggingInfo: draggingInfo)?.item
            ?? collectionProposedDropItem(indexPath: proposedIndexPath, dropOperation: dropOperation)
        return FileDropTargetPolicy.targetDirectory(
            defaultDirectoryURL: currentFolderURL,
            hitItemURL: hitItem?.url,
            hitItemIsDirectory: hitItem?.isDirectory ?? false
        )
    }

    private func collectionHitItem(
        for collectionView: NSCollectionView,
        draggingInfo: NSDraggingInfo
    ) -> (indexPath: IndexPath, item: FileItem)? {
        let point = collectionView.convert(draggingInfo.draggingLocation, from: nil)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              displayedItems.indices.contains(indexPath.item) else {
            return nil
        }
        return (indexPath, displayedItems[indexPath.item])
    }

    private func collectionProposedDropItem(
        indexPath: IndexPath?,
        dropOperation: NSCollectionView.DropOperation
    ) -> FileItem? {
        guard dropOperation == .on,
              let indexPath,
              displayedItems.indices.contains(indexPath.item) else {
            return nil
        }
        return displayedItems[indexPath.item]
    }

    private func dropTargetDirectory(
        for tableView: NSTableView,
        draggingInfo: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> URL? {
        let items: [FileItem]
        let defaultFolder: URL?

        if tableView === self.tableView {
            items = displayedItems
            defaultFolder = currentFolderURL
        } else if let columnIndex = columnIndex(for: tableView) {
            items = itemsForColumn(at: columnIndex)
            defaultFolder = columnFolders.indices.contains(columnIndex) ? columnFolders[columnIndex].url : currentFolderURL
        } else {
            return currentFolderURL
        }

        let hitItem = tableHitItem(for: tableView, draggingInfo: draggingInfo)?.item
            ?? tableProposedDropItem(items: items, row: row, dropOperation: dropOperation)
        return FileDropTargetPolicy.targetDirectory(
            defaultDirectoryURL: defaultFolder,
            hitItemURL: hitItem?.url,
            hitItemIsDirectory: hitItem?.isDirectory ?? false
        )
    }

    private func tableHitItem(
        for tableView: NSTableView,
        draggingInfo: NSDraggingInfo
    ) -> (row: Int, item: FileItem)? {
        let point = tableView.convert(draggingInfo.draggingLocation, from: nil)
        let row = tableView.row(at: point)
        guard row >= 0 else {
            return nil
        }

        let items: [FileItem]
        if tableView === self.tableView {
            items = displayedItems
        } else if let columnIndex = columnIndex(for: tableView) {
            items = itemsForColumn(at: columnIndex)
        } else {
            return nil
        }

        guard items.indices.contains(row) else {
            return nil
        }
        return (row, items[row])
    }

    private func tableProposedDropItem(
        items: [FileItem],
        row: Int,
        dropOperation: NSTableView.DropOperation
    ) -> FileItem? {
        guard dropOperation == .on,
              items.indices.contains(row) else {
            return nil
        }
        return items[row]
    }

    func compressSelection() {
        let urls = selectedItems().map(\.url)
        guard !urls.isEmpty, let currentFolderURL else {
            return
        }

        updateStatus(prefix: L10n.string("status.compressing", fallback: "Compressing"))
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                do {
                    return BackgroundOperationResult.success(
                        try FileOperations().compress(urls, in: currentFolderURL)
                    )
                } catch {
                    return BackgroundOperationResult<URL>.failure(error.localizedDescription)
                }
            }.value
            guard let self else {
                return
            }
            switch result {
            case .success:
                self.refresh()
            case .failure(let message):
                self.showOperationError(FileOperationExecutionError(message: message))
                self.updateStatus()
            }
        }
    }

    func calculateSelectedFolderSize() {
        guard let item = selectedItems().first,
              selectedItems().count == 1,
              item.isDirectory else {
            return
        }

        folderSizeCancellationToken?.cancel()
        let cancellationToken = FolderSizeCancellationToken()
        folderSizeCancellationToken = cancellationToken
        updateStatus(prefix: L10n.string("status.calculatingFolderSize", fallback: "Calculating folder size"))

        Task { [weak self] in
            let result = await Task.detached(priority: .utility) {
                do {
                    return FolderSizeExecutionResult.success(
                        try FolderSizeCalculator().calculateSize(
                            of: item.url,
                            cancellationToken: cancellationToken
                        )
                    )
                } catch FolderSizeCalculationError.cancelled {
                    return FolderSizeExecutionResult.cancelled
                } catch {
                    return FolderSizeExecutionResult.failure(error.localizedDescription)
                }
            }.value
            guard let self,
                  self.folderSizeCancellationToken === cancellationToken else {
                return
            }
            self.folderSizeCancellationToken = nil
            switch result {
            case .success(let sizeResult):
                let sizeText = self.byteFormatter.string(fromByteCount: sizeResult.byteSize)
                self.onStatusChange?(
                    L10n.format(
                        "status.folderSizeResult",
                        fallback: "%@: %@, %d files",
                        item.name,
                        sizeText,
                        sizeResult.fileCount
                    )
                )
            case .cancelled:
                self.onStatusChange?(L10n.string("status.folderSizeCancelled", fallback: "Folder size calculation cancelled"))
            case .failure(let message):
                self.showOperationError(FileOperationExecutionError(message: message))
                self.updateStatus()
            }
        }
    }

    func cancelFolderSizeCalculation() {
        guard let folderSizeCancellationToken else {
            return
        }
        folderSizeCancellationToken.cancel()
        self.folderSizeCancellationToken = nil
        onStatusChange?(L10n.string("status.folderSizeCancelled", fallback: "Folder size calculation cancelled"))
    }

    func showInfoForSelection() {
        let urls = selectedItems().map(\.url)
        guard let firstURL = urls.first else {
            return
        }

        do {
            let info = try fileInfoProvider.info(for: firstURL)
            showInfoWindow(info: info, selectedCount: urls.count)
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

        let marker = NSPasteboard.general.string(forType: NSPasteboard.PasteboardType(FileClipboardPolicy.operationPasteboardType))
        let pasteboardChangeCount = NSPasteboard.general.changeCount
        let operation = FileClipboardPolicy.operation(
            marker: marker,
            pasteboardChangeCount: pasteboardChangeCount,
            sourceURLs: urls,
            trustedMoveClaim: fileClipboardSession.trustedMoveClaim
        )
        if operation == .copy {
            fileClipboardSession.clear()
        }

        _ = transfer(urls, toDirectory: currentFolderURL, operation: operation) { [weak self] succeeded in
            guard let self, succeeded, operation == .move else {
                return
            }
            let pasteboard = NSPasteboard.general
            if pasteboard.changeCount == pasteboardChangeCount {
                pasteboard.clearContents()
            }
            self.fileClipboardSession.clear()
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

    @objc private func openSelectedItemWithApplication(_ sender: NSMenuItem) {
        guard let appURL = sender.representedObject as? URL,
              let item = selectedItems().first else {
            return
        }

        open(item.url, withApplicationAt: appURL)
    }

    @objc private func openSelectedItemWithOtherApplication() {
        guard let item = selectedItems().first,
              OpenWithMenuPolicy.canShowOpenWith(
                  selectedItemCount: selectedItems().count,
                  selectedItemIsDirectory: item.isDirectory
              ) else {
            return
        }

        let panel = NSOpenPanel()
        panel.title = L10n.string("info.section.openWith", fallback: "Open With")
        panel.prompt = L10n.string("dialog.ok", fallback: "OK")
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK,
              let appURL = panel.url else {
            return
        }

        open(item.url, withApplicationAt: appURL)
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

    @objc private func createTextFileFromMenu() {
        createFile(fromTemplate: .plainText)
    }

    @objc private func createMarkdownFileFromMenu() {
        createFile(fromTemplate: .markdown)
    }

    @objc private func createCSVFileFromMenu() {
        createFile(fromTemplate: .csv)
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

    @objc private func cutFromMenu() {
        cutSelectionToPasteboard()
    }

    @objc private func copyPathFromMenu() {
        copySelectedPathsToPasteboard()
    }

    @objc private func copyParentPathFromMenu() {
        copySelectedParentPathsToPasteboard()
    }

    @objc private func copyShellPathFromMenu() {
        copySelectedShellPathsToPasteboard()
    }

    @objc private func copyNameFromMenu() {
        copySelectedNamesToPasteboard()
    }

    @objc private func compressFromMenu() {
        compressSelection()
    }

    @objc private func calculateFolderSizeFromMenu() {
        calculateSelectedFolderSize()
    }

    @objc private func cancelFolderSizeCalculationFromMenu() {
        cancelFolderSizeCalculation()
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
        updateDisplayedItems()
        reloadViews()
        updateStatus()
    }

    private func updateDisplayedItems() {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            displayedItems = sortedItems(allItems)
        } else {
            displayedItems = sortedItems(allItems.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            })
        }
    }

    private func sortedItems(_ items: [FileItem]) -> [FileItem] {
        items.sorted { left, right in
            if left.isDirectory != right.isDirectory {
                return left.isDirectory && !right.isDirectory
            }

            let result: ComparisonResult
            switch sortMode {
            case .name:
                result = nameComparison(left, right)
            case .type:
                result = typeComparison(left, right)
            case .size:
                result = sizeComparison(left, right)
            case .modified:
                result = modifiedComparison(left, right)
            }
            return sortDirection == .ascending
                ? result == .orderedAscending
                : result == .orderedDescending
        }
    }

    private func compareByName(_ left: FileItem, _ right: FileItem) -> Bool {
        left.name.localizedStandardCompare(right.name) == .orderedAscending
    }

    private func nameComparison(_ left: FileItem, _ right: FileItem) -> ComparisonResult {
        left.name.localizedStandardCompare(right.name)
    }

    private func typeComparison(_ left: FileItem, _ right: FileItem) -> ComparisonResult {
        let typeResult = typeSortKey(left).localizedStandardCompare(typeSortKey(right))
        return typeResult == .orderedSame ? nameComparison(left, right) : typeResult
    }

    private func sizeComparison(_ left: FileItem, _ right: FileItem) -> ComparisonResult {
        switch (left.byteSize, right.byteSize) {
        case let (leftSize?, rightSize?) where leftSize != rightSize:
            return leftSize < rightSize ? .orderedAscending : .orderedDescending
        case (.some, nil):
            return .orderedAscending
        case (nil, .some):
            return .orderedDescending
        default:
            return nameComparison(left, right)
        }
    }

    private func modifiedComparison(_ left: FileItem, _ right: FileItem) -> ComparisonResult {
        switch (left.modifiedAt, right.modifiedAt) {
        case let (leftDate?, rightDate?) where leftDate != rightDate:
            return leftDate < rightDate ? .orderedAscending : .orderedDescending
        case (.some, nil):
            return .orderedAscending
        case (nil, .some):
            return .orderedDescending
        default:
            return nameComparison(left, right)
        }
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
        case .column:
            for table in columnTables.reversed() {
                guard let columnIndex = columnIndex(for: table),
                      !table.selectedRowIndexes.isEmpty else {
                    continue
                }
                let items = itemsForColumn(at: columnIndex)
                let selectedItems = table.selectedRowIndexes
                    .sorted()
                    .compactMap { row -> FileItem? in
                        guard items.indices.contains(row) else {
                            return nil
                        }
                        return items[row]
                    }
                if !selectedItems.isEmpty {
                    return selectedItems
                }
            }
            return []
        }
    }

    private func item(in tableView: NSTableView, row: Int) -> FileItem? {
        let items: [FileItem]
        if tableView === self.tableView {
            items = displayedItems
        } else if let columnIndex = columnIndex(for: tableView) {
            items = itemsForColumn(at: columnIndex)
        } else {
            return nil
        }

        guard items.indices.contains(row) else {
            return nil
        }
        return items[row]
    }

    private func nameTextField(in tableView: NSTableView, row: Int, event: NSEvent) -> NSTextField? {
        let point = tableView.convert(event.locationInWindow, from: nil)
        let column = tableView.column(at: point)
        guard column >= 0,
              tableView.tableColumns.indices.contains(column) else {
            return nil
        }

        let identifier = tableView.tableColumns[column].identifier.rawValue
        if tableView === self.tableView {
            guard identifier == "name" else {
                return nil
            }
        } else {
            guard identifier == "columnName" else {
                return nil
            }
        }

        guard let cell = tableView.view(atColumn: column, row: row, makeIfNecessary: false) as? NSTableCellView,
              let textField = cell.textField else {
            return nil
        }

        let textPoint = textField.convert(event.locationInWindow, from: nil)
        guard textField.bounds.insetBy(dx: -4, dy: -4).contains(textPoint) else {
            return nil
        }
        return textField
    }

    private func toggleSelection(for url: URL) {
        guard let index = displayedItems.firstIndex(where: { $0.url == url }) else {
            return
        }

        switch viewMode {
        case .icon:
            let indexPath = IndexPath(item: index, section: 0)
            if collectionView.selectionIndexPaths.contains(indexPath) {
                collectionView.deselectItems(at: [indexPath])
            } else {
                collectionView.selectItems(at: [indexPath], scrollPosition: [])
            }
        case .list:
            if tableView.selectedRowIndexes.contains(index) {
                tableView.deselectRow(index)
            } else {
                tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: true)
            }
        case .column:
            break
        }
        updateStatus()
    }

    @objc private func toggleSelectionCheckboxFromTable(_ sender: NSButton) {
        guard displayedItems.indices.contains(sender.tag) else {
            return
        }

        if sender.state == .on {
            tableView.selectRowIndexes(IndexSet(integer: sender.tag), byExtendingSelection: true)
        } else {
            tableView.deselectRow(sender.tag)
        }
        updateStatus()
    }

    private func updateTableCheckboxColumnVisibility() {
        tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("selectionCheckbox"))?.isHidden = !showsSelectionCheckboxes
    }

    private func updateVisibleTableCheckboxStates() {
        guard showsSelectionCheckboxes,
              let checkboxColumnIndex = tableView.tableColumns.firstIndex(where: { $0.identifier.rawValue == "selectionCheckbox" }) else {
            return
        }

        let visibleRows = tableView.rows(in: tableView.visibleRect)
        guard visibleRows.length > 0 else {
            return
        }

        for row in visibleRows.location..<(visibleRows.location + visibleRows.length) {
            guard let button = tableView.view(atColumn: checkboxColumnIndex, row: row, makeIfNecessary: false) as? NSButton else {
                continue
            }
            button.state = tableView.selectedRowIndexes.contains(row) ? .on : .off
        }
    }

    private func rebuildColumnView(for focusedFolderURL: URL) {
        let options = DirectoryLoadOptions(includesHiddenItems: includesHiddenItems)
        let columns = ColumnViewPath.columns(for: focusedFolderURL, rootURL: columnRootURL)
        columnFolders = columns.map { column in
            let items: [FileItem]
            if column.folderURL.standardizedFileURL == focusedFolderURL.standardizedFileURL {
                items = allItems
            } else {
                items = (try? directoryStore.loadItems(in: column.folderURL, options: options)) ?? []
            }

            return ColumnFolder(
                url: column.folderURL,
                items: sortedItems(items),
                selectedURL: column.selectedURL
            )
        }
        rebuildColumnTables()
    }

    private func rebuildColumnTables() {
        for view in columnDocumentView.subviews {
            view.removeFromSuperview()
        }
        columnTables = []

        let columnWidths = preferredColumnWidths()
        let layout = ColumnViewLayoutMetrics.layout(
            columnWidths: columnWidths.map(Double.init),
            viewportHeight: Double(columnScrollView.contentSize.height)
        )
        columnDocumentView.frame = NSRect(
            x: 0,
            y: 0,
            width: CGFloat(layout.documentWidth),
            height: CGFloat(layout.documentHeight)
        )

        for index in columnFolders.indices {
            let frame = layout.columnFrames[index]
            let scrollView = NSScrollView(frame: NSRect(
                x: CGFloat(frame.x),
                y: CGFloat(frame.y),
                width: CGFloat(frame.width),
                height: CGFloat(frame.height)
            ))
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.drawsBackground = true
            scrollView.backgroundColor = .controlBackgroundColor
            scrollView.borderType = .noBorder
            scrollView.autoresizingMask = [.height]

            let rowCount = itemsForColumn(at: index).count
            let tableHeight = max(
                CGFloat(frame.height),
                CGFloat(rowCount) * 33
            )
            let table = SmartTableView(frame: NSRect(
                x: 0,
                y: 0,
                width: CGFloat(frame.width),
                height: tableHeight
            ))
            table.dataSource = self
            table.delegate = self
            table.keyDelegate = self
            table.headerView = nil
            table.allowsMultipleSelection = true
            table.usesAlternatingRowBackgroundColors = false
            table.backgroundColor = .controlBackgroundColor
            table.rowHeight = 32
            table.intercellSpacing = NSSize(width: 0, height: 1)
            table.tag = index
            configureFileDragging(for: table)

            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("columnName"))
            column.width = CGFloat(frame.width)
            column.minWidth = 180
            column.resizingMask = []
            table.addTableColumn(column)

            scrollView.documentView = table
            columnTables.append(table)
            columnDocumentView.addSubview(scrollView)
            table.reloadData()
        }

        selectColumnPathRows()
        scrollColumnViewToTrailingEdge()
    }

    private func clearColumnView() {
        columnNavigationToken = UUID()
        for table in columnTables {
            table.dataSource = nil
            table.delegate = nil
            table.keyDelegate = nil
        }
        for view in columnDocumentView.subviews {
            if let scrollView = view as? NSScrollView {
                scrollView.documentView = nil
            }
            view.removeFromSuperview()
        }
        columnTables.removeAll(keepingCapacity: false)
        columnFolders.removeAll(keepingCapacity: false)
        columnDocumentView.frame = NSRect(
            origin: .zero,
            size: columnScrollView.contentSize
        )
    }

    private func preferredColumnWidths() -> [CGFloat] {
        let attributes: [NSAttributedString.Key: Any] = [.font: FinderFonts.tableCell]
        let columnTextWidths = columnFolders.indices.map { index in
            itemsForColumn(at: index).map { item in
                let suffix = item.isDirectory ? "  >" : ""
                return Double(((displayName(for: item) + suffix) as NSString).size(withAttributes: attributes).width)
            }
        }
        return ColumnViewWidthMetrics.widths(forColumnTextWidths: columnTextWidths).map { CGFloat($0) }
    }

    private func selectColumnPathRows() {
        suppressColumnSelectionChange = true
        defer {
            suppressColumnSelectionChange = false
        }

        for (index, table) in columnTables.enumerated() {
            table.deselectAll(nil)
            guard let selectedURL = columnFolders[index].selectedURL else {
                continue
            }
            let items = itemsForColumn(at: index)
            if let row = items.firstIndex(where: { $0.url.standardizedFileURL == selectedURL.standardizedFileURL }) {
                table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                table.scrollRowToVisible(row)
            }
        }
    }

    private func scrollColumnViewToTrailingEdge() {
        columnScrollView.layoutSubtreeIfNeeded()
        let maxX = max(0, columnDocumentView.frame.width - columnScrollView.contentSize.width)
        columnScrollView.contentView.scroll(to: NSPoint(x: maxX, y: 0))
        columnScrollView.reflectScrolledClipView(columnScrollView.contentView)
    }

    private func handleColumnSelection(in table: NSTableView, columnIndex: Int) {
        activeColumnIndexForCreation = columnIndex
        contextualCreationDirectoryURL = nil

        guard table.selectedRowIndexes.count == 1 else {
            updateStatus()
            return
        }

        let selectedRow = table.selectedRow
        guard selectedRow >= 0 else {
            updateStatus()
            return
        }

        let items = itemsForColumn(at: columnIndex)
        guard items.indices.contains(selectedRow) else {
            updateStatus()
            return
        }

        let item = items[selectedRow]
        if item.isDirectory {
            navigateColumn(to: item.url, selectedFromColumnIndex: columnIndex)
        } else {
            updateStatus()
        }
    }

    private func navigateColumn(to folderURL: URL, selectedFromColumnIndex columnIndex: Int) {
        guard columnFolders.indices.contains(columnIndex) else {
            return
        }

        let token = UUID()
        columnNavigationToken = token
        directoryLoadToken = UUID()
        currentFolderURL = folderURL
        filterText = ""
        allItems = []
        displayedItems = []

        let selectedColumn = ColumnFolder(
            url: columnFolders[columnIndex].url,
            items: columnFolders[columnIndex].items,
            selectedURL: folderURL
        )
        let nextColumn = ColumnFolder(
            url: folderURL,
            items: [],
            selectedURL: nil
        )
        columnFolders = ColumnViewSelectionUpdate.replaceTrailingColumns(
            in: columnFolders,
            selectedColumnIndex: columnIndex,
            selectedColumn: selectedColumn,
            nextColumn: nextColumn
        )
        rebuildColumnTables()
        onColumnFolderChange?(folderURL)
        updateStatus(prefix: L10n.string("status.loading", fallback: "Loading"))

        let options = DirectoryLoadOptions(includesHiddenItems: includesHiddenItems)
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                do {
                    return BackgroundOperationResult.success(
                        try DirectoryStore().loadItems(in: folderURL, options: options)
                    )
                } catch {
                    return BackgroundOperationResult<[FileItem]>.failure(error.localizedDescription)
                }
            }.value
            guard let self,
                  self.columnNavigationToken == token,
                  self.currentFolderURL == folderURL else {
                return
            }

            switch result {
            case .success(let items):
                self.allItems = items
                self.updateDisplayedItems()
                let loadedNextColumn = ColumnFolder(
                    url: folderURL,
                    items: self.displayedItems,
                    selectedURL: nil
                )
                self.columnFolders = ColumnViewSelectionUpdate.replaceTrailingColumns(
                    in: self.columnFolders,
                    selectedColumnIndex: columnIndex,
                    selectedColumn: selectedColumn,
                    nextColumn: loadedNextColumn
                )
                self.rebuildColumnTables()
                self.updateStatus()
            case .failure(let message):
                self.allItems = []
                self.displayedItems = []
                self.columnFolders = ColumnViewSelectionUpdate.replaceTrailingColumns(
                    in: self.columnFolders,
                    selectedColumnIndex: columnIndex,
                    selectedColumn: selectedColumn,
                    nextColumn: nextColumn
                )
                self.rebuildColumnTables()
                self.onStatusChange?(
                    L10n.format(
                        "error.cannotReadFolder",
                        fallback: "Cannot read folder: %@",
                        message
                    )
                )
            }
        }
    }

    private func itemsForColumn(at index: Int) -> [FileItem] {
        guard columnFolders.indices.contains(index) else {
            return []
        }
        if columnFolders[index].url.standardizedFileURL == currentFolderURL?.standardizedFileURL {
            return displayedItems
        }
        return columnFolders[index].items
    }

    private func columnIndex(for tableView: NSTableView) -> Int? {
        columnTables.firstIndex { $0 === tableView }
    }

    private func columnTable(atWindowPoint point: NSPoint) -> SmartTableView? {
        columnTables.first { table in
            let localPoint = table.convert(point, from: nil)
            return table.bounds.contains(localPoint)
        }
    }

    private func columnTableCell(for tableView: NSTableView, row: Int) -> NSView? {
        guard let columnIndex = columnIndex(for: tableView) else {
            return nil
        }
        let items = itemsForColumn(at: columnIndex)
        guard items.indices.contains(row) else {
            return nil
        }

        let item = items[row]
        let cell = tableCell(in: tableView, identifier: "columnNameCell", includesIcon: true)
        cell.textField?.stringValue = item.isDirectory
            ? "\(displayName(for: item))  >"
            : displayName(for: item)
        cell.imageView?.image = visualIconProvider.icon(for: item, size: 18)
        return cell
    }

    private func selectColumnItems(matching urls: Set<URL>) {
        suppressColumnSelectionChange = true
        defer {
            suppressColumnSelectionChange = false
        }

        for (columnIndex, table) in columnTables.enumerated() {
            table.deselectAll(nil)
            let items = itemsForColumn(at: columnIndex)
            let indexes = items.enumerated().compactMap { index, item in
                urls.contains(item.url) ? index : nil
            }
            if !indexes.isEmpty {
                table.selectRowIndexes(IndexSet(indexes), byExtendingSelection: false)
            }
        }
    }

    private func contextMenu() -> NSMenu {
        let menu = NSMenu()
        let hasSelection = !selectedItems().isEmpty
        let canCreate = creationTargetDirectoryURL() != nil

        menu.addItem(menuItem("menu.open", fallback: "Open", action: #selector(openSelectedItemFromMenu), enabled: hasSelection))
        menu.addItem(openWithMenuItem())
        menu.addItem(menuItem("menu.quickLook", fallback: "Quick Look", action: #selector(quickLookFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.getInfo", fallback: "Get Info", action: #selector(getInfoFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.newFolder", fallback: "New Folder", action: #selector(createFolderFromMenu), enabled: canCreate))
        menu.addItem(menuItem("menu.newTextFile", fallback: "New Text File", action: #selector(createTextFileFromMenu), enabled: canCreate))
        menu.addItem(menuItem("menu.newMarkdownFile", fallback: "New Markdown File", action: #selector(createMarkdownFileFromMenu), enabled: canCreate))
        menu.addItem(menuItem("menu.newCSVFile", fallback: "New CSV File", action: #selector(createCSVFileFromMenu), enabled: canCreate))
        menu.addItem(menuItem("menu.rename", fallback: "Rename", action: #selector(renameFromMenu), enabled: selectedItems().count == 1))
        menu.addItem(menuItem("menu.moveToTrash", fallback: "Move to Trash", action: #selector(moveToTrashFromMenu), enabled: hasSelection))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.cut", fallback: "Cut", action: #selector(cutFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copy", fallback: "Copy", action: #selector(copyFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyName", fallback: "Copy Name", action: #selector(copyNameFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyPath", fallback: "Copy Path", action: #selector(copyPathFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyParentPath", fallback: "Copy Parent Path", action: #selector(copyParentPathFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.copyShellPath", fallback: "Copy as Shell Path", action: #selector(copyShellPathFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.compress", fallback: "Compress", action: #selector(compressFromMenu), enabled: hasSelection))
        menu.addItem(menuItem("menu.calculateFolderSize", fallback: "Calculate Folder Size", action: #selector(calculateFolderSizeFromMenu), enabled: hasSingleSelectedFolder()))
        menu.addItem(menuItem("menu.cancelFolderSizeCalculation", fallback: "Cancel Size Calculation", action: #selector(cancelFolderSizeCalculationFromMenu), enabled: isFolderSizeCalculationRunning()))
        menu.addItem(menuItem("menu.paste", fallback: "Paste", action: #selector(pasteFromMenu), enabled: currentFolderURL != nil))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItem("menu.revealInFinder", fallback: "Reveal in Finder", action: #selector(revealInFinderFromMenu), enabled: hasSelection || currentFolderURL != nil))

        return menu
    }

    private func openWithMenuItem() -> NSMenuItem {
        let selected = selectedItems()
        let selectedItem = selected.first
        let canOpenWith = OpenWithMenuPolicy.canShowOpenWith(
            selectedItemCount: selected.count,
            selectedItemIsDirectory: selectedItem?.isDirectory ?? false
        )
        let item = NSMenuItem(
            title: L10n.string("info.section.openWith", fallback: "Open With"),
            action: nil,
            keyEquivalent: ""
        )
        item.isEnabled = canOpenWith

        let submenu = NSMenu()
        if canOpenWith, let selectedItem {
            let applications = applications(toOpen: selectedItem.url)
            if applications.isEmpty {
                let emptyItem = NSMenuItem(
                    title: L10n.string("info.noApplications", fallback: "No application found"),
                    action: nil,
                    keyEquivalent: ""
                )
                emptyItem.isEnabled = false
                submenu.addItem(emptyItem)
            } else {
                for application in applications {
                    let appItem = NSMenuItem(
                        title: application.name,
                        action: #selector(openSelectedItemWithApplication(_:)),
                        keyEquivalent: ""
                    )
                    appItem.target = self
                    appItem.representedObject = application.url
                    let icon = NSWorkspace.shared.icon(forFile: application.url.path)
                    icon.size = NSSize(width: 16, height: 16)
                    appItem.image = icon
                    submenu.addItem(appItem)
                }
                submenu.addItem(NSMenuItem.separator())
            }

            let otherItem = NSMenuItem(
                title: L10n.string("menu.openWithOther", fallback: "Other..."),
                action: #selector(openSelectedItemWithOtherApplication),
                keyEquivalent: ""
            )
            otherItem.target = self
            submenu.addItem(otherItem)
        }

        item.submenu = submenu
        return item
    }

    private func menuItem(_ key: String, fallback: String, action: Selector, enabled: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: L10n.string(key, fallback: fallback), action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        return item
    }

    private func tableCell(identifier: String, includesIcon: Bool) -> NSTableCellView {
        tableCell(in: tableView, identifier: identifier, includesIcon: includesIcon)
    }

    private func tableCell(in ownerTable: NSTableView, identifier: String, includesIcon: Bool) -> NSTableCellView {
        let cellIdentifier = NSUserInterfaceItemIdentifier(identifier)
        if let cell = ownerTable.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView {
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
        columnTables.forEach { $0.reloadData() }
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
        case .column:
            selectColumnItems(matching: urls)
        }
    }

    private func firstResponderForCurrentViewMode() -> NSResponder {
        switch viewMode {
        case .icon:
            return collectionView
        case .list:
            return tableView
        case .column:
            return columnTables.last ?? columnScrollView
        }
    }

    private func showInfoWindow(info: FileInfo, selectedCount: Int) {
        let presentation = FileInfoPanelPresentationBuilder().presentation(
            for: info,
            selectedCount: selectedCount,
            kindLabel: kindLabel(for: info),
            sizeLabel: sizeLabel(for: info),
            createdLabel: info.createdAt.map { listDateFormatter.string(from: $0) },
            modifiedLabel: info.modifiedAt.map { listDateFormatter.string(from: $0) },
            defaultApplicationName: defaultApplicationName(for: info.url)
        )
        let icon = NSWorkspace.shared.icon(forFile: info.url.path)
        icon.size = NSSize(width: 72, height: 72)
        let controller = FileInfoWindowController(presentation: presentation, icon: icon)
        controller.onClose = { [weak self, weak controller] in
            guard let controller else {
                return
            }
            self?.infoWindowControllers.removeAll { $0 === controller }
        }
        infoWindowControllers.append(controller)
        if let parentWindow = view.window, let infoWindow = controller.window {
            let parentFrame = parentWindow.frame
            infoWindow.setFrameOrigin(
                NSPoint(
                    x: parentFrame.midX - infoWindow.frame.width / 2,
                    y: parentFrame.midY - infoWindow.frame.height / 2
                )
            )
            parentWindow.addChildWindow(infoWindow, ordered: .above)
        } else {
            controller.window?.center()
        }
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func defaultApplicationName(for url: URL) -> String? {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            return nil
        }
        if let bundleName = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return FileManager.default.displayName(atPath: appURL.path)
    }

    private func beginInlineRename(
        item: FileItem,
        in containerView: NSView,
        frame: NSRect,
        alignment: NSTextAlignment,
        font: NSFont
    ) {
        finishInlineRename(commit: false)

        let minX = max(0, frame.minX)
        let editingFrame = NSRect(
            x: minX,
            y: frame.minY,
            width: min(containerView.bounds.width - minX, max(96, frame.width)),
            height: max(24, min(44, frame.height))
        )
        let textField = NSTextField(frame: editingFrame)
        textField.stringValue = item.name
        textField.font = font
        textField.alignment = alignment
        textField.isEditable = true
        textField.isSelectable = true
        textField.isBordered = true
        textField.drawsBackground = true
        textField.backgroundColor = .controlBackgroundColor
        textField.textColor = .labelColor
        textField.delegate = self
        textField.lineBreakMode = .byTruncatingTail
        textField.usesSingleLineMode = true

        inlineRenameItem = item
        inlineRenameField = textField
        containerView.addSubview(textField)
        view.window?.makeFirstResponder(textField)
        textField.currentEditor()?.selectedRange = FileRenameInputPolicy.editableNameRange(
            forName: item.name,
            isDirectory: item.isDirectory
        )
    }

    private func finishInlineRename(commit: Bool) {
        guard let textField = inlineRenameField else {
            return
        }

        let item = inlineRenameItem
        let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        inlineRenameField = nil
        inlineRenameItem = nil
        textField.delegate = nil
        textField.removeFromSuperview()
        view.window?.makeFirstResponder(firstResponderForCurrentViewMode())

        guard commit,
              let item,
              !newName.isEmpty,
              newName != item.name else {
            return
        }
        rename(item, to: newName)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField,
              textField === inlineRenameField else {
            return
        }
        finishInlineRename(commit: true)
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        guard control === inlineRenameField else {
            return false
        }

        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            finishInlineRename(commit: true)
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            finishInlineRename(commit: false)
            return true
        }
        return false
    }

    private func open(_ fileURL: URL, withApplicationAt appURL: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration)
    }

    private func applications(toOpen fileURL: URL) -> [OpenWithApplication] {
        let workspace = NSWorkspace.shared
        let defaultURL = workspace.urlForApplication(toOpen: fileURL)?.standardizedFileURL
        var urls = workspace.urlsForApplications(toOpen: fileURL).map(\.standardizedFileURL)
        if let defaultURL, !urls.contains(defaultURL) {
            urls.insert(defaultURL, at: 0)
        }

        var seen = Set<URL>()
        let apps = urls.compactMap { appURL -> OpenWithApplication? in
            guard !seen.contains(appURL) else {
                return nil
            }
            seen.insert(appURL)
            return OpenWithApplication(
                name: applicationName(for: appURL),
                url: appURL
            )
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

    private func applicationName(for url: URL) -> String {
        if let bundleName = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }
        return FileManager.default.displayName(atPath: url.path)
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

    private func promptForName(
        title: String,
        message: String,
        defaultValue: String,
        selectedRange: NSRange? = nil
    ) -> String? {
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
        alert.window.initialFirstResponder = textField

        if let selectedRange {
            textField.selectText(nil)
            textField.currentEditor()?.selectedRange = selectedRange
            DispatchQueue.main.async {
                textField.currentEditor()?.selectedRange = selectedRange
            }
        }

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
        NSSize(
            width: CGFloat(IconLabelLayoutPolicy.itemWidth(forIconSize: Double(iconSize))),
            height: CGFloat(IconLabelLayoutPolicy.itemHeight(forIconSize: Double(iconSize)))
        )
    }

    private func subtitle(for item: FileItem) -> String {
        let label = typeLabel(for: item)
        guard !item.isDirectory, let byteSize = item.byteSize else {
            return label
        }
        return "\(label) - \(byteFormatter.string(fromByteCount: byteSize))"
    }

    private func displayName(for item: FileItem) -> String {
        FileNameDisplayPolicy.displayName(for: item, showsFileExtensions: showsFileExtensions)
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
        let selectedItems = selectedItems()
        let selectedCount = selectedItems.count
        let itemText = L10n.itemCount(displayedItems.count)
        let selectionText = selectedCount > 0 ? L10n.selectedCount(selectedCount) : ""
        let selectedByteSize = SelectionSummary.totalFileByteSize(for: selectedItems)
        let sizeText = selectedByteSize > 0
            ? L10n.format(
                "status.selectedSize",
                fallback: ", %@ selected size",
                byteFormatter.string(fromByteCount: selectedByteSize)
            )
            : ""
        let availableText = currentFolderURL.flatMap(availableCapacityText(for:)).map {
            L10n.format("status.available", fallback: ", %@ available", $0)
        } ?? ""
        if let prefix {
            onStatusChange?("\(prefix) \(itemText)\(selectionText)\(sizeText)\(availableText)")
        } else {
            onStatusChange?("\(itemText)\(selectionText)\(sizeText)\(availableText)")
        }
        onSelectionChange?(selectedItems)
    }

    private func availableCapacityText(for folderURL: URL) -> String? {
        do {
            let values = try folderURL.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey
            ])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return byteFormatter.string(fromByteCount: capacity)
            }
            if let capacity = values.volumeAvailableCapacity {
                return byteFormatter.string(fromByteCount: Int64(capacity))
            }
        } catch {
            return nil
        }
        return nil
    }
}
