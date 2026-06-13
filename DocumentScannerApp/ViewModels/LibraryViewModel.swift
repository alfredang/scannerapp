import SwiftUI
import SwiftData
import Observation

/// Backs the document library: search text and document-level actions
/// (rename, delete, duplicate). The list itself is provided by `@Query` in the view.
@MainActor
@Observable
final class LibraryViewModel {
    var searchText = ""

    /// Filters documents by name or recognized (OCR) content.
    func filter(_ documents: [ScanDocument]) -> [ScanDocument] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return documents }
        return documents.filter {
            $0.name.lowercased().contains(query) ||
            $0.combinedOCRText.lowercased().contains(query)
        }
    }

    func rename(_ document: ScanDocument, to newName: String, context: ModelContext) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        document.name = trimmed
        document.modifiedAt = Date()
        try? context.save()
    }

    func delete(_ document: ScanDocument, context: ModelContext) {
        StorageService.delete(document, context: context)
    }

    @discardableResult
    func duplicate(_ document: ScanDocument, context: ModelContext) -> ScanDocument {
        StorageService.duplicate(document, context: context)
    }
}
