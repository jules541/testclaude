import Foundation
import WidgetKit
import Observation

/// Observable store for the plan data
/// Uses iOS 17's @Observable macro for automatic change tracking
@Observable
final class PlanStore {

    var plan: Plan {
        didSet {
            savePlan()
            reloadWidget()
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
    }

    // MARK: - Persistence

    private func savePlan() {
        do {
            try SharedContainer.savePlan(plan)
        } catch {
            print("Failed to save plan: \(error)")
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
        plan.goals.removeAll { $0.id == id }
        // Also remove scores for habits from this goal
        for weekKey in plan.scores.keys {
            if let goal = plan.goals.first(where: { $0.id == id }) {
                for habit in goal.habits {
                    plan.scores[weekKey]?.removeValue(forKey: habit.id)
                }
            }
        }
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        plan.goals.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Score Mutations

    func updateScore(week: Int, habitId: String, value: Double?) {
        let weekKey = String(week)
        if plan.scores[weekKey] == nil {
            plan.scores[weekKey] = [:]
        }

        if let value = value {
            plan.scores[weekKey]?[habitId] = value
        } else {
            plan.scores[weekKey]?.removeValue(forKey: habitId)
        }
    }

    func clearWeekScores(week: Int) {
        plan.scores.removeValue(forKey: String(week))
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
