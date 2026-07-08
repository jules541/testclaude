import Foundation
import Testing
@testable import GoalPlan

// MARK: - Date Keys and Day Activity

@Suite("Day keys and activity")
struct DayActivityTests {

    @Test("dayKey formats as yyyy-MM-dd")
    func dayKeyFormat() {
        #expect(Scoring.dayKey(for: makeDate(2026, 7, 6)) == "2026-07-06")
        #expect(Scoring.dayKey(for: makeDate(2026, 1, 3)) == "2026-01-03")
    }

    @Test("dayActivity is nil when nothing was logged that day")
    func dayActivityNilWhenEmpty() {
        let plan = makePlan()
        #expect(Scoring.dayActivity(plan: plan, date: makeDate(2026, 7, 6)) == nil)
    }

    @Test("dayActivity counts logged habits out of all habits")
    func dayActivityCounts() {
        let plan = makePlan(dailyScores: ["2026-07-06": ["workout": 1]])
        let activity = Scoring.dayActivity(plan: plan, date: makeDate(2026, 7, 6))
        #expect(activity?.logged == 1)
        #expect(activity?.total == 3)
    }

    @Test("dayActivity ignores entries for deleted habits")
    func dayActivityIgnoresUnknownHabits() {
        let plan = makePlan(dailyScores: ["2026-07-06": ["ghost": 1]])
        #expect(Scoring.dayActivity(plan: plan, date: makeDate(2026, 7, 6)) == nil)
    }

    @Test("daysOfCurrentWeek returns 7 consecutive dates containing now")
    func daysOfWeekSpan() {
        let now = Date()
        let days = Scoring.daysOfCurrentWeek(now: now)
        #expect(days.count == 7)
        let keys = days.map { Scoring.dayKey(for: $0) }
        #expect(keys.contains(Scoring.dayKey(for: now)))
        #expect(Set(keys).count == 7)
    }
}

// MARK: - Daily Logging Roll-Up

@Suite("Daily log roll-up into weekly totals", .serialized)
struct LogDailyTests {

    @Test("logs on different days sum into the weekly score")
    func dailyLogsSumIntoWeek() {
        let store = PlanStore()
        store.plan = makePlan()

        store.logDaily(habitId: "workout", value: 1, date: dayIntoQuarter(0))
        store.logDaily(habitId: "workout", value: 2, date: dayIntoQuarter(1))

        let week = Scoring.currentWeekOfQuarter(now: dayIntoQuarter(0))
        #expect(store.plan.scores[String(week)]?["workout"] == 3)
    }

    @Test("removing a daily log re-sums the week")
    func removingDailyLogResums() {
        let store = PlanStore()
        store.plan = makePlan()

        store.logDaily(habitId: "workout", value: 1, date: dayIntoQuarter(0))
        store.logDaily(habitId: "workout", value: 2, date: dayIntoQuarter(1))
        store.logDaily(habitId: "workout", value: nil, date: dayIntoQuarter(0))

        let week = Scoring.currentWeekOfQuarter(now: dayIntoQuarter(0))
        #expect(store.plan.scores[String(week)]?["workout"] == 2)
        #expect(store.plan.dailyScores[Scoring.dayKey(for: dayIntoQuarter(0))]?["workout"] == nil)
    }

    @Test("removing the only daily log clears the weekly entry")
    func removingLastDailyClearsWeek() {
        let store = PlanStore()
        store.plan = makePlan()

        store.logDaily(habitId: "workout", value: 1, date: dayIntoQuarter(0))
        store.logDaily(habitId: "workout", value: nil, date: dayIntoQuarter(0))

        let week = Scoring.currentWeekOfQuarter(now: dayIntoQuarter(0))
        #expect(store.plan.scores[String(week)]?["workout"] == nil)
    }

    @Test("manual weekly value becomes a baseline for later daily logs")
    func manualBaselinePreserved() {
        let store = PlanStore()
        store.plan = makePlan()
        let week = Scoring.currentWeekOfQuarter(now: dayIntoQuarter(0))

        store.updateScore(week: week, habitId: "workout", value: 5)
        store.logDaily(habitId: "workout", value: 1, date: dayIntoQuarter(0))

        #expect(store.plan.scores[String(week)]?["workout"] == 6)
    }

    @Test("manual weekly entry clears that habit's daily logs, others untouched")
    func manualOverrideClearsDailies() {
        let store = PlanStore()
        store.plan = makePlan()
        let day = dayIntoQuarter(0)
        let week = Scoring.currentWeekOfQuarter(now: day)

        store.logDaily(habitId: "workout", value: 2, date: day)
        store.logDaily(habitId: "vitamins", value: 3, date: day)
        store.updateScore(week: week, habitId: "workout", value: 7)

        let dayLog = store.plan.dailyScores[Scoring.dayKey(for: day)]
        #expect(dayLog?["workout"] == nil)
        #expect(dayLog?["vitamins"] == 3)
        #expect(store.plan.scores[String(week)]?["workout"] == 7)
        #expect(store.plan.scores[String(week)]?["vitamins"] == 3)
    }

    @Test("clearWeekScores removes the week's daily logs too")
    func clearWeekClearsDailies() {
        let store = PlanStore()
        store.plan = makePlan()
        let day = dayIntoQuarter(0)
        let week = Scoring.currentWeekOfQuarter(now: day)

        store.logDaily(habitId: "workout", value: 2, date: day)
        store.clearWeekScores(week: week)

        #expect(store.plan.scores[String(week)] == nil)
        #expect(store.plan.dailyScores[Scoring.dayKey(for: day)] == nil)
    }
}

// MARK: - Week Boundaries and Pure Logging

@Suite("Week boundary helpers (calendar weeks)")
struct WeekBoundaryTests {

    private let calendar = Calendar.current

    @Test("daysLeftInCurrentWeek is 7 on the calendar week's first day and 1 on its last")
    func daysLeftBounds() {
        let weekStart = Scoring.weekStart(of: makeDate(2026, 7, 8))
        let weekLast = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        #expect(Scoring.daysLeftInCurrentWeek(now: weekStart) == 7)
        #expect(Scoring.daysLeftInCurrentWeek(now: weekLast) == 1)
        #expect(Scoring.daysLeftInCurrentWeek(now: nextWeek) == 7)
    }

    @Test("currentWeekEndDate is the last day of the calendar week")
    func weekEndDate() {
        let anyDay = makeDate(2026, 7, 8)
        let weekStart = Scoring.weekStart(of: anyDay)
        let expected = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        #expect(Scoring.dayKey(for: Scoring.currentWeekEndDate(now: anyDay)) == Scoring.dayKey(for: expected))
        // Same answer anywhere in the same week
        #expect(Scoring.dayKey(for: Scoring.currentWeekEndDate(now: weekStart)) == Scoring.dayKey(for: expected))
    }

    @Test("dayKeys(inWeek:) covers the calendar week's 7 days")
    func dayKeysSpan() {
        let reference = makeDate(2026, 7, 8)
        let firstWeekStart = Scoring.weekStart(of: Scoring.quarterStartDate(now: reference))
        let week2Start = calendar.date(byAdding: .day, value: 7, to: firstWeekStart)!
        let week2Last = calendar.date(byAdding: .day, value: 13, to: firstWeekStart)!

        let keys = Scoring.dayKeys(inWeek: 2, reference: reference)
        #expect(keys.count == 7)
        #expect(keys.first == Scoring.dayKey(for: week2Start))
        #expect(keys.last == Scoring.dayKey(for: week2Last))
    }

    @Test("a date and its calendar-week sibling report the same quarter week")
    func siblingDaysShareWeek() {
        // The bug: Tue Jul 7 and Wed Jul 8 2026 fell into different quarter
        // weeks under quarter-start anchoring; calendar weeks keep them together
        let tuesday = makeDate(2026, 7, 7)
        let wednesday = makeDate(2026, 7, 8)
        if Scoring.weekStart(of: tuesday) == Scoring.weekStart(of: wednesday) {
            #expect(
                Scoring.currentWeekOfQuarter(now: tuesday) == Scoring.currentWeekOfQuarter(now: wednesday)
            )
        }
    }
}

@Suite("Suggested daily amounts")
struct SuggestedTodayTests {

    @Test("spreads the remainder over days left, rounded up per unit")
    func spreadsAndRounds() {
        let weekStart = Scoring.weekStart(of: makeDate(2026, 7, 8))
        // 2 days left → day 6 of the week
        let day = Calendar.current.date(byAdding: .day, value: 5, to: weekStart)!
        #expect(Scoring.daysLeftInCurrentWeek(now: day) == 2)

        // Reading: 22 min remaining / 2 days = 11 → rounds up to 15
        let reading = Habit(id: "r", name: "Reading", unit: "minutes", target: 30)
        #expect(Scoring.suggestedToday(habit: reading, weekTotal: 8, now: day) == 15)

        // Creative: 1.2 hr remaining / 2 days = 0.6 → rounds up to 1.0
        let creative = Habit(id: "c", name: "Creative", unit: "hours", target: 2)
        #expect(Scoring.suggestedToday(habit: creative, weekTotal: 0.8, now: day) == 1.0)

        // Workout: 3 remaining / 2 days = 1.5 → rounds up to 2
        let workout = Habit(id: "w", name: "Workout", unit: "days", target: 7)
        #expect(Scoring.suggestedToday(habit: workout, weekTotal: 4, now: day) == 2)
    }

    @Test("never suggests more than the remainder")
    func cappedAtRemainder() {
        let weekStart = Scoring.weekStart(of: makeDate(2026, 7, 8))
        let lastDay = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!

        // 3 min remaining on the last day: step-rounds to 5, capped at 3
        let reading = Habit(id: "r", name: "Reading", unit: "minutes", target: 30)
        #expect(Scoring.suggestedToday(habit: reading, weekTotal: 27, now: lastDay) == 3)
    }

    @Test("nil once the weekly target is met")
    func nilWhenDone() {
        let habit = Habit(id: "w", name: "Workout", unit: "days", target: 7)
        #expect(Scoring.suggestedToday(habit: habit, weekTotal: 7) == nil)
        #expect(Scoring.suggestedToday(habit: habit, weekTotal: 9) == nil)
    }
}

@Suite("Weekly totals resync migration")
struct ResyncTests {

    @Test("weekly totals move to the weeks the dailies now map to")
    func resyncMovesTotals() {
        let reference = makeDate(2026, 7, 8)
        let firstWeekStart = Scoring.weekStart(of: Scoring.quarterStartDate(now: reference))
        let week2Day = Calendar.current.date(byAdding: .day, value: 8, to: firstWeekStart)!

        // Old mapping filed this daily log's total under week 1
        let plan = makePlan(
            scores: ["1": ["creative": 2]],
            dailyScores: [Scoring.dayKey(for: week2Day): ["creative": 2]]
        )

        let synced = PlanStore.resyncWeeklyTotals(plan, reference: reference)
        #expect(synced.scores["1"]?["creative"] == nil)
        #expect(synced.scores["2"]?["creative"] == 2)
    }

    @Test("manual-only weekly entries are untouched")
    func manualEntriesSurvive() {
        // workout has a manual weekly value and no dailies anywhere
        let plan = makePlan(
            scores: ["3": ["workout": 5]],
            dailyScores: ["2026-07-08": ["reading": 10]]
        )
        let synced = PlanStore.resyncWeeklyTotals(plan, reference: makeDate(2026, 7, 8))
        #expect(synced.scores["3"]?["workout"] == 5)
    }
}

@Suite("Today's focus selection", .serialized)
struct FocusToggleTests {

    @Test("toggle adds then removes a habit for the given day")
    func toggleRoundTrip() {
        let testDay = makeDate(1999, 1, 5)  // synthetic day so real data is untouched
        let key = "focusHabits-\(Scoring.dayKey(for: testDay))"
        UserDefaults.standard.removeObject(forKey: key)
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let store = PlanStore()
        store.refreshFocusForToday(now: testDay)
        #expect(store.todayFocusIds.isEmpty)

        store.toggleFocus(habitId: "workout", now: testDay)
        #expect(store.todayFocusIds == ["workout"])
        #expect(UserDefaults.standard.stringArray(forKey: key) == ["workout"])

        store.toggleFocus(habitId: "workout", now: testDay)
        #expect(store.todayFocusIds.isEmpty)
    }
}

@Suite("Pure Plan.loggingDaily")
struct LoggingDailyPureTests {

    @Test("applies the daily entry and rolls up without mutating the original")
    func pureApplication() {
        let plan = makePlan()
        let day = dayIntoQuarter(0)
        let week = Scoring.currentWeekOfQuarter(now: day)

        let next = plan.loggingDaily(habitId: "workout", value: 2, date: day)

        #expect(plan.dailyScores.isEmpty)  // original untouched
        #expect(next.dailyScores[Scoring.dayKey(for: day)]?["workout"] == 2)
        #expect(next.scores[String(week)]?["workout"] == 2)
    }

    @Test("manual weekly baseline survives daily logging")
    func baselineSurvives() {
        let day = dayIntoQuarter(0)
        let week = Scoring.currentWeekOfQuarter(now: day)
        let plan = makePlan(scores: [String(week): ["workout": 5]])

        let next = plan.loggingDaily(habitId: "workout", value: 1, date: day)
        #expect(next.scores[String(week)]?["workout"] == 6)
    }
}

// MARK: - Rollover and Codable

@Suite("Daily scores rollover and persistence")
struct DailyPersistenceTests {

    @Test("rolledOver clears dailyScores")
    func rolloverClearsDailies() {
        let plan = makePlan(dailyScores: ["2026-07-06": ["workout": 1]])
        #expect(plan.rolledOver(to: "Q4 2026").dailyScores.isEmpty)
    }

    @Test("JSON without dailyScores decodes with empty dailies (backward compat)")
    func decodesLegacyJSON() throws {
        var legacy = makePlan(scores: ["1": ["workout": 3]])
        legacy.dailyScores = ["2026-07-06": ["workout": 1]]

        // Simulate an old export: strip dailyScores from the encoded JSON
        let encoded = try JSONEncoder().encode(legacy)
        var json = try #require(
            try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        json.removeValue(forKey: "dailyScores")
        let legacyData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(Plan.self, from: legacyData)
        #expect(decoded.dailyScores.isEmpty)
        #expect(decoded.scores["1"]?["workout"] == 3)
    }

    @Test("encoded plan includes dailyScores")
    func encodesDailyScores() throws {
        let plan = makePlan(dailyScores: ["2026-07-06": ["workout": 1]])
        let data = try JSONEncoder().encode(plan)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(json["dailyScores"] != nil)
    }
}
