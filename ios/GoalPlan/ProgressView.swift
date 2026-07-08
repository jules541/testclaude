import SwiftUI

enum ProgressViewMode: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
}

struct ProgressView: View {
    @Environment(PlanStore.self) private var store
    @State private var viewMode: ProgressViewMode = .week

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // View Mode Toggle
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ProgressViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Content based on view mode
                Group {
                    switch viewMode {
                    case .week:
                        WeekView(store: store)
                    case .month:
                        MonthView(store: store)
                    case .quarter:
                        QuarterView(store: store)
                    }
                }

                // Export Button
                ShareLink(
                    item: PlanExport(plan: store.plan),
                    preview: SharePreview("Goal Plan JSON")
                ) {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Progress")
    }
}

// MARK: - Week View (Current Week, Mon-Sun)

struct WeekView: View {
    @Bindable var store: PlanStore

    private var weekDays: [(name: String, activity: (logged: Int, total: Int)?)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return Scoring.daysOfCurrentWeek().map { date in
            (
                name: formatter.string(from: date),
                activity: Scoring.dayActivity(plan: store.plan, date: date)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("This Week's Activity")
                .sectionHeaderStyle()

            ForEach(Array(weekDays.enumerated()), id: \.offset) { _, item in
                HStack {
                    Text(item.name)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    if let activity = item.activity {
                        let fraction = Double(activity.logged) / Double(activity.total)

                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .fill(AppGradients.progressBar)
                                    .frame(width: geo.size.width * fraction)

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                        )

                        Text("\(activity.logged) of \(activity.total)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(width: 50, alignment: .trailing)
                    } else {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                                .frame(width: geo.size.width, height: 20)
                        }
                        .frame(height: 20)

                        Text("—")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Month View (Last 4 Weeks)

struct MonthView: View {
    @Bindable var store: PlanStore

    private var monthData: [(week: Int, pct: Double?)] {
        Scoring.monthView(plan: store.plan)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Month View (Last 4 Weeks)")
                .sectionHeaderStyle()

            ForEach(monthData, id: \.week) { item in
                HStack {
                    Text("Week \(item.week)")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    if let pct = item.pct {
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .fill(AppGradients.progressBar)
                                    .frame(width: geo.size.width * pct)

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                        )

                        Text(Scoring.formatPct(pct))
                            .badge(percentage: pct)
                    } else {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                                .frame(width: geo.size.width, height: 20)
                        }
                        .frame(height: 20)

                        Text("—")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Quarter View (All 13 Weeks, Grouped)

struct QuarterView: View {
    @Bindable var store: PlanStore

    private var quarterData: [(week: Int, pct: Double?)] {
        (1...store.plan.weeksInQuarter).map { week in
            (week: week, pct: Scoring.weekPct(plan: store.plan, week: week))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Quarter Overview (All Weeks)")
                .sectionHeaderStyle()

            // Show quarter score at top
            if let quarterPct = Scoring.quarterPct(plan: store.plan) {
                HStack {
                    Text("Quarter Average:")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text(Scoring.formatPct(quarterPct))
                        .badge(percentage: quarterPct)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.Radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
            }

            // All weeks
            ForEach(quarterData, id: \.week) { item in
                HStack {
                    Text("Week \(item.week)")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .frame(width: 80, alignment: .leading)

                    if let pct = item.pct {
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .fill(AppGradients.progressBar)
                                    .frame(width: geo.size.width * pct)

                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                        )

                        Text(Scoring.formatPct(pct))
                            .badge(percentage: pct)
                    } else {
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .fill(AppTheme.Colors.border)
                                .frame(width: geo.size.width, height: 20)
                        }
                        .frame(height: 20)

                        Text("—")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        ProgressView()
            .environment(PlanStore())
    }
}
