import SwiftUI

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: AppTheme.Shadows.card.color,
                radius: AppTheme.Shadows.card.radius,
                x: AppTheme.Shadows.card.x,
                y: AppTheme.Shadows.card.y
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Input Style

struct InputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.inputBackground)
            .cornerRadius(AppTheme.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func inputStyle() -> some View {
        modifier(InputStyle())
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.body)
            .foregroundColor(.white)
            .padding(.vertical, AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.Radius.medium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
}

// MARK: - Ghost Button Style

struct GhostButtonStyle: ButtonStyle {
    var danger: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.body)
            .foregroundColor(danger ? AppTheme.Colors.danger : AppTheme.Colors.primary)
            .padding(.vertical, AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(
                configuration.isPressed ?
                    (danger ? AppTheme.Colors.danger.opacity(0.1) : AppTheme.Colors.primarySoft) :
                    Color.clear
            )
            .cornerRadius(AppTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(danger ? AppTheme.Colors.danger : AppTheme.Colors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func ghostButtonStyle(danger: Bool = false) -> some View {
        buttonStyle(GhostButtonStyle(danger: danger))
    }
}

// MARK: - Badge Style

struct BadgeStyle: ViewModifier {
    let percentage: Double?

    func body(content: Content) -> some View {
        let colors = AppTheme.scoreColor(for: percentage)

        content
            .font(AppTheme.Typography.captionBold)
            .foregroundColor(colors.text)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .fill(colors.background)
            )
    }
}

extension View {
    func badge(percentage: Double?) -> some View {
        modifier(BadgeStyle(percentage: percentage))
    }
}

// MARK: - Section Header Style

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .padding(.bottom, AppTheme.Spacing.sm)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}
