import Foundation
import UniformTypeIdentifiers

public enum FileCategory: Equatable, Hashable {
    case folder
    case image
    case document
    case other
}

public enum FileClassifier {
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "webp", "gif", "tiff", "tif", "bmp"
    ]

    private static let documentExtensions: Set<String> = [
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key"
    ]

    public static func category(for url: URL, isDirectory: Bool) -> FileCategory {
        if isDirectory {
            return .folder
        }

        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) {
            return .image
        }
        if documentExtensions.contains(ext) {
            return .document
        }

        if let type = UTType(filenameExtension: ext) {
            if type.conforms(to: .image) {
                return .image
            }
            if type.conforms(to: .pdf) || type.conforms(to: .presentation) || type.conforms(to: .spreadsheet) {
                return .document
            }
        }

        return .other
    }
}
