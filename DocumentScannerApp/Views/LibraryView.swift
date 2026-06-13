import SwiftUI
import SwiftData

/// Full document library: searchable list with open / rename / duplicate / delete / share.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanDocument.createdAt, order: .reverse) private var documents: [ScanDocument]

    @State private var viewModel = LibraryViewModel()
    @State private var renameTarget: ScanDocument?
    @State private var renameText = ""
    @State private var shareItems: [Any] = []
    @State private var showShare = false

    private var filtered: [ScanDocument] { viewModel.filter(documents) }

    var body: some View {
        List {
            ForEach(filtered) { document in
                NavigationLink {
                    DocumentDetailView(document: document)
                } label: {
                    DocumentRow(document: document)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.delete(document, context: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button { beginRename(document) } label: { Label("Rename", systemImage: "pencil") }
                    Button { viewModel.duplicate(document, context: modelContext) } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    Button { sharePDF(document) } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) {
                        viewModel.delete(document, context: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Library")
        .searchable(text: $viewModel.searchText, prompt: "Search by name or text")
        .overlay {
            if documents.isEmpty {
                ContentUnavailableView("No Documents", systemImage: "folder",
                                       description: Text("Your scanned documents will appear here."))
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .alert("Rename Document", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } })
        ) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renameTarget = nil }
            Button("Save") {
                if let target = renameTarget {
                    viewModel.rename(target, to: renameText, context: modelContext)
                }
                renameTarget = nil
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    private func beginRename(_ document: ScanDocument) {
        renameText = document.name
        renameTarget = document
    }

    private func sharePDF(_ document: ScanDocument) {
        let images = document.orderedPages.compactMap { $0.loadProcessedImage() }
        guard !images.isEmpty else { return }
        let data = PDFService.makePDF(from: images,
                                      pageSize: SettingsStore.shared.pdfPageSize,
                                      quality: SettingsStore.shared.pdfQuality)
        if let url = ExportService.writePDFTemp(data, baseName: document.name) {
            shareItems = [url]
            showShare = true
        }
    }
}
