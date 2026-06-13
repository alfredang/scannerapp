import SwiftUI
import VisionKit
import PhotosUI
import UniformTypeIdentifiers

/// Whether the device supports VisionKit's document camera (false on Simulator).
enum ScannerSupport {
    @MainActor static var isAvailable: Bool { VNDocumentCameraViewController.isSupported }
}

/// SwiftUI wrapper around `VNDocumentCameraViewController` — Apple's built-in document
/// scanner with edge detection, perspective correction, multi-page capture, manual corner
/// adjustment, retake, flash, and auto-capture.
struct DocumentCameraView: UIViewControllerRepresentable {
    /// Called with the captured page images (in scan order), or empty on cancel.
    var onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for index in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: index))
            }
            onComplete(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onComplete([])
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            print("DocumentCameraView error: \(error)")
            onComplete([])
        }
    }
}

/// Photo-library importer used as a fallback where the document camera is unavailable
/// (e.g. the Simulator), so the full scan → filter → export pipeline stays testable.
struct PhotoImportView: UIViewControllerRepresentable {
    var onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0   // unlimited → multi-page
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    @MainActor
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onComplete: ([UIImage]) -> Void
        init(onComplete: @escaping ([UIImage]) -> Void) { self.onComplete = onComplete }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else { onComplete([]); return }
            let providers = results.map(\.itemProvider)
            Task { @MainActor in
                var images: [UIImage] = []
                for provider in providers {
                    // Load raw bytes (Sendable) off-main, then build the UIImage here.
                    let identifier = provider.registeredTypeIdentifiers.first {
                        UTType($0)?.conforms(to: .image) ?? false
                    } ?? UTType.image.identifier
                    let data: Data? = await withCheckedContinuation { continuation in
                        provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, _ in
                            continuation.resume(returning: data)
                        }
                    }
                    if let data, let image = UIImage(data: data) { images.append(image) }
                }
                onComplete(images)
            }
        }
    }
}
