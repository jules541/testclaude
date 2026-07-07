import SwiftUI

struct OnboardingVisionView: View {
    @Binding var vision: String
    let onNext: () -> Void
    let onBack: () -> Void

    private let maxCharacters = 500
    private let placeholderText = """
    I want to build a life of purpose, health, and meaningful connections. \
    I'm focused on physical wellness, deep relationships, creative expression, \
    and financial independence. Each day is an opportunity to become the person I envision.
    """

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("What's your vision?")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("This is your north star. What kind of life do you want to build?")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.xl)

            // Vision TextEditor
            ZStack(alignment: .topLeading) {
                if vision.isEmpty {
                    Text(placeholderText)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .padding(AppTheme.Spacing.md)
                        .padding(.top, 8)
                }

                TextEditor(text: $vision)
                    .font(AppTheme.Typography.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            .padding(.horizontal, AppTheme.Spacing.lg)

            // Character count
            HStack {
                Spacer()
                Text("\(vision.count)/\(maxCharacters)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(vision.count > maxCharacters ? AppTheme.Colors.danger : AppTheme.Colors.textMuted)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            // Navigation buttons
            HStack(spacing: AppTheme.Spacing.md) {
                Button("Back") {
                    onBack()
                }
                .ghostButtonStyle()

                Button("Next") {
                    onNext()
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
        .onChange(of: vision) { _, newValue in
            // Limit to max characters
            if newValue.count > maxCharacters {
                vision = String(newValue.prefix(maxCharacters))
            }
        }
    }
}

#Preview {
    OnboardingVisionView(
        vision: .constant(""),
        onNext: {},
        onBack: {}
    )
}
