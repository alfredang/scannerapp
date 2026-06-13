import SwiftUI
import SwiftData

@main
struct DocumentScannerApp: App {

    /// Shared SwiftData container for documents and pages.
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: ScanDocument.self, ScanPage.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
    }
}
