import AppKit
import SmartFinderCore

extension FinderShortcutModifiers {
    init(eventModifierFlags: NSEvent.ModifierFlags) {
        var modifiers: FinderShortcutModifiers = []
        let flags = eventModifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        self = modifiers
    }
}

extension FinderKeyboardShortcut {
    static func resolve(event: NSEvent) -> FinderKeyboardShortcut? {
        resolve(
            keyCode: event.keyCode,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            modifiers: FinderShortcutModifiers(eventModifierFlags: event.modifierFlags)
        )
    }
}
