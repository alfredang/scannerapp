import SwiftUI
import SwiftData

/// Root screen: prominent Scan button, recent documents, and entry points to the
/// full library and settings.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanDocument.createdAt, order: .reverse) private var documents: [ScanDocument]

    @State private var scannerVM = ScannerViewModel()
    @State private var showCapture = false
    @State private var showEditor = false
    @State private var showSettings = false

    private var recentDocuments: [ScanDocument] { Array(documents.prefix(5)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scanButton

                    if documents.isEmpty {
                        emptyState
                    } else {
                        recentSection
                    }

                    footer
                }
                .padding()
            }
            .navigationTitle(Constants.appName)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        LibraryView()
                    } label: {
                        Label("Library", systemImage: "folder")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCapture) {
                ScannerView { images in
                    showCapture = false
                    guard !images.isEmpty else { return }
                    scannerVM.beginNewDocument(with: images)
                    showEditor = true
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showEditor) {
                ScanEditorView(viewModel: scannerVM)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { SettingsView() }
            }
            .task {
                #if DEBUG
                DemoSeed.seedIfNeeded(modelContext)
                #endif
            }
        }
    }

    // MARK: - Sections

    private var scanButton: some View {
        Button {
            showCapture = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 44, weight: .semibold))
                Text("Scan Document")
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a new document")
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.title2.bold())
                Spacer()
                NavigationLink("See All") { LibraryView() }
                    .font(.subheadline)
            }
            VStack(spacing: 0) {
                ForEach(recentDocuments) { document in
                    NavigationLink {
                        DocumentDetailView(document: document)
                    } label: {
                        DocumentRow(document: document)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if document.id != recentDocuments.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var footer: some View {
        Text("Powered by Tertiary Infotech Academy Pte Ltd")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .accessibilityLabel("Powered by Tertiary Infotech Academy Pte Ltd")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No scans yet")
                .font(.headline)
            Text("Tap Scan Document to create your first scan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
