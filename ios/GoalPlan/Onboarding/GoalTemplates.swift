import Foundation

/// Template for creating goals during onboarding
struct GoalTemplate: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let why: String
    let habits: [HabitTemplate]
}

/// Template for creating habits within goal templates
struct HabitTemplate {
    let name: String
    let unit: String
    let defaultTarget: Double
}

extension GoalTemplate {

    /// Convert template to actual Goal with real Habit objects
    func toGoal() -> Goal {
        Goal(
            id: id,
            emoji: emoji,
            name: name,
            why: why,
            habits: habits.map { habitTemplate in
                Habit(
                    id: UUID().uuidString,
                    name: habitTemplate.name,
                    unit: habitTemplate.unit,
                    target: habitTemplate.defaultTarget
                )
            }
        )
    }

    /// All pre-configured goal templates for onboarding
    static let all: [GoalTemplate] = [
        // 1. Healthy Lifestyle
        GoalTemplate(
            id: "healthy",
            emoji: "💪",
            name: "Healthy Lifestyle",
            why: "Build physical, mental, and spiritual health",
            habits: [
                HabitTemplate(name: "Workout", unit: "days", defaultTarget: 7),
                HabitTemplate(name: "Take vitamins", unit: "days", defaultTarget: 7),
                HabitTemplate(name: "Clean eating", unit: "days", defaultTarget: 7)
            ]
        ),

        // 2. Strong Relationships
        GoalTemplate(
            id: "relationships",
            emoji: "❤️",
            name: "Strong Relationships",
            why: "Deepen connections with family and friends",
            habits: [
                HabitTemplate(name: "Phone calls", unit: "calls", defaultTarget: 2),
                HabitTemplate(name: "Days with fellowship", unit: "days", defaultTarget: 1)
            ]
        ),

        // 3. Mental Toolkit
        GoalTemplate(
            id: "mental",
            emoji: "🧘",
            name: "Mental Toolkit",
            why: "Develop emotional resilience and calm",
            habits: [
                HabitTemplate(name: "Breathing exercises", unit: "minutes", defaultTarget: 30)
            ]
        ),

        // 4. Creative Assets
        GoalTemplate(
            id: "creative",
            emoji: "🎨",
            name: "Creative Assets",
            why: "Build things that create lasting value",
            habits: [
                HabitTemplate(name: "Creative work", unit: "hours", defaultTarget: 2)
            ]
        ),

        // 5. Financial Freedom
        GoalTemplate(
            id: "financial",
            emoji: "🏖️",
            name: "Financial Freedom",
            why: "Build wealth for long-term security",
            habits: [
                HabitTemplate(name: "Reading", unit: "minutes", defaultTarget: 30)
            ]
        ),

        // 6. Language Learning
        GoalTemplate(
            id: "language",
            emoji: "🗣️",
            name: "Language Learning",
            why: "Master a new language for connection",
            habits: [
                HabitTemplate(name: "Classes", unit: "classes", defaultTarget: 2)
            ]
        ),

        // 7. Start from Scratch
        GoalTemplate(
            id: "custom",
            emoji: "➕",
            name: "Start from Scratch",
            why: "Create your own custom goal",
            habits: []
        )
    ]
}
