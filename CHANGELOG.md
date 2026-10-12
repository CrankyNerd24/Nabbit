# Changelog

All notable changes to Nabbit are documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-12

- Add privacy manifests and the App Store listing for release

- Nabbit has an icon: a sticky note with bunny ears and a big check, on
  the iPhone (with dark and tinted versions) and the watch

- Pick a day works on the watch too: choose any of the next two weeks
  and the reminder lands that morning at your usual time

- The alarm's second button is now Done instead of Open, so you can
  finish a reminder right from the alarm, on your iPhone or your watch,
  without opening the app. Stop still just quiets it, and the nudges
  follow

- Nabbit on Apple Watch: see Today and Coming up, tap a note for Done,
  15 min, or Tonight, and make a new reminder in three taps from your
  wrist. Hot keys come along, and a Next up complication shows what's
  next on your watch face. Taps on the watch reach your iPhone as soon
  as it's nearby

- Salty unlocks at 16 and Sweary at 18. Tapping one asks to see your age
  range once, through Apple's age-sharing sheet; if you'd rather not
  share, they stay locked and Plain and Sassy work as always

- Add a Sweary tone next to Plain, Sassy, and Salty, for full swearing:
  "Call Dentist. Right fucking now." Still aimed at the task, never at
  you

- Home now opens on the mic and the verb notes, with Today and Coming up
  right below them, then Again? and Wins today

- New, higher-contrast themes: Primary (now the default), Midnight, and
  Retro join Slate and Berry, with clearly different colors for the
  verb, who-or-what, and when notes. Ember, Workshop, and Forest are
  gone; if you used one, Nabbit switches you to Primary

- Pick a tone in Settings: Plain, Sassy, or Salty. Sassy gets cheeky and
  Salty adds mild swearing ("Call Dentist. Right damn now."), in nudges,
  alerts, celebrations, banners, and prompts. Siri keeps the plain voice

- Add your own verbs with + New on the grid, like Text, Clean, or Water,
  and go straight to who or what. Press and hold a verb to hide it or,
  if you added it, remove it, and use Settings > Edit verbs to reorder.
  Siri and the mic understand added verbs too

- Again? now holds only hot keys you ask for. After you've made the same
  reminder three times, Nabbit offers one once; say yes to pin it, or no
  and it won't ask about that one again. Press and hold a hot key to
  remove it

- Again? notes and Wins today now sit below the verb notes, so the mic
  and the verbs come first on Home

- The first time Nabbit opens, pick your colors from the five themes and
  see them on real notes before you start. Ember is picked already, and
  Settings uses the same row of swatches

- A big mic button above the verbs: say "call the dentist tomorrow at
  3" and it's saved, with Undo. Say less and it opens the next step,
  so "call the dentist" asks when. It listens on your iPhone and stops
  on its own when you pause

- Add a Next up widget for the Home Screen and Lock Screen, with a Done
  button right on it, and a New reminder control for Control Center and
  the Action button that opens Nabbit ready to go. Settings and
  reminders now live where the widget can read them, so test reminders
  and settings start fresh once

- Add the widget extension and app group

- Tell Siri how "Nabbit" is said, so it treats the name as the app
  instead of asking whether you meant Notes

- Move and Cancel show up in Shortcuts and Siri even before you have
  any reminders: "Move a reminder in Nabbit" and "Cancel a reminder in
  Nabbit" ask which one

- Start a changelog, with a post-commit hook in .githooks that logs any
  commit whose subject isn't already here

- Talk to Nabbit through Siri and Shortcuts: "Remind me in Nabbit to
  call" asks who and when, and "Nabbit, done with dentist", "Nabbit,
  snooze that", "Move dentist in Nabbit", "What's on my Nabbit list" and
  "Nabbit, cancel dentist" handle the rest

- Marking something done celebrates it: the note peels away with
  confetti in your theme's colors, a haptic thump and double tap, and a
  rotating line. It's bigger for first tries and things that hung
  around, and an empty-fridge screen shows when nothing's left today.
  Reduce Motion gets a color flash instead of confetti

- A Wins today strip on Home shows what you've finished today

- The first alert for a reminder rings as a real alarm, even on silent
  or in a Focus. Stop silences it and the nudges still follow; Open goes
  to the full-screen alert

- When something comes due with the app open, or you tap its
  notification, a full-screen alert takes over with Done, 15 min and
  Tonight

- Home leads with Today, showing what's due and what's slipped, then a
  short Coming up list. Tap a note when it's done, or press and hold to
  push it back or remove it, with Undo instead of "are you sure"

- Each reminder alerts at its time, then nudges three more times with
  sharper wording before going quiet. Done, 15 min and Tonight work
  straight from the notification, and Settings sets how often nudges
  come

- Make a reminder in three taps: what to do, who or what, and when.
  Things you use most come first, + New adds one, and Again? notes on
  Home repeat recent reminders

- Five themes and default times for Tonight and Morning in Settings
