import SwiftUI

/// Compact week header: "Week N · pct" on the left, days-left on the right,
/// one thin progress bar. Replaces the old hero card + separate quarter/year
/// header on the Dashboard — quarter/year progress now lives on Progress tab.
struct TodayHeaderCard: View {
    @Bindable var store: PlanStore

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter(maxWeek: store.plan.weeksInQuarter)
    }

    private var weekPct: Double {
        Scoring.weekPct(plan: store.plan, week: currentWeek) ?? 0
    }

    private var daysLeft: Int {
        Scoring.daysLeftInCurrentWeek()
    }

    private var isWeekComplete: Bool {
        store.plan.allHabits.allSatisfy { habit in
            (store.plan.weekTotal(for: habit, week: currentWeek) ?? 0) >= habit.target
        }
    }

    private var daysLeftText: String {
        if isWeekComplete { return "Week complete 🎉" }
        return daysLeft == 1 ? "Last day" : "\(daysLeft) days left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Week \(currentWeek) · \(Scoring.formatPct(weekPct))")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(daysLeftText)
                    .font(AppTheme.Typography.caption)
                    .bold()
                    .foregroundColor(isWeekComplete ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.Colors.border)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppGradients.progressMeter)
                        .frame(width: geo.size.width * weekPct, height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    TodayHeaderCard(store: PlanStore())
        .padding()
}
