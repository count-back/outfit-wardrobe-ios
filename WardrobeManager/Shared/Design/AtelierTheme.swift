import SwiftUI

enum AtelierTheme {
    static let background = Color(red: 1.0, green: 0.988, blue: 0.969)
    static let surface = Color.white
    static let surfaceLow = Color(red: 0.988, green: 0.976, blue: 0.953)
    static let surfaceHigh = Color(red: 0.941, green: 0.933, blue: 0.902)
    static let surfaceHighest = Color(red: 0.918, green: 0.910, blue: 0.878)
    static let primary = Color(red: 0.353, green: 0.412, blue: 0.322)
    static let primaryDim = Color(red: 0.306, green: 0.361, blue: 0.278)
    static let secondary = Color(red: 0.506, green: 0.353, blue: 0.357)
    static let secondaryContainer = Color(red: 1.0, green: 0.855, blue: 0.851)
    static let tertiary = Color(red: 0.431, green: 0.388, blue: 0.325)
    static let tertiaryContainer = Color(red: 0.996, green: 0.937, blue: 0.855)
    static let textPrimary = Color(red: 0.220, green: 0.220, blue: 0.200)
    static let textSecondary = Color(red: 0.396, green: 0.396, blue: 0.369)
    static let outline = Color(red: 0.733, green: 0.725, blue: 0.698)
    static let shadow = Color(red: 0.220, green: 0.220, blue: 0.200).opacity(0.06)

    fileprivate static let cardShadow = Shadow(color: shadow, radius: 24, x: 0, y: 12)
}

struct AtelierCardModifier: ViewModifier {
    var background: Color = AtelierTheme.surface
    var cornerRadius: CGFloat = 32
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: AtelierTheme.cardShadow.color, radius: AtelierTheme.cardShadow.radius, x: AtelierTheme.cardShadow.x, y: AtelierTheme.cardShadow.y)
    }
}

struct AtelierPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AtelierTheme.primary, AtelierTheme.primaryDim],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct AtelierSecondaryButtonStyle: ButtonStyle {
    var background: Color = AtelierTheme.surfaceHigh
    var foreground: Color = AtelierTheme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(background, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

extension View {
    func atelierPageBackground() -> some View {
        background(AtelierTheme.background.ignoresSafeArea())
    }

    func atelierCard(
        background: Color = AtelierTheme.surface,
        cornerRadius: CGFloat = 32,
        padding: CGFloat = 18
    ) -> some View {
        modifier(AtelierCardModifier(background: background, cornerRadius: cornerRadius, padding: padding))
    }
}

private struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
