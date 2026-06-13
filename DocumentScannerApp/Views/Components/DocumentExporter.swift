import SwiftUI
import UIKit

/// Wraps `UIDocumentPickerViewController(forExporting:)` so the user can save files to
/// **Files** or **iCloud Drive** — no iCloud entitlement required.
struct DocumentExporter: UIViewControllerRepresentable {
    let urls: [URL]
    var onFinish: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFinish: (() -> Void)?
        init(onFinish: (() -> Void)?) { self.onFinish = onFinish }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onFinish?()
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onFinish?()
        }
    }
}
