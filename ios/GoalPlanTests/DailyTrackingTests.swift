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
