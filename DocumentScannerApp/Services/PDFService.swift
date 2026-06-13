import Foundation
import UIKit
import PDFKit

/// Generates PDFs from page images using `UIGraphicsPDFRenderer`.
@MainActor
enum PDFService {

    /// Builds PDF data from an ordered list of page images.
    /// - Parameters:
    ///   - images: page images in display order.
    ///   - pageSize: fixed page size (A4/Letter) or `.fit` to use each image's own size.
    ///   - quality: JPEG compression used when drawing images into the PDF (0...1).
    static func makePDF(from images: [UIImage],
                        pageSize: Constants.PageSize = .fit,
                        quality: CGFloat = Constants.jpegQuality) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: .zero)
        return renderer.pdfData { context in
            for image in images {
                let pageRect = rect(for: image, pageSize: pageSize)
                context.beginPage(withBounds: pageRect, pageInfo: [:])
                let drawRect = aspectFit(imageSize: image.size, in: pageRect)
                // Recompress to honor the quality setting, then draw.
                if let data = image.jpegData(compressionQuality: quality),
                   let compressed = UIImage(data: data) {
                    compressed.draw(in: drawRect)
                } else {
                    image.draw(in: drawRect)
                }
            }
        }
    }

    /// Writes a generated PDF to disk and returns the URL.
    @discardableResult
    static func writePDF(_ data: Data, named name: String, in directory: URL) -> URL? {
        let safe = name.replacingOccurrences(of: "/", with: "-")
        let url = directory.appendingPathComponent("\(safe).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("PDFService.writePDF failed: \(error)")
            return nil
        }
    }

    // MARK: - Layout helpers

    private static func rect(for image: UIImage, pageSize: Constants.PageSize) -> CGRect {
        if let size = pageSize.size {
            // Match orientation of the source image.
            if image.size.width > image.size.height {
                return CGRect(origin: .zero, size: CGSize(width: size.height, height: size.width))
            }
            return CGRect(origin: .zero, size: size)
        }
        return CGRect(origin: .zero, size: image.size)
    }

    private static func aspectFit(imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }
}
