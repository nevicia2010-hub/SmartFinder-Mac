import Foundation

public struct FinderShortcutModifiers: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let command = FinderShortcutModifiers(rawValue: 1 << 0)
    public static let shift = FinderShortcutModifiers(rawValue: 1 << 1)
    public static let option = FinderShortcutModifiers(rawValue: 1 << 2)
    public static let control = FinderShortcutModifiers(rawValue: 1 << 3)
}

public enum FinderKeyboardShortcut: Equatable, Sendable {
    case quickLook
    case renameSelection
    case moveToTrash
    case selectAll
    case copy
    case paste
    case refresh
    case getInfo
    case newFolder
    case goBack
    case goForward
    case goUp
    case openSelection
    case showIconView
    case showListView
    case showColumnView
    case focusSearch
    case copyPath

    public static func resolve(
        keyCode: UInt16,
        charactersIgnoringModifiers: String?,
        modifiers: FinderShortcutModifiers
    ) -> FinderKeyboardShortcut? {
        let character = charactersIgnoringModifiers?.lowercased()

        switch modifiers {
        case []:
            if keyCode == 49 {
                return .quickLook
            }
            if keyCode == 36 {
                return .renameSelection
            }
            if keyCode == 51 || keyCode == 117 {
                return .moveToTrash
            }
        case [.command]:
            switch (keyCode, character) {
            case (_, "a"):
                return .selectAll
            case (_, "c"):
                return .copy
            case (_, "v"):
                return .paste
            case (_, "r"):
                return .refresh
            case (_, "i"):
                return .getInfo
            case (_, "y"):
                return .quickLook
            case (_, "f"):
                return .focusSearch
            case (_, "1"):
                return .showIconView
            case (_, "2"):
                return .showListView
            case (_, "3"):
                return .showColumnView
            case (_, "["):
                return .goBack
            case (_, "]"):
                return .goForward
            case (126, _):
                return .goUp
            case (125, _):
                return .openSelection
            case (51, _), (117, _):
                return .moveToTrash
            default:
                return nil
            }
        case [.command, .shift]:
            if character == "n" {
                return .newFolder
            }
        case [.command, .option]:
            if character == "c" {
                return .copyPath
            }
        default:
            return nil
        }

        return nil
    }
}
