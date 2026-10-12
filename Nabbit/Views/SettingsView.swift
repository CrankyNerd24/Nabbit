import DeclaredAgeRange
import StoreKit
import SwiftData
import SwiftUI
import WidgetKit

/// Every change applies the moment it's made. No Save button.
struct SettingsView: View {
    @AppStorage(Theme.storageKey, store: .nabbit) private var themeID = Theme.standard.id
    @AppStorage(DefaultTimes.tonightHourKey, store: .nabbit) private var tonightHour = 19
    @AppStorage(DefaultTimes.morningHourKey, store: .nabbit) private var morningHour = 9
    @AppStorage(Tone.storageKey, store: .nabbit) private var tone = Tone.plain
    @AppStorage(AgeGate.floorKey, store: .nabbit) private var ageFloor = 0
    @Environment(\.requestAgeRange) private var requestAgeRange
    @State private var gateNote: String?
    /// Debug and TestFlight builds show the Testing section and 1-minute nudges.
    @State private var isTestBuild = false
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
                    Picker("Tone", selection: toneSelection) {
                        ForEach(Tone.allCases) { option in
                            Text(label(for: option)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    // Nudges already scheduled pick up the new wording.
                    .onChange(of: tone) { Nudges.shared.reschedule() }
                } header: {
                    Text("Tone")
                } footer: {
                    Text(gateNote ?? effectiveTone.sample)
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

                Section {
                    NavigationLink("Help and FAQ") {
                        HelpView()
                    }
                }

                if isTestBuild {
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
                }

                Section {
                } footer: {
                    Text(versionLine)
                        .frame(maxWidth: .infinity)
                }
            }
            .task { isTestBuild = await Self.checkTestBuild() }
            .onChange(of: themeID) {
                WidgetCenter.shared.reloadAllTimelines()
                WatchLink.shared.send()
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

    /// Picking an age-gated tone asks for an age range first, once.
    private var toneSelection: Binding<Tone> {
        Binding {
            effectiveTone
        } set: { picked in
            gateNote = nil
            if unlocked(picked) {
                tone = picked
            } else {
                Task { await unlock(picked) }
            }
        }
    }

    /// The saved tone, or Plain if it's gated and not unlocked.
    private var effectiveTone: Tone {
        unlocked(tone) ? tone : .plain
    }

    private func unlocked(_ option: Tone) -> Bool {
        guard let minimum = AgeGate.minimumAge(for: option) else { return true }
        return ageFloor >= minimum
    }

    /// Locked tones show their age: "Salty 16+".
    private func label(for option: Tone) -> String {
        guard !unlocked(option), let minimum = AgeGate.minimumAge(for: option) else { return option.title }
        return "\(option.title) \(minimum)+"
    }

    private func unlock(_ picked: Tone) async {
        guard let minimum = AgeGate.minimumAge(for: picked) else { return }
        do {
            let response = try await requestAgeRange(ageGates: AgeGate.gates.0, AgeGate.gates.1)
            guard case let .sharing(range) = response else {
                gateNote = "\(picked.title) stays locked unless you share your age range."
                return
            }
            // No lower bound means under the lowest gate.
            ageFloor = range.lowerBound ?? 0
            if ageFloor >= minimum {
                tone = picked
            } else {
                gateNote = "\(picked.title) unlocks at \(minimum)."
            }
        } catch {
            gateNote = "Age check isn't available here, so \(picked.title) stays locked."
        }
    }

    private var nudgeChoices: [Int] {
        isTestBuild ? [1, 5, 10, 15, 20, 30] : [5, 10, 15, 20, 30]
    }

    /// "Nabbit 1.0.0 (1)": the version and build number.
    private var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Nabbit \(version) (\(build))"
    }

    /// True when run from Xcode or installed through TestFlight; false from the App Store,
    /// so testing tools never ship there.
    private static func checkTestBuild() async -> Bool {
        #if DEBUG
        return true
        #else
        guard let result = try? await AppTransaction.shared else { return false }
        let environment = switch result {
        case .verified(let transaction), .unverified(let transaction, _): transaction.environment
        }
        return environment != .production
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
