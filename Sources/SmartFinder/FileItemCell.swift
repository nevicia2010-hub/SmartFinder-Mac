import AppKit
import SmartFinderCore

final class FileItemCell: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("FileItemCell")

    private let iconView = NSImageView()
    private let selectionCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let tagIndicator = NSView()
    private let titleField = NSTextField(labelWithString: "")
    private let subtitleField = NSTextField(labelWithString: "")
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?
    private var onCheckboxToggle: ((URL) -> Void)?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 128, height: 150))
        view.wantsLayer = true
        view.layer?.cornerRadius = 6

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        selectionCheckbox.target = self
        selectionCheckbox.action = #selector(toggleSelectionCheckbox)
        selectionCheckbox.translatesAutoresizingMaskIntoConstraints = false
        selectionCheckbox.isHidden = true

        tagIndicator.wantsLayer = true
        tagIndicator.layer?.cornerRadius = 4
        tagIndicator.translatesAutoresizingMaskIntoConstraints = false
        tagIndicator.isHidden = true

        titleField.alignment = .center
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.font = FinderFonts.iconTitle
        titleField.translatesAutoresizingMaskIntoConstraints = false

        subtitleField.alignment = .center
        subtitleField.lineBreakMode = .byTruncatingTail
        subtitleField.maximumNumberOfLines = 1
        subtitleField.font = FinderFonts.iconSubtitle
        subtitleField.textColor = .secondaryLabelColor
        subtitleField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iconView)
        view.addSubview(selectionCheckbox)
        view.addSubview(tagIndicator)
        view.addSubview(titleField)
        view.addSubview(subtitleField)

        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 96)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 96)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconWidthConstraint!,
            iconHeightConstraint!,

            selectionCheckbox.leadingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -2),
            selectionCheckbox.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -2),
            selectionCheckbox.widthAnchor.constraint(equalToConstant: 18),
            selectionCheckbox.heightAnchor.constraint(equalToConstant: 18),

            tagIndicator.widthAnchor.constraint(equalToConstant: 8),
            tagIndicator.heightAnchor.constraint(equalToConstant: 8),
            tagIndicator.trailingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: -6),
            tagIndicator.bottomAnchor.constraint(equalTo: iconView.bottomAnchor, constant: -6),

            titleField.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),

            subtitleField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 2),
            subtitleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            subtitleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        selectionCheckbox.isHidden = true
        selectionCheckbox.state = .off
        onCheckboxToggle = nil
        tagIndicator.isHidden = true
        tagIndicator.layer?.backgroundColor = nil
        titleField.stringValue = ""
        subtitleField.stringValue = ""
        representedObject = nil
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected
                ? NSColor.selectedControlColor.withAlphaComponent(0.24).cgColor
                : NSColor.clear.cgColor
            selectionCheckbox.state = isSelected ? .on : .off
        }
    }

    func configure(
        name: String,
        subtitle: String,
        image: NSImage,
        representedURL: URL,
        iconSize: CGFloat,
        finderLabelNumber: Int,
        showsSelectionCheckbox: Bool,
        onCheckboxToggle: ((URL) -> Void)?
    ) {
        representedObject = representedURL
        iconWidthConstraint?.constant = iconSize
        iconHeightConstraint?.constant = iconSize
        iconView.image = image
        selectionCheckbox.isHidden = !showsSelectionCheckbox
        selectionCheckbox.state = isSelected ? .on : .off
        self.onCheckboxToggle = onCheckboxToggle
        updateTagIndicator(finderLabelNumber: finderLabelNumber)
        titleField.stringValue = name
        subtitleField.stringValue = subtitle
    }

    @objc private func toggleSelectionCheckbox() {
        guard let url = representedObject as? URL else {
            return
        }
        onCheckboxToggle?(url)
    }

    private func updateTagIndicator(finderLabelNumber: Int) {
        guard let color = FinderTagColor(rawValue: finderLabelNumber) else {
            tagIndicator.isHidden = true
            tagIndicator.layer?.backgroundColor = nil
            return
        }

        tagIndicator.isHidden = false
        tagIndicator.layer?.backgroundColor = swatchColor(for: color).cgColor
    }

    private func swatchColor(for color: FinderTagColor) -> NSColor {
        switch color {
        case .gray:
            return .systemGray
        case .green:
            return .systemGreen
        case .purple:
            return .systemPurple
        case .blue:
            return .systemBlue
        case .yellow:
            return .systemYellow
        case .red:
            return .systemRed
        case .orange:
            return .systemOrange
        }
    }
}
