import SwiftUI

struct RootTabView: View {

    enum Tab: Hashable {
        case dashboard, plan, tracker, progress, settings
    }

    @Environment(PlanStore.self) private var store
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(Tab.dashboard)

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard")
                }
                .tag(Tab.plan)

            TrackerView()
                .tabItem {
                    Label("Tracker", systemImage: "checkmark.square.fill")
                }
                .tag(Tab.tracker)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
        .onOpenURL { url in
            // goalplan://today from the widget lands on the Dashboard
            if url.scheme == "goalplan" {
                selectedTab = .dashboard
            }
        }
    }
}

#Preview {
    RootTabView()
        .environment(PlanStore())
}
