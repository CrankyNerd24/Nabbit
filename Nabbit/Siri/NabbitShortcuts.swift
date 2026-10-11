import AppIntents

/// Every phrase names the app. Apple allows one variable per phrase, so Siri
/// asks for the rest ("Call who?", "When?"). Each shortcut also needs one phrase
/// without a reminder in it: iOS skips reminder phrases while there are none.
nonisolated struct NabbitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CreateReminderIntent(), phrases: [
            "Remind me in \(.applicationName) to \(\.$verb)",
            "\(.applicationName), \(\.$verb)",
            "New \(.applicationName) reminder",
            "Remind me in \(.applicationName)",
        ], shortTitle: "New reminder", systemImageName: "note.text.badge.plus")

        AppShortcut(intent: DoneReminderIntent(), phrases: [
            "\(.applicationName), done with \(\.$reminder)",
            "I did \(\.$reminder) in \(.applicationName)",
            "Done in \(.applicationName)",
            "\(.applicationName), I'm done",
        ], shortTitle: "Mark done", systemImageName: "checkmark.circle")

        AppShortcut(intent: SnoozeReminderIntent(), phrases: [
            "\(.applicationName), snooze that",
            "Snooze \(\.$reminder) in \(.applicationName)",
        ], shortTitle: "Snooze", systemImageName: "clock")

        AppShortcut(intent: MoveReminderIntent(), phrases: [
            "Move \(\.$reminder) in \(.applicationName)",
            "\(.applicationName), move \(\.$reminder)",
            "Move a reminder in \(.applicationName)",
        ], shortTitle: "Move reminder", systemImageName: "calendar")

        AppShortcut(intent: CheckListIntent(), phrases: [
            "What's on my \(.applicationName) list",
            "What's next in \(.applicationName)",
        ], shortTitle: "What's on my list", systemImageName: "list.bullet")

        AppShortcut(intent: CancelReminderIntent(), phrases: [
            "Cancel \(\.$reminder) in \(.applicationName)",
            "\(.applicationName), cancel \(\.$reminder)",
            "Cancel a reminder in \(.applicationName)",
        ], shortTitle: "Cancel reminder", systemImageName: "trash")
    }
}
