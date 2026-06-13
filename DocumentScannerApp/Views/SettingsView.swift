import SwiftUI

/// App preferences: PDF quality, page size, default filter, plus an about section.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = SettingsStore.shared

    var body: some View {
        Form {
            Section("PDF Export") {
                Picker("Page Size", selection: $settings.pdfPageSize) {
                    ForEach(Constants.PageSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                VStack(alignment: .leading) {
                    Text("Quality: \(Int(settings.pdfQuality * 100))%")
                    Slider(value: $settings.pdfQuality, in: 0.3...1.0, step: 0.05)
                }
            }

            Section("Scanning") {
                Picker("Default Filter", selection: $settings.defaultFilter) {
                    ForEach(FilterType.allCases) { filter in
                        Label(filter.displayName, systemImage: filter.systemImage).tag(filter)
                    }
                }
            }

            Section("About") {
                LabeledContent("App", value: Constants.appName)
                LabeledContent("Version", value: appVersion)
                Text("Scan, enhance, and share documents — fully offline. Nothing leaves your device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Powered by Tertiary Infotech Academy Pte Ltd")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
