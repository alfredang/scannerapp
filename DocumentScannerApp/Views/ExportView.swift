import SwiftUI
import SwiftData

/// Final step of the scan flow: name the document, optionally run OCR, save it to the
/// library, and export/share as PDF or JPG to Photos, Files, or any share target.
struct ExportView: View {
    @Bindable var viewModel: ScannerViewModel
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var settings = SettingsStore.shared

    /// Identifiable payloads so `sheet(item:)` presents with the URLs already set —
    /// `sheet(isPresented:)` + separate state raced and showed an empty sheet on first tap.
    private struct SharePayload: Identifiable {
        let id = UUID()
        let urls: [URL]
    }

    @State private var sharePayload: SharePayload?
    @State private var exportPayload: SharePayload?
    @State private var statusMessage: String?
    @State private var isWorking = false

    private var pages: [WorkingPage] { viewModel.working?.pages ?? [] }
    private var images: [UIImage] { pages.map(\.processedImage) }
    private var baseName: String {
        let name = viewModel.working?.name ?? "Scan"
        return name.replacingOccurrences(of: "/", with: "-")
    }

    private var nameBinding: Binding<String> {
        Binding(get: { viewModel.working?.name ?? "" },
                set: { viewModel.working?.name = $0 })
    }

    var body: some View {
        Form {
            Section {
                Text("Share, AirDrop, or save your document.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Section("Document") {
                TextField("Name", text: nameBinding)
                LabeledContent("Pages", value: "\(pages.count)")
            }

            Section("Text Recognition") {
                Button {
                    Task { await viewModel.runOCR() }
                } label: {
                    HStack {
                        Label("Run OCR", systemImage: "text.viewfinder")
                        Spacer()
                        if viewModel.isRunningOCR { ProgressView() }
                    }
                }
                .disabled(viewModel.isRunningOCR)
                if let text = pages.first?.ocrText, !text.isEmpty {
                    Text("Text recognized — searchable in your library.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Export") {
                Button { sharePDF() } label: { Label("Share / AirDrop PDF", systemImage: "square.and.arrow.up") }
                Button { saveToFiles(asPDF: true) } label: { Label("Save PDF to Files / iCloud", systemImage: "folder") }
                Button { saveToFiles(asPDF: false) } label: { Label("Save JPGs to Files / iCloud", systemImage: "photo.on.rectangle") }
                Button { saveToPhotos() } label: { Label("Save Images to Photos", systemImage: "photo") }
            }
            .disabled(images.isEmpty || isWorking)

            if let statusMessage {
                Section { Text(statusMessage).font(.footnote).foregroundStyle(.secondary) }
            }

            Section {
                Button {
                    saveToLibrary()
                } label: {
                    Text("Save to Library")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Save & Share")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sharePayload) { payload in
            ShareSheet(items: payload.urls)
        }
        .sheet(item: $exportPayload) { payload in
            DocumentExporter(urls: payload.urls)
        }
    }

    // MARK: - Actions

    private func makePDFData() -> Data {
        PDFService.makePDF(from: images,
                           pageSize: settings.pdfPageSize,
                           quality: settings.pdfQuality)
    }

    private func sharePDF() {
        guard let url = ExportService.writePDFTemp(makePDFData(), baseName: baseName) else { return }
        sharePayload = SharePayload(urls: [url])
    }

    private func saveToFiles(asPDF: Bool) {
        let urls: [URL]
        if asPDF {
            guard let url = ExportService.writePDFTemp(makePDFData(), baseName: baseName) else { return }
            urls = [url]
        } else {
            urls = ExportService.writeJPGs(images, baseName: baseName)
        }
        guard !urls.isEmpty else { return }
        exportPayload = SharePayload(urls: urls)
    }

    private func saveToPhotos() {
        isWorking = true
        Task {
            do {
                try await ExportService.saveToPhotos(images)
                statusMessage = "Saved \(images.count) image\(images.count == 1 ? "" : "s") to Photos."
            } catch {
                statusMessage = error.localizedDescription
            }
            isWorking = false
        }
    }

    private func saveToLibrary() {
        viewModel.save(into: modelContext)
        onFinish()
    }
}
