import Foundation

/// What a spoken reminder said. Anything missing is asked for by the three-tap flow.
struct SpokenReminder: Equatable {
    var verb: Verb?
    /// As heard ("dentist"); matched against saved things by the caller.
    var thing: String?
    var due: Date?
}

/// Turns "call the dentist tomorrow at 3" into a verb, a thing, and a time. English only.
enum VoiceParser {
    private static let verbWords: [(Verb, [String])] = [
        (.pickUp, ["pick up", "collect", "grab"]),
        (.goTo, ["go to", "head to", "drive to", "stop at"]),
        (.call, ["call", "phone", "ring"]),
        (.take, ["take"]),
        (.pay, ["pay"]),
        (.buy, ["buy", "get"]),
        (.email, ["email", "e mail", "message"]),
        (.book, ["book", "schedule"]),
    ]

    private static let leadIns = ["remind me to", "remind me", "i need to", "i have to", "i gotta",
                                  "need to", "have to", "don't forget to", "nabbit"]
    private static let fillers = ["the", "my", "a", "an", "some", "our", "to", "up", "at", "for", "with", "please"]

    private static let numberWords: [String: Int] = [
        "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
        "ten": 10, "fifteen": 15, "twenty": 20, "thirty": 30, "forty five": 45,
    ]

    private static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    static func parse(_ text: String, now: Date = .now, times: DefaultTimes = .current,
                      calendar: Calendar = .current) -> SpokenReminder {
        var words = normalize(text)
        for lead in leadIns where words.hasPrefix(lead + " ") || words == lead {
            words = String(words.dropFirst(lead.count)).trimmingCharacters(in: .whitespaces)
        }

        var result = SpokenReminder()
        let (due, rest) = extractWhen(from: words, now: now, times: times, calendar: calendar)
        result.due = due

        // The earliest verb in what's left; on a tie, the longer phrase ("pick up" over "pick").
        var best: (verb: Verb, range: Range<String.Index>)?
        for (verb, phrases) in verbWords {
            for phrase in phrases {
                guard let range = wordRange(of: phrase, in: rest) else { continue }
                if best == nil || range.lowerBound < best!.range.lowerBound {
                    best = (verb, range)
                }
            }
        }
        guard let best else { return result }
        result.verb = best.verb

        var thing = rest[best.range.upperBound...].split(separator: " ").map(String.init)
        while let first = thing.first, fillers.contains(first) { thing.removeFirst() }
        while let last = thing.last, fillers.contains(last) { thing.removeLast() }
        if !thing.isEmpty {
            result.thing = thing.joined(separator: " ")
        }
        return result
    }

    // MARK: When

    /// Finds a time in the words, and returns it with those words taken out.
    private static func extractWhen(from words: String, now: Date, times: DefaultTimes,
                                    calendar: Calendar) -> (Date?, String) {
        var rest = words

        // "in 20 minutes", "in an hour", "in half an hour"
        if let match = firstMatch(#"\bin half an hour\b"#, in: rest) {
            rest.removeSubrange(match.range)
            return (now.addingTimeInterval(30 * 60), tidy(rest))
        }
        let amount = #"(\d+|a|an|one|two|three|four|five|six|ten|fifteen|twenty|thirty|forty five)"#
        if let match = firstMatch(#"\bin "# + amount + #" (minute|minutes|min|mins|hour|hours)\b"#, in: rest),
           let count = number(match.groups[0]) {
            let unit: Double = match.groups[1].hasPrefix("h") ? 3600 : 60
            rest.removeSubrange(match.range)
            return (now.addingTimeInterval(Double(count) * unit), tidy(rest))
        }

        var day: Date?
        var hour: Int?
        var minute = 0
        let today = calendar.startOfDay(for: now)

        if let match = firstMatch(#"\btomorrow\b"#, in: rest) {
            day = calendar.date(byAdding: .day, value: 1, to: today)
            rest.removeSubrange(match.range)
        } else if let match = firstMatch(#"\b(?:next |on |this )?(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\b"#, in: rest),
                  let index = weekdays.firstIndex(of: match.groups[0]) {
            // The next one after today, so "Monday" said on a Monday means a week out.
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            day = calendar.nextDate(after: tomorrow.addingTimeInterval(-1),
                                    matching: DateComponents(weekday: index + 1), matchingPolicy: .nextTime)
            rest.removeSubrange(match.range)
        } else if let match = firstMatch(#"\btoday\b"#, in: rest) {
            day = today
            rest.removeSubrange(match.range)
        }

        if let match = firstMatch(#"\bat (\d{1,2})(?::(\d{2}))? ?(am|pm|a m|p m)?\b"#, in: rest),
           let h = Int(match.groups[0]), (1...12).contains(h) {
            let suffix = match.groups[2]
            minute = Int(match.groups[1]) ?? 0
            if suffix.hasPrefix("p") {
                hour = h == 12 ? 12 : h + 12
            } else if suffix.hasPrefix("a") {
                hour = h == 12 ? 0 : h
            } else {
                // No am or pm: 1 to 7 means afternoon or evening.
                hour = h <= 7 ? h + 12 : h
            }
            rest.removeSubrange(match.range)
        } else if let match = firstMatch(#"\b(?:this )?(tonight|night|evening)\b"#, in: rest) {
            hour = times.tonightHour
            day = day ?? today
            rest.removeSubrange(match.range)
        } else if let match = firstMatch(#"\b(?:this |in the )?morning\b"#, in: rest) {
            hour = times.morningHour
            rest.removeSubrange(match.range)
        }

        guard day != nil || hour != nil else { return (nil, tidy(rest)) }
        // "Today" with no time: an hour from now.
        if day == today && hour == nil {
            return (now.addingTimeInterval(60 * 60), tidy(rest))
        }

        let base = day ?? today
        var date = calendar.date(bySettingHour: hour ?? times.morningHour, minute: minute, second: 0, of: base) ?? base
        if date <= now {
            // "At 3" or "in the morning" once that's passed means tomorrow;
            // "tonight" or "today at 3" once passed means an hour from now.
            if day == nil {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            } else {
                date = now.addingTimeInterval(60 * 60)
            }
        }
        return (date, tidy(rest))
    }

    // MARK: Text helpers

    /// Lowercase, keep letters, digits, colons, and apostrophes, single spaces.
    private static func normalize(_ text: String) -> String {
        let kept = text.lowercased().map { char -> Character in
            char.isLetter || char.isNumber || char == ":" || char == "'" ? char : " "
        }
        return tidy(String(kept))
    }

    private static func tidy(_ text: String) -> String {
        text.split(separator: " ").joined(separator: " ")
    }

    private static func number(_ word: String) -> Int? {
        Int(word) ?? numberWords[word]
    }

    private static func wordRange(of phrase: String, in text: String) -> Range<String.Index>? {
        firstMatch(#"\b"# + NSRegularExpression.escapedPattern(for: phrase) + #"\b"#, in: text)?.range
    }

    private struct Match {
        let range: Range<String.Index>
        /// Capture groups in order, empty when a group didn't match.
        let groups: [String]
    }

    private static func firstMatch(_ pattern: String, in text: String) -> Match? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let result = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(result.range, in: text) else { return nil }
        let groups = (1..<max(result.numberOfRanges, 1)).map { index -> String in
            Range(result.range(at: index), in: text).map { String(text[$0]) } ?? ""
        }
        return Match(range: range, groups: groups)
    }
}
