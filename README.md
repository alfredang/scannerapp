# Scanner — Native iOS Document Scanner

A clean, fast, fully-offline document scanner for iOS 18+, built with **Swift 6**, **SwiftUI**,
and **MVVM**. Scan with VisionKit, enhance with Core Image filters, recognize text with Vision
OCR, and export as PDF or JPG to Photos, Files, or iCloud Drive — all on-device, no backend.

## Features

- **Scanning** — VisionKit document camera: auto edge detection, perspective correction,
  auto-crop, multi-page capture, manual corner adjustment, retake, flash, auto-capture.
- **8 enhancement filters** (Core Image) — Original, Auto, White Document, Black & White,
  Denoise, Brighten, Sharpen Text, Receipt — with live preview, per-page or apply-to-all.
- **OCR** (Vision) — recognize text on every page; copy, share, and **search your library by content**.
- **Export** — single/multi-page PDF (A4 / Letter / fit, adjustable quality) and high-quality JPG.
- **Destinations** — Photos, Files, iCloud Drive (via document picker), local app library.
- **Share** — native share sheet (AirDrop, Messages, Mail, WhatsApp, Print, …).
- **Library** — SwiftData-backed: thumbnails, name, date, page count; rename, delete, duplicate,
  share, export, search.
- **Accessibility** — Dynamic Type, VoiceOver labels, Dark/Light, semantic colors.

## Architecture (MVVM)

```
App/          DocumentScannerApp.swift   — @main, SwiftData ModelContainer
Models/       ScanDocument, ScanPage (@Model), FilterType
Services/     ScannerService (VisionKit), OCRService (Vision), PDFService,
              ExportService (Photos/Files), StorageService (files + SwiftData)
ViewModels/   ScannerViewModel (capture→edit→save), LibraryViewModel
Views/        Home, Scanner, Preview, Filter, Export, Library, DocumentDetail,
              Settings, ScanEditor + Components (ShareSheet, DocumentExporter, …)
Utilities/    ImageProcessor (Core Image), SettingsStore, Constants
Resources/    Assets.xcassets (AppIcon, AccentColor)
```

- **Persistence**: document/page **metadata** in SwiftData; page **images, thumbnails, and PDFs**
  as files under Application Support (`Constants.scansDirectory`). Models store filenames only.
- **Swift 6 strict concurrency**: ViewModels are `@MainActor @Observable`; heavy work (Core Image,
  OCR, PDF) runs in async services and crosses actor boundaries via `Data`/`CGImage`.

## Build & Run

Requires **Xcode 26+** and **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** (`brew install xcodegen`).

```bash
xcodegen generate          # regenerate DocumentScannerApp.xcodeproj from project.yml
open DocumentScannerApp.xcodeproj
# or from the CLI:
xcodebuild -project DocumentScannerApp.xcodeproj -scheme DocumentScannerApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO
```

The project uses **automatic signing with an empty team**, so **Simulator builds need no Apple
account**. To run on a physical device, open the target → Signing & Capabilities → select your Team.

### Simulator note
The Simulator has no camera, so the **Scan** button falls back to the **photo picker**
(`PhotoImportView`) — pick image(s) to drive the full filter → OCR → export pipeline. A sample
document image is included in this Simulator's Photos for quick testing.

## Manual test checklist (device)

- Scan a page; verify edge detection, perspective correction, auto-crop.
- Multi-page: add pages, reorder via order, delete a page, retake.
- Apply each of the 8 filters; "Apply to All Pages".
- Rotate a page; confirm it persists.
- Run OCR; copy and share the recognized text; search the library by that text.
- Export PDF (A4/Letter/fit, quality slider) and JPG.
- Save to Photos, Files, iCloud Drive; Share via the share sheet; Print.
- Library: rename, duplicate, delete, share.

## App Store submission

See [`.claude/skills/app-store-submission/`](.claude/skills/app-store-submission/) — an
API-first submission workflow already filled in for this app (bundle id
`com.scannerapp.DocumentScanner`, Productivity category, Camera + Photo-Add permissions,
universal iPhone/iPad, "Data Not Collected"). Two design-reference skills are bundled too:
`mobile-ios-design` and `ipados-design-guidelines`.

> **App icon note:** the bundled `AppIcon-1024.png` is a generated placeholder that currently
> has an alpha channel. App Store Connect requires a **flat, no-alpha** 1024 icon — flatten it
> (or regenerate via the submission skill's `make_app_icon.swift`) before archiving for release.

## License

MIT
