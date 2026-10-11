# Nabbit

Three-tap reminders for ADHD brains. Verb, thing, when, done. Alerts are big, nudges are friendly, nothing guilts you.

iOS 26 · SwiftUI · SwiftData · local-only

Open `Nabbit.xcodeproj` in Xcode and run. The full product brief is in [CLAUDE.md](CLAUDE.md).

## Status

- **Step 1 (done):** the data model (reminders, verbs, things, when presets) and the five-theme system, with a settings sheet for theme and default times.
- **Step 2 (done):** three-tap capture. Verb, then thing (most-used first, "+ New" adds one and moves on), then a when chip, which saves. Home shows "Again?" notes for recent reminders, which jump straight to the when step.
- **Step 3 (done):** each reminder alerts at its time, then nudges every 10 minutes (set in Settings) three more times with sharper copy, then goes quiet. Done / 15 min / Tonight work right from the notification.
- **Step 4 (done):** Home shows Today (due and slipped) and Coming up; tap a note when it's done, press and hold to push it back or remove it, with Undo. A full-screen alert with Done / 15 min / Tonight takes over when something comes due with the app open or when you tap its notification. The first alert rings as a real alarm through AlarmKit, breaking through silent mode and Focus; Stop silences it and the nudges continue, Open goes to the full-screen alert.
- **Step 5 (done):** marking something done peels the note away with confetti in the theme's colors (a color flash with Reduce Motion), a haptic thump and double tap, and a rotating line. Bigger for first tries and things that hung around; an empty-fridge screen when the day's clear. A Wins today strip shows what's done.
- **Step 6 (done):** Siri and Shortcuts: "Remind me in Nabbit to call" (asks who and when), "Nabbit, done with dentist", "Nabbit, snooze that", "Move dentist in Nabbit", "What's on my Nabbit list", "Nabbit, cancel dentist".
- **Next:** widgets, the Action button, and Control Center.
