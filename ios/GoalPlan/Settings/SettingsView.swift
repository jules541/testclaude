import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable private var notifications = NotificationManager.shared
    @Environment(PlanStore.self) private var store

    @State private var isImporting = false
    @State private var showResetConfirmation = false
    @State private var importError: String?

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
                ShareLink(
                    item: PlanExport(plan: store.plan),
                    preview: SharePreview("Goal Plan JSON")
                ) {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                }

                Button {
                    isImporting = true
                } label: {
                    Label("Import JSON", systemImage: "square.and.arrow.down")
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
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
        .onAppear {
            notifications.checkAuthorizationStatus()
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                importPlan(from: url)
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .confirmationDialog(
            "Reset to Default?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                store.resetToDefault()
            }
        } message: {
            Text("This replaces your goals and scores with the default plan.")
        }
        .alert(
            "Import Failed",
            isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    private func importPlan(from url: URL) {
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            try store.importJSON(data: data)
        } catch {
            importError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(PlanStore())
    }
}
