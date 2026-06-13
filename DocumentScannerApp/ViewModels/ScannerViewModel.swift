import SwiftUI
import SwiftData
import Observation

/// In-memory page being edited before the document is persisted.
@MainActor
@Observable
final class WorkingPage: Identifiable {
    let id = UUID()
    let original: UIImage
    var filter: FilterType {
        didSet { rerender() }
    }
    var rotationDegrees: Int {
        didSet { rerender() }
    }
    /// Cached render of `original` with `filter` + rotation applied (for display & export).
    private(set) var processedImage: UIImage
    var ocrText: String = ""

    init(original: UIImage, filter: FilterType = .original) {
        self.original = original
        self.filter = filter
        self.rotationDegrees = 0
        self.processedImage = original
        rerender()
    }

    func rotateClockwise() { rotationDegrees = (rotationDegrees + 90) % 360 }

    private func rerender() {
        processedImage = ImageProcessor.shared.process(original, filter: filter, rotationDegrees: rotationDegrees)
    }
}

/// In-memory document being assembled during the scan/edit flow.
@MainActor
@Observable
final class WorkingDocument: Identifiable {
    let id = UUID()
    var name: String
    var pages: [WorkingPage]

    init(name: String = "Untitled Scan", pages: [WorkingPage] = []) {
        self.name = name
        self.pages = pages
    }
}

/// Drives the scan → preview → filter → save flow.
@MainActor
@Observable
final class ScannerViewModel {

    /// The document currently being assembled, if any.
    var working: WorkingDocument?

    /// True while OCR is running across the pages.
    var isRunningOCR = false

    var hasPages: Bool { !(working?.pages.isEmpty ?? true) }

    // MARK: - Capture

    /// Starts a fresh working document from the first batch of captured images.
    func beginNewDocument(with images: [UIImage]) {
        guard !images.isEmpty else { return }
        let defaultFilter = SettingsStore.shared.defaultFilter
        let pages = images.map { WorkingPage(original: $0, filter: defaultFilter) }
        let name = Self.suggestedName()
        working = WorkingDocument(name: name, pages: pages)
    }

    /// Appends more captured images to the current working document.
    func addPages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        let defaultFilter = SettingsStore.shared.defaultFilter
        let newPages = images.map { WorkingPage(original: $0, filter: defaultFilter) }
        if working == nil {
            working = WorkingDocument(name: Self.suggestedName(), pages: newPages)
        } else {
            working?.pages.append(contentsOf: newPages)
        }
    }

    // MARK: - Page edits

    func deletePage(_ page: WorkingPage) {
        working?.pages.removeAll { $0.id == page.id }
    }

    func applyFilterToAll(_ filter: FilterType) {
        working?.pages.forEach { $0.filter = filter }
    }

    // MARK: - OCR

    /// Runs OCR on every page and stores the recognized text.
    func runOCR() async {
        guard let pages = working?.pages else { return }
        isRunningOCR = true
        for page in pages {
            page.ocrText = await OCRService.recognizeText(in: page.processedImage)
        }
        isRunningOCR = false
    }

    // MARK: - Persistence

    /// Persists the working document and clears the working state. Returns the saved model.
    @discardableResult
    func save(into context: ModelContext) -> ScanDocument? {
        guard let working, !working.pages.isEmpty else { return nil }
        let document = StorageService.persist(working, into: context)
        self.working = nil
        return document
    }

    func discard() { working = nil }

    // MARK: - Helpers

    private static func suggestedName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm"
        return "Scan \(formatter.string(from: Date()))"
    }
}
