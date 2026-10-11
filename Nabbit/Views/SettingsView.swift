import SwiftData
import SwiftUI
import WidgetKit

/// Every change applies the moment it's made. No Save button.
struct SettingsView: View {
    @AppStorage(Theme.storageKey, store: .nabbit) private var themeID = Theme.ember.id
    @AppStorage(DefaultTimes.tonightHourKey, store: .nabbit) private var tonightHour = 19
    @AppStorage(DefaultTimes.morningHourKey, store: .nabbit) private var morningHour = 9
    @AppStorage(Tone.storageKey, store: .nabbit) private var tone = Tone.plain
    @AppStorage(NudgeTiming.intervalKey, store: .nabbit) private var nudgeMinutes = NudgeTiming.defaultMinutes
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    ThemeSwatches(selection: $themeID)
                        .padding(.vertical, 4)
                }

                Section {
                    Picker("Tone", selection: $tone) {
                        ForEach(Tone.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    // Nudges already scheduled pick up the new wording.
                    .onChange(of: tone) { Nudges.shared.reschedule() }
                } header: {
                    Text("Tone")
                } footer: {
                    Text(tone.sample)
                }

                Section {
                    NavigationLink("Edit verbs") {
                        VerbEditorView()
                    }
                } header: {
                    Text("Verbs")
                } footer: {
                    Text("Add your own, hide ones you don't use, or change the order.")
                }

                Section("Default times") {
                    Picker("Tonight", selection: $tonightHour) {
                        ForEach(16..<24, id: \.self) { Text(hourLabel($0)).tag($0) }
                    }
                    Picker("Morning", selection: $morningHour) {
                        ForEach(5..<12, id: \.self) { Text(hourLabel($0)).tag($0) }
                    }
                }

                Section {
                    Picker("Nudge every", selection: $nudgeMinutes) {
                        ForEach(nudgeChoices, id: \.self) { Text("\($0) min").tag($0) }
                    }
                    .onChange(of: nudgeMinutes) { Nudges.shared.reschedule() }
                } header: {
                    Text("Nudges")
                } footer: {
                    Text("If it's not done, Nabbit nudges you \(NudgeTiming.count) more times, then goes quiet.")
                }

                #if DEBUG
                Section("Testing") {
                    Button("Alert in 10 seconds") {
                        context.insert(Reminder(verb: .call, thing: "Dentist", dueDate: .now.addingTimeInterval(10)))
                        try? context.save()
                        Task {
                            await Nudges.requestPermission()
                            Nudges.shared.reschedule()
                        }
                    }
                }
                #endif
            }
            .onChange(of: themeID) {
                WidgetCenter.shared.reloadAllTimelines()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }

    private var nudgeChoices: [Int] {
        #if DEBUG
        return [1, 5, 10, 15, 20, 30]
        #else
        return [5, 10, 15, 20, 30]
        #endif
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    SettingsView()
}
