import Foundation

public enum SmartFinderMenuAction: String, Equatable, Sendable {
    case about
    case quit
    case newFolder
    case newTextFile
    case newMarkdownFile
    case newCSVFile
    case openSelection
    case quickLook
    case getInfo
    case rename
    case moveToTrash
    case compress
    case revealInFinder
    case copy
    case paste
    case copyName
    case copyPath
    case copyParentPath
    case copyShellPath
    case selectAll
    case find
    case goBack
    case goForward
    case goUp
    case showIconView
    case showListView
    case showColumnView
    case smallIcons
    case mediumIcons
    case largeIcons
    case hiddenItems
    case fileExtensions
    case itemCheckboxes
    case detailsPane
    case sortName
    case sortType
    case sortSize
    case sortModified
    case sortAscending
    case sortDescending
}

public struct SmartFinderMenuItemSpecification: Equatable, Sendable {
    public let titleKey: String
    public let fallbackTitle: String
    public let action: SmartFinderMenuAction?
    public let keyEquivalent: String
    public let modifiers: FinderShortcutModifiers
    public let isSeparator: Bool

    public static let separator = SmartFinderMenuItemSpecification(
        titleKey: "",
        fallbackTitle: "",
        action: nil,
        keyEquivalent: "",
        modifiers: [],
        isSeparator: true
    )

    private init(
        titleKey: String,
        fallbackTitle: String,
        action: SmartFinderMenuAction?,
        keyEquivalent: String,
        modifiers: FinderShortcutModifiers,
        isSeparator: Bool
    ) {
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.action = action
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
        self.isSeparator = isSeparator
    }

    public init(
        titleKey: String,
        fallbackTitle: String,
        action: SmartFinderMenuAction,
        keyEquivalent: String = "",
        modifiers: FinderShortcutModifiers = []
    ) {
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.action = action
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
        self.isSeparator = false
    }
}

public struct SmartFinderMenuSpecification: Equatable, Sendable {
    public let titleKey: String
    public let fallbackTitle: String
    public let items: [SmartFinderMenuItemSpecification]

    public init(titleKey: String, fallbackTitle: String, items: [SmartFinderMenuItemSpecification]) {
        self.titleKey = titleKey
        self.fallbackTitle = fallbackTitle
        self.items = items
    }
}

public enum SmartFinderMenuBarSpecification {
    public static let menus: [SmartFinderMenuSpecification] = [
        SmartFinderMenuSpecification(titleKey: "menu.app", fallbackTitle: "SmartFinder", items: [
            SmartFinderMenuItemSpecification(titleKey: "menu.about", fallbackTitle: "About SmartFinder", action: .about),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.quit", fallbackTitle: "Quit SmartFinder", action: .quit, keyEquivalent: "q", modifiers: [.command])
        ]),
        SmartFinderMenuSpecification(titleKey: "menu.file", fallbackTitle: "File", items: [
            SmartFinderMenuItemSpecification(titleKey: "menu.newFolder", fallbackTitle: "New Folder", action: .newFolder, keyEquivalent: "n", modifiers: [.command, .shift]),
            SmartFinderMenuItemSpecification(titleKey: "menu.newTextFile", fallbackTitle: "New Text File", action: .newTextFile),
            SmartFinderMenuItemSpecification(titleKey: "menu.newMarkdownFile", fallbackTitle: "New Markdown File", action: .newMarkdownFile),
            SmartFinderMenuItemSpecification(titleKey: "menu.newCSVFile", fallbackTitle: "New CSV File", action: .newCSVFile),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.open", fallbackTitle: "Open", action: .openSelection, keyEquivalent: "o", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.quickLook", fallbackTitle: "Quick Look", action: .quickLook, keyEquivalent: "y", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.getInfo", fallbackTitle: "Get Info", action: .getInfo, keyEquivalent: "i", modifiers: [.command]),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.rename", fallbackTitle: "Rename", action: .rename),
            SmartFinderMenuItemSpecification(titleKey: "menu.moveToTrash", fallbackTitle: "Move to Trash", action: .moveToTrash, keyEquivalent: "\u{8}", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.compress", fallbackTitle: "Compress", action: .compress),
            SmartFinderMenuItemSpecification(titleKey: "menu.revealInFinder", fallbackTitle: "Reveal in Finder", action: .revealInFinder)
        ]),
        SmartFinderMenuSpecification(titleKey: "menu.edit", fallbackTitle: "Edit", items: [
            SmartFinderMenuItemSpecification(titleKey: "menu.copy", fallbackTitle: "Copy", action: .copy, keyEquivalent: "c", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.paste", fallbackTitle: "Paste", action: .paste, keyEquivalent: "v", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.copyName", fallbackTitle: "Copy Name", action: .copyName),
            SmartFinderMenuItemSpecification(titleKey: "menu.copyPath", fallbackTitle: "Copy Path", action: .copyPath, keyEquivalent: "c", modifiers: [.command, .option]),
            SmartFinderMenuItemSpecification(titleKey: "menu.copyParentPath", fallbackTitle: "Copy Parent Path", action: .copyParentPath),
            SmartFinderMenuItemSpecification(titleKey: "menu.copyShellPath", fallbackTitle: "Copy as Shell Path", action: .copyShellPath),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.selectAll", fallbackTitle: "Select All", action: .selectAll, keyEquivalent: "a", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.find", fallbackTitle: "Find", action: .find, keyEquivalent: "f", modifiers: [.command])
        ]),
        SmartFinderMenuSpecification(titleKey: "menu.view", fallbackTitle: "View", items: [
            SmartFinderMenuItemSpecification(titleKey: "menu.display.iconView", fallbackTitle: "Icon View", action: .showIconView, keyEquivalent: "1", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.listView", fallbackTitle: "List View", action: .showListView, keyEquivalent: "2", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.columnView", fallbackTitle: "Column View", action: .showColumnView, keyEquivalent: "3", modifiers: [.command]),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.display.smallIcons", fallbackTitle: "Small Icons", action: .smallIcons),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.mediumIcons", fallbackTitle: "Medium Icons", action: .mediumIcons),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.largeIcons", fallbackTitle: "Large Icons", action: .largeIcons),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "menu.display.hiddenItems", fallbackTitle: "Hidden Items", action: .hiddenItems),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.fileExtensions", fallbackTitle: "File Name Extensions", action: .fileExtensions),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.itemCheckboxes", fallbackTitle: "Item Checkboxes", action: .itemCheckboxes),
            SmartFinderMenuItemSpecification(titleKey: "menu.display.detailsPane", fallbackTitle: "Details Pane", action: .detailsPane)
        ]),
        SmartFinderMenuSpecification(titleKey: "menu.go", fallbackTitle: "Go", items: [
            SmartFinderMenuItemSpecification(titleKey: "button.back", fallbackTitle: "Back", action: .goBack, keyEquivalent: "[", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "button.forward", fallbackTitle: "Forward", action: .goForward, keyEquivalent: "]", modifiers: [.command]),
            SmartFinderMenuItemSpecification(titleKey: "button.up", fallbackTitle: "Up", action: .goUp, keyEquivalent: "\u{F700}", modifiers: [.command])
        ]),
        SmartFinderMenuSpecification(titleKey: "menu.sort", fallbackTitle: "Sort", items: [
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.name", fallbackTitle: "Name", action: .sortName),
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.type", fallbackTitle: "Type", action: .sortType),
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.size", fallbackTitle: "Size", action: .sortSize),
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.modified", fallbackTitle: "Modified", action: .sortModified),
            .separator,
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.ascending", fallbackTitle: "Ascending", action: .sortAscending),
            SmartFinderMenuItemSpecification(titleKey: "toolbar.sort.descending", fallbackTitle: "Descending", action: .sortDescending)
        ])
    ]
}
