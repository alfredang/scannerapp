import SwiftUI

/// Presents the appropriate capture UI: VisionKit's document camera on device,
/// or the photo importer where the camera is unavailable (Simulator).
struct ScannerView: View {
    var onComplete: ([UIImage]) -> Void

    var body: some View {
        if ScannerSupport.isAvailable {
            DocumentCameraView(onComplete: onComplete)
                .ignoresSafeArea()
        } else {
            PhotoImportView(onComplete: onComplete)
                .ignoresSafeArea()
        }
    }
}
