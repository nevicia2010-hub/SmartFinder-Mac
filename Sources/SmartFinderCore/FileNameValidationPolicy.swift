import Foundation

public enum FileNameValidationError: Error, Equatable, LocalizedError, Sendable {
    case empty
    case reservedPathComponent
    case pathSeparator
    case controlCharacter

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "The file name cannot be empty."
        case .reservedPathComponent:
            return "The names . and .. are reserved by the file system."
        case .pathSeparator:
            return "The file name cannot contain / or :."
        case .controlCharacter:
            return "The file name cannot contain control characters."
        }
    }
}

public enum FileNameValidationPolicy {
    public static func validatedName(_ name: String) throws -> String {
        guard !name.isEmpty else {
            throw FileNameValidationError.empty
        }
        guard name != ".", name != ".." else {
            throw FileNameValidationError.reservedPathComponent
        }
        guard !name.contains("/"), !name.contains(":") else {
            throw FileNameValidationError.pathSeparator
        }
        guard name.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw FileNameValidationError.controlCharacter
        }
        return name
    }

    public static func isValid(_ name: String) -> Bool {
        (try? validatedName(name)) != nil
    }
}
