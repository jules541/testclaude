import Foundation

// MARK: - Scoring Logic
// Ported verbatim from script.js to match web app calculations exactly

enum Scoring {

    /// Get scores for a specific week
    static func weekScores(plan: Plan, week: Int) -> [String: Double] {
        return plan.scores[String(week)] ?? [:]
    }

    /// Calculate habit percentage: value / target, capped at 100%
    /// Returns nil if value is nil (not logged)
    static func habitPct(habit: Habit, value: Double?) -> Double? {
        guard let value = value, habit.target > 0 else { return nil }
        return min(value / habit.target, 1.0)
    }

    /// Average of non-nil values
    private static func avg(_ values: [Double?]) -> Double? {
        let nonNil = values.compactMap { $0 }
        guard !nonNil.isEmpty else { return nil }
        return nonNil.reduce(0, +) / Double(nonNil.count)
    }

    /// Calculate goal percentage for a specific week
    /// Returns nil if no habits are logged
    static func goalPct(plan: Plan, goal: Goal, week: Int) -> Double? {
        let scores = weekScores(plan: plan, week: week)
        let habitPcts = goal.habits.map { habitPct(habit: $0, value: scores[$0.id]) }
        return avg(habitPcts)
    }

    /// Calculate overall week percentage
    /// Returns nil if no goals have any logged habits
    static func weekPct(plan: Plan, week: Int) -> Double? {
        let goalPcts = plan.goals.map { goalPct(plan: plan, goal: $0, week: week) }
        return avg(goalPcts)
    }

    /// Get list of weeks that have at least one logged score
    static func loggedWeeks(plan: Plan) -> [Int] {
        return (1...plan.weeksInQuarter).filter { weekPct(plan: plan, week: $0) != nil }
    }

    /// Calculate quarter-wide percentage (average of all logged weeks)
    static func quarterPct(plan: Plan) -> Double? {
        let weekPcts = loggedWeeks(plan: plan).map { weekPct(plan: plan, week: $0) }
        return avg(weekPcts)
    }

    /// Calculate goal's quarter-wide percentage
    static func goalQuarterPct(plan: Plan, goal: Goal) -> Double? {
        let goalPcts = (1...plan.weeksInQuarter).compactMap { goalPct(plan: plan, goal: goal, week: $0) }
        return avg(goalPcts)
    }

    /// Find the next week that needs to be logged
    /// Returns the first week with no score, or the last week if all are logged
    static func nextWeekToLog(plan: Plan) -> Int {
        for week in 1...plan.weeksInQuarter {
            if weekPct(plan: plan, week: week) == nil {
                return week
            }
        }
        return plan.weeksInQuarter
    }

    /// Format percentage for display (0-100% or "—" if nil)
    static func formatPct(_ pct: Double?) -> String {
        guard let pct = pct else { return "—" }
        return "\(Int(round(pct * 100)))%"
    }

    /// Get color coding for percentage
    static func pctColor(_ pct: Double?) -> PctColor {
        guard let pct = pct else { return .none }
        if pct >= 1.0 { return .full }
        if pct >= 0.7 { return .good }
        if pct >= 0.4 { return .mid }
        return .low
    }

    // MARK: - Daily Tracking

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Key used in Plan.dailyScores for a given local date, e.g. "2026-07-06"
    static func dayKey(for date: Date = Date()) -> String {
        dayKeyFormatter.string(from: date)
    }

    /// How many of the plan's habits were logged on the given day.
    /// Returns nil when nothing was logged — days are activity, never grades.
    static func dayActivity(plan: Plan, date: Date) -> (logged: Int, total: Int)? {
        let habitIds = Set(plan.allHabits.map(\.id))
        guard !habitIds.isEmpty,
              let dayLog = plan.dailyScores[dayKey(for: date)] else { return nil }

        let logged = habitIds.intersection(dayLog.keys).count
        guard logged > 0 else { return nil }
        return (logged, habitIds.count)
    }

    /// The 7 dates of the calendar week containing `now`
    static func daysOfCurrentWeek(now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    /// Day keys ("yyyy-MM-dd") for the 7 days of a quarter week.
    /// `reference` picks which calendar quarter the week belongs to.
    static func dayKeys(inWeek week: Int, reference: Date = Date()) -> [String] {
        let calendar = Calendar.current
        let quarterStart = quarterStartDate(now: reference)
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: (week - 1) * 7 + day, to: quarterStart)
                .map { dayKey(for: $0) }
        }
    }

    /// Days remaining in the current quarter week, counting today
    /// (7 on the week's first day, 1 on its last)
    static func daysLeftInCurrentWeek(now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let quarterStart = quarterStartDate(now: now)
        let daysElapsed = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: quarterStart),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        return 7 - (daysElapsed % 7)
    }

    /// The last day of the current quarter week
    static func currentWeekEndDate(now: Date = Date(), maxWeek: Int = 13) -> Date {
        let calendar = Calendar.current
        let week = currentWeekOfQuarter(now: now, maxWeek: maxWeek)
        let quarterStart = quarterStartDate(now: now)
        return calendar.date(byAdding: .day, value: (week - 1) * 7 + 6, to: quarterStart) ?? now
    }

    /// Get last 4 weeks of the quarter for month view
    /// Returns array of tuples: [(week, percentage)]
    static func monthView(plan: Plan) -> [(week: Int, pct: Double?)] {
        let currentWeek = nextWeekToLog(plan: plan)
        let startWeek = max(1, currentWeek - 3)
        return (startWeek...currentWeek).map { week in
            (week: week, pct: weekPct(plan: plan, week: week))
        }
    }

    /// Calculate year progress (% of calendar year elapsed)
    /// Returns percentage of year complete (0.0 to 1.0)
    static func yearProgress(now: Date = Date()) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)

        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return 0.0
        }

        let totalSeconds = endOfYear.timeIntervalSince(startOfYear)
        let elapsedSeconds = now.timeIntervalSince(startOfYear)

        return elapsedSeconds / totalSeconds
    }

    /// Get days remaining in the year
    static func daysRemainingInYear(now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)

        guard let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return 0
        }

        let days = calendar.dateComponents([.day], from: now, to: endOfYear).day ?? 0
        return days
    }

    /// Calculate quarter completion based on weeks tracked
    /// Returns percentage of quarter complete (0.0 to 1.0)
    static func quarterProgress(plan: Plan) -> Double {
        let loggedCount = loggedWeeks(plan: plan).count
        let totalWeeks = plan.weeksInQuarter
        return totalWeeks > 0 ? Double(loggedCount) / Double(totalWeeks) : 0.0
    }

    // MARK: - Date-Based Quarter and Week Calculations

    /// Get current quarter (1-4) and year based on today's date
    /// Returns tuple: (quarter: Int, year: Int)
    /// Example: June 28, 2026 → (2, 2026)
    static func currentQuarter(now: Date = Date()) -> (quarter: Int, year: Int) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        let quarter = (month - 1) / 3 + 1  // 1-3→Q1, 4-6→Q2, 7-9→Q3, 10-12→Q4
        return (quarter, year)
    }

    /// First day of the calendar quarter containing `now`
    static func quarterStartDate(now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let (quarter, year) = currentQuarter(now: now)
        let startMonth = (quarter - 1) * 3 + 1  // Q1→Jan, Q2→Apr, Q3→Jul, Q4→Oct
        return calendar.date(from: DateComponents(year: year, month: startMonth, day: 1)) ?? now
    }

    /// Get current week number within the quarter, clamped to 1...maxWeek
    /// Based on weeks elapsed since quarter start date
    static func currentWeekOfQuarter(now: Date = Date(), maxWeek: Int = 13) -> Int {
        let calendar = Calendar.current
        let quarterStart = quarterStartDate(now: now)

        // Calculate weeks elapsed
        let components = calendar.dateComponents([.weekOfYear], from: quarterStart, to: now)
        let weeksElapsed = (components.weekOfYear ?? 0) + 1  // +1 because week 1 starts immediately

        return min(max(weeksElapsed, 1), maxWeek)
    }

    /// Format current quarter as "Q# YYYY" string
    /// Example: "Q2 2026"
    static func currentQuarterString(now: Date = Date()) -> String {
        let (quarter, year) = currentQuarter(now: now)
        return "Q\(quarter) \(year)"
    }
}

enum PctColor {
    case none   // No data
    case full   // 100%
    case good   // 70-99%
    case mid    // 40-69%
    case low    // 0-39%
}
