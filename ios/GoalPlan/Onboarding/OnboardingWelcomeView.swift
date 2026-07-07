import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()

            // Large emoji illustration
            Text("🎯")
                .font(.system(size: 80))

            // App title and tagline
            VStack(spacing: AppTheme.Spacing.md) {
                Text("GoalPlan")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Build the life you envision,\none week at a time")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Feature bullets
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                FeatureBullet(
                    icon: "target",
                    text: "Set meaningful goals with clear reasons why"
                )
                FeatureBullet(
                    icon: "calendar",
                    text: "Track weekly habits that move you forward"
                )
                FeatureBullet(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "See your progress visualized over time"
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            // Get Started button
            Button("Get Started") {
                onNext()
            }
            .primaryButtonStyle()
            .padding(.horizontal, AppTheme.Spacing.lg)

            // Skip link
            Button("I've used this before") {
                onSkip()
            }
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Colors.textMuted)
            .padding(.bottom, AppTheme.Spacing.md)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.background)
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    OnboardingWelcomeView(
        onNext: {},
        onSkip: {}
    )
}
