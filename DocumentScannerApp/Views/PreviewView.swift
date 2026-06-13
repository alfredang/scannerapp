import SwiftUI

/// Shows captured pages in a paged carousel with per-page rotate / delete,
/// add-more-pages, a path to filters, and a path to export.
struct PreviewView: View {
    @Bindable var viewModel: ScannerViewModel
    /// Dismisses the entire editor flow (the fullScreenCover).
    var onFinish: () -> Void

    @State private var selectedIndex = 0
    @State private var showAddPages = false

    private var pages: [WorkingPage] { viewModel.working?.pages ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            if pages.isEmpty {
                ContentUnavailableView("No Pages", systemImage: "doc",
                                       description: Text("Add a page to continue."))
            } else {
                pager
                pageIndicator
                controlBar
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", role: .cancel) {
                    viewModel.discard()
                    onFinish()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExportView(viewModel: viewModel, onFinish: onFinish)
                } label: {
                    Text("Next").bold()
                }
                .disabled(pages.isEmpty)
            }
        }
        .fullScreenCover(isPresented: $showAddPages) {
            ScannerView { images in
                showAddPages = false
                viewModel.addPages(images)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Pieces

    private var pager: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                Image(uiImage: page.processedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .tag(index)
                    .accessibilityLabel("Page \(index + 1) of \(pages.count)")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground))
    }

    private var pageIndicator: some View {
        Text("Page \(min(selectedIndex + 1, pages.count)) of \(pages.count)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
    }

    private var controlBar: some View {
        HStack(spacing: 0) {
            control("Rotate", systemImage: "rotate.right") {
                guard pages.indices.contains(selectedIndex) else { return }
                pages[selectedIndex].rotateClockwise()
            }
            NavigationLink {
                if pages.indices.contains(selectedIndex) {
                    FilterView(viewModel: viewModel, pageIndex: selectedIndex)
                }
            } label: {
                controlLabel("Filters", systemImage: "wand.and.stars")
            }
            .buttonStyle(.plain)
            control("Add Page", systemImage: "plus.viewfinder") {
                showAddPages = true
            }
            control("Delete", systemImage: "trash", role: .destructive) {
                deleteCurrentPage()
            }
        }
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func control(_ title: String, systemImage: String,
                         role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            controlLabel(title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red : Color.accentColor)
    }

    private func controlLabel(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.title3)
            Text(title).font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteCurrentPage() {
        guard pages.indices.contains(selectedIndex) else { return }
        let page = pages[selectedIndex]
        viewModel.deletePage(page)
        let newCount = viewModel.working?.pages.count ?? 0
        if newCount == 0 {
            viewModel.discard()
            onFinish()
        } else {
            selectedIndex = min(selectedIndex, newCount - 1)
        }
    }
}
