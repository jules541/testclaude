import Foundation
import WidgetKit
import Observation
import os

/// Observable store for the plan data
/// Uses iOS 17's @Observable macro for automatic change tracking
@Observable
final class PlanStore {

    var plan: Plan {
        didSet {
            savePlan()
            reloadWidget()
            // Pending notification content is computed at schedule time,
            // so it must be rebuilt whenever the underlying data changes
            NotificationManager.shared.scheduleAllNotifications()
        }
    }

    var streakThreshold: Double {
        didSet {
            UserDefaults.standard.set(streakThreshold, forKey: "streakThreshold")
        }
    }

    init() {
        // Load streak threshold from UserDefaults (default 80%)
        self.streakThreshold = UserDefaults.standard.object(forKey: "streakThreshold") as? Double ?? 0.8

        // Load plan from shared container or use default
        if let loaded = SharedContainer.loadPlan() {
            self.plan = loaded
        } else {
            self.plan = Plan.defaultPlan()
            savePlan()  // Save default plan immediately
        }

        rollOverIfNeeded()
    }

    // MARK: - Quarter Rollover

    /// Archive the finished quarter and start fresh when the calendar quarter changes.
    /// Scores are only cleared if the archive write succeeds, so data is never lost.
    /// Call on launch and whenever the app returns to the foreground.
    func rollOverIfNeeded() {
        guard plan.needsRollover else { return }
        do {
            try SharedContainer.archivePlan(plan)
            plan = plan.rolledOver(to: Scoring.currentQuarterString())
        } catch {
            Self.logger.error("Quarter rollover skipped — archiving \(self.plan.quarter) failed: \(error)")
        }
    }

    // MARK: - Persistence

    private static let logger = Logger(subsystem: "com.goalplan.GoalPlan", category: "store")

    private func savePlan() {
        do {
            try SharedContainer.savePlan(plan)
        } catch {
            Self.logger.error("Failed to save plan: \(error)")
        }
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Plan Mutations

    func updateVision(_ vision: String) {
        plan.vision = vision
    }

    func updatePlanSettings(owner: String, quarter: String, weeksInQuarter: Int) {
        plan.owner = owner
        plan.quarter = quarter
        plan.weeksInQuarter = max(1, min(weeksInQuarter, 27))
    }

    func addGoal(_ goal: Goal) {
        plan.goals.append(goal)
    }

    func updateGoal(_ goal: Goal) {
        if let index = plan.goals.firstIndex(where: { $0.id == goal.id }) {
            plan.goals[index] = goal
        }
    }

    func deleteGoal(id: String) {
        // Capture habit ids before removal so their scores can be cleaned up
        guard let goal = plan.goals.first(where: { $0.id == id }) else { return }
        let habitIds = Set(goal.habits.map(\.id))

        var next = plan
        next.goals.removeAll { $0.id == id }
        next.scores = next.scores.mapValues { week in
            week.filter { !habitIds.contains($0.key) }
        }
        plan = next
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        plan.goals.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Score Mutations

    /// Manual weekly entry (Tracker tab). Overrides daily logs: the habit's
    /// daily entries for that week are cleared so a later daily tap starts
    /// from this value as its baseline instead of re-summing stale days.
    func updateScore(week: Int, habitId: String, value: Double?) {
        var next = plan
        Self.removeDailyEntries(from: &next, habitId: habitId, week: week)

        let weekKey = String(week)
        if let value = value {
            next.scores[weekKey, default: [:]][habitId] = value
        } else {
            next.scores[weekKey]?.removeValue(forKey: habitId)
            if next.scores[weekKey]?.isEmpty == true {
                next.scores.removeValue(forKey: weekKey)
            }
        }
        plan = next
    }

    func clearWeekScores(week: Int) {
        var next = plan
        next.scores.removeValue(forKey: String(week))
        for key in Self.dayKeys(inWeek: week) {
            next.dailyScores.removeValue(forKey: key)
        }
        plan = next
    }

    // MARK: - Daily Logging

    /// Log what was done today (or on `date`) for a habit, then roll the week's
    /// daily logs up into the weekly total. Any manual weekly value beyond the
    /// previous daily sum is preserved as a baseline, so backfilled weeks and
    /// daily taps combine instead of clobbering each other.
    func logDaily(habitId: String, value: Double?, date: Date = Date()) {
        var next = plan
        let dayKey = Scoring.dayKey(for: date)
        let week = Scoring.currentWeekOfQuarter(now: date, maxWeek: next.weeksInQuarter)
        let weekKeys = Self.dayKeys(inWeek: week, reference: date)
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

        plan = next
    }

    /// Day keys ("yyyy-MM-dd") for the 7 days of a quarter week.
    /// `reference` picks which calendar quarter the week belongs to.
    private static func dayKeys(inWeek week: Int, reference: Date = Date()) -> [String] {
        let calendar = Calendar.current
        let quarterStart = Scoring.quarterStartDate(now: reference)
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: (week - 1) * 7 + day, to: quarterStart)
                .map { Scoring.dayKey(for: $0) }
        }
    }

    /// Remove a habit's daily entries for a week, dropping empty day dicts
    private static func removeDailyEntries(from plan: inout Plan, habitId: String, week: Int) {
        for key in dayKeys(inWeek: week) {
            plan.dailyScores[key]?.removeValue(forKey: habitId)
            if plan.dailyScores[key]?.isEmpty == true {
                plan.dailyScores.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Import/Export

    func exportJSON() throws -> Data {
        return try SharedContainer.exportPlan(plan)
    }

    func importJSON(data: Data) throws {
        let imported = try SharedContainer.importPlan(from: data)
        plan = imported
    }

    func resetToDefault() {
        plan = Plan.defaultPlan()
    }

    // MARK: - ID Generation

    func newGoalId() -> String {
        "g-" + UUID().uuidString.prefix(8).lowercased()
    }

    func newHabitId() -> String {
        "h-" + UUID().uuidString.prefix(8).lowercased()
    }
}
