import AppKit
import SmartFinderCore

@MainActor
final class MainMenuBuilder {
    static func install(target: MainWindowController) {
        let mainMenu = NSMenu()

        for menuSpec in SmartFinderMenuBarSpecification.menus {
            let menuItem = NSMenuItem(title: localized(menuSpec.titleKey, fallback: menuSpec.fallbackTitle), action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: menuItem.title)
            menuItem.submenu = submenu
            mainMenu.addItem(menuItem)

            for itemSpec in menuSpec.items {
                if itemSpec.isSeparator {
                    submenu.addItem(.separator())
                    continue
                }

                let item = NSMenuItem(
                    title: localized(itemSpec.titleKey, fallback: itemSpec.fallbackTitle),
                    action: selector(for: itemSpec.action),
                    keyEquivalent: itemSpec.keyEquivalent
                )
                item.keyEquivalentModifierMask = itemSpec.modifiers.eventModifierFlags
                item.representedObject = itemSpec.action?.rawValue
                item.target = menuTarget(for: itemSpec.action, controller: target)
                submenu.addItem(item)
            }
        }

        NSApplication.shared.mainMenu = mainMenu
    }

    private static func localized(_ key: String, fallback: String) -> String {
        L10n.string(key, fallback: fallback)
    }

    private static func selector(for action: SmartFinderMenuAction?) -> Selector? {
        guard let action else {
            return nil
        }

        switch action {
        case .cut:
            return #selector(NSText.cut(_:))
        case .copy:
            return #selector(NSText.copy(_:))
        case .paste:
            return #selector(NSText.paste(_:))
        case .selectAll:
            return #selector(NSText.selectAll(_:))
        default:
            return #selector(MainWindowController.performMainMenuItem(_:))
        }
    }

    private static func menuTarget(for action: SmartFinderMenuAction?, controller: MainWindowController) -> AnyObject? {
        switch action {
        case .cut, .copy, .paste, .selectAll:
            return nil
        default:
            return controller
        }
    }
}

extension FinderShortcutModifiers {
    var eventModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if contains(.command) {
            flags.insert(.command)
        }
        if contains(.shift) {
            flags.insert(.shift)
        }
        if contains(.option) {
            flags.insert(.option)
        }
        if contains(.control) {
            flags.insert(.control)
        }
        return flags
    }
}
