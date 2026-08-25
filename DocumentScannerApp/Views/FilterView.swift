import SwiftUI

/// Step 2 of the scan flow: adjust (rotate) and pick a filter for the page,
/// with a large live preview and a thumbnail strip, then continue to Save & Share.
struct FilterView: View {
    @Bindable var viewModel: ScannerViewModel
    let pageIndex: Int
    /// Dismisses the entire editor flow (passed through to Save & Share).
    var onFinish: () -> Void
    /// Asks Step 1 to relaunch the scanner once this screen has popped.
    var onRetake: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var previews: [FilterType: UIImage] = [:]

    private var page: WorkingPage? {
        let pages = viewModel.working?.pages ?? []
        return pages.indices.contains(pageIndex) ? pages[pageIndex] : nil
    }

    private var pageCount: Int { viewModel.working?.pages.count ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            if let page {
                stepHeader

                Image(uiImage: page.processedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))

                adjustBar(page: page)
                filterStrip(page: page)
                nextButton
            } else {
                ContentUnavailableView("No Page", systemImage: "photo")
            }
        }
        .navigationTitle("Adjust & Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if onRetake != nil {
                    Button("Retake") {
                        onRetake?()
                        dismiss()
                    }
                }
            }
        }
        .task(id: pageIndex) { await buildPreviews() }
    }

    // MARK: - Pieces

    private var stepHeader: some View {
        Text("Adjust and filter, then export")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
    }

    private func adjustBar(page: WorkingPage) -> some View {
        HStack {
            Button {
                page.rotateClockwise()
            } label: {
                Label("Rotate", systemImage: "rotate.right")
            }
            Spacer()
            if pageCount > 1 {
                Button("Apply Filter to All Pages") {
                    viewModel.applyFilterToAll(page.filter)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal)
        .padding(.top, 10)
        .background(.bar)
    }

    private func filterStrip(page: WorkingPage) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(FilterType.allCases) { filter in
                    Button {
                        page.filter = filter
                    } label: {
                        FilterThumbnail(filter: filter,
                                        preview: previews[filter] ?? page.original,
                                        isSelected: page.filter == filter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.bar)
    }

    private var nextButton: some View {
        NavigationLink {
            ExportView(viewModel: viewModel, onFinish: onFinish)
        } label: {
            Text("Export")
                .bold()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(.bar)
    }

    /// Renders a small preview for each filter from a downscaled copy of the page.
    private func buildPreviews() async {
        guard let original = page?.original else { return }
        let small = StorageService.makeThumbnail(original, maxDimension: 140)
        guard let cg = small.cgImage else { return }
        var result: [FilterType: UIImage] = [:]
        for filter in FilterType.allCases {
            let filtered = ImageProcessor.shared.apply(filter, to: cg)
            result[filter] = UIImage(cgImage: filtered)
        }
        previews = result
    }
}
