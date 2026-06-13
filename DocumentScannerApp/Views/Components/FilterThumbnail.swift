import SwiftUI

/// A selectable filter preset cell showing a live preview of the filter applied
/// to a small sample of the page.
struct FilterThumbnail: View {
    let filter: FilterType
    let preview: UIImage          // already filtered, downscaled preview
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(uiImage: preview)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color(.separator),
                                lineWidth: isSelected ? 2.5 : 0.5)
                )
            Text(filter.displayName)
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filter.displayName) filter")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
