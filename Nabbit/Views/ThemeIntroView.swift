import SwiftUI

/// Shown once at first launch: pick colors, see them on real notes, start.
/// The pick applies the moment it's tapped; Start just moves on.
struct ThemeIntroView: View {
    static let shownKey = "themeIntroShown"

    @AppStorage(Theme.storageKey, store: .nabbit) private var themeID = Theme.standard.id
    let onStart: () -> Void

    private var theme: Theme { Theme.named(themeID) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Text("Pick your colors")
                    .font(.largeTitle.bold())
                Text("Change them any time in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                StickyNote(text: "Call", fill: theme.tap1)
                StickyNote(text: "Dentist", fill: theme.tap2)
                StickyNote(text: "Tonight", fill: theme.tap3)
            }
            .accessibilityHidden(true)

            ThemeSwatches(selection: $themeID, size: 54)
            Text(theme.name)
                .font(.headline)

            Spacer(minLength: 0)
            Button(action: onStart) {
                Text("Start")
                    .font(.title2.bold())
                    .foregroundStyle(theme.done.text.color)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(theme.done.color, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(NoteButtonStyle())
        }
        .padding(24)
        .animation(.snappy, value: themeID)
    }
}

#Preview {
    ThemeIntroView {}
}
