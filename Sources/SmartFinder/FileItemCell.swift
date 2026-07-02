import AppKit

final class FileItemCell: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("FileItemCell")

    private let iconView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 128, height: 150))
        view.wantsLayer = true
        view.layer?.cornerRadius = 6

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleField.alignment = .center
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.font = .systemFont(ofSize: 12)
        titleField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iconView)
        view.addSubview(titleField)

        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 96)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 96)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconWidthConstraint!,
            iconHeightConstraint!,

            titleField.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        titleField.stringValue = ""
        representedObject = nil
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.selectedControlColor.withAlphaComponent(0.24).cgColor
                : NSColor.clear.cgColor
        }
    }

    func configure(name: String, image: NSImage, representedURL: URL, iconSize: CGFloat) {
        representedObject = representedURL
        iconWidthConstraint?.constant = iconSize
        iconHeightConstraint?.constant = iconSize
        iconView.image = image
        titleField.stringValue = name
    }
}
