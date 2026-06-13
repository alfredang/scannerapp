import SwiftUI
import UIKit

/// SwiftUI wrapper around `UIActivityViewController` — the native iOS share sheet
/// (AirDrop, Messages, Mail, WhatsApp, Print, Save to Files, etc.).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in completion?() }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
