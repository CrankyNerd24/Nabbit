import SwiftUI

/// Every change applies the moment it's made. No Save button.
struct SettingsView: View {
    @AppStorage(Theme.storageKey) private var themeID = Theme.ember.id
    @AppStorage(DefaultTimes.tonightHourKey) private var tonightHour = 19
    @AppStorage(DefaultTimes.morningHourKey) private var morningHour = 9
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

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    SettingsView()
}
