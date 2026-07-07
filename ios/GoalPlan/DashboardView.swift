import SwiftUI

struct DashboardView: View {
    @Environment(PlanStore.self) private var store

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Quarter + Year Progress Header
                QuarterProgressView(store: store)

                // Today's Goals Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("Your Goals Today")
                            .sectionHeaderStyle()
                    }

                    ForEach(store.plan.todayGoals(), id: \.habit.id) { item in
                        TodayGoalRow(
                            habit: item.habit,
                            progress: store.plan.todayProgress(for: item.habit),
                            currentWeek: currentWeek,
                            store: store
                        )
                    }
                }
                .padding(AppTheme.Spacing.xl)
                .cardStyle()
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Dashboard")
    }
}

struct TodayGoalRow: View {
    let habit: Habit
    let progress: Double?
    let currentWeek: Int
    @Bindable var store: PlanStore

    @State private var isPressed = false

    private var isComplete: Bool {
        guard let progress = progress else { return false }
        return progress >= habit.target
    }

    private func toggleCompletion() {
        let currentProgress = progress ?? 0
        let newValue: Double

        // Increment by 1, wrap to 0 when at target
        if currentProgress >= habit.target {
            newValue = 0  // Reset to start
        } else {
            newValue = currentProgress + 1  // Increment by 1
        }

        store.updateScore(week: currentWeek, habitId: habit.id, value: newValue)
    }

    private var progressText: String {
        guard let progress = progress else { return "0/\(Int(habit.target))" }

        if habit.unit == "minutes" {
            return "\(Int(progress))/\(Int(habit.target)) min"
        } else if habit.unit == "hours" {
            return "\(Int(progress))/\(Int(habit.target)) hr"
        } else {
            return "\(Int(progress))/\(Int(habit.target))"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Completion indicator
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? AppTheme.Colors.scoreFull : AppTheme.Colors.textMuted)
                .font(.title3)

            // Habit info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(habit.name)
                    .font(AppTheme.Typography.body)
                    .bold()
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(progressText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // Percentage badge
            if let pct = Scoring.habitPct(habit: habit, value: progress ?? 0) {
                Text(Scoring.formatPct(pct))
                    .badge(percentage: pct)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.inputBackground)
        .cornerRadius(AppTheme.Radius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            isPressed = true
            toggleCompletion()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(PlanStore())
    }
}
