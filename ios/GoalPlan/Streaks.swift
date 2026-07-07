import Foundation

// MARK: - Streak Calculation
// Counts consecutive logged weeks >= threshold, counting backward from latest

enum Streaks {

    /// Calculate overall weekly streak
    /// Counts consecutive weeks with weekPct >= threshold, starting from the latest logged week
    static func weeklyStreak(plan: Plan, threshold: Double = 0.8) -> Int {
        let logged = Scoring.loggedWeeks(plan: plan).sorted()
        guard !logged.isEmpty else { return 0 }

        var streak = 0
        var previousWeek: Int? = nil

        // Iterate backward from the latest logged week
        for week in logged.reversed() {
            guard let pct = Scoring.weekPct(plan: plan, week: week) else { continue }

            // Check if this week meets the threshold
            if pct >= threshold {
                // Check if this is consecutive with the previous week (or the first week)
                if let prev = previousWeek {
                    if week == prev - 1 {
                        streak += 1
                        previousWeek = week
                    } else {
                        // Gap detected, stop counting
                        break
                    }
                } else {
                    // First week in the streak
                    streak = 1
                    previousWeek = week
                }
            } else {
                // Week didn't meet threshold, stop
                break
            }
        }

        return streak
    }

    /// Calculate per-goal streak
    /// Counts consecutive weeks with goalPct >= threshold for a specific goal
    static func goalStreak(plan: Plan, goal: Goal, threshold: Double = 0.8) -> Int {
        let logged = Scoring.loggedWeeks(plan: plan).sorted()
        guard !logged.isEmpty else { return 0 }

        var streak = 0
        var previousWeek: Int? = nil

        // Iterate backward from the latest logged week
        for week in logged.reversed() {
            guard let pct = Scoring.goalPct(plan: plan, goal: goal, week: week) else { continue }

            // Check if this week meets the threshold
            if pct >= threshold {
                // Check if this is consecutive with the previous week (or the first week)
                if let prev = previousWeek {
                    if week == prev - 1 {
                        streak += 1
                        previousWeek = week
                    } else {
                        // Gap detected, stop counting
                        break
                    }
                } else {
                    // First week in the streak
                    streak = 1
                    previousWeek = week
                }
            } else {
                // Week didn't meet threshold, stop
                break
            }
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
