import Foundation
import Testing
@testable import GoalPlan

@Suite("Weekly streaks")
struct WeeklyStreakTests {

    @Test("counts consecutive weeks at or above threshold")
    func consecutiveWeeksCount() {
        let plan = makePlan(scores: ["1": fullWeek(), "2": fullWeek(), "3": fullWeek()])
        #expect(Streaks.weeklyStreak(plan: plan) == 3)
    }

    @Test("stops at a week below threshold")
    func breaksBelowThreshold() {
        let plan = makePlan(scores: ["1": fullWeek(), "2": halfWeek(), "3": fullWeek()])
        #expect(Streaks.weeklyStreak(plan: plan) == 1)
    }

    @Test("stops at a gap in logged weeks")
    func breaksOnGap() {
        let plan = makePlan(scores: ["1": fullWeek(), "2": fullWeek(), "4": fullWeek()])
        #expect(Streaks.weeklyStreak(plan: plan) == 1)
    }

    @Test("returns zero with no logged weeks")
    func zeroWhenEmpty() {
        #expect(Streaks.weeklyStreak(plan: makePlan()) == 0)
    }

    @Test("respects a custom threshold")
    func customThreshold() {
        let plan = makePlan(scores: ["1": halfWeek(), "2": halfWeek()])
        #expect(Streaks.weeklyStreak(plan: plan, threshold: 0.5) == 2)
        #expect(Streaks.weeklyStreak(plan: plan, threshold: 0.8) == 0)
    }
}

@Suite("Per-goal streaks")
struct GoalStreakTests {

    @Test("tracks a single goal independently of others")
    func goalIndependence() {
        // g1 (workout+vitamins) full both weeks; g2 (reading) at half
        let scores: [String: [String: Double]] = [
            "1": ["workout": 7, "vitamins": 7, "reading": 15],
            "2": ["workout": 7, "vitamins": 7, "reading": 15]
        ]
        let plan = makePlan(scores: scores)
        #expect(Streaks.goalStreak(plan: plan, goal: plan.goals[0]) == 2)
        #expect(Streaks.goalStreak(plan: plan, goal: plan.goals[1]) == 0)
    }
}

@Suite("Best and latest weeks")
struct BestLatestWeekTests {

    @Test("bestWeek finds the highest scoring week")
    func bestWeekFindsHighest() {
        let plan = makePlan(scores: ["1": halfWeek(), "2": fullWeek(), "3": halfWeek()])
        let best = Streaks.bestWeek(plan: plan)
        #expect(best?.week == 2)
        #expect(best?.pct == 1.0)
    }

    @Test("latestWeek returns the last logged week")
    func latestWeekIsLastLogged() {
        let plan = makePlan(scores: ["1": fullWeek(), "5": halfWeek()])
        let latest = Streaks.latestWeek(plan: plan)
        #expect(latest?.week == 5)
        #expect(latest?.pct == 0.5)
    }

    @Test("both are nil with no logged weeks")
    func nilWhenEmpty() {
        #expect(Streaks.bestWeek(plan: makePlan()) == nil)
        #expect(Streaks.latestWeek(plan: makePlan()) == nil)
    }
}
