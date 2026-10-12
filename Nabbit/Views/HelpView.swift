import SwiftUI
import UIKit

/// Short answers to the questions people actually have. Tap one to open it.
struct HelpView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Making reminders") {
                answer("How do I make a reminder?",
                       "Three taps: what to do, who or what, and when. Tapping the time saves it. "
                       + "Or tap the mic and say it: \u{201C}call the dentist tomorrow at 3.\u{201D}")
                answer("Can I add my own verbs or things?",
                       "Yes. Tap + New on the verb notes or the who-or-what notes. To hide, remove, "
                       + "or reorder verbs, use Settings > Edit verbs, or press and hold a verb.")
                answer("What's Again?",
                       "Hot keys for reminders you make a lot. After you make the same one three times, "
                       + "Nabbit offers a hot key once. Say yes and it's one tap from Home. Press and hold "
                       + "a hot key to remove it.")
                answer("What does Pick a day do?",
                       "It sets the reminder for that day at your Morning time, which you can change "
                       + "in Settings > Default times.")
            }

            Section("When it's due") {
                answer("What happens when a reminder is due?",
                       "The first alert rings like an alarm. Stop just quiets it. Done marks it done. "
                       + "If it's not done, Nabbit nudges you three more times, then goes quiet.")
                answer("What are Done, 15 min, and Tonight?",
                       "Done clears it. 15 min brings it back in 15 minutes. Tonight moves it to your "
                       + "Tonight time. They're on the full-screen alert, on each nudge, and on Home: "
                       + "tap a note for Done, or press and hold it for the rest.")
                answer("What does Slipped mean?",
                       "The nudges ran out and it's still open. It stays on Home until you finish it "
                       + "or push it back. No judgment.")
                answer("How do I change how often nudges come?",
                       "Settings > Nudges. Pick anywhere from every 5 to every 30 minutes.")
                answer("How do I remove a reminder?",
                       "Press and hold it on Home, then tap Remove. Undo shows up for a few seconds "
                       + "in case that wasn't the plan.")
            }

            Section("Not getting alerts?") {
                answer("Why doesn't the alert make a sound?",
                       "Check that Nabbit can send notifications, that Time Sensitive is on for it, "
                       + "and that alarms are allowed. Alarms ring even on silent and in a Focus; "
                       + "nudges follow your Focus settings unless Nabbit is allowed through.") {
                    Button("Open Nabbit's settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
                answer("Why do I only see some reminders in Notification Center?",
                       "iPhone keeps a limited number of alerts waiting per app, so Nabbit schedules the "
                       + "soonest ones and tops them up each time you open it.")
            }

            Section("Siri, widgets, and watch") {
                answer("How do I use Siri?",
                       "Say \u{201C}Remind me in Nabbit to call,\u{201D} \u{201C}Nabbit, done with dentist,\u{201D} "
                       + "\u{201C}Nabbit, snooze that,\u{201D} or \u{201C}What's on my Nabbit list?\u{201D} "
                       + "If Siri doesn't know the phrases, open the Shortcuts app, find Nabbit, and turn them on.")
                answer("Where are the widgets?",
                       "Press and hold your Home Screen or Lock Screen, tap Edit, then Add Widget, and "
                       + "find Nabbit. The New reminder control works in Control Center and on the "
                       + "Action button too.")
                answer("How does the Apple Watch app work?",
                       "It shows Today and Coming up, does Done, 15 min, and Tonight, and makes new "
                       + "reminders in three taps. Your iPhone keeps the list, so open Nabbit on it once "
                       + "if the watch looks empty. Add Next up to a watch face for a glance.")
            }

            Section("Tone and privacy") {
                answer("What are the tones?",
                       "Plain is straight to the point. Sassy is cheeky. Salty adds mild swearing and "
                       + "unlocks at 16. Sweary goes all the way and unlocks at 18. The age check uses "
                       + "Apple's age-range sharing, and Siri always stays Plain.")
                answer("Where are my reminders stored?",
                       "Only on your iPhone, with a copy on your watch if you use one. No account, no "
                       + "servers, no tracking. Deleting Nabbit deletes them.")
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func answer(_ question: String, _ text: String) -> some View {
        answer(question, text) { EmptyView() }
    }

    private func answer<Extra: View>(_ question: String, _ text: String,
                                     @ViewBuilder extra: () -> Extra) -> some View {
        let extraView = extra()
        return DisclosureGroup(question) {
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .foregroundStyle(.secondary)
                extraView
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack { HelpView() }
}
