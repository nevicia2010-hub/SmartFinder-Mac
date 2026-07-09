import AppKit
import ImageIO
import SmartFinderCore

final class DetailsPaneView: NSVisualEffectView {
    var onClose: (() -> Void)?

    private let headerTitleField = NSTextField(labelWithString: "")
    private let closeButton = NSButton()
    private let iconView = NSImageView()
    private let titleField = NSTextField(labelWithString: "")
    private let subtitleField = NSTextField(labelWithString: "")
    private let bodyField = NSTextField(labelWithString: "")
    private let openInMapsButton = NSButton(title: "", target: nil, action: nil)
    private let byteFormatter = ByteCountFormatter()
    private let dateFormatter = DateFormatter()
    private var mapsURL: URL?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .sidebar
        blendingMode = .withinWindow
        state = .active
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(selection: [FileItem]) {
        guard let item = selection.first else {
            iconView.image = nil
            headerTitleField.stringValue = L10n.string("details.panel.title", fallback: "Info")
            titleField.stringValue = L10n.string("details.empty.title", fallback: "No Selection")
            subtitleField.stringValue = L10n.string("details.empty.subtitle", fallback: "Select an item to view details.")
            bodyField.stringValue = ""
            mapsURL = nil
            openInMapsButton.isHidden = true
            return
        }

        if selection.count > 1 {
            iconView.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: nil)
            headerTitleField.stringValue = L10n.string("details.panel.title", fallback: "Info")
            titleField.stringValue = L10n.format("details.multiple.title", fallback: "%d Items", selection.count)
            subtitleField.stringValue = L10n.string("details.multiple.subtitle", fallback: "Multiple selection")
            bodyField.stringValue = selection.map(\.name).prefix(8).joined(separator: "\n")
            mapsURL = nil
            openInMapsButton.isHidden = true
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 96, height: 96)
        iconView.image = icon
        headerTitleField.stringValue = item.category == .image
            ? L10n.string("details.photo.title", fallback: "Photo Info")
            : L10n.string("details.panel.title", fallback: "Info")
        titleField.stringValue = item.name
        subtitleField.stringValue = kindLabel(for: item)
        let details = detailsText(for: item)
        bodyField.stringValue = details.text
        mapsURL = details.mapsURL
        openInMapsButton.isHidden = details.mapsURL == nil
    }

    func refreshAppearance() {
        headerTitleField.textColor = .labelColor
        titleField.textColor = .labelColor
        subtitleField.textColor = .secondaryLabelColor
        bodyField.textColor = .secondaryLabelColor
        needsDisplay = true
    }

    private func setup() {
        byteFormatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        byteFormatter.countStyle = .file
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        headerTitleField.font = FinderFonts.toolbarTitle
        headerTitleField.textColor = .labelColor
        headerTitleField.translatesAutoresizingMaskIntoConstraints = false

        closeButton.image = NSImage(
            systemSymbolName: "sidebar.right",
            accessibilityDescription: L10n.string("details.close", fallback: "Close Info Pane")
        )
        closeButton.toolTip = L10n.string("details.close", fallback: "Close Info Pane")
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closePane)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleField.font = FinderFonts.toolbarTitle
        titleField.lineBreakMode = .byTruncatingMiddle
        titleField.maximumNumberOfLines = 2
        titleField.alignment = .center
        titleField.translatesAutoresizingMaskIntoConstraints = false

        subtitleField.font = FinderFonts.iconSubtitle
        subtitleField.textColor = .secondaryLabelColor
        subtitleField.alignment = .center
        subtitleField.translatesAutoresizingMaskIntoConstraints = false

        bodyField.font = FinderFonts.status
        bodyField.textColor = .secondaryLabelColor
        bodyField.maximumNumberOfLines = 0
        bodyField.lineBreakMode = .byWordWrapping
        bodyField.translatesAutoresizingMaskIntoConstraints = false

        openInMapsButton.title = L10n.string("photo.openInMaps", fallback: "Open in Maps")
        openInMapsButton.target = self
        openInMapsButton.action = #selector(openInMaps)
        openInMapsButton.bezelStyle = .rounded
        openInMapsButton.isHidden = true
        openInMapsButton.translatesAutoresizingMaskIntoConstraints = false

        let header = NSStackView(views: [headerTitleField, closeButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        headerTitleField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let contentStack = NSStackView(views: [iconView, titleField, subtitleField, bodyField, openInMapsButton])
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 10
        contentStack.edgeInsets = NSEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let rootStack = NSStackView(views: [header, contentStack])
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 0
        rootStack.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: rootStack.widthAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 26),
            closeButton.heightAnchor.constraint(equalToConstant: 26),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96),
            contentStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor, constant: -24),
            titleField.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -28),
            subtitleField.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -28),
            bodyField.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -28),
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])

        update(selection: [])
    }

    private func detailsText(for item: FileItem) -> (text: String, mapsURL: URL?) {
        var lines: [String] = []
        lines.append(sectionTitle("details.section.file", fallback: "File"))
        lines.append("\(L10n.string("info.kind", fallback: "Kind")): \(kindLabel(for: item))")
        if let byteSize = item.byteSize, !item.isDirectory {
            lines.append("\(L10n.string("info.size", fallback: "Size")): \(byteFormatter.string(fromByteCount: byteSize))")
        }
        if !item.url.pathExtension.isEmpty {
            lines.append("\(L10n.string("info.extension", fallback: "Extension")): \(item.url.pathExtension.lowercased())")
        }
        if let modifiedAt = item.modifiedAt {
            lines.append("\(L10n.string("info.modified", fallback: "Modified")): \(dateFormatter.string(from: modifiedAt))")
        }

        let photoDetails = photoMetadataLines(for: item)
        if !photoDetails.lines.isEmpty {
            lines.append("")
            lines.append(sectionTitle("details.section.photo", fallback: "Photography"))
            lines.append(contentsOf: photoDetails.lines)
        }

        lines.append("")
        lines.append(sectionTitle("details.section.location", fallback: "Location"))
        lines.append("\(L10n.string("info.where", fallback: "Where")): \(item.url.deletingLastPathComponent().path)")
        return (lines.joined(separator: "\n"), photoDetails.mapsURL)
    }

    private func photoMetadataLines(for item: FileItem) -> (lines: [String], mapsURL: URL?) {
        guard item.category == .image,
              let source = CGImageSourceCreateWithURL(item.url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return ([], nil)
        }

        let summary = PhotoMetadataSummary(properties: properties)
        var lines: [String] = []
        if let captureDate = summary.captureDate {
            lines.append("\(L10n.string("photo.captureDate", fallback: "Capture Date")): \(captureDate)")
        }
        if let camera = summary.camera {
            lines.append("\(L10n.string("photo.camera", fallback: "Camera")): \(camera)")
        }
        if let lens = summary.lens {
            lines.append("\(L10n.string("photo.lens", fallback: "Lens")): \(lens)")
        }
        if let pixelDimensions = summary.pixelDimensions {
            lines.append("\(L10n.string("photo.dimensions", fallback: "Dimensions")): \(pixelDimensions)")
        }
        if let resolution = summary.resolution {
            lines.append("\(L10n.string("photo.resolution", fallback: "Resolution")): \(resolution)")
        }
        if let iso = summary.iso {
            lines.append("\(L10n.string("photo.iso", fallback: "ISO")): \(iso)")
        }
        if let focalLength = summary.focalLength {
            lines.append("\(L10n.string("photo.focalLength", fallback: "Focal Length")): \(focalLength)")
        }
        if let aperture = summary.aperture {
            lines.append("\(L10n.string("photo.aperture", fallback: "Aperture")): \(aperture)")
        }
        if let shutterSpeed = summary.shutterSpeed {
            lines.append("\(L10n.string("photo.shutterSpeed", fallback: "Shutter")): \(shutterSpeed)")
        }
        if let exposureCompensation = summary.exposureCompensation {
            lines.append("\(L10n.string("photo.exposureCompensation", fallback: "Exposure Bias")): \(exposureCompensation)")
        }
        if let whiteBalance = summary.whiteBalance {
            lines.append("\(L10n.string("photo.whiteBalance", fallback: "White Balance")): \(localizedWhiteBalance(whiteBalance))")
        }
        if let colorSpace = summary.colorSpace {
            lines.append("\(L10n.string("photo.colorSpace", fallback: "Color Space")): \(localizedColorSpace(colorSpace))")
        }
        if let gpsCoordinate = summary.gpsCoordinate {
            lines.append("\(L10n.string("photo.gps", fallback: "GPS")): \(gpsCoordinate)")
        }
        return (lines, summary.mapsURL)
    }

    private func sectionTitle(_ key: String, fallback: String) -> String {
        L10n.string(key, fallback: fallback).uppercased(with: Locale.current)
    }

    private func localizedWhiteBalance(_ value: String) -> String {
        switch value {
        case "Auto":
            return L10n.string("photo.whiteBalance.auto", fallback: "Auto")
        case "Manual":
            return L10n.string("photo.whiteBalance.manual", fallback: "Manual")
        default:
            return value
        }
    }

    private func localizedColorSpace(_ value: String) -> String {
        switch value {
        case "Uncalibrated":
            return L10n.string("photo.colorSpace.uncalibrated", fallback: "Uncalibrated")
        default:
            return value
        }
    }

    @objc private func closePane() {
        onClose?()
    }

    @objc private func openInMaps() {
        guard let mapsURL else {
            NSSound.beep()
            return
        }
        NSWorkspace.shared.open(mapsURL)
    }

    private func kindLabel(for item: FileItem) -> String {
        if item.isDirectory {
            return L10n.string("category.folder", fallback: "Folder")
        }

        let ext = item.url.pathExtension.uppercased()
        if !ext.isEmpty {
            return ext
        }

        switch item.category {
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
}
