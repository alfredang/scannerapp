import SwiftUI

/// A single row in the library list: cover thumbnail, name, date, and page count.
struct DocumentRow: View {
    let document: ScanDocument

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
                .frame(width: 52, height: 68)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: document.createdAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("\(document.pageCount) \(document.pageCount == 1 ? "page" : "pages")",
                      systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.name), \(document.pageCount) pages, created \(Self.dateFormatter.string(from: document.createdAt))")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = document.coverThumbnail() {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Image(systemName: "doc.text.image")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
