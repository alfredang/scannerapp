import SwiftUI

/// Step 1 of the scan flow: review the captured pages, retake the scan,
/// add or delete pages, then continue to Adjust & Filters.
struct PreviewView: View {
    @Bindable var viewModel: ScannerViewModel
    /// Dismisses the entire editor flow (the fullScreenCover).
    var onFinish: () -> Void

    @State private var selectedIndex = 0
    @State private var showAddPages = false
    @State private var showRetake = false
    @State private var pendingRetake = false

    private var pages: [WorkingPage] { viewModel.working?.pages ?? [] }

    var body: some View {
        VStack(spacing: 0) {
            if pages.isEmpty {
                ContentUnavailableView("No Pages", systemImage: "doc",
                                       description: Text("Add a page to continue."))
            } else {
                stepHeader
                pager
                pageIndicator
                bottomBar
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
                Button("Retake") { showRetake = true }
                    .disabled(pages.isEmpty)
            }
        }
        .onAppear {
            // A Retake requested from Step 2 fires once that screen has popped back here.
            if pendingRetake {
                pendingRetake = false
                showRetake = true
            }
        }
        .fullScreenCover(isPresented: $showAddPages) {
            ScannerView { images in
                showAddPages = false
                viewModel.addPages(images)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showRetake) {
            ScannerView { images in
                showRetake = false
                guard !images.isEmpty else { return }
                viewModel.beginNewDocument(with: images)
                selectedIndex = 0
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Pieces

    private var stepHeader: some View {
        Text("Review your scan — Export, or Adjust first")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
    }

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

    private var bottomBar: some View {
        VStack(spacing: 8) {
            controlBar
            // Looks good → export straight away; Adjust & Filters is the optional detour.
            HStack(spacing: 12) {
                NavigationLink {
                    FilterView(viewModel: viewModel,
                               pageIndex: selectedIndex,
                               onFinish: onFinish,
                               onRetake: { pendingRetake = true })
                } label: {
                    Text("Adjust")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                NavigationLink {
                    ExportView(viewModel: viewModel, onFinish: onFinish)
                } label: {
                    Text("Export")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    private var controlBar: some View {
        HStack(spacing: 0) {
            control("Add Page", systemImage: "plus.viewfinder") {
                showAddPages = true
            }
            control("Delete", systemImage: "trash", role: .destructive) {
                deleteCurrentPage()
            }
        }
        .padding(.vertical, 10)
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
