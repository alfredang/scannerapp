import SwiftUI

/// Filter preset picker with a large live preview and a thumbnail strip.
/// Applies the chosen filter to the selected page (or to all pages).
struct FilterView: View {
    @Bindable var viewModel: ScannerViewModel
    let pageIndex: Int

    @State private var previews: [FilterType: UIImage] = [:]

    private var page: WorkingPage? {
        let pages = viewModel.working?.pages ?? []
        return pages.indices.contains(pageIndex) ? pages[pageIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if let page {
                Image(uiImage: page.processedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))

                filterStrip(page: page)
            } else {
                ContentUnavailableView("No Page", systemImage: "photo")
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Apply to All Pages") {
                        if let filter = page?.filter { viewModel.applyFilterToAll(filter) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: pageIndex) { await buildPreviews() }
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
