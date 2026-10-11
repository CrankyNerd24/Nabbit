# Nabbit — project brief

Name: **Nabbit** ("Remind me in Nabbit to call the dentist").

An iOS planning and reminder app for people with ADHD. Think sticky notes on the fridge: making a reminder takes three taps, alerts are big and impossible to ignore, and the tone is forceful but friendly.

## Core principles

- Every extra step is a reason to quit. Never add a field, screen, or confirmation that isn't essential.
- No "Save" buttons. The last tap saves.
- No guilt. No streaks that can break, no "you forgot", no "late", no "again".
- Never use the word "nag" anywhere — code comments, UI, or copy. Repeat alerts are called **nudges**.

## Tech

- SwiftUI, iOS 26 target, Xcode.
- SwiftData for storage. Local-only: no account, no backend, no sync in v1.
- App Intents for Siri, Shortcuts, Spotlight, Action button, widgets, and Control Center.
- AlarmKit for alarm-style alerts that break through silent mode and Focus; time-sensitive notifications for softer ones. Don't rely on the Critical Alerts entitlement.
- iOS allows 64 pending local notifications per app, so schedule nudges in rolling batches.
- On-device speech recognition for the in-app mic.
- Core Haptics for completion feedback.
- Apple Watch app and complication (later phase).

## Capture flow (three taps)

1. **Verb** — fixed grid of big sticky notes: Call, Pick up, Take, Pay, Buy, Email, Book, Go to. User can reorder or hide.
2. **Thing** — list depends on the verb (Call → Dentist, Mom, Doctor, Vet, Pharmacy; Take → Meds, Vitamins; Pick up → Kids, Prescription, Dry cleaning). Most-used float to the front. "+ New" adds one with a single text field.
3. **When** — plain-language chips: In 1 hour, Tonight, Tomorrow AM, Next Monday, Pick a day. Each maps to a default time set once in settings (Tonight = 7pm, AM = 9am). Tapping a chip saves.

Home screen leads with "Again?" notes for recent reminders so repeats are one tap. Big mic button above the verb grid.

## Alerts

- Full screen, theme-colored, task in huge text, three buttons only: **Done**, **15 min**, **Tonight**.
- Nudges are on by default: if not done, repeat every 10 minutes up to 3 times, copy gets more direct each time.
- After nudge 3, stop making sound. The item stays on the home screen as "Slipped: call the dentist".

Nudge copy:
- 1: "Call the dentist. Right now. It's a two-minute call."
- 2: "Still here. Dentist. Phone. Go."
- 3: "Last one. Do it now or push it to tonight. No judgment."

## Completion celebration (under 1.5 seconds, never blocks the next tap)

- Note peels off the screen, confetti in the current theme's colors, firm haptic thump + double tap, short optional sound (respects silent switch), one line of copy.
- Scales with effort:
  - Routine (meds, daily): small pop, light tap.
  - Done on first nudge: medium burst. "First try. Look at you."
  - Slipped or snoozed several times: full-screen confetti. "Finally handled. That one's been hanging around."
  - Whole day cleared: special empty-fridge screen. "Clear board. Nothing left today."
- Rotate 20–30 lines, never the same one twice in a row ("Handled.", "Done and gone.", "That's off your plate.", "One less thing in your head."). Some task-aware ("Dentist called. Your teeth thank you.").
- Respect Reduce Motion: color flash instead of confetti, keep haptic and copy.
- Optional "Wins today" strip of small crumpled notes on the home screen. No points, levels, or streaks.

## Themes (five max — avoids decision paralysis)

Text color is chosen automatically per background (warm near-black #1E1A16 or warm off-white #FFF6EE, whichever contrasts better). All combinations must hit at least 4.5:1.

| Theme | Vibe | Tap 1 | Tap 2 | Tap 3 | Alert | Done |
|---|---|---|---|---|---|---|
| Ember (default) | Warm | #FAC775 | #F5C4B3 | #F0997B | #D85C32 | #FAC775 |
| Workshop | Kraft and charcoal | #E3CBA0 | #C9A979 | #B4B2A9 | #2C2C2A | #EF9F27 |
| Forest | Olive and moss | #C0DD97 | #97C459 | #D6C793 | #27500A | #EF9F27 |
| Slate | Steel and navy | #B5D4F4 | #A9B8C6 | #D3D1C7 | #0C447C | #EF9F27 |
| Berry | Pink and coral | #F4C0D1 | #ED93B1 | #F0997B | #D55681 | #FAC775 |

Ember and Berry alerts were lifted a shade from the original #D85A30 and #D4537E, which measured 4.47:1 and 4.40:1 against the dark text.

Picker: one row of swatches in settings, Ember preselected, applies instantly, no Save. Also shown once at first launch.

## Siri and voice

Phrases must include the app name and use fixed lists (verb enum, user's saved things as entities, when chips as enum). Missing pieces get a one-word follow-up.

- Create: "Remind me in Nabbit to call the dentist next Monday" / "Nabbit, call the dentist next Monday" / "New Nabbit reminder"
  - All given: "Got it. Call the dentist, Monday at 9. I'll make sure it happens."
  - Missing when: "Call the dentist. When? Today, tonight, tomorrow, or pick a day."
  - Missing thing: "Call who?"
  - New thing: "Plumber's new. Added it. When do you need to call?"
  - Not understood: "Missed that. Say it like this: call the dentist tomorrow."
- Done: "I called the dentist in Nabbit" / "Nabbit, done with meds" → "Handled. Nice work."
- Push back: "Nabbit, snooze that 15 minutes" / "Move dentist to tomorrow in Nabbit" → "Dentist moved to tomorrow at 9. No dodging that one."
- Check: "What's on my Nabbit list?" → top three only, ending with which to do first.
- Cancel: "Nabbit, cancel the dentist reminder" → "Dentist reminder's gone." (Undo on screen, no "are you sure".)

Voice rules: lead with the task, under 12 words, one question at a time, one encouraging beat max.

## Copy rules (everywhere)

Short, direct, warm, present tense. Lead with the task, then the push. Say "slipped", never "forgot" or "failed".

## v1 scope

1. Three-tap capture with learned shortcuts
2. Full-screen alert with Done / 15 min / Tonight
3. Repeat nudges with escalating copy
4. Today list (due and slipped)
5. Settings: default times, nudge frequency, theme
6. Completion celebration
7. Siri / App Intents for create, done, snooze, check

Out of scope for v1: categories, tags, notes fields, calendar sync, sharing, accounts.

## Suggested build order

1. Data model (Reminder, Verb, Thing, When presets) + theme system
2. Three-tap capture UI
3. Local notifications + nudge scheduling
4. Full-screen alert (AlarmKit) and Today list
5. Completion celebration
6. App Intents / Siri
7. Widgets, Action button, Control Center
8. Apple Watch

## Changelog

- `CHANGELOG.md` follows Semantic Versioning, newest first, with an `## [Unreleased]` section at the top.
- Every commit that changes the app adds one bullet under `## [Unreleased]` in that same commit: plain words for someone using the app, what changed and why it matters, no trailing period, wrapped at about 72 characters, a blank line between bullets. Build-only fixes can use the commit subject.
- To release: bump `MARKETING_VERSION` in a commit titled "Bump marketing version to X.Y.Z", then a commit titled "Release X.Y.Z in the changelog" that adds `## [X.Y.Z] - YYYY-MM-DD` under `## [Unreleased]`, so everything below it belongs to that version.
- `.githooks/post-commit` appends a commit's subject under `## [Unreleased]` if no bullet for it exists. Enable it once per clone with `git config core.hooksPath .githooks`.

## Project layout

- `Nabbit.xcodeproj` uses synchronized folders: `Nabbit/` is the app, `NabbitWidgets/` is the widget extension, and `Shared/` is compiled into both. Any file added under a folder is in its target automatically.
- `Shared/`: the SwiftData models, `Store`, the fixed lists, the themes, `NudgeTiming`, `UserDefaults.nabbit`, and the widget intents. It builds under two isolation defaults (the app is MainActor, the extension isn't), so keep it free of UI and app-only types.
- App group `group.CrankyNerdNew.Nabbit` holds the SwiftData store and the settings (`UserDefaults.nabbit`, used by every `@AppStorage`) so the widgets can read them.
- Models (`Reminder`, `Thing`) and the fixed lists (`Verb`, `WhenPreset`) store enums as raw strings so predicates work. `ThemeColor` picks the text color by WCAG contrast.
- `Nabbit/Alerts`: `Nudges` schedules each reminder's alert plus its nudges as time-sensitive local notifications (soonest 60 only, refilled whenever the app comes forward) and handles their Done / 15 min / Tonight buttons. Slipped is worked out from the clock, since nudges fire while the app isn't running.
- `ReminderAction` is the three buttons (Done / 15 min / Tonight); `Nudges.perform` applies one from any of the three places they appear (notification, full-screen alert, Today list).
- `AlertCenter` holds which reminder the full-screen `AlertView` is showing. It opens when a notification arrives with the app open, when a notification is tapped, or when the app comes forward with something due.
- `Alarms` rings each reminder's first alert through AlarmKit (soonest 20). The system's Stop only silences it, so the nudges still come; its Open button (`OpenAlarmIntent`) launches the full-screen alert. Reminders with an alarm skip the first notification. No widget extension, since there's no countdown presentation. Open doesn't launch the app in the Simulator ("Could not find an intent with identifier OpenAlarmIntent" in the log) but works on a device; test alarms on a real iPhone.
- `Store.container` is the single SwiftData container, opened on first use so intents can reach it.
- Deployment target is iOS 26.1, for AlarmKit's current `Alert` initializer.
- `Nabbit/Info.plist` holds keys Xcode has no build setting for (`NSAlarmKitUsageDescription`, and `INAlternativeAppNames` with a "nab it" pronunciation hint so Siri hears the name as the app). It merges with the generated plist and is excluded from the synced folder's resources.
- `Nabbit/Celebration`: `Celebration` sizes a Done (small / medium / big / clear board) before the reminder is marked done, and `CelebrationLines` rotates the copy without repeats. `CelebrationOverlay` draws confetti as plain animated shapes (a color flash with Reduce Motion) and never takes taps; `Haptics` plays the Core Haptics thump. Today rows peel off with `.peel`. Only Done from the app celebrates, not the notification button.
- `Nabbit/Siri`: App Intents for create, done, snooze, move, check, and cancel, with phrases in `NabbitShortcuts`. Apple allows one variable per phrase, so create takes the verb in the phrase and asks for the thing and when. `VerbOption`, `WhenOption`, and `ReminderEntity` are nonisolated for App Intents; `SiriActions` does the work on the main actor through the same paths as the app's buttons. `ReminderEntity` displays the thing ("Dentist") so "done with dentist" matches. Test Siri on a device.
- `NabbitWidgets/`: the Next up widget (Home Screen small and medium, Lock Screen inline, circular, and rectangular) and the New reminder control for Control Center and the Action button. Widget buttons use intents from `Shared/WidgetIntents.swift`: `CompleteReminderIntent` is a LiveActivityIntent so it runs in the app process, and `OpenCaptureIntent` brings the app forward. Each target has its own `WidgetActions`; the app's (`Nabbit/Widgets`) does the work and the extension's is empty. `Nudges.reschedule` and theme changes reload the widget timelines.
- `Nabbit/Voice`: the mic button. `SpeechListener` records and transcribes on device (en-US), stopping after a 1.5-second pause; its audio and recognition callbacks are set up in nonisolated helpers because they arrive off the main actor. `VoiceParser` turns the words into a verb, a thing, and a time ("in 20 minutes", "tonight", "tomorrow at 3", "Friday"); Home saves it when all three are there, otherwise opens the three-tap flow at the first missing step.
- `Nabbit/Capture/CaptureStore` is the one save path for new reminders (three taps and voice) and matches a spoken thing to a saved one or adds it.
- `Nabbit/Views`: SwiftUI screens. `ThemeSwatches` is the one row of theme swatches, used in Settings and in `ThemeIntroView`, the sheet `NabbitApp` shows once at first launch (`themeIntroShown` in `UserDefaults.nabbit`).
- Settings live in `@AppStorage`; keys are static constants on the type that owns them (`Theme.storageKey`, `DefaultTimes.tonightHourKey`).
- Default actor isolation is MainActor (Swift 5 mode, approachable concurrency).
