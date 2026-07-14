import Foundation

public enum FileRenameInputPolicy {
    public static func editableNameRange(forName name: String, isDirectory: Bool) -> NSRange {
        let fullRange = NSRange(location: 0, length: (name as NSString).length)
        guard !isDirectory else {
            return fullRange
        }

        let extensionStart = extensionDelimiterIndex(in: name)
        guard let extensionStart else {
            return fullRange
        }

        let prefix = String(name[..<extensionStart])
        let prefixLength = (prefix as NSString).length
        guard prefixLength > 0 else {
            return fullRange
        }

        return NSRange(location: 0, length: prefixLength)
    }

    private static func extensionDelimiterIndex(in name: String) -> String.Index? {
        guard let dotIndex = name.lastIndex(of: "."),
              dotIndex != name.startIndex,
              name.index(after: dotIndex) != name.endIndex else {
            return nil
        }

        return dotIndex
    }
}
