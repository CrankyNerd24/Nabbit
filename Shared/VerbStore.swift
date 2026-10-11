import Foundation

/// The verb grid as the person set it up: their own verbs, the order, and what's hidden.
/// Kept as JSON in `UserDefaults.nabbit` so views can watch it with `@AppStorage(VerbStore.key)`
/// and Siri and the widgets read the same list.
nonisolated enum VerbStore {
    static let key = "verbLayout"

    struct Layout: Codable, Equatable {
        /// Raw values of added verbs, oldest first.
        var custom: [String] = []
        /// Raw values in the person's order. Verbs missing from it go at the end.
        var order: [String] = []
        var hidden: [String] = []
    }

    static func layout(from json: String) -> Layout {
        guard let data = json.data(using: .utf8),
              let layout = try? JSONDecoder().decode(Layout.self, from: data) else { return Layout() }
        return layout
    }

    static var layout: Layout {
        get { layout(from: UserDefaults.nabbit.string(forKey: key) ?? "") }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.nabbit.set(String(decoding: data, as: UTF8.self), forKey: key)
        }
    }

    /// Every verb, hidden ones included, in the person's order.
    static func all(in layout: Layout = layout) -> [Verb] {
        let known = Verb.builtIns + layout.custom.compactMap(Verb.init(rawValue:))
        let ordered = layout.order.compactMap { raw in known.first { $0.rawValue == raw } }
        return ordered + known.filter { !ordered.contains($0) }
    }

    /// The verbs on the grid, for Siri, and for the mic.
    static func visible(in layout: Layout = layout) -> [Verb] {
        all(in: layout).filter { !layout.hidden.contains($0.rawValue) }
    }

    /// Adds a verb, or brings back a matching one that was hidden.
    @discardableResult
    static func add(_ word: String) -> Verb? {
        let word = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return nil }
        var layout = self.layout
        if let existing = all(in: layout).first(where: { $0.title.localizedCaseInsensitiveCompare(word) == .orderedSame }) {
            layout.hidden.removeAll { $0 == existing.rawValue }
            self.layout = layout
            return existing
        }
        let verb = Verb.custom(word)
        layout.custom.append(verb.rawValue)
        self.layout = layout
        return verb
    }

    /// Removes a verb the person added. Built-ins can only be hidden.
    static func remove(_ verb: Verb) {
        guard !verb.isBuiltIn else { return }
        var layout = self.layout
        layout.custom.removeAll { $0 == verb.rawValue }
        layout.order.removeAll { $0 == verb.rawValue }
        layout.hidden.removeAll { $0 == verb.rawValue }
        self.layout = layout
    }

    /// Hides or shows a verb. The last visible verb can't be hidden.
    static func setHidden(_ hidden: Bool, for verb: Verb) {
        var layout = self.layout
        if hidden {
            guard visible(in: layout).count > 1, !layout.hidden.contains(verb.rawValue) else { return }
            layout.hidden.append(verb.rawValue)
        } else {
            layout.hidden.removeAll { $0 == verb.rawValue }
        }
        self.layout = layout
    }

    static func setOrder(_ verbs: [Verb]) {
        var layout = self.layout
        layout.order = verbs.map(\.rawValue)
        self.layout = layout
    }
}
