#if DEBUG
import SwiftUI
import SwiftData

/// DEBUG-only sample-data seeding for App Store screenshots and local testing.
/// Activated only when the process is launched with `SCANNER_SEED_DEMO=1`.
/// Never compiled into Release builds.
@MainActor
enum DemoSeed {

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["SCANNER_SEED_DEMO"] == "1"
    }

    /// Populates a few realistic documents if the library is empty.
    static func seedIfNeeded(_ context: ModelContext) {
        guard isEnabled else { return }
        let existing = (try? context.fetch(FetchDescriptor<ScanDocument>())) ?? []
        guard existing.isEmpty else { return }

        let samples: [(String, [String], FilterType)] = [
            ("Invoice — Acme Studio", ["INVOICE", "Acme Studio Pte Ltd", "Bill To: Tertiary Infotech",
                                       "Item            Qty     Amount",
                                       "Design work      12     $1,440.00",
                                       "Consulting        6       $900.00",
                                       "Total                   $2,340.00"], .whiteDocument),
            ("Meeting Notes", ["Project Kickoff — 13 Jun 2026", "Attendees: Alfred, Mei, Raj",
                               "1. Scope confirmed for v1 release",
                               "2. Scanner uses VisionKit + on-device OCR",
                               "3. Ship to App Store this week",
                               "Action: finalise screenshots"], .autoEnhance),
            ("Cafe Receipt", ["THE DAILY GRIND", "Flat White        $5.50", "Croissant         $4.00",
                              "Sparkling Water   $3.00", "----------------------",
                              "TOTAL            $12.50", "Thank you!"], .receipt),
        ]

        for (title, lines, filter) in samples {
            let image = renderDocument(title: title, lines: lines)
            let page = WorkingPage(original: image, filter: filter)
            page.ocrText = ([title] + lines).joined(separator: "\n")
            let working = WorkingDocument(name: title, pages: [page])
            let doc = StorageService.persist(working, into: context)
            doc.combinedOCRText = page.ocrText
        }
        try? context.save()
    }

    /// Draws a paper-like document image with a title bar and text lines.
    private static func renderDocument(title: String, lines: [String]) -> UIImage {
        let size = CGSize(width: 1000, height: 1414)   // A4 ratio
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(white: 0.97, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let margin: CGFloat = 90
            // Title bar
            UIColor(red: 0.18, green: 0.40, blue: 0.85, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: margin, y: 110, width: size.width - margin * 2, height: 90),
                         cornerRadius: 10).fill()
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 44),
                .foregroundColor: UIColor.white
            ]
            (title as NSString).draw(at: CGPoint(x: margin + 24, y: 130), withAttributes: titleAttrs)

            // Body lines
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 34),
                .foregroundColor: UIColor(white: 0.15, alpha: 1)
            ]
            var y: CGFloat = 280
            for line in lines {
                (line as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttrs)
                y += 64
            }
        }
    }
}
#endif
