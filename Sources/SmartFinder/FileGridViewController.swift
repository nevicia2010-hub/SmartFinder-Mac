import AppKit
import SmartFinderCore

protocol SmartCollectionViewKeyDelegate: AnyObject {
    func smartCollectionViewDidPressSpace()
    func smartCollectionViewDidPressCommandA()
    func smartCollectionViewDidDoubleClick()
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
        if flags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "a" {
            keyDelegate?.smartCollectionViewDidPressCommandA()
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
}

final class FileGridViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, SmartCollectionViewKeyDelegate {
    var onOpenFolder: ((URL) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let directoryStore = DirectoryStore()
    private let iconProvider = IconProvider()
    private let thumbnailPipeline = ThumbnailPipeline()
    private let quickLookController = QuickLookController()
    private let collectionView = SmartCollectionView()

    private var currentFolderURL: URL?
    private var allItems: [FileItem] = []
    private var displayedItems: [FileItem] = []
    private var filterText = ""

    override func loadView() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 128, height: 150)
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
            cell.configure(name: item.name, image: cached, representedURL: item.url)
        } else {
            cell.configure(name: item.name, image: fallbackIcon, representedURL: item.url)
        }

        if ThumbnailPipeline.isThumbnailEligible(item.category) {
            thumbnailPipeline.thumbnail(for: item, size: CGSize(width: 128, height: 128)) { [weak cell] image in
                guard let image, cell?.representedObject as? URL == item.url else {
                    return
                }
                cell?.configure(name: item.name, image: image, representedURL: item.url)
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
