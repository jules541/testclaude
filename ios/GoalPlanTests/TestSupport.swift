import Foundation
@testable import GoalPlan

// MARK: - Shared Test Fixtures

/// Build a Date from components using the current calendar
func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
}

/// A small two-goal plan: g1 (workout 7, vitamins 7) and g2 (reading 30)
func makePlan(scores: [String: [String: Double]] = [:], weeksInQuarter: Int = 13) -> Plan {
    Plan(
        owner: "Test",
        quarter: "Q3 2026",
        weeksInQuarter: weeksInQuarter,
        vision: "",
        goals: [
            Goal(id: "g1", emoji: "💪", name: "Fitness", why: "", habits: [
                Habit(id: "workout", name: "Workout", unit: "days", target: 7),
                Habit(id: "vitamins", name: "Vitamins", unit: "days", target: 7)
            ]),
            Goal(id: "g2", emoji: "📚", name: "Learning", why: "", habits: [
                Habit(id: "reading", name: "Reading", unit: "minutes", target: 30)
            ])
        ],
        scores: scores
    )
}

/// Scores that produce weekPct == 1.0 for makePlan()
func fullWeek() -> [String: Double] {
    ["workout": 7, "vitamins": 7, "reading": 30]
}

/// Scores that produce weekPct == 0.5 for makePlan()
func halfWeek() -> [String: Double] {
    ["workout": 3.5, "vitamins": 3.5, "reading": 15]
}
