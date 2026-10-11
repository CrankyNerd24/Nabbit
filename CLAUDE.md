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

## Project layout

- `Nabbit.xcodeproj` uses a synchronized folder: any file added under `Nabbit/` is in the target automatically.
- `Nabbit/Model`: SwiftData models (`Reminder`, `Thing`) and the fixed lists (`Verb`, `WhenPreset`). Enums are stored as raw strings so predicates work.
- `Nabbit/Theme`: the five themes and `ThemeColor`, which picks the text color by WCAG contrast.
- `Nabbit/Alerts`: `Nudges` schedules each reminder's alert plus its nudges as time-sensitive local notifications (soonest 60 only, refilled whenever the app comes forward) and handles their Done / 15 min / Tonight buttons. Slipped is worked out from the clock, since nudges fire while the app isn't running.
- `Nabbit/Views`: SwiftUI screens.
- Settings live in `@AppStorage`; keys are static constants on the type that owns them (`Theme.storageKey`, `DefaultTimes.tonightHourKey`).
- Default actor isolation is MainActor (Swift 5 mode, approachable concurrency).
