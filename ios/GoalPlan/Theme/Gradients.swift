import SwiftUI

// MARK: - App Gradients

enum AppGradients {

    // MARK: - Progress Gradients

    /// Horizontal gradient for progress meters (primary → accent)
    static let progressMeter = LinearGradient(
        colors: [
            AppTheme.Colors.primary,
            AppTheme.Colors.accent
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Vertical gradient for progress bars (accent → primary)
    static let progressBar = LinearGradient(
        colors: [
            AppTheme.Colors.accent,
            AppTheme.Colors.primary
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Hero Gradient

    /// Diagonal gradient for hero cards (white → primarySoft)
    static let heroCard = LinearGradient(
        colors: [
            AppTheme.Colors.surface,
            AppTheme.Colors.primarySoft
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Background Gradients

    /// Subtle background gradient (warm beige variation)
    static let backgroundSubtle = LinearGradient(
        colors: [
            AppTheme.Colors.background,
            AppTheme.Colors.background.opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
