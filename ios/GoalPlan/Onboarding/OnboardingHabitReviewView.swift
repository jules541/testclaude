import SwiftUI

struct OnboardingHabitReviewView: View {
    @Binding var customizedGoals: [Goal]
    let onComplete: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Header
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Review your habits")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("These are the weekly actions tied to your goals")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.xl)

            // Goals with habits
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    ForEach($customizedGoals) { $goal in
                        GoalHabitsSection(goal: $goal)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }

            // Navigation buttons
            HStack(spacing: AppTheme.Spacing.md) {
                Button("Back") {
                    onBack()
                }
                .ghostButtonStyle()

                Button("Start Planning") {
                    onComplete()
                }
                .primaryButtonStyle()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
    }
}

struct GoalHabitsSection: View {
    @Binding var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Goal header
            HStack {
                Text(goal.emoji)
                    .font(.title2)
                Text(goal.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            // Habits list
            if goal.habits.isEmpty {
                Text("No habits yet")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .padding(AppTheme.Spacing.md)
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach($goal.habits) { $habit in
                        HabitEditRow(habit: $habit)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }
}

struct HabitEditRow: View {
    @Binding var habit: Habit
    @State private var isEditing = false

    private let unitPresets = ["days", "minutes", "hours", "calls", "pages", "classes"]

    var body: some View {
        if isEditing {
            // Edit mode
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                // Habit name
                TextField("Habit name", text: $habit.name)
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(AppTheme.Radius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )

                // Target and unit
                HStack {
                    // Target value
                    TextField("Target", value: $habit.target, format: .number)
                        .keyboardType(.decimalPad)
                        .font(AppTheme.Typography.body)
                        .padding(AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.inputBackground)
                        .cornerRadius(AppTheme.Radius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                .stroke(AppTheme.Colors.border, lineWidth: 1)
                        )
                        .frame(width: 80)

                    // Unit picker
                    Picker("Unit", selection: $habit.unit) {
                        ForEach(unitPresets, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(AppTheme.Radius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )

                    Button("Done") {
                        isEditing = false
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.small)
        } else {
            // Display mode
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(AppTheme.Colors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Target: \(Int(habit.target)) \(habit.unit)/week")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Button(action: {
                    isEditing = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
            }
            .padding(AppTheme.Spacing.sm)
        }
    }
}

#Preview {
    OnboardingHabitReviewView(
        customizedGoals: .constant([
            Goal(
                id: "healthy",
                emoji: "💪",
                name: "Healthy Lifestyle",
                why: "Build physical health",
                habits: [
                    Habit(id: "1", name: "Workout", unit: "days", target: 7),
                    Habit(id: "2", name: "Take vitamins", unit: "days", target: 7)
                ]
            )
        ]),
        onComplete: {},
        onBack: {}
    )
}
