import SwiftUI

struct OnboardingFlowView: View {
    @Environment(PlanStore.self) private var store
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var vision = ""
    @State private var selectedTemplateIds: Set<String> = []
    @State private var customizedGoals: [Goal] = []

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            // Page indicators
            PageIndicators(currentPage: currentPage, totalPages: totalPages)
                .padding(.top, AppTheme.Spacing.md)

            // Current page content
            TabView(selection: $currentPage) {
                // Page 0: Welcome
                OnboardingWelcomeView(
                    onNext: { advancePage() },
                    onSkip: { skipOnboarding() }
                )
                .tag(0)

                // Page 1: Vision
                OnboardingVisionView(
                    vision: $vision,
                    onNext: { advancePage() },
                    onBack: { goBack() }
                )
                .tag(1)

                // Page 2: Goal Selection
                OnboardingGoalSelectionView(
                    selectedTemplateIds: $selectedTemplateIds,
                    onNext: {
                        prepareCustomizedGoals()
                        advancePage()
                    },
                    onBack: { goBack() }
                )
                .tag(2)

                // Page 3: Habit Review
                OnboardingHabitReviewView(
                    customizedGoals: $customizedGoals,
                    onComplete: { completeOnboarding() },
                    onBack: { goBack() }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
        }
        .background(AppTheme.Colors.background)
    }

    // MARK: - Navigation

    private func advancePage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }

    private func goBack() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    private func skipOnboarding() {
        // Use default plan and complete onboarding
        OnboardingManager.hasCompleted = true
        onComplete()
    }

    // MARK: - Data Preparation

    private func prepareCustomizedGoals() {
        // Convert selected templates to actual Goal objects
        customizedGoals = selectedTemplateIds.compactMap { templateId in
            GoalTemplate.all.first(where: { $0.id == templateId })?.toGoal()
        }
        // Sort to maintain consistent order
        customizedGoals.sort { $0.name < $1.name }
    }

    private func completeOnboarding() {
        // Create final plan
        let finalVision = vision.isEmpty ? Plan.defaultPlan().vision : vision
        let currentDate = Date()
        let calendar = Calendar.current
        let quarterNumber = (calendar.component(.month, from: currentDate) - 1) / 3 + 1

        let newPlan = Plan(
            owner: "You",
            quarter: "Q\(quarterNumber) \(calendar.component(.year, from: currentDate))",
            weeksInQuarter: 13,
            vision: finalVision,
            goals: customizedGoals,
            scores: [:]
        )

        // Save to store
        store.plan = newPlan

        // Mark onboarding as complete
        OnboardingManager.hasCompleted = true

        // Dismiss onboarding
        onComplete()
    }
}

// MARK: - Page Indicators

struct PageIndicators: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppTheme.Colors.primary : AppTheme.Colors.textMuted)
                    .frame(width: 8, height: 8)
                    .opacity(index == currentPage ? 1.0 : 0.3)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
        .environment(PlanStore())
}
