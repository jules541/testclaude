import Foundation
import UserNotifications
import os

/// Manages local notifications for habit reminders
@Observable
final class NotificationManager {

    static let shared = NotificationManager()

    private static let logger = Logger(subsystem: "com.goalplan.GoalPlan", category: "notifications")

    // MARK: - Settings (persisted in UserDefaults)

    var morningFocusEnabled: Bool {
        didSet {
            UserDefaults.standard.set(morningFocusEnabled, forKey: "morningFocusEnabled")
            if morningFocusEnabled { requestAuthorizationIfNeeded() }
            updateMorningFocus()
        }
    }

    var morningFocusTime: Date {
        didSet {
            UserDefaults.standard.set(morningFocusTime, forKey: "morningFocusTime")
            updateMorningFocus()
        }
    }

    var eveningReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(eveningReminderEnabled, forKey: "eveningReminderEnabled")
            if eveningReminderEnabled { requestAuthorizationIfNeeded() }
            updateEveningReminder()
        }
    }

    var eveningReminderTime: Date {
        didSet {
            UserDefaults.standard.set(eveningReminderTime, forKey: "eveningReminderTime")
            updateEveningReminder()
        }
    }

    var weeklySummaryEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weeklySummaryEnabled, forKey: "weeklySummaryEnabled")
            if weeklySummaryEnabled { requestAuthorizationIfNeeded() }
            updateWeeklySummary()
        }
    }

    var isAuthorized: Bool = false

    // MARK: - Notification Identifiers

    private let morningFocusID = "goalplan.morning.focus"
    private let eveningReminderID = "goalplan.evening.reminder"
    private let weeklySummaryID = "goalplan.weekly.summary"

    // MARK: - Initialization

    private init() {
        // Load settings from UserDefaults
        self.morningFocusEnabled = UserDefaults.standard.bool(forKey: "morningFocusEnabled")
        self.eveningReminderEnabled = UserDefaults.standard.bool(forKey: "eveningReminderEnabled")
        self.weeklySummaryEnabled = UserDefaults.standard.bool(forKey: "weeklySummaryEnabled")

        // Default morning time: 7:00 AM
        if let savedTime = UserDefaults.standard.object(forKey: "morningFocusTime") as? Date {
            self.morningFocusTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            self.morningFocusTime = Calendar.current.date(from: components) ?? Date()
        }

        // Default evening time: 8:00 PM
        if let savedTime = UserDefaults.standard.object(forKey: "eveningReminderTime") as? Date {
            self.eveningReminderTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            self.eveningReminderTime = Calendar.current.date(from: components) ?? Date()
        }

        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }

            if granted {
                scheduleAllNotifications()
            }

            return granted
        } catch {
            Self.logger.error("Notification authorization error: \(error)")
            return false
        }
    }

    /// Request permission the first time a reminder is switched on
    private func requestAuthorizationIfNeeded() {
        guard !isAuthorized else { return }
        Task { _ = await requestAuthorization() }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleAllNotifications() {
        if morningFocusEnabled { scheduleMorningFocus() }
        if eveningReminderEnabled { scheduleEveningReminder() }
        if weeklySummaryEnabled { scheduleWeeklySummary() }
    }

    // MARK: - Morning Focus Notification

    func scheduleMorningFocus() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningFocusID])

        // Get habits that are behind
        let behindHabits = getBehindHabits()
        let focusText = behindHabits.isEmpty
            ? "You're on track! Keep up the great work."
            : "Focus today: \(behindHabits.joined(separator: ", "))"

        let content = UNMutableNotificationContent()
        content.title = "🎯 Morning Focus"
        content.body = focusText
        content.sound = .default

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: morningFocusTime)
        let minute = calendar.component(.minute, from: morningFocusTime)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningFocusID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule morning focus: \(error)")
            }
        }
    }

    private func updateMorningFocus() {
        if morningFocusEnabled {
            scheduleMorningFocus()
        } else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [morningFocusID])
        }
    }

    /// Get habits that are below 50% of target this week
    private func getBehindHabits() -> [String] {
        guard let plan = SharedContainer.loadPlan() else { return [] }

        let currentWeek = Scoring.currentWeekOfQuarter(maxWeek: plan.weeksInQuarter)
        let weekScores = plan.scores[String(currentWeek)] ?? [:]

        var behindHabits: [String] = []

        for goal in plan.goals {
            for habit in goal.habits {
                let current = weekScores[habit.id] ?? 0
                let percentage = habit.target > 0 ? current / habit.target : 0

                if percentage < 0.5 {
                    let progress = "\(formatValue(current))/\(formatValue(habit.target))"
                    behindHabits.append("\(habit.name) (\(progress))")
                }
            }
        }

        // Return top 3 behind habits
        return Array(behindHabits.prefix(3))
    }

    /// Format a habit value without truncating fractional progress (0.5 stays "0.5")
    private func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }

    // MARK: - Evening Reminder Notification

    func scheduleEveningReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [eveningReminderID])

        let content = UNMutableNotificationContent()
        content.title = "📝 Log Your Habits"
        content.body = "Time to track your progress for today!"
        content.sound = .default
        content.badge = 1

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: eveningReminderTime)
        let minute = calendar.component(.minute, from: eveningReminderTime)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: eveningReminderID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule evening reminder: \(error)")
            }
        }
    }

    private func updateEveningReminder() {
        if eveningReminderEnabled {
            scheduleEveningReminder()
        } else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [eveningReminderID])
        }
    }

    // MARK: - Weekly Summary Notification

    func scheduleWeeklySummary() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklySummaryID])

        let content = UNMutableNotificationContent()
        content.title = "📊 Your Week in Review"
        content.body = getWeeklySummaryText()
        content.sound = .default

        // Sunday at 6:00 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: weeklySummaryID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule weekly summary: \(error)")
            }
        }
    }

    private func updateWeeklySummary() {
        if weeklySummaryEnabled {
            scheduleWeeklySummary()
        } else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [weeklySummaryID])
        }
    }

    private func getWeeklySummaryText() -> String {
        guard let plan = SharedContainer.loadPlan() else {
            return "See how you did this week!"
        }

        let currentWeek = Scoring.currentWeekOfQuarter(maxWeek: plan.weeksInQuarter)
        if let weekPct = Scoring.weekPct(plan: plan, week: currentWeek) {
            let percentage = Int(weekPct * 100)
            return "You achieved \(percentage)% of your goals this week!"
        }

        return "Review your progress and plan for next week!"
    }

    // MARK: - Badge Management

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
