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

1. **Verb** — grid of big sticky notes: Call, Pick up, Take, Pay, Buy, Email, Book, Go to, plus any the user adds ("+ New" on the grid, one word). User can reorder or hide them, and delete ones they added.
2. **Thing** — list depends on the verb (Call → Dentist, Mom, Doctor, Vet, Pharmacy; Take → Meds, Vitamins; Pick up → Kids, Prescription, Dry cleaning). Most-used float to the front. "+ New" adds one with a single text field.
3. **When** — plain-language chips: In 1 hour, Tonight, Tomorrow AM, Next Monday, Pick a day. Each maps to a default time set once in settings (Tonight = 7pm, AM = 9am). Tapping a chip saves.

"Again?" holds hot keys for one-tap repeats, opt-in only: after the same verb and thing are made 3 times, offer once ("You've added Call Dentist 3 times. Want a hot key for it?"). Yes pins it; no never asks about it again. Big mic button above the verb grid.

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
| Primary (default) | Bold and simple | #FFC93C | #3D7BFF | #FF5A5F | #14213D | #2EC4B6 |
| Midnight | Dark notes, bright pops | #26334D | #5B2A86 | #0F5257 | #FF5E3A | #FFD23F |
| Slate | Steel and navy | #B5D4F4 | #A9B8C6 | #D3D1C7 | #0C447C | #EF9F27 |
| Berry | Pink and coral | #F4C0D1 | #ED93B1 | #F0997B | #D55681 | #FAC775 |
| Retro | 70s kitchen | #F4D35E | #0D3B66 | #EE964B | #B8341B | #F4D35E |

Tap 1, 2, and 3 should be clearly different hues so the three steps read apart. Berry's alert was lifted a shade from the original #D4537E, which measured 4.40:1 against the dark text. `Theme.standard` is the default and the fallback for a saved theme that's no longer offered.

Picker: one row of swatches in settings, Primary preselected, applies instantly, no Save. Also shown once at first launch.

## Siri and voice

Phrases must include the app name and use known lists (the user's verbs and saved things as entities, when chips as enum). Missing pieces get a one-word follow-up.

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

Tone setting (Settings): Plain (the voice above), Sassy (cheeky, no swearing), Salty (mild swearing: damn, hell, crap, ass), Sweary (full swearing, f-words included). Salty unlocks at 16+ and Sweary at 18+ through the Declared Age Range API: tapping a locked tone ("Salty 16+") shows the system age-sharing sheet once, and if it's declined, under age, or unavailable the tone stays locked. Gating doesn't change the App Store age rating by itself; answer the questionnaire for profanity the app can show. Applies to nudges and the alert, celebrations, and banners and prompts; Siri stays Plain. Spice is aimed at the task, never the person, and the no-guilt rules still hold in every tone.

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

- `Nabbit.xcodeproj` uses synchronized folders: `Nabbit/` is the app, `NabbitWidgets/` is the widget extension, `Shared/` is compiled into both, `NabbitWatch/` is the watch app, `NabbitWatchWidgets/` is its complication extension, and `Common/` is compiled into all four. Any file added under a folder is in its target automatically.
- `Shared/`: the SwiftData models, `Store`, `Verb` and `VerbStore`, and the widget intents. It builds under two isolation defaults (the app is MainActor, the extension isn't), so keep it free of UI and app-only types.
- `Common/`: what the watch needs too: `WhenPreset`, the themes, `NudgeTiming`, `ReminderAction`, `UserDefaults.nabbit`, and `WatchSnapshot` / `WatchRequest`. Foundation and SwiftUI only, no SwiftData, and the same two isolation defaults.
- App group `group.CrankyNerdNew.Nabbit` holds the SwiftData store and the settings (`UserDefaults.nabbit`, used by every `@AppStorage`) so the widgets can read them.
- Models (`Reminder`, `Thing`) store the verb as its raw value so predicates work. `ThemeColor` picks the text color by WCAG contrast.
- `Nabbit/Alerts`: `Nudges` schedules each reminder's alert plus its nudges as time-sensitive local notifications (soonest 60 only, refilled whenever the app comes forward) and handles their Done / 15 min / Tonight buttons. Slipped is worked out from the clock, since nudges fire while the app isn't running.
- `ReminderAction` is the three buttons (Done / 15 min / Tonight); `Nudges.perform` applies one from any of the three places they appear (notification, full-screen alert, Today list).
- `AlertCenter` holds which reminder the full-screen `AlertView` is showing. It opens when a notification arrives with the app open, when a notification is tapped, or when the app comes forward with something due.
- `Alarms` rings each reminder's first alert through AlarmKit (soonest 20). The system's Stop only silences it, so the nudges still come; its Done button runs `CompleteReminderIntent` in the background, so it works from the watch without opening the phone. Reminders with an alarm skip the first notification. No widget extension, since there's no countdown presentation.
- `Store.container` is the single SwiftData container, opened on first use so intents can reach it.
- Deployment target is iOS 26.1, for AlarmKit's current `Alert` initializer.
- `Nabbit/Info.plist` holds keys Xcode has no build setting for (`NSAlarmKitUsageDescription`, and `INAlternativeAppNames` with a "nab it" pronunciation hint so Siri hears the name as the app). It merges with the generated plist and is excluded from the synced folder's resources.
- `Nabbit/Celebration`: `Celebration` sizes a Done (small / medium / big / clear board) before the reminder is marked done, and `CelebrationLines` rotates the copy without repeats. `CelebrationOverlay` draws confetti as plain animated shapes (a color flash with Reduce Motion) and never takes taps; `Haptics` plays the Core Haptics thump. Today rows peel off with `.peel`. Only Done from the app celebrates, not the notification button.
- `Nabbit/Siri`: App Intents for create, done, snooze, move, check, and cancel, with phrases in `NabbitShortcuts`. Apple allows one variable per phrase, so create takes the verb in the phrase and asks for the thing and when. `VerbEntity`, `WhenOption`, and `ReminderEntity` are nonisolated for App Intents; `SiriActions` does the work on the main actor through the same paths as the app's buttons. `ReminderEntity` displays the thing ("Dentist") so "done with dentist" matches. Test Siri on a device.
- `NabbitWidgets/`: the Next up widget (Home Screen small and medium, Lock Screen inline, circular, and rectangular) and the New reminder control for Control Center and the Action button. Widget buttons use intents from `Shared/WidgetIntents.swift`: `CompleteReminderIntent` is a LiveActivityIntent so it runs in the app process, and `OpenCaptureIntent` brings the app forward. Each target has its own `WidgetActions`; the app's (`Nabbit/Widgets`) does the work and the extension's is empty. `Nudges.reschedule` and theme changes reload the widget timelines.
- `Nabbit/Voice`: the mic button. `SpeechListener` records and transcribes on device (en-US), stopping after a 1.5-second pause; its audio and recognition callbacks are set up in nonisolated helpers because they arrive off the main actor. `VoiceParser` turns the words into a verb, a thing, and a time ("in 20 minutes", "tonight", "tomorrow at 3", "Friday"); Home saves it when all three are there, otherwise opens the three-tap flow at the first missing step.
- `Nabbit/Copy/Tone.swift`: `Tone` (stored as `Tone.storageKey` in `UserDefaults.nabbit`) and `Copy`, the one place for every tone-dependent line. Add new user-facing lines there in every tone. Changing the tone reschedules nudges so pending ones get the new wording.
- `Nabbit/Copy/AgeGate.swift`: the tone age gates (16, 18) and the remembered age floor (`AgeGate.floorKey` in `UserDefaults.nabbit`). `Tone.current` falls back to Plain when the saved tone isn't unlocked. Needs the `com.apple.developer.declared-age-range` entitlement.
- `Nabbit/Capture/CaptureStore` is the one save path for new reminders (three taps and voice) and matches a spoken thing to a saved one or adds it.
- Verbs: `Verb` is a struct with eight built-ins and `Verb.custom(_:)` for added ones, stored as "custom:Word" so the word survives removal. `VerbStore` keeps the added verbs, order, and hidden list as JSON in `UserDefaults.nabbit` (watch it with `@AppStorage(VerbStore.key)`); `visible()` is the grid, Siri's list, and the mic's list. Siri's verb is `VerbEntity` (dynamic), and Home refreshes App Shortcut parameters when the layout changes. Hidden or removed verbs keep their reminders.
- `Nabbit/Views`: SwiftUI screens. Home runs top to bottom: the mic, the verb grid, Today and Coming up, the hot key offer, Again? (hot keys), then Wins today. A hot key is opt-in: once a `Thing`'s `useCount` reaches `Thing.hotKeyThreshold` (3), Home offers it once (`hotKeyOffered`); yes sets `hotKey`, which pins it to Again?. `ThemeSwatches` is the one row of theme swatches, used in Settings and in `ThemeIntroView`, the sheet `NabbitApp` shows once at first launch (`themeIntroShown` in `UserDefaults.nabbit`).
- Settings live in `@AppStorage`; keys are static constants on the type that owns them (`Theme.storageKey`, `DefaultTimes.tonightHourKey`).
- Apple Watch: the watch has no SwiftData store. The iPhone's `WatchLink` (`Nabbit/Watch`) sends a `WatchSnapshot` (open reminders, the visible verbs with their things, hot keys, the tone's lines, the theme, default times, nudge timing) as the WatchConnectivity application context whenever it changes (`Nudges.reschedule`, theme and verb changes, and when the app goes to the background), and applies `WatchRequest`s (Done / 15 min / Tonight, a new reminder, refresh) through `Nudges.perform` and `CaptureStore`. On the watch, `PhoneLink` sends requests live when the iPhone is reachable and queues them with `transferUserInfo` when it isn't; `WatchModel` changes the list right away and saves the snapshot in the watch's app group, where the Next up complication reads it. The alarm shows on the watch with Stop and Done. A new reminder from the watch carries its own UUID, so a request delivered twice saves once. The iPhone's notifications show on the watch with the same three buttons; `WatchNotifications` passes them to the iPhone. Pick a day stays on the iPhone. Bundle IDs: `CrankyNerdNew.Nabbit.watchkitapp` and `CrankyNerdNew.Nabbit.watchkitapp.NabbitWatchWidgets`, watchOS 26.
- Default actor isolation is MainActor (Swift 5 mode, approachable concurrency).
