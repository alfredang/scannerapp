import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Applies enhancement filters and rotation to scanned page images using Core Image.
///
/// Thread-safe: a single shared `CIContext` is reused (Core Image contexts are safe to
/// use from multiple threads). Methods operate on `CGImage` (Sendable) so they can be
/// called freely from background async contexts under Swift 6 strict concurrency.
final class ImageProcessor: @unchecked Sendable {

    static let shared = ImageProcessor()

    private let context = CIContext(options: [.cacheIntermediates: false])

    private init() {}

    // MARK: - Public API

    /// Applies the given filter to an image. Returns the original on failure.
    func apply(_ filter: FilterType, to cgImage: CGImage) -> CGImage {
        guard filter != .original else { return cgImage }
        let input = CIImage(cgImage: cgImage)
        guard let output = output(for: filter, input: input) else { return cgImage }
        return render(output, fallbackExtent: input.extent) ?? cgImage
    }

    /// Rotates an image clockwise by a multiple of 90 degrees.
    func rotate(_ cgImage: CGImage, degrees: Int) -> CGImage {
        let normalized = ((degrees % 360) + 360) % 360
        guard normalized != 0 else { return cgImage }
        let radians = -CGFloat(normalized) * .pi / 180   // CI rotates counter-clockwise
        let input = CIImage(cgImage: cgImage)
        let rotated = input
            .transformed(by: CGAffineTransform(rotationAngle: radians))
        // Re-origin to (0,0) so the rendered image isn't clipped.
        let shifted = rotated.transformed(by: CGAffineTransform(
            translationX: -rotated.extent.origin.x,
            y: -rotated.extent.origin.y))
        return render(shifted, fallbackExtent: shifted.extent) ?? cgImage
    }

    /// Convenience for UI: apply filter + rotation to a `UIImage`.
    func process(_ image: UIImage, filter: FilterType, rotationDegrees: Int) -> UIImage {
        guard let cg = image.cgImage else { return image }
        var result = apply(filter, to: cg)
        result = rotate(result, degrees: rotationDegrees)
        return UIImage(cgImage: result)
    }

    // MARK: - Rendering

    private func render(_ image: CIImage, fallbackExtent: CGRect) -> CGImage? {
        let extent = image.extent.isInfinite ? fallbackExtent : image.extent
        return context.createCGImage(image, from: extent)
    }

    // MARK: - Filter graphs

    private func output(for filter: FilterType, input: CIImage) -> CIImage? {
        switch filter {
        case .original:
            return input

        case .autoEnhance:
            var image = input
            for adjustment in input.autoAdjustmentFilters() {
                adjustment.setValue(image, forKey: kCIInputImageKey)
                if let out = adjustment.outputImage { image = out }
            }
            return image

        case .whiteDocument:
            // Lift exposure, push contrast, then crush highlights toward pure white.
            let controls = CIFilter.colorControls()
            controls.inputImage = input
            controls.brightness = 0.12
            controls.contrast = 1.45
            controls.saturation = 0.9
            guard let mid = controls.outputImage else { return input }
            let highlight = CIFilter.highlightShadowAdjust()
            highlight.inputImage = mid
            highlight.highlightAmount = 1.0
            highlight.shadowAmount = 0.3
            return highlight.outputImage

        case .blackAndWhite:
            let mono = CIFilter.photoEffectNoir()
            mono.inputImage = input
            guard let gray = mono.outputImage else { return input }
            let controls = CIFilter.colorControls()
            controls.inputImage = gray
            controls.contrast = 1.5
            controls.brightness = 0.05
            return controls.outputImage

        case .removeNoise:
            let noise = CIFilter.noiseReduction()
            noise.inputImage = input
            noise.noiseLevel = 0.02
            noise.sharpness = 0.4
            guard let denoised = noise.outputImage else { return input }
            let shadows = CIFilter.highlightShadowAdjust()
            shadows.inputImage = denoised
            shadows.shadowAmount = 1.0
            shadows.highlightAmount = 0.8
            return shadows.outputImage

        case .brighten:
            let exposure = CIFilter.exposureAdjust()
            exposure.inputImage = input
            exposure.ev = 0.7
            return exposure.outputImage

        case .sharpenText:
            let sharpen = CIFilter.unsharpMask()
            sharpen.inputImage = input
            sharpen.radius = 2.0
            sharpen.intensity = 0.8
            return sharpen.outputImage

        case .receipt:
            // Desaturate, boost contrast and brightness to recover faded thermal print.
            let controls = CIFilter.colorControls()
            controls.inputImage = input
            controls.saturation = 0.0
            controls.contrast = 1.6
            controls.brightness = 0.1
            guard let toned = controls.outputImage else { return input }
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = toned
            sharpen.sharpness = 0.5
            return sharpen.outputImage
        }
    }
}
