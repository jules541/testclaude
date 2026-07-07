import SwiftUI

// MARK: - App Animations

enum AppAnimations {

    // MARK: - Animation Curves

    /// Springy animation for interactive elements
    static let springy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Smooth easing for transitions
    static let smooth = Animation.easeInOut(duration: 0.2)

    /// Quick animation for micro-interactions
    static let quick = Animation.easeOut(duration: 0.15)

    /// Progress fill animation
    static let progressFill = Animation.easeOut(duration: 0.3)

    /// Slow fade for subtle changes
    static let fade = Animation.easeInOut(duration: 0.4)
}
