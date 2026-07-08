import SwiftUI

struct DashboardView: View {
    @Environment(PlanStore.self) private var store
    @State private var quickLogHabit: Habit?

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter(maxWeek: store.plan.weeksInQuarter)
    }

    /// All habits, focused ones first (in focus order), then behind habits
    /// in plan order, completed habits last.
    private var sortedHabits: [Habit] {
        let focusOrder = store.todayFocusIds
        let all = store.plan.allHabits

        func isComplete(_ habit: Habit) -> Bool {
            (store.plan.weekTotal(for: habit, week: currentWeek) ?? 0) >= habit.target
        }

        let focused = focusOrder.compactMap { id in all.first { $0.id == id } }
        let focusedIds = Set(focusOrder)
        let remaining = all.filter { !focusedIds.contains($0.id) }
        let behind = remaining.filter { !isComplete($0) }
        let completed = remaining.filter { isComplete($0) }

        return focused + behind + completed
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                TodayHeaderCard(store: store)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("Today")
                            .sectionHeaderStyle()
                    }

                    ForEach(sortedHabits) { habit in
                        TodayGoalRow(
                            habit: habit,
                            todayValue: store.plan.todayContribution(for: habit),
                            weekValue: store.plan.weekTotal(for: habit, week: currentWeek),
                            isFocused: store.todayFocusIds.contains(habit.id),
                            store: store,
                            onLongPress: { quickLogHabit = habit }
                        )
                    }

                    Text("tap = +1 · hold = enter amount · ★ = today's focus")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .padding(AppTheme.Spacing.xl)
                .cardStyle()
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Dashboard")
        .onAppear {
            store.refreshFocusForToday()
        }
        .sheet(item: $quickLogHabit) { habit in
            QuickLogSheet(habit: habit, store: store)
        }
    }
}

struct TodayGoalRow: View {
    let habit: Habit
    let todayValue: Double?
    let weekValue: Double?
    let isFocused: Bool
    @Bindable var store: PlanStore
    var onLongPress: () -> Void = {}

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

    /// On-pace dose for today, e.g. "Do ~30 min today"
    private var suggestionText: String? {
        guard !isWeekComplete else { return nil }
        guard let suggested = Scoring.suggestedToday(habit: habit, weekTotal: weekValue) else { return nil }
        let amount = suggested.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(suggested)) : String(suggested)
        switch habit.unit {
        case "minutes": return "~\(amount) min today"
        case "hours": return "~\(amount) hr today"
        default: return "~\(amount) today"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Focus star — independent tap target from the row itself
            Button {
                store.toggleFocus(habitId: habit.id)
            } label: {
                Image(systemName: isFocused ? "star.fill" : "star")
                    .foregroundColor(isFocused ? AppTheme.Colors.accent : AppTheme.Colors.textMuted)
                    .font(.body)
            }
            .buttonStyle(.plain)

            // Weekly completion indicator
            Image(systemName: isWeekComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isWeekComplete ? AppTheme.Colors.scoreFull : AppTheme.Colors.textMuted)
                .font(.title3)

            // Habit info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(habit.name)
                    .font(AppTheme.Typography.body)
                    .bold()
                    .foregroundColor(isWeekComplete ? AppTheme.Colors.textMuted : AppTheme.Colors.textPrimary)
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
                    if let suggestionText {
                        Text("· \(suggestionText)")
                            .font(AppTheme.Typography.caption)
                            .bold()
                            .foregroundColor(AppTheme.Colors.accent)
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
        .opacity(isWeekComplete ? 0.6 : 1.0)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            isPressed = true
            toggleCompletion()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(PlanStore())
    }
}
