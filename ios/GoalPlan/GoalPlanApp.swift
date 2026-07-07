import SwiftUI

@main
struct GoalPlanApp: App {

    @State private var store = PlanStore()
    @State private var showOnboarding = !OnboardingManager.hasCompleted

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingFlowView(onComplete: {
                    showOnboarding = false
                })
                .environment(store)
            } else {
                RootTabView()
                    .environment(store)
            }
        }
    }
}
