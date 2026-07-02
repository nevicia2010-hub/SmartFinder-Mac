import AppKit

enum FinderFonts {
    static var toolbarTitle: NSFont {
        preferred(.headline, fallback: .systemFont(ofSize: 13, weight: .semibold))
    }

    static var toolbarField: NSFont {
        preferred(.body, fallback: .systemFont(ofSize: 14))
    }

    static var sidebarHeader: NSFont {
        preferred(.caption1, fallback: .systemFont(ofSize: 11, weight: .semibold))
    }

    static var sidebarRow: NSFont {
        preferred(.body, fallback: .systemFont(ofSize: 13))
    }

    static var status: NSFont {
        preferred(.footnote, fallback: .systemFont(ofSize: 12))
    }

    static var breadcrumb: NSFont {
        preferred(.footnote, fallback: .systemFont(ofSize: 12))
    }

    static var iconTitle: NSFont {
        preferred(.caption1, fallback: .systemFont(ofSize: 12))
    }

    static var iconSubtitle: NSFont {
        preferred(.caption2, fallback: .systemFont(ofSize: 10))
    }

    static var tableCell: NSFont {
        preferred(.body, fallback: .systemFont(ofSize: 13))
    }

    private static func preferred(_ textStyle: NSFont.TextStyle, fallback: NSFont) -> NSFont {
        let font = NSFont.preferredFont(forTextStyle: textStyle, options: [:])
        if font.pointSize > 0 {
            return font
        }
        return fallback
    }
}
