import SwiftUI

struct QuarterProgressView: View {
    @Bindable var store: PlanStore

    private var currentWeek: Int {
        Scoring.currentWeekOfQuarter()
    }

    private var quarterName: String {
        Scoring.currentQuarterString()
    }

    private var quarterProgress: Double {
        Scoring.quarterProgress(plan: store.plan)
    }

    private var loggedWeeks: Int {
        Scoring.loggedWeeks(plan: store.plan).count
    }

    private var yearProgress: Double {
        Scoring.yearProgress()
    }

    private var daysRemaining: Int {
        Scoring.daysRemainingInYear()
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header: Quarter name + current week
            HStack {
                Text(quarterName)
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("Week \(currentWeek)")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            // Quarter Progress
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("Quarter Progress")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppTheme.Colors.border)
                            .frame(height: 24)

                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppGradients.progressMeter)
                            .frame(width: geo.size.width * quarterProgress, height: 24)
                    }
                }
                .frame(height: 24)

                // Stats
                HStack {
                    Text("\(Int(quarterProgress * 100))% complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("\(loggedWeeks) of \(store.plan.weeksInQuarter) weeks tracked")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            // Year Progress
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(AppTheme.Colors.accent)
                    Text("Year Progress")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppTheme.Colors.border)
                            .frame(height: 24)

                        // Progress fill with gradient
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppGradients.progressMeter)
                            .frame(width: geo.size.width * yearProgress, height: 24)
                    }
                }
                .frame(height: 24)

                // Stats
                HStack {
                    Text("\(Int(yearProgress * 100))% complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("\(daysRemaining) days remaining")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

#Preview {
    QuarterProgressView(store: PlanStore())
}
