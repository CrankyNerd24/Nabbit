import Foundation
import CoreHaptics

/// A firm thump and a double tap when something's done; a light tap for small things.
enum Haptics {
    private static var engine: CHHapticEngine?

    static func play(_ size: Celebration.Size) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            // A fresh engine each time: celebrations are rare, and it avoids
            // handling the engine's stop and reset callbacks.
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            try engine.start()
            let pattern = try CHHapticPattern(events: events(for: size), parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private static func events(for size: Celebration.Size) -> [CHHapticEvent] {
        switch size {
        case .small:
            [tap(at: 0, intensity: 0.55, sharpness: 0.5)]
        case .medium, .big, .clearBoard:
            [tap(at: 0, intensity: 1, sharpness: 0.2),
             tap(at: 0.16, intensity: 0.7, sharpness: 0.8),
             tap(at: 0.26, intensity: 0.7, sharpness: 0.8)]
        }
    }

    private static func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                   CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: time)
    }
}
