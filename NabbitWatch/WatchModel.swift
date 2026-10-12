import Accessibility
import Foundation
import Observation
import WatchKit
import WidgetKit

/// What the watch shows, from the iPhone's latest `WatchSnapshot`. Taps change the list
/// right away and go to the iPhone, which sends back the real thing.
@Observable
final class WatchModel {
    static let shared = WatchModel()

    private(set) var snapshot = WatchSnapshot.saved
    /// The line shown for a moment after Done.
    private(set) var celebration: String?
    /// The line shown for a moment after a new reminder is saved.
    private(set) var savedLine: String?

    private var lastLine: String?

    var theme: Theme { snapshot.theme }

    /// A snapshot from the iPhone replaces whatever's here.
    func apply(_ data: Data) {
        guard let new = WatchSnapshot(data: data), new != snapshot else { return }
        snapshot = new
        new.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func perform(_ action: ReminderAction, on note: WatchSnapshot.Note) {
        guard let index = snapshot.notes.firstIndex(where: { $0.id == note.id }) else { return }
        switch action {
        case .done:
            snapshot.notes.remove(at: index)
            WKInterfaceDevice.current().play(.success)
            celebrate(clearedToday: !hasDueToday)
        case .snooze15:
            snapshot.notes[index].due = .now.addingTimeInterval(15 * 60)
            snapshot.notes[index].snoozeCount += 1
            WKInterfaceDevice.current().play(.click)
        case .tonight:
            snapshot.notes[index].due = WhenPreset.tonight.date() ?? .now.addingTimeInterval(60 * 60)
            snapshot.notes[index].snoozeCount += 1
            WKInterfaceDevice.current().play(.click)
        }
        snapshot.notes.sort { $0.due < $1.due }
        saveLocally()
        PhoneLink.shared.send(.act(action, reminder: note.id))
    }

    func create(verb: WatchSnapshot.VerbOption, thing: String, due: Date) {
        let text = "\(verb.title) \(thing)"
        let id = UUID()
        snapshot.notes.append(.init(id: id, text: text, thing: thing, due: due, snoozeCount: 0))
        snapshot.notes.sort { $0.due < $1.due }
        saveLocally()
        WKInterfaceDevice.current().play(.success)
        flash(\.savedLine, "\(snapshot.savedLead) \(text), \(due.dueDescription()).")
        PhoneLink.shared.send(.create(id: id, verbRaw: verb.raw, thing: thing, due: due))
    }

    func verb(_ raw: String) -> WatchSnapshot.VerbOption? {
        snapshot.verbs.first { $0.raw == raw }
    }

    /// Anything open that's due before tomorrow, slipped ones included.
    var hasDueToday: Bool {
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
        return snapshot.notes.contains { $0.due < tomorrow }
    }

    private func saveLocally() {
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// A rotating line, never the same one twice in a row.
    private func celebrate(clearedToday: Bool) {
        let line: String
        if clearedToday {
            line = snapshot.clearBoard
        } else {
            let choices = snapshot.doneLines.filter { $0 != lastLine }
            line = choices.randomElement() ?? "Handled."
            lastLine = line
        }
        flash(\.celebration, line)
    }

    private func flash(_ keyPath: ReferenceWritableKeyPath<WatchModel, String?>, _ line: String) {
        self[keyPath: keyPath] = line
        // VoiceOver reads the line, since it's only on screen for a moment.
        AccessibilityNotification.Announcement(line).post()
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            if self[keyPath: keyPath] == line {
                self[keyPath: keyPath] = nil
            }
        }
    }
}
