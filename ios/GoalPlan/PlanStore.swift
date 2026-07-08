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
        resyncWeeklyTotalsIfNeeded()
        refreshFocusForToday()
    }

    // MARK: - Week Model Migration

    /// One-time fix-up after weeks changed from quarter-start-anchored blocks
    /// to calendar weeks: weekly totals rolled up under the old mapping can sit
    /// in the wrong week (e.g. a Tuesday log filed one week behind). For every
    /// habit that has daily logs, recompute each week's total from the dailies
    /// under the new mapping. Manual-only weekly entries are left untouched.
    private func resyncWeeklyTotalsIfNeeded() {
        let flag = "weekModelV2Resynced"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        UserDefaults.standard.set(true, forKey: flag)
        plan = Self.resyncWeeklyTotals(plan)
    }

    /// Pure core of the migration, separated for testability
    static func resyncWeeklyTotals(_ plan: Plan, reference: Date = Date()) -> Plan {
        let habitsWithDailies = Set(plan.dailyScores.values.flatMap { $0.keys })
        guard !habitsWithDailies.isEmpty else { return plan }

        var next = plan
        for habitId in habitsWithDailies {
            for week in 1...next.weeksInQuarter {
                let weekKey = String(week)
                let sum = Scoring.dayKeys(inWeek: week, reference: reference)
                    .compactMap { next.dailyScores[$0]?[habitId] }
                    .reduce(0, +)

                if sum > 0 {
                    next.scores[weekKey, default: [:]][habitId] = sum
                } else if next.scores[weekKey]?[habitId] != nil {
                    // Old roll-up left a value here but no dailies map to this
                    // week anymore — drop it so it doesn't double-count
                    next.scores[weekKey]?.removeValue(forKey: habitId)
                    if next.scores[weekKey]?.isEmpty == true {
                        next.scores.removeValue(forKey: weekKey)
                    }
                }
            }
        }
        return next
    }

    // MARK: - Today's Focus

    /// Habit ids the user chose to focus on today (per-day, device-local)
    private(set) var todayFocusIds: [String] = []
    private var focusDayKey = ""

    /// Reload the focus list when the day changes (call on appear/foreground)
    func refreshFocusForToday(now: Date = Date()) {
        let dayKey = Scoring.dayKey(for: now)
        guard dayKey != focusDayKey else { return }
        focusDayKey = dayKey
        todayFocusIds = UserDefaults.standard.stringArray(forKey: "focusHabits-\(dayKey)") ?? []
    }

    func toggleFocus(habitId: String, now: Date = Date()) {
        refreshFocusForToday(now: now)
        if let index = todayFocusIds.firstIndex(of: habitId) {
            todayFocusIds.remove(at: index)
        } else {
            todayFocusIds.append(habitId)
        }
        UserDefaults.standard.set(todayFocusIds, forKey: "focusHabits-\(focusDayKey)")
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
        for key in Scoring.dayKeys(inWeek: week) {
            next.dailyScores.removeValue(forKey: key)
        }
        plan = next
    }

    // MARK: - Daily Logging

    /// Log what was done today (or on `date`) for a habit; the week's daily
    /// logs roll up into the weekly total (see Plan.loggingDaily)
    func logDaily(habitId: String, value: Double?, date: Date = Date()) {
        plan = plan.loggingDaily(habitId: habitId, value: value, date: date)
    }

    /// Remove a habit's daily entries for a week, dropping empty day dicts
    private static func removeDailyEntries(from plan: inout Plan, habitId: String, week: Int) {
        for key in Scoring.dayKeys(inWeek: week) {
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
