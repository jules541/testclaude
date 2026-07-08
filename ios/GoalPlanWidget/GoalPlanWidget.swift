import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Bundle (extension entry point)

@main
struct GoalPlanWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoalPlanWidget()
    }
}

// MARK: - Widget

struct GoalPlanWidget: Widget {
    let kind: String = "GoalPlanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GoalPlanWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Goal Plan")
        .description("Track your quarterly goals")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

// MARK: - Timeline Entry

struct BehindHabit: Identifiable {
    let id: String
    let name: String
    let done: Int
    let target: Int
}

struct GoalPlanEntry: TimelineEntry {
    let date: Date
    let quarterName: String
    let currentWeek: Int
    let weekPct: Double?
    let quarterPct: Double?
    let streak: Int
    let behindHabits: [BehindHabit]

    static let placeholder = GoalPlanEntry(
        date: .now,
        quarterName: "Q3 2026",
        currentWeek: 1,
        weekPct: 0.62,
        quarterPct: 0.74,
        streak: 3,
        behindHabits: [
            BehindHabit(id: "workout", name: "Workout", done: 3, target: 7),
            BehindHabit(id: "reading", name: "Reading", done: 10, target: 30)
        ]
    )
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GoalPlanEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalPlanEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalPlanEntry>) -> Void) {
        // Refresh at midnight so week boundaries roll over; data changes
        // arrive sooner via reloadAllTimelines() from the app on every save
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)
            ?? now.addingTimeInterval(24 * 60 * 60)

        completion(Timeline(entries: [loadEntry(now: now)], policy: .after(nextMidnight)))
    }

    private func loadEntry(now: Date = Date()) -> GoalPlanEntry {
        guard let plan = SharedContainer.loadPlan() else { return .placeholder }

        let week = Scoring.currentWeekOfQuarter(now: now, maxWeek: plan.weeksInQuarter)

        // The two habits furthest from their weekly target, for +1 buttons
        let behind = plan.allHabits
            .compactMap { habit -> (BehindHabit, Double)? in
                let done = plan.weekTotal(for: habit, week: week) ?? 0
                guard habit.target > 0, done < habit.target else { return nil }
                return (
                    BehindHabit(id: habit.id, name: habit.name, done: Int(done), target: Int(habit.target)),
                    done / habit.target
                )
            }
            .sorted { $0.1 < $1.1 }
            .prefix(2)
            .map(\.0)

        return GoalPlanEntry(
            date: now,
            quarterName: plan.quarter,
            currentWeek: week,
            weekPct: Scoring.weekPct(plan: plan, week: week),
            quarterPct: Scoring.quarterPct(plan: plan),
            streak: Streaks.weeklyStreak(plan: plan),
            behindHabits: behind
        )
    }
}

// MARK: - Brand Colors
// Mirror AppTheme.Colors (the app's theme files are not compiled into this target)

private extension Color {
    static let brandGreen = Color(red: 0x2F / 255, green: 0x6F / 255, blue: 0x5E / 255)
    static let brandGold = Color(red: 0xD9 / 255, green: 0xA4 / 255, blue: 0x41 / 255)
}

// MARK: - Entry View

struct GoalPlanWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: GoalPlanEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                CircularAccessoryView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "goalplan://today"))
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let pct: Double?
    var lineWidth: CGFloat = 9

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brandGreen.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: pct ?? 0)
                .stroke(
                    LinearGradient(
                        colors: [.brandGreen, .brandGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: GoalPlanEntry

    var body: some View {
        ZStack {
            ProgressRing(pct: entry.weekPct)
            VStack(spacing: 2) {
                Text(Scoring.formatPct(entry.weekPct))
                    .font(.title2.bold())
                    .foregroundStyle(Color.brandGreen)
                Text("Week \(entry.currentWeek)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: GoalPlanEntry

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(pct: entry.weekPct)
                VStack(spacing: 2) {
                    Text(Scoring.formatPct(entry.weekPct))
                        .font(.headline.bold())
                        .foregroundStyle(Color.brandGreen)
                    Text("Week \(entry.currentWeek)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.quarterName)
                        .font(.headline)
                    if entry.streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color.brandGold)
                        Text("\(entry.streak)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                if entry.behindHabits.isEmpty {
                    Text("All targets met 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    // One-tap logging for the habits furthest behind
                    ForEach(entry.behindHabits) { habit in
                        HStack(spacing: 6) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(habit.name)
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                Text("\(habit.done)/\(habit.target)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 4)
                            Button(intent: LogHabitIntent(habitId: habit.id)) {
                                Text("+1")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.brandGreen.opacity(0.15))
                                    .foregroundStyle(Color.brandGreen)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
    }
}

// MARK: - Lock Screen Circular

struct CircularAccessoryView: View {
    let entry: GoalPlanEntry

    var body: some View {
        Gauge(value: entry.weekPct ?? 0) {
            Text("W\(entry.currentWeek)")
        } currentValueLabel: {
            Text(Scoring.formatPct(entry.weekPct))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    GoalPlanWidget()
} timeline: {
    GoalPlanEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    GoalPlanWidget()
} timeline: {
    GoalPlanEntry.placeholder
}
