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
            [tap(at: 0, intensity: 0.8, sharpness: 0.6)]
        case .medium, .big, .clearBoard:
            // The thump: a short full-strength buzz under a hard hit, then a crisp double tap.
            [thump(at: 0, duration: 0.09),
             tap(at: 0, intensity: 1, sharpness: 0.6),
             tap(at: 0.2, intensity: 1, sharpness: 0.9),
             tap(at: 0.32, intensity: 1, sharpness: 0.9)]
        }
    }

    private static func thump(at time: TimeInterval, duration: TimeInterval) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                                   CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)],
                      relativeTime: time, duration: duration)
    }

    private static func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                   CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                      relativeTime: time)
    }
}
