import SwiftUI

struct TrackerView: View {
    @Environment(PlanStore.self) private var store
    @State private var selectedWeek = 1

    var body: some View {
        VStack {
            // Week Picker
            Picker("Week", selection: $selectedWeek) {
                ForEach(1...store.plan.weeksInQuarter, id: \.self) { week in
                    Text("Week \(week)").tag(week)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, AppTheme.Spacing.lg)

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    ForEach(store.plan.goals) { goal in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text(goal.emoji)
                                Text(goal.name)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }

                            ForEach(goal.habits) { habit in
                                HabitRow(
                                    habit: habit,
                                    week: selectedWeek,
                                    store: store
                                )
                            }
                        }
                        .padding(AppTheme.Spacing.xl)
                        .cardStyle()
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Tracker")
        .onAppear {
            selectedWeek = Scoring.nextWeekToLog(plan: store.plan)
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    let week: Int
    @Bindable var store: PlanStore

    private var currentValue: Double {
        store.plan.scores[String(week)]?[habit.id] ?? 0
    }

    var body: some View {
        HStack {
            Text(habit.name)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            TextField("0", value: Binding(
                get: { currentValue },
                set: { newValue in
                    store.updateScore(week: week, habitId: habit.id, value: newValue)
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )

            Text(habit.unit)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 60, alignment: .leading)

            if let pct = Scoring.habitPct(habit: habit, value: currentValue) {
                Text(Scoring.formatPct(pct))
                    .badge(percentage: pct)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrackerView()
            .environment(PlanStore())
    }
}
