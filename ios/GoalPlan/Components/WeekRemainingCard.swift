import SwiftUI

/// The hero "Today" card: days left in the week, week progress bar, and a
/// focus picker — tap habits to choose today's focus; each shows the dose
/// needed to stay on pace ("~30 min today").
struct WeekRemainingCard: View {
    @Bindable var store: PlanStore

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter(maxWeek: store.plan.weeksInQuarter)
    }

    private var daysLeft: Int {
        Scoring.daysLeftInCurrentWeek()
    }

    private var weekPct: Double {
        Scoring.weekPct(plan: store.plan, week: currentWeek) ?? 0
    }

    private var behindHabits: [(habit: Habit, remaining: Double, suggested: Double)] {
        store.plan.allHabits.compactMap { habit in
            let done = store.plan.weekTotal(for: habit, week: currentWeek)
            guard let suggested = Scoring.suggestedToday(habit: habit, weekTotal: done) else { return nil }
            return (habit, habit.target - (done ?? 0), suggested)
        }
    }

    private var doneCount: Int {
        store.plan.allHabits.count - behindHabits.count
    }

    private var daysLeftText: String {
        daysLeft == 1 ? "Last day of the week" : "\(daysLeft) days left this week"
    }

    private func amountText(_ value: Double, unit: String) -> String {
        let amount = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value)) : String(value)
        switch unit {
        case "minutes": return "\(amount) min"
        case "hours": return "\(amount) hr"
        default: return amount
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Header: days left + week progress
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(AppTheme.Colors.accent)
                Text(daysLeftText)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(Scoring.formatPct(weekPct))
                    .font(AppTheme.Typography.caption)
                    .bold()
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.Colors.border)
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppGradients.progressMeter)
                        .frame(width: geo.size.width * weekPct, height: 12)
                }
            }
            .frame(height: 12)

            if behindHabits.isEmpty {
                HStack {
                    Text("🎉")
                        .font(.title2)
                    Text("Week complete — every target met!")
                        .font(AppTheme.Typography.body)
                        .bold()
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            } else {
                // Focus picker
                Text("What's your focus today?")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(behindHabits, id: \.habit.id) { item in
                        FocusPickerRow(
                            habit: item.habit,
                            remaining: amountText(item.remaining, unit: item.habit.unit) + " left",
                            suggested: "~" + amountText(item.suggested, unit: item.habit.unit) + " today",
                            isSelected: store.todayFocusIds.contains(item.habit.id),
                            onTap: { store.toggleFocus(habitId: item.habit.id) }
                        )
                    }
                }

                if doneCount > 0 {
                    Text("✓ \(doneCount) habit\(doneCount == 1 ? "" : "s") done for the week")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

private struct FocusPickerRow: View {
    let habit: Habit
    let remaining: String
    let suggested: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(AppTheme.Typography.body)
                    .bold()
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(remaining)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            Text(suggested)
                .font(AppTheme.Typography.caption)
                .bold()
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(AppTheme.Spacing.md)
        .background(isSelected ? AppTheme.Colors.primarySoft : AppTheme.Colors.inputBackground)
        .cornerRadius(AppTheme.Radius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                .stroke(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    WeekRemainingCard(store: PlanStore())
        .padding()
}
