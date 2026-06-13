import Foundation
import Vision
import UIKit

/// Recognizes text in scanned pages using the Vision framework (fully on-device).
enum OCRService {

    /// Recognizes text in a `CGImage`. Safe to call from a background context.
    static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("OCRService failed: \(error)")
                continuation.resume(returning: "")
            }
        }
    }

    /// Convenience overload for `UIImage`.
    static func recognizeText(in image: UIImage) async -> String {
        guard let cg = image.cgImage else { return "" }
        return await recognizeText(in: cg)
    }
}
