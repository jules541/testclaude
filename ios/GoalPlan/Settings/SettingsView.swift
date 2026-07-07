import SwiftUI

struct SettingsView: View {
    @Bindable private var notifications = NotificationManager.shared
    @Environment(PlanStore.self) private var store

    var body: some View {
        List {
            // MARK: - Notifications Section
            Section {
                // Morning Focus
                Toggle(isOn: $notifications.morningFocusEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Morning Focus")
                            Text("Get reminded of habits you're behind on")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "sun.horizon.fill")
                            .foregroundColor(.orange)
                    }
                }

                if notifications.morningFocusEnabled {
                    DatePicker(
                        "Time",
                        selection: $notifications.morningFocusTime,
                        displayedComponents: .hourAndMinute
                    )
                    .padding(.leading, 36)
                }

                // Evening Reminder
                Toggle(isOn: $notifications.eveningReminderEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Evening Reminder")
                            Text("Reminder to log your habits")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                    }
                }

                if notifications.eveningReminderEnabled {
                    DatePicker(
                        "Time",
                        selection: $notifications.eveningReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .padding(.leading, 36)
                }

                // Weekly Summary
                Toggle(isOn: $notifications.weeklySummaryEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weekly Summary")
                            Text("Sunday recap of your progress")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if !notifications.isAuthorized {
                    Text("Enable notifications in Settings to receive reminders.")
                        .foregroundColor(.red)
                }
            }

            // MARK: - Data Section
            Section("Data") {
                Button {
                    exportData()
                } label: {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                }

                Button {
                    // Import functionality
                } label: {
                    Label("Import JSON", systemImage: "square.and.arrow.down")
                }

                Button(role: .destructive) {
                    store.resetToDefault()
                } label: {
                    Label("Reset to Default", systemImage: "arrow.counterclockwise")
                }
            }

            // MARK: - About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .navigationTitle("Settings")
        .tint(AppTheme.Colors.primary)
        .task {
            if !notifications.isAuthorized {
                await notifications.requestAuthorization()
            }
        }
    }

    private func exportData() {
        do {
            let data = try store.exportJSON()
            let activityVC = UIActivityViewController(
                activityItems: [data],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(PlanStore())
    }
}
