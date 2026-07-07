import SwiftUI

struct RootTabView: View {

    @Environment(PlanStore.self) private var store

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard")
                }

            TrackerView()
                .tabItem {
                    Label("Tracker", systemImage: "checkmark.square.fill")
                }

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(PlanStore())
}
