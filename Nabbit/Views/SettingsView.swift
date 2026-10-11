import SwiftUI

/// Every change applies the moment it's made. No Save button.
struct SettingsView: View {
    @AppStorage(Theme.storageKey) private var themeID = Theme.ember.id
    @AppStorage(DefaultTimes.tonightHourKey) private var tonightHour = 19
    @AppStorage(DefaultTimes.morningHourKey) private var morningHour = 9
    @AppStorage(Nudges.intervalKey) private var nudgeMinutes = Nudges.defaultMinutes
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    HStack(spacing: 14) {
                        ForEach(Theme.all) { theme in
                            Button {
                                themeID = theme.id
                            } label: {
                                Circle()
                                    .fill(theme.tap1.color)
                                    .overlay(Circle().fill(theme.alert.color).padding(14))
                                    .overlay {
                                        if theme.id == themeID {
                                            Circle().stroke(.primary, lineWidth: 3)
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(theme.name)
                            .accessibilityAddTraits(theme.id == themeID ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
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
                    Text("If it's not done, Nabbit nudges you \(Nudges.count) more times, then goes quiet.")
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
