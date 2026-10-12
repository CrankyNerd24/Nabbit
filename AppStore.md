# App Store listing and release checklist

What goes into App Store Connect for Nabbit 1.0.0. Copy follows the brief: short,
direct, warm, no guilt, and never the word for repeat alerts other than "nudges".

## Before uploading

- [ ] App icon final (the bunny note is in place, marked tentative)
- [ ] `MARKETING_VERSION` 1.0.0 in all four targets, `CURRENT_PROJECT_VERSION` 1
- [ ] Privacy manifests (`PrivacyInfo.xcprivacy`) in the app, both widget
      extensions, and the watch app: no tracking, no collected data, UserDefaults
      for the app's own settings (CA92.1) and the app group (1C8F.1)
- [ ] `ITSAppUsesNonExemptEncryption` is NO, so uploads skip the export question
- [x] App record created in App Store Connect ("Nabbit - Reminders That Stick", bundle ID `CrankyNerdNew.Nabbit`, SKU CN_Nabbit)
- [ ] Privacy policy and support URLs live (a simple page is enough; text below)
- [ ] Archive with the **Nabbit** scheme (Product → Archive, destination
      "Any iOS Device"), then Distribute App → App Store Connect. The watch app
      and both widget extensions ride along inside it
- [ ] TestFlight build installed and run through on the iPhone and the watch
- [ ] Screenshots, listing text, privacy labels, and age rating filled in
- [ ] Submit for review

## Listing

**Name** (30 max): Nabbit - Reminders That Stick

"Nabbit" alone was taken. The store name only labels the listing; the Home Screen
and Siri still say Nabbit.

**Subtitle** (30 max): ADHD planner with big alerts

**Category:** Productivity. Secondary: Health & Fitness, or none.

**Promotional text** (170 max):
Three taps to remember anything. Big alerts you can't miss, nudges that get more
direct, and a little celebration every time you get it done.

**Description** (4000 max):

Nabbit is a reminder app built for ADHD brains. Think sticky notes on the fridge:
quick to make, hard to miss, and satisfying to clear.

THREE TAPS, DONE
Pick what to do (Call, Pick up, Take, Pay…), who or what, and when. Tapping the
time saves it. No forms, no Save button. The things you use most float to the
front, and the reminders you make all the time can become one-tap hot keys.

OR JUST SAY IT
Tap the big mic and say "call the dentist tomorrow at 3." It listens on your
iPhone and saves it. Siri works too: "Remind me in Nabbit to call."

ALERTS YOU CAN'T IGNORE
The first alert rings like an alarm, even on silent or in a Focus. Then the
full-screen alert gives you three buttons: Done, 15 min, or Tonight. Still not
done? Nabbit nudges you three more times, a little more direct each time, then
goes quiet. Anything that slips stays on your list, no judgment.

A WIN EVERY TIME
Marking something done peels the note off with confetti, a firm haptic thump,
and a line like "That's off your plate." Clear your whole day and you get the
empty fridge. No streaks, no points, nothing to lose.

ON YOUR WRIST
The Apple Watch app shows what's next, lets you hit Done, 15 min, or Tonight,
and makes new reminders in three taps. Add the Next up complication to your
watch face.

MADE YOURS
- Five color themes
- Your own verbs, in your order
- Default times for Tonight and Morning
- Pick a tone: Plain, Sassy, Salty (16+), or Sweary (18+)
- Widgets, Control Center, and the Action button

PRIVATE BY DESIGN
No account. No ads. No tracking. Your reminders stay on your iPhone and watch.

**Keywords** (100 max, comma-separated, no spaces). Words already in the name or
subtitle (reminders, stick, adhd, planner, alerts) count on their own, so they're
left out here:
todo,alarm,nudge,sticky,notes,focus,routine,memory,watch,tasks,habit,checklist,meds,to-do,organizer

**Support URL:** https://crankynerd24.github.io/Nabbit/support.html

**Privacy policy URL:** https://crankynerd24.github.io/Nabbit/privacy.html

**Marketing URL:** https://crankynerd24.github.io/Nabbit/

## Privacy policy text

Nabbit doesn't collect any data. Your reminders and settings are stored only on
your devices (your iPhone and, if you use it, your Apple Watch) and are never sent
to us or anyone else. There's no account, no analytics, no ads, and no tracking.
Speech for the mic is transcribed on your device. When you unlock the Salty or
Sweary tone, Apple's age-range sharing tells Nabbit only whether you're over 16 or
18; that answer stays on your device. Questions: crankynerdcustoms@gmail.com.

## App Privacy (nutrition labels)

- Data collection: **No, we do not collect data from this app**
- Tracking: none

## Age rating questionnaire

Answer for the most the app can show, since Sweary is in the build even though
it's gated:

- Profanity or crude humor: **Frequent or Intense** (Sweary uses f-words in
  alerts, nudges, celebrations, and banners)
- Everything else (violence, sexual content, gambling, drugs, horror, medical,
  user-generated content, web access, messaging, contests): **None**
- Age assurance / parental controls: the app uses the Declared Age Range API to
  gate the Salty and Sweary tones

App Store Connect works out the rating from these answers. Profanity at this level
usually lands at the top tiers. If the rating matters more than Sweary, the
alternative is a store build without it.

## Screenshots

Required: 6.9" iPhone (1320 × 2868 portrait). Apple scales these for smaller
iPhones. Up to 10; 3–5 is plenty:

1. Home: mic, verb grid, Today
2. The three taps (thing step, or the when chips)
3. Full-screen alert with Done / 15 min / Tonight
4. A celebration (confetti and a line)
5. Settings: themes and tone

Apple Watch screenshots are required because the app includes a watch app
(any current size, e.g. 422 × 514 for the 49mm Ultra, or 416 × 496 for 46mm):
the watch list and the alert view.

Take them in the Simulator with ⌘S (saves to the Desktop) after making a few
believable reminders: Call Dentist, Take Meds, Pick up Prescription, Pay Rent.

## Notes for the reviewer

Nabbit is a local-only reminder app with no account or sign-in.

- To see an alert: make a reminder (Call → Dentist → In 1 hour), lock the
  device, and set the clock an hour ahead, or wait for it. Done, 15 min, and
  Tonight are on the alert; the nudges follow every 10 minutes.
- The first alert for each reminder uses AlarmKit, which asks for permission on
  the first save. Notifications are time-sensitive.
- Salty and Sweary tones are gated by the Declared Age Range API (16+ and 18+).
- The Apple Watch app syncs with the iPhone over WatchConnectivity; no server.
