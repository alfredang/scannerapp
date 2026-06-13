import Foundation
import UIKit
import Photos

/// Handles exporting scans to JPG/PDF files and to system destinations
/// (Photos library, Files / iCloud Drive via the document picker).
@MainActor
enum ExportService {

    enum ExportError: LocalizedError {
        case photoPermissionDenied
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .photoPermissionDenied: return "Photo access was denied. Enable it in Settings."
            case .writeFailed: return "Could not write the file."
            }
        }
    }

    // MARK: - Temp file generation (for sharing / document picker)

    /// Writes page images as JPGs into a temporary directory and returns their URLs.
    static func writeJPGs(_ images: [UIImage], baseName: String) -> [URL] {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var urls: [URL] = []
        for (index, image) in images.enumerated() {
            guard let data = image.jpegData(compressionQuality: Constants.jpegQuality) else { continue }
            let url = dir.appendingPathComponent("\(baseName)-\(index + 1).jpg")
            if (try? data.write(to: url, options: .atomic)) != nil { urls.append(url) }
        }
        return urls
    }

    /// Writes a PDF into a temporary directory and returns its URL.
    static func writePDFTemp(_ data: Data, baseName: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("\(baseName).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Save to Photos

    /// Saves images to the Photos library, requesting add-only permission as needed.
    static func saveToPhotos(_ images: [UIImage]) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let granted: Bool
        switch status {
        case .authorized, .limited:
            granted = true
        case .notDetermined:
            let new = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            granted = (new == .authorized || new == .limited)
        default:
            granted = false
        }
        guard granted else { throw ExportError.photoPermissionDenied }

        try await PHPhotoLibrary.shared().performChanges {
            for image in images {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }
}
