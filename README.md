# Nabbit

Three-tap reminders for ADHD brains. Verb, thing, when, done. Alerts are big, nudges are friendly, nothing guilts you.

iOS 26 · SwiftUI · SwiftData · local-only

Open `Nabbit.xcodeproj` in Xcode and run. The full product brief is in [CLAUDE.md](CLAUDE.md).

## Status

- **Step 1 (done):** the data model (reminders, verbs, things, when presets) and the five-theme system, with a settings sheet for theme and default times.
- **Step 2 (done):** three-tap capture. Verb, then thing (most-used first, "+ New" adds one and moves on), then a when chip, which saves. Home shows "Again?" notes for recent reminders, which jump straight to the when step.
- **Next:** local notifications and nudge scheduling. Saved reminders don't alert yet.
