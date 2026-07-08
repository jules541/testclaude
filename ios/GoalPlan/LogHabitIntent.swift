import AppIntents
import WidgetKit

/// Adds +1 to a habit's daily log straight from the widget,
/// without opening the app. Compiled into both the app and
/// widget targets; the shared container is the common store.
struct LogHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Habit"
    static let description = IntentDescription("Add 1 to a habit's progress for today")

    @Parameter(title: "Habit ID")
    var habitId: String

    init() {}

    init(habitId: String) {
        self.habitId = habitId
    }

    func perform() async throws -> some IntentResult {
        guard let plan = SharedContainer.loadPlan() else { return .result() }
        guard let habit = plan.allHabits.first(where: { $0.id == habitId }) else { return .result() }

        let today = plan.todayContribution(for: habit) ?? 0
        let updated = plan.loggingDaily(habitId: habitId, value: today + 1)
        try SharedContainer.savePlan(updated)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
