import Foundation
import SwiftData
import UIKit

/// A scanned document: a named, ordered collection of pages plus metadata.
/// Page images and any generated PDF live on disk under `Constants.documentDirectory(id:)`.
@Model
final class ScanDocument {
    /// Stable identifier; names the on-disk asset directory.
    @Attribute(.unique) var id: UUID = UUID()

    var name: String = "Untitled Scan"
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    /// Cached count so the library list doesn't have to fault the pages relationship.
    var pageCount: Int = 0

    /// Aggregated OCR text across all pages, used for content search.
    var combinedOCRText: String = ""

    /// Pages owned by this document. Deleting the document cascades to its pages.
    @Relationship(deleteRule: .cascade, inverse: \ScanPage.document)
    var pages: [ScanPage] = []

    init(name: String = "Untitled Scan") {
        self.id = UUID()
        self.name = name
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
    }

    /// Pages sorted by their `order` field (the SwiftData array order isn't guaranteed).
    var orderedPages: [ScanPage] {
        pages.sorted { $0.order < $1.order }
    }

    /// On-disk directory holding this document's assets.
    var directory: URL { Constants.documentDirectory(id: id) }

    /// Recomputes derived metadata (page count, ordering, combined OCR text) and
    /// bumps the modified timestamp. Call after mutating `pages`.
    func refreshMetadata() {
        let ordered = orderedPages
        for (index, page) in ordered.enumerated() { page.order = index }
        pageCount = ordered.count
        combinedOCRText = ordered.map(\.ocrText).joined(separator: "\n")
        modifiedAt = Date()
    }

    @MainActor
    func coverThumbnail() -> UIImage? {
        orderedPages.first?.loadThumbnail()
    }
}
