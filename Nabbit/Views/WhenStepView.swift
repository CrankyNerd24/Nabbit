import SwiftData
import SwiftUI

/// Third tap: pick when. Tapping a chip saves the reminder.
struct WhenStepView: View {
    let verb: Verb
    let thing: String
    let theme: Theme
    /// Called with the line to show on Home once the reminder is saved.
    let onSaved: (String) -> Void

    @Environment(\.modelContext) private var context
    @State private var pickingDay = false
    @State private var pickedDay = Date.now

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(verb.title) \(thing)")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: NoteGrid.columns, spacing: 12) {
                    ForEach(WhenPreset.allCases) { preset in
                        Button {
                            choose(preset)
                        } label: {
                            StickyNote(text: preset.title, fill: theme.tap3)
                        }
                        .buttonStyle(NoteButtonStyle())
                    }
                }

                if pickingDay {
                    // Choosing a day saves. Today is covered by the chips above.
                    DatePicker("Day", selection: $pickedDay,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(theme.alert.color)
                        .onChange(of: pickedDay) {
                            save(at: morning(of: pickedDay))
                        }
                }
            }
            .padding()
        }
        .navigationTitle("When?")
    }

    private func choose(_ preset: WhenPreset) {
        if let date = preset.date() {
            save(at: date)
        } else {
            withAnimation { pickingDay = true }
        }
    }

    /// The default morning time on that day, or an hour from now if that's already passed.
    private func morning(of day: Date) -> Date {
        let hour = DefaultTimes.current.morningHour
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        return date > .now ? date : Date.now.addingTimeInterval(60 * 60)
    }

    private func save(at date: Date) {
        let reminder = CaptureStore.save(verb: verb, thing: thing, due: date, in: context)
        onSaved(Copy.saved(reminder.text, due: date))
    }
}
