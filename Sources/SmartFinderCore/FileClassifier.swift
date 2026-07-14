import Foundation
import UniformTypeIdentifiers

public enum FileCategory: Equatable, Hashable, Sendable {
    case folder
    case image
    case video
    case audio
    case document
    case archive
    case code
    case other
}

public enum FileClassifier {
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "webp", "gif", "tiff", "tif", "bmp"
    ]

    private static let rawPhotoExtensions: Set<String> = [
        "3fr", "ari", "arw", "bay", "cap", "cr2", "cr3", "crw", "dcr",
        "dng", "eip", "erf", "fff", "iiq", "kdc", "mdc", "mef", "mos",
        "mrw", "nef", "nrw", "orf", "ori", "pef", "raf", "raw", "rwl",
        "rw2", "sr2", "srf", "srw", "x3f"
    ]

    private static let documentExtensions: Set<String> = [
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key", "md", "markdown"
    ]

    private static let videoExtensions: Set<String> = [
        "mov", "mp4", "m4v", "avi", "mkv", "webm", "mpg", "mpeg", "mts", "m2ts"
    ]

    private static let audioExtensions: Set<String> = [
        "mp3", "wav", "aiff", "aif", "m4a", "flac", "aac", "ogg", "opus"
    ]

    private static let archiveExtensions: Set<String> = [
        "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "pkg"
    ]

    private static let codeExtensions: Set<String> = [
        "swift", "js", "jsx", "ts", "tsx", "py", "rb", "go", "rs", "java",
        "c", "h", "m", "mm", "cpp", "hpp", "cs", "php", "html", "css",
        "scss", "json", "xml", "yaml", "yml", "sh", "zsh", "sql"
    ]

    public static func category(for url: URL, isDirectory: Bool) -> FileCategory {
        if isDirectory {
            return .folder
        }

        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) || rawPhotoExtensions.contains(ext) {
            return .image
        }
        if videoExtensions.contains(ext) {
            return .video
        }
        if audioExtensions.contains(ext) {
            return .audio
        }
        if documentExtensions.contains(ext) {
            return .document
        }
        if archiveExtensions.contains(ext) {
            return .archive
        }
        if codeExtensions.contains(ext) {
            return .code
        }

        if let type = UTType(filenameExtension: ext) {
            if type.conforms(to: .image) {
                return .image
            }
            if type.conforms(to: .movie) || type.conforms(to: .video) {
                return .video
            }
            if type.conforms(to: .audio) {
                return .audio
            }
            if type.conforms(to: .archive) {
                return .archive
            }
            if type.conforms(to: .sourceCode) || type.conforms(to: .text) {
                return .code
            }
            if type.conforms(to: .pdf) || type.conforms(to: .presentation) || type.conforms(to: .spreadsheet) {
                return .document
            }
        }

        return .other
    }
}
