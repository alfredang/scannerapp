import Foundation
import SwiftData
import UIKit

/// A single scanned page. The image bytes live on disk (under the parent document's
/// directory); the model only stores filenames plus lightweight metadata so the
/// SwiftData store stays small.
@Model
final class ScanPage {
    /// Stable identifier; also used as the basis for on-disk filenames.
    var id: UUID = UUID()

    /// Ordering within the parent document (0-based).
    var order: Int = 0

    /// Filename of the **original** capture (un-filtered), relative to the doc directory.
    var originalFileName: String = ""

    /// Filename of the **processed** image (after the chosen filter + rotation).
    var processedFileName: String = ""

    /// Filename of the thumbnail used in list/grid previews.
    var thumbnailFileName: String = ""

    /// Persisted raw value of the applied `FilterType`.
    var filterRaw: String = FilterType.original.rawValue

    /// Clockwise rotation applied to the page, in degrees (0/90/180/270).
    var rotationDegrees: Int = 0

    /// Recognized text from OCR (empty until OCR has run).
    var ocrText: String = ""

    /// Inverse relationship back to the owning document.
    var document: ScanDocument?

    init(order: Int) {
        self.id = UUID()
        self.order = order
    }

    var filter: FilterType {
        get { FilterType(rawValue: filterRaw) ?? .original }
        set { filterRaw = newValue.rawValue }
    }

    // MARK: - File URLs

    private var directory: URL? {
        guard let docID = document?.id else { return nil }
        return Constants.documentDirectory(id: docID)
    }

    var originalURL: URL? { directory?.appendingPathComponent(originalFileName) }
    var processedURL: URL? { directory?.appendingPathComponent(processedFileName) }
    var thumbnailURL: URL? { directory?.appendingPathComponent(thumbnailFileName) }

    /// Loads the processed (display) image from disk, falling back to the original.
    @MainActor
    func loadProcessedImage() -> UIImage? {
        if let url = processedURL, let img = UIImage(contentsOfFile: url.path) { return img }
        if let url = originalURL, let img = UIImage(contentsOfFile: url.path) { return img }
        return nil
    }

    @MainActor
    func loadThumbnail() -> UIImage? {
        guard let url = thumbnailURL, let img = UIImage(contentsOfFile: url.path) else {
            return loadProcessedImage()
        }
        return img
    }
}
