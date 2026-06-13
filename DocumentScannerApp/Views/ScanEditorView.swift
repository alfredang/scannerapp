import SwiftUI

/// Navigation container for the post-capture editing flow: Preview → Filter → Export.
/// Owns the dismissal of the whole fullScreenCover via `onFinish`.
struct ScanEditorView: View {
    @Bindable var viewModel: ScannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PreviewView(viewModel: viewModel, onFinish: { dismiss() })
        }
    }
}
