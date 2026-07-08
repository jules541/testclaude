import Foundation
import Testing
@testable import GoalPlan

// MARK: - Percentage Math

@Suite("Habit and week percentages")
struct HabitPctTests {

    @Test("habitPct caps at 100% when value exceeds target")
    func habitPctCapsAtFull() {
        let habit = Habit(id: "h", name: "H", unit: "days", target: 7)
        #expect(Scoring.habitPct(habit: habit, value: 14) == 1.0)
    }

    @Test("habitPct returns nil when value is not logged")
    func habitPctNilValue() {
        let habit = Habit(id: "h", name: "H", unit: "days", target: 7)
        #expect(Scoring.habitPct(habit: habit, value: nil) == nil)
    }

    @Test("habitPct returns nil for a zero target")
    func habitPctZeroTarget() {
        let habit = Habit(id: "h", name: "H", unit: "days", target: 0)
        #expect(Scoring.habitPct(habit: habit, value: 3) == nil)
    }

    @Test("goalPct averages logged habits and ignores unlogged ones")
    func goalPctIgnoresUnlogged() {
        let plan = makePlan(scores: ["1": ["workout": 3.5]])  // vitamins unlogged
        let goal = plan.goals[0]
        #expect(Scoring.goalPct(plan: plan, goal: goal, week: 1) == 0.5)
    }

    @Test("weekPct averages goal percentages")
    func weekPctAveragesGoals() {
        // g1: workout 3.5/7 + vitamins 3.5/7 → 0.5; g2: reading 30/30 → 1.0
        let plan = makePlan(scores: ["1": ["workout": 3.5, "vitamins": 3.5, "reading": 30]])
        #expect(Scoring.weekPct(plan: plan, week: 1) == 0.75)
    }

    @Test("weekPct is nil when nothing is logged")
    func weekPctNilWhenEmpty() {
        let plan = makePlan()
        #expect(Scoring.weekPct(plan: plan, week: 1) == nil)
    }

    @Test("quarterPct averages only logged weeks")
    func quarterPctAveragesLoggedWeeks() {
        let plan = makePlan(scores: ["1": fullWeek(), "2": halfWeek()])
        #expect(Scoring.quarterPct(plan: plan) == 0.75)
    }

    @Test("nextWeekToLog finds first unlogged week")
    func nextWeekToLogFirstGap() {
        let plan = makePlan(scores: ["1": fullWeek(), "2": fullWeek()])
        #expect(Scoring.nextWeekToLog(plan: plan) == 3)
    }

    @Test("nextWeekToLog returns last week when all are logged")
    func nextWeekToLogAllLogged() {
        var scores: [String: [String: Double]] = [:]
        for week in 1...13 { scores[String(week)] = fullWeek() }
        let plan = makePlan(scores: scores)
        #expect(Scoring.nextWeekToLog(plan: plan) == 13)
    }
}

// MARK: - Formatting and Colors

@Suite("Formatting and color thresholds")
struct FormattingTests {

    @Test("formatPct rounds to whole percent")
    func formatPctRounds() {
        #expect(Scoring.formatPct(0.746) == "75%")
        #expect(Scoring.formatPct(0) == "0%")
        #expect(Scoring.formatPct(1.0) == "100%")
    }

    @Test("formatPct shows dash for nil")
    func formatPctNil() {
        #expect(Scoring.formatPct(nil) == "—")
    }

    @Test("pctColor thresholds", arguments: [
        (nil as Double?, PctColor.none),
        (1.0, PctColor.full),
        (0.7, PctColor.good),
        (0.69, PctColor.mid),
        (0.4, PctColor.mid),
        (0.39, PctColor.low)
    ])
    func pctColorThresholds(pct: Double?, expected: PctColor) {
        #expect(Scoring.pctColor(pct) == expected)
    }
}

// MARK: - Date-Based Quarter and Week

@Suite("Calendar quarter and week calculations")
struct QuarterDateTests {

    @Test("currentQuarter maps months to quarters", arguments: [
        (1, 15, 1), (3, 31, 1),   // Jan/Mar → Q1
        (4, 1, 2), (6, 28, 2),    // Apr/Jun → Q2
        (7, 6, 3), (9, 30, 3),    // Jul/Sep → Q3
        (10, 1, 4), (12, 31, 4)   // Oct/Dec → Q4
    ])
    func currentQuarterMapping(month: Int, day: Int, expectedQuarter: Int) {
        let result = Scoring.currentQuarter(now: makeDate(2026, month, day))
        #expect(result.quarter == expectedQuarter)
        #expect(result.year == 2026)
    }

    @Test("currentWeekOfQuarter is 1 throughout the quarter's first calendar week")
    func weekOneAtQuarterStart() {
        let quarterStart = makeDate(2026, 7, 1)
        #expect(Scoring.currentWeekOfQuarter(now: quarterStart) == 1)
        // The last day of that same calendar week is still week 1
        let weekEnd = Scoring.currentWeekEndDate(now: quarterStart)
        #expect(Scoring.currentWeekOfQuarter(now: weekEnd) == 1)
    }

    @Test("currentWeekOfQuarter increments at the calendar week boundary")
    func weekTwoAfterBoundary() {
        let quarterStart = makeDate(2026, 7, 1)
        let weekEnd = Scoring.currentWeekEndDate(now: quarterStart)
        let nextWeekDay = Calendar.current.date(byAdding: .day, value: 1, to: weekEnd)!
        #expect(Scoring.currentWeekOfQuarter(now: nextWeekDay) == 2)
    }

    @Test("currentWeekOfQuarter clamps to 13 at quarter end")
    func weekClampsAtQuarterEnd() {
        #expect(Scoring.currentWeekOfQuarter(now: makeDate(2026, 9, 30)) == 13)
    }

    @Test("currentQuarterString formats as Q# YYYY")
    func quarterStringFormat() {
        #expect(Scoring.currentQuarterString(now: makeDate(2026, 7, 6)) == "Q3 2026")
    }

    @Test("yearProgress stays within 0...1 and grows through the year")
    func yearProgressBounds() {
        let early = Scoring.yearProgress(now: makeDate(2026, 1, 2))
        let late = Scoring.yearProgress(now: makeDate(2026, 12, 30))
        #expect(early > 0 && early < 0.02)
        #expect(late > 0.98 && late < 1)
        #expect(early < late)
    }

    @Test("daysRemainingInYear counts to Jan 1")
    func daysRemaining() {
        #expect(Scoring.daysRemainingInYear(now: makeDate(2026, 12, 31)) == 1)
    }
}

// MARK: - Quarter Rollover

@Suite("Plan quarter rollover")
struct RolloverTests {

    @Test("rolledOver clears scores and updates quarter, keeping goals")
    func rolloverResetsScoresKeepsGoals() {
        let plan = makePlan(scores: ["1": fullWeek(), "5": halfWeek()])
        let next = plan.rolledOver(to: "Q4 2026")

        #expect(next.quarter == "Q4 2026")
        #expect(next.scores.isEmpty)
        #expect(next.goals == plan.goals)
        #expect(next.vision == plan.vision)
        #expect(next.owner == plan.owner)
    }

    @Test("needsRollover is false for the current calendar quarter")
    func noRolloverForCurrentQuarter() {
        var plan = makePlan()
        plan.quarter = Scoring.currentQuarterString()
        #expect(plan.needsRollover == false)
    }

    @Test("needsRollover is true for a past quarter")
    func rolloverForPastQuarter() {
        var plan = makePlan()
        plan.quarter = "Q1 1999"
        #expect(plan.needsRollover == true)
    }
}
