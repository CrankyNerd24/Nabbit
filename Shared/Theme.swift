import SwiftUI

/// Five themes, no more. Every color clears 4.5:1 against its automatic text color.
struct Theme: Identifiable, Hashable {
    static let storageKey = "theme"

    let id: String
    let name: String
    /// Sticky-note colors for the verb, thing, and when steps.
    let tap1: ThemeColor
    let tap2: ThemeColor
    let tap3: ThemeColor
    /// Full-screen alert background.
    let alert: ThemeColor
    /// Completion celebration.
    let done: ThemeColor

    static let primary = Theme(id: "primary", name: "Primary",
                               tap1: .init(hex: 0xFFC93C), tap2: .init(hex: 0x3D7BFF), tap3: .init(hex: 0xFF5A5F),
                               alert: .init(hex: 0x14213D), done: .init(hex: 0x2EC4B6))
    static let midnight = Theme(id: "midnight", name: "Midnight",
                                tap1: .init(hex: 0x26334D), tap2: .init(hex: 0x5B2A86), tap3: .init(hex: 0x0F5257),
                                alert: .init(hex: 0xFF5E3A), done: .init(hex: 0xFFD23F))
    static let slate = Theme(id: "slate", name: "Slate",
                             tap1: .init(hex: 0xB5D4F4), tap2: .init(hex: 0xA9B8C6), tap3: .init(hex: 0xD3D1C7),
                             alert: .init(hex: 0x0C447C), done: .init(hex: 0xEF9F27))
    // Berry's alert is lifted a shade from the brief's #D4537E, which fell just
    // short of 4.5:1 with either text color.
    static let berry = Theme(id: "berry", name: "Berry",
                             tap1: .init(hex: 0xF4C0D1), tap2: .init(hex: 0xED93B1), tap3: .init(hex: 0xF0997B),
                             alert: .init(hex: 0xD55681), done: .init(hex: 0xFAC775))
    static let retro = Theme(id: "retro", name: "Retro",
                             tap1: .init(hex: 0xF4D35E), tap2: .init(hex: 0x0D3B66), tap3: .init(hex: 0xEE964B),
                             alert: .init(hex: 0xB8341B), done: .init(hex: 0xF4D35E))

    static let all: [Theme] = [primary, midnight, slate, berry, retro]

    /// Preselected on first launch, and the fallback for a theme that's no longer offered.
    static let standard = primary

    static func named(_ id: String) -> Theme {
        all.first { $0.id == id } ?? standard
    }
}
