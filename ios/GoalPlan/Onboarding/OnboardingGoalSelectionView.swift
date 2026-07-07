import SwiftUI

struct OnboardingGoalSelectionView: View {
    @Binding var selectedTemplateIds: Set<String>
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("What areas of life matter most?")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Pick 3-6 goals to focus on this quarter")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.xl)

            // Goal template cards
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(GoalTemplate.all) { template in
                        GoalTemplateCard(
                            template: template,
                            isSelected: selectedTemplateIds.contains(template.id),
                            onTap: {
                                toggleSelection(template.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }

            // Validation message
            if selectedTemplateIds.isEmpty {
                Text("Select at least one goal to continue")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.danger)
            }

            // Navigation buttons
            HStack(spacing: AppTheme.Spacing.md) {
                Button("Back") {
                    onBack()
                }
                .ghostButtonStyle()

                Button(buttonText) {
                    onNext()
                }
                .primaryButtonStyle()
                .disabled(selectedTemplateIds.isEmpty)
                .opacity(selectedTemplateIds.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
    }

    private var buttonText: String {
        if selectedTemplateIds.isEmpty {
            return "Continue"
        } else {
            let count = selectedTemplateIds.count
            return "Continue with \(count) goal\(count == 1 ? "" : "s")"
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedTemplateIds.contains(id) {
            selectedTemplateIds.remove(id)
        } else {
            selectedTemplateIds.insert(id)
        }
    }
}

struct GoalTemplateCard: View {
    let template: GoalTemplate
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Emoji
                Text(template.emoji)
                    .font(.system(size: 32))

                // Goal info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(template.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(template.why)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)

                    if !template.habits.isEmpty {
                        Text("Includes \(template.habits.count) habit\(template.habits.count == 1 ? "" : "s")")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                }

                Spacer()

                // Checkmark indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.textMuted)
                    .font(.title2)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(
                        isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingGoalSelectionView(
        selectedTemplateIds: .constant(["healthy", "relationships"]),
        onNext: {},
        onBack: {}
    )
}
