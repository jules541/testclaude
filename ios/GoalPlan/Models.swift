import Foundation

// MARK: - Data Models
// These mirror the web app's JSON structure exactly for import/export compatibility

struct Plan: Codable, Equatable {
    var owner: String
    var quarter: String
    var weeksInQuarter: Int
    var vision: String
    var goals: [Goal]
    var scores: [String: [String: Double]]  // week → habitId → value
    var dailyScores: [String: [String: Double]]  // "yyyy-MM-dd" → habitId → value

    init(
        owner: String,
        quarter: String,
        weeksInQuarter: Int,
        vision: String,
        goals: [Goal],
        scores: [String: [String: Double]],
        dailyScores: [String: [String: Double]] = [:]
    ) {
        self.owner = owner
        self.quarter = quarter
        self.weeksInQuarter = weeksInQuarter
        self.vision = vision
        self.goals = goals
        self.scores = scores
        self.dailyScores = dailyScores
    }

    // Custom decoding: dailyScores is optional in the JSON so plans saved by
    // older app versions and web-app exports (which never write it) still import
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.owner = try container.decode(String.self, forKey: .owner)
        self.quarter = try container.decode(String.self, forKey: .quarter)
        self.weeksInQuarter = try container.decode(Int.self, forKey: .weeksInQuarter)
        self.vision = try container.decode(String.self, forKey: .vision)
        self.goals = try container.decode([Goal].self, forKey: .goals)
        self.scores = try container.decode([String: [String: Double]].self, forKey: .scores)
        self.dailyScores = try container.decodeIfPresent([String: [String: Double]].self, forKey: .dailyScores) ?? [:]
    }

    static func defaultPlan() -> Plan {
        Plan(
            owner: "Jules",
            quarter: "Q3 2026",
            weeksInQuarter: 13,
            vision: """
                I want to be living a healthy lifestyle that allows me to be fully present \
                in my goal of having a strong relationship with my family, friends, and God; \
                in my goal of having a toolkit of techniques at my disposal to deal with my emotions; \
                in my goal of having multiple assets that allow me to exercise my creativity and \
                drive enough income for me to have the option to retire at 45 years old; \
                and to speak multiple languages.
                """,
            goals: [
                Goal(
                    id: "healthy",
                    emoji: "💪",
                    name: "Healthy Lifestyle",
                    why: "That's the base of everything. In whatever I try to do, I need to make sure I'm healthy — physically, mentally, and spiritually.",
                    habits: [
                        Habit(id: "workout", name: "Workout", unit: "days", target: 7),
                        Habit(id: "vitamins", name: "Take vitamins", unit: "days", target: 7),
                        Habit(id: "cleanEating", name: "Clean eating", unit: "days", target: 7)
                    ]
                ),
                Goal(
                    id: "relationships",
                    emoji: "❤️",
                    name: "Strong Relationships",
                    why: "You only get one family in this life, and I want to help take care of them the same way they've taken care of me. Beyond family, having someone choose to spend time with you is something special — I want to do my part to be a good friend. And I want a strong relationship with God because my faith is my foundation.",
                    habits: [
                        Habit(id: "calls", name: "Phone calls", unit: "calls", target: 2),
                        Habit(id: "fellowship", name: "Days with fellowship", unit: "days", target: 1)
                    ]
                ),
                Goal(
                    id: "toolkit",
                    emoji: "🧘",
                    name: "Mental Toolkit",
                    why: "Relying on a substance builds addiction, and I don't want to be addicted to anything that can be replaced with something I can do on my own to feel the same way. I want a proper routine to deal with my issues.",
                    habits: [
                        Habit(id: "breathing", name: "5-min breathing", unit: "days", target: 7)
                    ]
                ),
                Goal(
                    id: "assets",
                    emoji: "🎨",
                    name: "Multiple Assets",
                    why: "It's a very special thing to create something in this world that you can share with others — something you truly dove deep into your creativity bag to make. Money-maker or just for fun, I want to create and acquire assets.",
                    habits: [
                        Habit(id: "creative", name: "Creative work", unit: "hours", target: 2)
                    ]
                ),
                Goal(
                    id: "retire45",
                    emoji: "🏖️",
                    name: "Retire at 45",
                    why: "There's a lot I want to do in life that requires time, and the biggest time consumer is my job. Waking up every day with the energy to decide what I want to do in pursuit of my goals sounds way too exciting. In my 40s I'll still have the energy to chase my dreams — with twice the time.",
                    habits: [
                        Habit(id: "reading", name: "Reading", unit: "minutes", target: 30)
                    ]
                ),
                Goal(
                    id: "languages",
                    emoji: "🗣️",
                    name: "Multiple Languages",
                    why: "I want to speak Haitian Creole and French to deeply connect with my culture and family, and pass the language on to my kids. I want to travel back to Haiti with my family and connect with the people there on a deep level. French opens up even more family connections and the chance to live freely where English isn't the main language.",
                    habits: [
                        Habit(id: "classes", name: "Language classes", unit: "classes", target: 2)
                    ]
                )
            ],
            scores: [
                "1": [
                    "workout": 3,
                    "vitamins": 6,
                    "cleanEating": 6,
                    "calls": 2,
                    "fellowship": 0.5,
                    "breathing": 6,
                    "creative": 2,
                    "reading": 30,
                    "classes": 2
                ]
            ]
        )
    }
}

struct Goal: Codable, Equatable, Identifiable {
    var id: String
    var emoji: String
    var name: String
    var why: String
    var habits: [Habit]
}

struct Habit: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var unit: String
    var target: Double
}

extension Plan {
    /// True when the stored quarter no longer matches the calendar quarter,
    /// meaning scores belong to a previous quarter and must not be overwritten
    var needsRollover: Bool {
        quarter != Scoring.currentQuarterString()
    }

    /// A copy of this plan rolled over to a new quarter:
    /// goals and vision carry forward, scores start fresh
    func rolledOver(to newQuarter: String) -> Plan {
        var next = self
        next.quarter = newQuarter
        next.scores = [:]
        next.dailyScores = [:]
        return next
    }

    /// All habits across all goals, in display order
    var allHabits: [Habit] {
        goals.flatMap(\.habits)
    }

    /// What was logged for this habit today (nil if nothing yet)
    func todayContribution(for habit: Habit, now: Date = Date()) -> Double? {
        dailyScores[Scoring.dayKey(for: now)]?[habit.id]
    }

    /// This habit's weekly total for the given week (nil if unlogged)
    func weekTotal(for habit: Habit, week: Int) -> Double? {
        scores[String(week)]?[habit.id]
    }

    /// A copy of this plan with a daily log applied and the week's dailies
    /// rolled up into the weekly total. A manually entered weekly value beyond
    /// the previous daily sum is preserved as a baseline, so backfilled weeks
    /// and daily taps combine instead of clobbering each other.
    /// Pure so both the app (PlanStore) and the widget intent can use it.
    func loggingDaily(habitId: String, value: Double?, date: Date = Date()) -> Plan {
        var next = self
        let dayKey = Scoring.dayKey(for: date)
        let week = Scoring.currentWeekOfQuarter(now: date, maxWeek: next.weeksInQuarter)
        let weekKeys = Scoring.dayKeys(inWeek: week, reference: date)
        let weekKey = String(week)

        // Manual baseline = existing weekly value minus what dailies accounted for
        let oldSum = weekKeys.compactMap { next.dailyScores[$0]?[habitId] }.reduce(0, +)
        let oldWeekly = next.scores[weekKey]?[habitId] ?? 0
        let baseline = max(0, oldWeekly - oldSum)

        // Write or remove the daily entry
        if let value = value {
            next.dailyScores[dayKey, default: [:]][habitId] = value
        } else {
            next.dailyScores[dayKey]?.removeValue(forKey: habitId)
            if next.dailyScores[dayKey]?.isEmpty == true {
                next.dailyScores.removeValue(forKey: dayKey)
            }
        }

        // Roll up into the weekly total
        let newSum = weekKeys.compactMap { next.dailyScores[$0]?[habitId] }.reduce(0, +)
        let hasAnyDaily = weekKeys.contains { next.dailyScores[$0]?[habitId] != nil }

        if hasAnyDaily || baseline > 0 {
            next.scores[weekKey, default: [:]][habitId] = newSum + baseline
        } else {
            next.scores[weekKey]?.removeValue(forKey: habitId)
            if next.scores[weekKey]?.isEmpty == true {
                next.scores.removeValue(forKey: weekKey)
            }
        }

        return next
    }
}
