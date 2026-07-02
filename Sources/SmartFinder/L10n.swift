import Foundation

enum L10n {
    static func string(_ key: String, fallback: String) -> String {
        if let mainValue = localizedString(in: Bundle.main, key: key) {
            return mainValue
        }

        if let moduleValue = localizedString(in: Bundle.module, key: key) {
            return moduleValue
        }

        return fallback
    }

    static func format(_ key: String, fallback: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key, fallback: fallback),
            locale: Locale.current,
            arguments: arguments
        )
    }

    static func itemCount(_ count: Int) -> String {
        let key = count == 1 ? "status.items.one" : "status.items.other"
        let fallback = count == 1 ? "%d item" : "%d items"
        return format(key, fallback: fallback, count)
    }

    static func selectedCount(_ count: Int) -> String {
        format("status.selected", fallback: ", %d selected", count)
    }

    private static func localizedString(in bundle: Bundle, key: String) -> String? {
        let localizations = bundle.localizations.filter { $0 != "Base" }
        guard !localizations.isEmpty else {
            return nil
        }

        let preferred = Bundle.preferredLocalizations(
            from: localizations,
            forPreferences: preferredLanguages
        ).first ?? "en"

        let resourceName = localizations.contains(preferred) ? preferred : "en"
        guard let path = bundle.path(forResource: resourceName, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return nil
        }

        let value = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
        return value == key ? nil : value
    }

    private static var preferredLanguages: [String] {
        UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? Locale.preferredLanguages
    }
}
