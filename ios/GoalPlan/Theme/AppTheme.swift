import SwiftUI

// MARK: - App Theme
// Centralized design system matching the web app's warm, refined aesthetic

enum AppTheme {

    // MARK: - Colors

    enum Colors {
        // Background & Surface
        static let background = Color(hex: "f6f4ef")      // Warm beige
        static let surface = Color(hex: "ffffff")          // White
        static let inputBackground = Color(hex: "fdfcf9")  // Off-white for inputs

        // Primary Colors
        static let primary = Color(hex: "2f6f5e")          // Muted green
        static let primaryDark = Color(hex: "24574a")      // Darker green
        static let primarySoft = Color(hex: "e3efe9")      // Light green tint

        // Accent & Supporting
        static let accent = Color(hex: "d9a441")           // Warm gold
        static let danger = Color(hex: "b4504c")           // Muted burgundy
        static let border = Color(hex: "e5e1d8")           // Warm tan

        // Score Color System
        static let scoreFull = Color(hex: "2f6f5e")        // 100% - Green
        static let scoreFullBg = Color(hex: "e3efe9")      // 100% background

        static let scoreGood = Color(hex: "3b8a6f")        // 70-99% - Good green
        static let scoreGoodBg = Color(hex: "e8f4ed")      // 70-99% background

        static let scoreMid = Color(hex: "d9a441")         // 40-69% - Amber
        static let scoreMidBg = Color(hex: "fdf6e8")       // 40-69% background

        static let scoreLow = Color(hex: "b4504c")         // 0-39% - Burgundy
        static let scoreLowBg = Color(hex: "f8e8e7")       // 0-39% background

        // Text Colors
        static let textPrimary = Color(hex: "22302c")      // Dark green-gray
        static let textSecondary = Color(hex: "6b7b76")    // Medium gray
        static let textMuted = Color(hex: "9ca8a3")        // Light gray
    }

    // MARK: - Typography

    enum Typography {
        // Font sizes
        static let heroScore: Font = .system(size: 56, weight: .bold)
        static let title: Font = .system(size: 28, weight: .bold)
        static let headline: Font = .system(size: 17, weight: .semibold)
        static let body: Font = .system(size: 17, weight: .regular)
        static let caption: Font = .system(size: 12, weight: .regular)
        static let captionBold: Font = .system(size: 12, weight: .semibold)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows

    enum Shadows {
        static let card = Shadow(
            color: Color(hex: "22302c").opacity(0.07),
            radius: 10,
            x: 0,
            y: 2
        )

        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    // MARK: - Helper: Score Color

    static func scoreColor(for pct: Double?) -> (text: Color, background: Color) {
        guard let pct = pct else {
            return (text: Colors.textMuted, background: Color(.systemGray6))
        }

        if pct >= 1.0 {
            return (text: Colors.scoreFull, background: Colors.scoreFullBg)
        } else if pct >= 0.7 {
            return (text: Colors.scoreGood, background: Colors.scoreGoodBg)
        } else if pct >= 0.4 {
            return (text: Colors.scoreMid, background: Colors.scoreMidBg)
        } else {
            return (text: Colors.scoreLow, background: Colors.scoreLowBg)
        }
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
