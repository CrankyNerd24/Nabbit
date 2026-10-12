import Foundation

/// How Nabbit talks. Plain is the brief's voice; Sassy, Salty, and Sweary turn it up.
/// Whatever the tone, the swearing is at the task, never at the person, and there's
/// still no guilt.
enum Tone: String, CaseIterable, Identifiable {
    case plain, sassy, salty, sweary

    static let storageKey = "tone"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plain: "Plain"
        case .sassy: "Sassy"
        case .salty: "Salty"
        case .sweary: "Sweary"
        }
    }

    /// A taste of the tone, shown under the picker.
    var sample: String {
        switch self {
        case .plain: "\u{201C}Still here. Dentist. Go.\u{201D}"
        case .sassy: "\u{201C}Still here. Dentist. I'm not going anywhere.\u{201D}"
        case .salty: "\u{201C}Still here. Dentist. Let's knock this crap out.\u{201D} Mild swearing."
        case .sweary: "\u{201C}Still here. Dentist. Let's get this shit done.\u{201D} Full swearing."
        }
    }

    /// The chosen tone, or Plain if it's age-gated and the person hasn't been confirmed old enough.
    static var current: Tone {
        let chosen = Tone(rawValue: UserDefaults.nabbit.string(forKey: storageKey) ?? "") ?? .plain
        return AgeGate.allows(chosen) ? chosen : .plain
    }
}

/// Every line whose wording depends on the tone. Siri always uses the plain voice.
enum Copy {
    private static var tone: Tone { .current }

    // MARK: Nudges and the full-screen alert

    /// Gets more direct with each nudge: 0 is the first alert, 3 the last nudge.
    static func nudge(for reminder: Reminder, step: Int) -> String {
        let text = reminder.text
        let thing = reminder.thing
        switch tone {
        case .plain:
            switch step {
            case 0: return "It's time."
            case 1: return "\(text). Right now. \(reminder.verb.push)"
            case 2: return "Still here. \(thing). Go."
            default: return "Last one. Do it now or push it to tonight. No judgment."
            }
        case .sassy:
            switch step {
            case 0: return "It's go time."
            case 1: return "\(text). Now-ish. Actually, now."
            case 2: return "Still here. \(thing). I'm not going anywhere."
            default: return "Last one, I promise. Do it now or punt it to tonight. Zero judgment."
            }
        case .salty:
            switch step {
            case 0: return "Hey. It's time."
            case 1: return "\(text). Right damn now."
            case 2: return "Still here. \(thing). Let's knock this crap out."
            default: return "Last one. Do the damn thing or push it to tonight. No judgment."
            }
        case .sweary:
            switch step {
            case 0: return "Hey. It's fucking time."
            case 1: return "\(text). Right fucking now."
            case 2: return "Still here. \(thing). Let's get this shit done."
            default: return "Last one. Do the fucking thing or push it to tonight. No judgment."
            }
        }
    }

    // MARK: Celebrations

    static var firstTry: String {
        switch tone {
        case .plain: "First try. Look at you."
        case .sassy: "First try? Who even are you?"
        case .salty: "First damn try. Look at you."
        case .sweary: "First fucking try. Look at you."
        }
    }

    static var finallyHandled: String {
        switch tone {
        case .plain: "Finally handled. That one's been hanging around."
        case .sassy: "Finally. That one was getting way too comfy."
        case .salty: "Finally handled. That one was a pain in the ass."
        case .sweary: "Finally fucking handled. That one was a pain in the ass."
        }
    }

    static var clearBoard: String {
        switch tone {
        case .plain: "Clear board. Nothing left today."
        case .sassy: "Clear board. Go be fabulous."
        case .salty: "Clear board. Nothing left. Hell yes."
        case .sweary: "Clear board. Fuck yes. Nothing left."
        }
    }

    /// The rotating done lines for the current tone.
    static var doneLines: [String] {
        switch tone {
        case .plain:
            ["Handled.", "Done and gone.", "That's off your plate.", "One less thing in your head.",
             "Off the fridge.", "Crossed off.", "Nice. Next.", "Sorted.", "That's taken care of.",
             "Done. Breathe.", "Look at you go.", "Checked off.", "Out of your head, off the list.",
             "Done is done.", "Nailed it.", "Boom. Handled.", "Brain space freed.",
             "That one's history.", "Clean.", "Small win. Real win."]
        case .sassy:
            ["Look at you, functioning.", "Done. Show-off.", "Handled. Who even are you?",
             "Crossed off. Smug face allowed.", "Another one bites the dust.", "Done and dusted.",
             "Nailed it. Obviously.", "Look who's on a roll.", "Gone. Poof.",
             "One less thing. You're welcome, brain.", "Done. Take a bow.", "Flawless. Basically.",
             "Chef's kiss.", "Productive? In this economy?", "Iconic behavior.",
             "Off the list and out of your hair.", "Main character energy.", "Done. Mic drop."]
        case .salty:
            ["Hell yes. Handled.", "Done. Damn right.", "Knocked that crap out.", "Done. Badass.",
             "Hell yeah, crossed off.", "Kicked its ass.", "Damn, look at you.",
             "That's one less damn thing.", "Boom. Done. Hell yes.", "Handled like a damn pro.",
             "That crap's done.", "Smashed it.", "Done and damn well dusted.", "Hell of a job.",
             "Off the damn list.", "Damn fine work.", "Took care of that crap.", "Hell, that was easy."]
        case .sweary:
            ["Fuck yes. Handled.", "Done. Hell fucking yes.", "Knocked that shit out.", "Done. Absolute badass.",
             "That shit's handled.", "Fuck yeah, crossed off.", "Kicked its fucking ass.", "Holy shit, look at you.",
             "One less fucking thing.", "Boom. Fucking done.", "Handled like a goddamn pro.",
             "Smashed the shit out of it.", "Done and fucking dusted.", "Fucking legend.",
             "Off the damn list. Fuck yes.", "Shit got done.", "Hell of a fucking job.", "That was easy as shit."]
        }
    }

    /// Whether the plain voice's task-aware lines ("Dentist called…") are in the mix.
    static var usesTaskLines: Bool { tone == .plain }

    // MARK: Banners and prompts

    static func saved(_ text: String, due: Date) -> String {
        let when = due.dueDescription()
        return switch tone {
        case .plain: "Got it. \(text), \(when)."
        case .sassy: "Locked in. \(text), \(when)."
        case .salty: "Hell yes. \(text), \(when)."
        case .sweary: "Fuck yes. \(text), \(when)."
        }
    }

    static func moved(_ thing: String, to due: Date) -> String {
        let when = due.dueDescription()
        return switch tone {
        case .plain: "\(thing) moved to \(when)."
        case .sassy: "\(thing) bumped to \(when). Fine."
        case .salty: "\(thing) pushed to \(when). Damn it, fine."
        case .sweary: "\(thing) pushed to \(when). Fine. Fucking fine."
        }
    }

    static func removed(_ thing: String) -> String {
        switch tone {
        case .plain: "\(thing) reminder's gone."
        case .sassy: "\(thing)? Never heard of it."
        case .salty: "\(thing) reminder's gone. To hell with it."
        case .sweary: "\(thing) reminder's gone. Fuck it."
        }
    }

    static var missed: String {
        switch tone {
        case .plain: "Missed that. Say it like this: call the dentist tomorrow."
        case .sassy: "Say what? Try it like this: call the dentist tomorrow."
        case .salty: "What the hell was that? Try: call the dentist tomorrow."
        case .sweary: "What the fuck was that? Try: call the dentist tomorrow."
        }
    }

    static func hotKeyOffer(_ text: String, count: Int) -> String {
        switch tone {
        case .plain: "You've added \(text) \(count) times. Want a hot key for it?"
        case .sassy: "\(text), \(count) times now. A hot key, maybe? Just saying."
        case .salty: "\(text), \(count) damn times. Want a hot key?"
        case .sweary: "\(text), \(count) fucking times. Want a hot key?"
        }
    }

    /// "Call who?" on the second tap.
    static func thingPrompt(for verb: Verb) -> String {
        let prompt = verb.thingPrompt
        return switch tone {
        case .plain: prompt
        case .sassy: "\(prompt) Spill."
        case .salty: prompt.replacingOccurrences(of: "?", with: " the hell?")
        case .sweary: prompt.replacingOccurrences(of: "?", with: " the fuck?")
        }
    }
}
