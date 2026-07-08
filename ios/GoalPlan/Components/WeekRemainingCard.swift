import SwiftUI

/// The coach card: what's still needed to hit this week's targets,
/// and how many days are left to do it.
struct WeekRemainingCard: View {
    @Bindable var store: PlanStore

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter(maxWeek: store.plan.weeksInQuarter)
    }

    private var daysLeft: Int {
        Scoring.daysLeftInCurrentWeek()
    }

    private var remainingHabits: [(habit: Habit, remaining: Double)] {
        store.plan.allHabits.compactMap { habit in
            let done = store.plan.weekTotal(for: habit, week: currentWeek) ?? 0
            let remaining = habit.target - done
            return remaining > 0 ? (habit, remaining) : nil
        }
    }

    private var daysLeftText: String {
        daysLeft == 1 ? "Last day of the week" : "\(daysLeft) days left this week"
    }

    private func remainingText(for habit: Habit, remaining: Double) -> String {
        let amount = remaining.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(remaining)) : String(remaining)
        switch habit.unit {
        case "minutes": return "\(amount) min left"
        case "hours": return "\(amount) hr left"
        default: return "\(amount) more"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if remainingHabits.isEmpty {
                // Everything hit — celebrate
                HStack {
                    Text("🎉")
                        .font(.title)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Week complete!")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Every target met — enjoy the rest of the week.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundColor(AppTheme.Colors.accent)
                    Text(daysLeftText)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ForEach(remainingHabits, id: \.habit.id) { item in
                        HStack {
                            Text(item.habit.name)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Text(remainingText(for: item.habit, remaining: item.remaining))
                                .font(AppTheme.Typography.caption)
                                .bold()
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

#Preview {
    WeekRemainingCard(store: PlanStore())
        .padding()
}
