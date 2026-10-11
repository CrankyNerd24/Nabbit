import SwiftUI

/// An sRGB color that knows which text color reads best on top of it.
struct ThemeColor: Hashable {
    let hex: UInt32

    static let ink = ThemeColor(hex: 0x1E1A16)
    static let paper = ThemeColor(hex: 0xFFF6EE)

    private var red: Double { Double((hex >> 16) & 0xFF) / 255 }
    private var green: Double { Double((hex >> 8) & 0xFF) / 255 }
    private var blue: Double { Double(hex & 0xFF) / 255 }

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue) }

    /// WCAG relative luminance.
    var luminance: Double {
        func linear(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    func contrast(with other: ThemeColor) -> Double {
        let (a, b) = (luminance, other.luminance)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Warm near-black or warm off-white, whichever contrasts better.
    var text: ThemeColor {
        contrast(with: .ink) >= contrast(with: .paper) ? .ink : .paper
    }
}
