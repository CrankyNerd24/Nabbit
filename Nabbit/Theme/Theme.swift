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

    // Ember and Berry alerts are lifted a shade from the brief's #D85A30 and
    // #D4537E, which fell just short of 4.5:1 with either text color.
    static let ember = Theme(id: "ember", name: "Ember",
                             tap1: .init(hex: 0xFAC775), tap2: .init(hex: 0xF5C4B3), tap3: .init(hex: 0xF0997B),
                             alert: .init(hex: 0xD85C32), done: .init(hex: 0xFAC775))
    static let workshop = Theme(id: "workshop", name: "Workshop",
                                tap1: .init(hex: 0xE3CBA0), tap2: .init(hex: 0xC9A979), tap3: .init(hex: 0xB4B2A9),
                                alert: .init(hex: 0x2C2C2A), done: .init(hex: 0xEF9F27))
    static let forest = Theme(id: "forest", name: "Forest",
                              tap1: .init(hex: 0xC0DD97), tap2: .init(hex: 0x97C459), tap3: .init(hex: 0xD6C793),
                              alert: .init(hex: 0x27500A), done: .init(hex: 0xEF9F27))
    static let slate = Theme(id: "slate", name: "Slate",
                             tap1: .init(hex: 0xB5D4F4), tap2: .init(hex: 0xA9B8C6), tap3: .init(hex: 0xD3D1C7),
                             alert: .init(hex: 0x0C447C), done: .init(hex: 0xEF9F27))
    static let berry = Theme(id: "berry", name: "Berry",
                             tap1: .init(hex: 0xF4C0D1), tap2: .init(hex: 0xED93B1), tap3: .init(hex: 0xF0997B),
                             alert: .init(hex: 0xD55681), done: .init(hex: 0xFAC775))

    static let all: [Theme] = [ember, workshop, forest, slate, berry]

    static func named(_ id: String) -> Theme {
        all.first { $0.id == id } ?? ember
    }
}
