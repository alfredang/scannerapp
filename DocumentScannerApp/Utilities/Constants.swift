import Foundation
import CoreGraphics

/// App-wide constants: storage locations, export quality, page sizing, and user-facing strings.
enum Constants {

    // MARK: - Storage

    /// Root directory for all scan assets (page images, thumbnails, generated PDFs).
    /// Lives in Application Support so it is excluded from Photos and survives launches.
    static var scansDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Scans", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Per-document subdirectory.
    static func documentDirectory(id: UUID) -> URL {
        let dir = scansDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Image / Export

    static let jpegQuality: CGFloat = 0.85
    static let thumbnailMaxDimension: CGFloat = 320

    // MARK: - PDF page sizes (points, 72 dpi)

    enum PageSize: String, CaseIterable, Identifiable {
        case a4 = "A4"
        case letter = "Letter"
        case fit = "Fit to Image"

        var id: String { rawValue }

        /// Returns the target page rect for a given image size, or nil to use the image's own size.
        var size: CGSize? {
            switch self {
            case .a4: return CGSize(width: 595.2, height: 841.8)        // 210 × 297 mm
            case .letter: return CGSize(width: 612, height: 792)        // 8.5 × 11 in
            case .fit: return nil
            }
        }
    }

    // MARK: - UserDefaults keys

    enum DefaultsKey {
        static let pdfQuality = "pdfQuality"
        static let pdfPageSize = "pdfPageSize"
        static let defaultFilter = "defaultFilter"
    }

    // MARK: - Strings

    static let appName = "Scanner"
}
