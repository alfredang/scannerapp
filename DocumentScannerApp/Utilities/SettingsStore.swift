import SwiftUI
import Observation

/// App preferences backed by `UserDefaults`: PDF quality, page size, default filter.
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var pdfQuality: Double {
        didSet { defaults.set(pdfQuality, forKey: Constants.DefaultsKey.pdfQuality) }
    }

    var pdfPageSize: Constants.PageSize {
        didSet { defaults.set(pdfPageSize.rawValue, forKey: Constants.DefaultsKey.pdfPageSize) }
    }

    var defaultFilter: FilterType {
        didSet { defaults.set(defaultFilter.rawValue, forKey: Constants.DefaultsKey.defaultFilter) }
    }

    private init() {
        let storedQuality = defaults.object(forKey: Constants.DefaultsKey.pdfQuality) as? Double
        pdfQuality = storedQuality ?? 0.85

        let storedSize = defaults.string(forKey: Constants.DefaultsKey.pdfPageSize)
        pdfPageSize = storedSize.flatMap(Constants.PageSize.init(rawValue:)) ?? .fit

        let storedFilter = defaults.string(forKey: Constants.DefaultsKey.defaultFilter)
        defaultFilter = storedFilter.flatMap(FilterType.init(rawValue:)) ?? .original
    }
}
