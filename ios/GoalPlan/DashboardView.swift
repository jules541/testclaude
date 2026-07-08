import SwiftUI

struct DashboardView: View {
    @Environment(PlanStore.self) private var store

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter(maxWeek: store.plan.weeksInQuarter)
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

                    ForEach(store.plan.allHabits) { habit in
                        TodayGoalRow(
                            habit: habit,
                            todayValue: store.plan.todayContribution(for: habit),
                            weekValue: store.plan.weekTotal(for: habit, week: currentWeek),
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
    let todayValue: Double?
    let weekValue: Double?
    @Bindable var store: PlanStore

    @State private var isPressed = false

    /// Success is measured against the weekly target (contribution model)
    private var isWeekComplete: Bool {
        (weekValue ?? 0) >= habit.target
    }

    private func toggleCompletion() {
        let today = todayValue ?? 0

        if isWeekComplete {
            // Weekly target met: tapping undoes today's contribution (if any);
            // never wipes progress logged on other days
            if today > 0 {
                store.logDaily(habitId: habit.id, value: nil)
            }
        } else {
            store.logDaily(habitId: habit.id, value: today + 1)
        }
    }

    private var weekText: String {
        let base = "\(Int(weekValue ?? 0))/\(Int(habit.target))"
        switch habit.unit {
        case "minutes": return "\(base) min this week"
        case "hours": return "\(base) hr this week"
        default: return "\(base) this week"
        }
    }

    private var todayText: String? {
        guard let today = todayValue, today > 0 else { return nil }
        let display = today.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(today)) : String(today)
        return "+\(display) today"
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Weekly completion indicator
            Image(systemName: isWeekComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isWeekComplete ? AppTheme.Colors.scoreFull : AppTheme.Colors.textMuted)
                .font(.title3)

            // Habit info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(habit.name)
                    .font(AppTheme.Typography.body)
                    .bold()
                    .foregroundColor(AppTheme.Colors.textPrimary)
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(weekText)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    if let todayText {
                        Text(todayText)
                            .font(AppTheme.Typography.caption)
                            .bold()
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }

            Spacer()

            // Weekly percentage badge (only once the habit has been logged)
            if let pct = Scoring.habitPct(habit: habit, value: weekValue) {
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
