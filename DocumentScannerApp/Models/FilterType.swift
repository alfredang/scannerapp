import Foundation

/// The set of image-enhancement presets that can be applied to a scanned page.
/// Raw values are persisted on `ScanPage`, so they must remain stable.
enum FilterType: String, CaseIterable, Identifiable, Codable, Sendable {
    case original
    case autoEnhance
    case whiteDocument
    case blackAndWhite
    case removeNoise
    case brighten
    case sharpenText
    case receipt

    var id: String { rawValue }

    /// Human-readable name shown in the filter strip.
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .autoEnhance: return "Auto"
        case .whiteDocument: return "White"
        case .blackAndWhite: return "B&W"
        case .removeNoise: return "Denoise"
        case .brighten: return "Bright"
        case .sharpenText: return "Sharpen"
        case .receipt: return "Receipt"
        }
    }

    /// SF Symbol used to represent the filter.
    var systemImage: String {
        switch self {
        case .original: return "photo"
        case .autoEnhance: return "wand.and.stars"
        case .whiteDocument: return "doc.plaintext"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .removeNoise: return "sparkles"
        case .brighten: return "sun.max"
        case .sharpenText: return "textformat"
        case .receipt: return "receipt"
        }
    }
}
