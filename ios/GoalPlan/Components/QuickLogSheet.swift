import SwiftUI

/// Fast entry for quantity habits: type a value or tap unit-aware
/// quick-add buttons instead of tapping +1 repeatedly.
struct QuickLogSheet: View {
    let habit: Habit
    @Bindable var store: PlanStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Double = 0
    @FocusState private var fieldFocused: Bool

    private var quickAddValues: [Double] {
        switch habit.unit {
        case "minutes": return [5, 15, 30]
        case "hours": return [0.5, 1]
        default: return [1, 2]
        }
    }

    private func format(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Today's value
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Today")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("0", value: $draft, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($fieldFocused)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .fixedSize()
                        Text(habit.unit)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(.top, AppTheme.Spacing.xl)

                // Quick-add buttons
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(quickAddValues, id: \.self) { amount in
                        Button {
                            draft += amount
                        } label: {
                            Text("+\(format(amount))")
                                .font(AppTheme.Typography.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.primarySoft)
                                .foregroundColor(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.Radius.small)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                if draft > 0 {
                    Button("Clear today", role: .destructive) {
                        draft = 0
                    }
                    .font(AppTheme.Typography.caption)
                }

                Spacer()
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.logDaily(habitId: habit.id, value: draft > 0 ? draft : nil)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                draft = store.plan.todayContribution(for: habit) ?? 0
            }
        }
        .presentationDetents([.height(320)])
    }
}

#Preview {
    QuickLogSheet(
        habit: Habit(id: "reading", name: "Reading", unit: "minutes", target: 30),
        store: PlanStore()
    )
}
