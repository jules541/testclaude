import SwiftUI

struct PlanView: View {
    @Environment(PlanStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Vision
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("My Vision")
                        .sectionHeaderStyle()
                    TextEditor(text: Binding(
                        get: { store.plan.vision },
                        set: { store.updateVision($0) }
                    ))
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.inputBackground)
                    .cornerRadius(AppTheme.Radius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    )
                }
                .padding(AppTheme.Spacing.xl)
                .cardStyle()

                // Goals
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack {
                        Text("Goals")
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Button("Add Goal") {
                            addGoal()
                        }
                        .primaryButtonStyle()
                    }

                    ForEach(store.plan.goals) { goal in
                        GoalCard(goal: goal, store: store)
                    }
                }
                .padding(AppTheme.Spacing.xl)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Plan")
    }

    private func addGoal() {
        let newGoal = Goal(
            id: store.newGoalId(),
            emoji: "🎯",
            name: "New Goal",
            why: "",
            habits: []
        )
        store.addGoal(newGoal)
    }
}

struct GoalCard: View {
    let goal: Goal
    @Bindable var store: PlanStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                TextField("Emoji", text: goalBinding(\.emoji))
                    .font(AppTheme.Typography.title)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                TextField("Goal Name", text: goalBinding(\.name))
                    .font(AppTheme.Typography.headline)
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )

            TextField("Why is this important?", text: goalBinding(\.why), axis: .vertical)
                .font(AppTheme.Typography.body)
                .lineLimit(2...4)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.inputBackground)
                .cornerRadius(AppTheme.Radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )

            Button("Delete Goal") {
                store.deleteGoal(id: goal.id)
            }
            .ghostButtonStyle(danger: true)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func goalBinding<T>(_ keyPath: WritableKeyPath<Goal, T>) -> Binding<T> {
        Binding(
            get: { goal[keyPath: keyPath] },
            set: { newValue in
                var updatedGoal = goal
                updatedGoal[keyPath: keyPath] = newValue
                store.updateGoal(updatedGoal)
            }
        )
    }
}

#Preview {
    NavigationStack {
        PlanView()
            .environment(PlanStore())
    }
}
