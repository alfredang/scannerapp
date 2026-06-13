import SwiftUI
import SwiftData

/// Opens a saved document: paged image viewer, recognized text, and export/share actions.
struct DocumentDetailView: View {
    @Bindable var document: ScanDocument
    @Environment(\.modelContext) private var modelContext

    @State private var selectedIndex = 0
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var exportURLs: [URL] = []
    @State private var showFileExporter = false
    @State private var isRunningOCR = false
    @State private var statusMessage: String?

    private var orderedPages: [ScanPage] { document.orderedPages }

    private func images() -> [UIImage] { orderedPages.compactMap { $0.loadProcessedImage() } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                pager
                Text("Page \(min(selectedIndex + 1, max(orderedPages.count, 1))) of \(orderedPages.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                recognizedTextSection

                if let statusMessage {
                    Text(statusMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { sharePDF() } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }
                    Button { saveToFiles(asPDF: true) } label: { Label("Export PDF to Files", systemImage: "folder") }
                    Button { saveToFiles(asPDF: false) } label: { Label("Export JPGs to Files", systemImage: "photo.on.rectangle") }
                    Button { saveToPhotos() } label: { Label("Save to Photos", systemImage: "photo") }
                    Divider()
                    Button { runOCR() } label: { Label("Run OCR", systemImage: "text.viewfinder") }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showFileExporter) { DocumentExporter(urls: exportURLs) }
    }

    // MARK: - Pieces

    private var pager: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(orderedPages.enumerated()), id: \.element.id) { index, page in
                Group {
                    if let image = page.loadProcessedImage() {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 460)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var recognizedTextSection: some View {
        let text = document.combinedOCRText.trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Recognized Text", systemImage: "text.alignleft").font(.headline)
                Spacer()
                if isRunningOCR { ProgressView() }
            }
            if text.isEmpty {
                Text("No text recognized yet. Use the share menu to Run OCR.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(text)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Button { UIPasteboard.general.string = text } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    Button { shareText(text) } label: {
                        Label("Share Text", systemImage: "square.and.arrow.up")
                    }
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func makePDFData() -> Data {
        PDFService.makePDF(from: images(),
                           pageSize: SettingsStore.shared.pdfPageSize,
                           quality: SettingsStore.shared.pdfQuality)
    }

    private func sharePDF() {
        guard let url = ExportService.writePDFTemp(makePDFData(), baseName: document.name) else { return }
        shareItems = [url]
        showShare = true
    }

    private func shareText(_ text: String) {
        shareItems = [text]
        showShare = true
    }

    private func saveToFiles(asPDF: Bool) {
        if asPDF {
            guard let url = ExportService.writePDFTemp(makePDFData(), baseName: document.name) else { return }
            exportURLs = [url]
        } else {
            exportURLs = ExportService.writeJPGs(images(), baseName: document.name)
        }
        guard !exportURLs.isEmpty else { return }
        showFileExporter = true
    }

    private func saveToPhotos() {
        Task {
            do {
                try await ExportService.saveToPhotos(images())
                statusMessage = "Saved to Photos."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func runOCR() {
        isRunningOCR = true
        Task {
            for page in orderedPages {
                if let image = page.loadProcessedImage() {
                    page.ocrText = await OCRService.recognizeText(in: image)
                }
            }
            document.refreshMetadata()
            try? modelContext.save()
            isRunningOCR = false
            statusMessage = "Text recognition complete."
        }
    }
}
