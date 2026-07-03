import Foundation

public enum CopyPathFormat: Equatable, Sendable {
    case fullPath
    case parentDirectory
    case shellEscapedPath
}

public enum CopyPathFormatter {
    public static func strings(for urls: [URL], format: CopyPathFormat) -> [String] {
        urls.map { url in
            switch format {
            case .fullPath:
                return url.path
            case .parentDirectory:
                return url.deletingLastPathComponent().path
            case .shellEscapedPath:
                return shellEscaped(url.path)
            }
        }
    }

    public static func joinedString(for urls: [URL], format: CopyPathFormat) -> String {
        strings(for: urls, format: format).joined(separator: "\n")
    }

    private static func shellEscaped(_ path: String) -> String {
        guard path.rangeOfCharacter(from: shellSafeCharacterSet.inverted) != nil else {
            return path
        }
        return "'\(path.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static let shellSafeCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_+-=.,/:")
}
