import Foundation

/// Manages onboarding completion state using UserDefaults
struct OnboardingManager {

    private static let hasCompletedKey = "hasCompletedOnboarding"

    /// Check if user has completed onboarding
    static var hasCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedKey)
        }
    }

    /// Reset onboarding state (useful for testing)
    static func reset() {
        UserDefaults.standard.removeObject(forKey: hasCompletedKey)
    }
}
