import Foundation

// MARK: - Streak Calculation
// Counts consecutive logged weeks >= threshold, counting backward from latest

enum Streaks {

    /// Calculate overall weekly streak
    /// Counts consecutive weeks with weekPct >= threshold, starting from the latest logged week
    static func weeklyStreak(plan: Plan, threshold: Double = 0.8) -> Int {
        streak(logged: Scoring.loggedWeeks(plan: plan), threshold: threshold) {
            Scoring.weekPct(plan: plan, week: $0)
        }
    }

    /// Calculate per-goal streak
    /// Counts consecutive weeks with goalPct >= threshold for a specific goal
    static func goalStreak(plan: Plan, goal: Goal, threshold: Double = 0.8) -> Int {
        streak(logged: Scoring.loggedWeeks(plan: plan), threshold: threshold) {
            Scoring.goalPct(plan: plan, goal: goal, week: $0)
        }
    }

    /// Walk backward from the latest logged week, counting consecutive
    /// weeks whose percentage meets the threshold; a gap or miss ends the streak
    private static func streak(logged: [Int], threshold: Double, pct: (Int) -> Double?) -> Int {
        var streak = 0
        var previousWeek: Int? = nil

        for week in logged.sorted().reversed() {
            guard let weekPct = pct(week) else { continue }
            guard weekPct >= threshold else { break }

            if let prev = previousWeek {
                guard week == prev - 1 else { break }  // Gap detected
                streak += 1
            } else {
                streak = 1
            }
            previousWeek = week
        }

        return streak
    }

    /// Find the best (highest) week percentage in the quarter
    static func bestWeek(plan: Plan) -> (week: Int, pct: Double)? {
        let logged = Scoring.loggedWeeks(plan: plan)
        guard !logged.isEmpty else { return nil }

        var bestWeek = logged[0]
        var bestPct = Scoring.weekPct(plan: plan, week: bestWeek) ?? 0

        for week in logged.dropFirst() {
            if let pct = Scoring.weekPct(plan: plan, week: week), pct > bestPct {
                bestWeek = week
                bestPct = pct
            }
        }

        return (bestWeek, bestPct)
    }

    /// Get the latest logged week
    static func latestWeek(plan: Plan) -> (week: Int, pct: Double)? {
        let logged = Scoring.loggedWeeks(plan: plan)
        guard let last = logged.last else { return nil }

        guard let pct = Scoring.weekPct(plan: plan, week: last) else { return nil }
        return (last, pct)
    }
}
