import SwiftUI

/// One row of swatches, five themes. Tapping one applies it at once.
struct ThemeSwatches: View {
    @Binding var selection: String
    var size: CGFloat = 48

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Theme.all) { theme in
                Button {
                    selection = theme.id
                } label: {
                    Circle()
                        .fill(theme.tap1.color)
                        .overlay(Circle().fill(theme.alert.color).padding(size * 0.29))
                        .overlay {
                            if theme.id == selection {
                                Circle().stroke(.primary, lineWidth: 3)
                            }
                        }
                        .frame(width: size, height: size)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.name)
                .accessibilityAddTraits(theme.id == selection ? .isSelected : [])
            }
        }
    }
}
