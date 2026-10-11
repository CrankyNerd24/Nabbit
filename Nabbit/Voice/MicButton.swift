import SwiftUI
import UIKit

/// The big mic above the verb grid: say the whole reminder, or as much of it as you know.
struct MicButton: View {
    let theme: Theme
    /// Words to listen for: the verbs and saved things.
    let hints: [String]
    let onHeard: (String) -> Void

    @State private var listener = SpeechListener()
    @Environment(\.openURL) private var openURL

    private var listening: Bool { listener.state == .listening }

    var body: some View {
        Button {
            tapped()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: listening ? "waveform" : "mic.fill")
                    .font(.title.bold())
                    .symbolEffect(.variableColor.iterative, isActive: listening)
                    .frame(width: 36)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .foregroundStyle(theme.alert.text.color)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(theme.alert.color, in: .rect(cornerRadius: 6))
            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
        }
        .buttonStyle(NoteButtonStyle())
        .accessibilityLabel(listening ? "Stop listening" : "Say a reminder")
        .accessibilityValue(listener.transcript)
    }

    private var title: String {
        switch listener.state {
        case .listening:
            listener.transcript.isEmpty ? "Listening…" : listener.transcript
        case .needsPermission:
            "Tap to turn on the mic in Settings"
        case .unavailable:
            "Voice isn't available right now. Tap to try again"
        case .idle:
            "Say it: \u{201C}call the dentist tomorrow\u{201D}"
        }
    }

    private func tapped() {
        switch listener.state {
        case .listening:
            listener.stop()
        case .needsPermission:
            // Try again first, in case it was turned on in Settings since.
            Task {
                await listener.start(hints: hints, onFinish: onHeard)
                if listener.state == .needsPermission, let settings = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settings)
                }
            }
        case .idle, .unavailable:
            Task { await listener.start(hints: hints, onFinish: onHeard) }
        }
    }
}
