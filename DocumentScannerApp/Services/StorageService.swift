import Foundation
import SwiftData
import UIKit

/// Owns on-disk asset IO and the SwiftData lifecycle for documents.
///
/// Runs on the main actor because it touches `ModelContext` and `UIImage`
/// (both non-Sendable). Heavy pixel work is delegated to `ImageProcessor`.
@MainActor
enum StorageService {

    // MARK: - File helpers

    @discardableResult
    static func writeJPEG(_ image: UIImage, to url: URL, quality: CGFloat = Constants.jpegQuality) -> Bool {
        guard let data = image.jpegData(compressionQuality: quality) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            print("StorageService.writeJPEG failed: \(error)")
            return false
        }
    }

    /// Aspect-fit downscale for list/grid thumbnails.
    static func makeThumbnail(_ image: UIImage, maxDimension: CGFloat = Constants.thumbnailMaxDimension) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / max(size.width, 1), maxDimension / max(size.height, 1), 1)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
    }

    // MARK: - Persistence

    /// Writes a working document's assets to disk and inserts the SwiftData models.
    /// Returns the freshly created (and inserted) `ScanDocument`.
    @discardableResult
    static func persist(_ working: WorkingDocument, into context: ModelContext) -> ScanDocument {
        let document = ScanDocument(name: working.name)
        context.insert(document)

        let dir = Constants.documentDirectory(id: document.id)

        for (index, workingPage) in working.pages.enumerated() {
            let page = ScanPage(order: index)
            page.document = document

            let originalName = "page_\(index)_original.jpg"
            let processedName = "page_\(index)_processed.jpg"
            let thumbName = "page_\(index)_thumb.jpg"

            writeJPEG(workingPage.original, to: dir.appendingPathComponent(originalName))
            let processed = workingPage.processedImage
            writeJPEG(processed, to: dir.appendingPathComponent(processedName))
            writeJPEG(makeThumbnail(processed), to: dir.appendingPathComponent(thumbName))

            page.originalFileName = originalName
            page.processedFileName = processedName
            page.thumbnailFileName = thumbName
            page.filter = workingPage.filter
            page.rotationDegrees = workingPage.rotationDegrees
            page.ocrText = workingPage.ocrText

            document.pages.append(page)
        }

        document.refreshMetadata()
        try? context.save()
        return document
    }

    /// Re-renders and rewrites a single page's processed image + thumbnail after an edit.
    static func updateProcessedImage(for page: ScanPage, context: ModelContext) {
        guard let originalURL = page.originalURL,
              let original = UIImage(contentsOfFile: originalURL.path),
              let cg = original.cgImage,
              let docDir = page.document?.directory else { return }

        var result = ImageProcessor.shared.apply(page.filter, to: cg)
        result = ImageProcessor.shared.rotate(result, degrees: page.rotationDegrees)
        let processed = UIImage(cgImage: result)

        writeJPEG(processed, to: docDir.appendingPathComponent(page.processedFileName))
        writeJPEG(makeThumbnail(processed), to: docDir.appendingPathComponent(page.thumbnailFileName))
        page.document?.modifiedAt = Date()
        try? context.save()
    }

    static func delete(_ document: ScanDocument, context: ModelContext) {
        let dir = Constants.documentDirectory(id: document.id)
        try? FileManager.default.removeItem(at: dir)
        context.delete(document)
        try? context.save()
    }

    /// Deep-copies a document (files + models) under a new identity.
    @discardableResult
    static func duplicate(_ document: ScanDocument, context: ModelContext) -> ScanDocument {
        let copy = ScanDocument(name: document.name + " copy")
        context.insert(copy)
        let srcDir = Constants.documentDirectory(id: document.id)
        let dstDir = Constants.documentDirectory(id: copy.id)

        for source in document.orderedPages {
            let page = ScanPage(order: source.order)
            page.document = copy
            page.filterRaw = source.filterRaw
            page.rotationDegrees = source.rotationDegrees
            page.ocrText = source.ocrText
            page.originalFileName = source.originalFileName
            page.processedFileName = source.processedFileName
            page.thumbnailFileName = source.thumbnailFileName

            for name in [source.originalFileName, source.processedFileName, source.thumbnailFileName] where !name.isEmpty {
                let src = srcDir.appendingPathComponent(name)
                let dst = dstDir.appendingPathComponent(name)
                try? FileManager.default.copyItem(at: src, to: dst)
            }
            copy.pages.append(page)
        }
        copy.refreshMetadata()
        try? context.save()
        return copy
    }
}
