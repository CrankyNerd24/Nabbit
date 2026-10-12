import Foundation

/// Salty needs 16+ and Sweary 18+, checked with the system's Declared Age Range.
/// The lowest age the person has shown is remembered, so the sheet appears once.
enum AgeGate {
    static let floorKey = "toneAgeFloor"
    /// The age gates asked for. Ranges must span at least two years.
    static let gates = (16, 18)

    static func minimumAge(for tone: Tone) -> Int? {
        switch tone {
        case .plain, .sassy: nil
        case .salty: 16
        case .sweary: 18
        }
    }

    /// The lowest age the shared range confirms: 0 until someone shares, or if under 16.
    static var ageFloor: Int {
        get { UserDefaults.nabbit.integer(forKey: floorKey) }
        set { UserDefaults.nabbit.set(newValue, forKey: floorKey) }
    }

    static func allows(_ tone: Tone) -> Bool {
        guard let minimum = minimumAge(for: tone) else { return true }
        return ageFloor >= minimum
    }
}
