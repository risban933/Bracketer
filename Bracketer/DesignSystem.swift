import SwiftUI

// MARK: - Design System
/// Professional design system for Bracketer camera app
/// Inspired by Halide's minimalist aesthetic with enhanced visual hierarchy

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary palette
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.8)
        static let tertiary = Color.white.opacity(0.6)
        
        // Accent colors
        static let accent = Color.yellow
        static let accentSecondary = Color.blue
        static let accentTertiary = Color.purple
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Background colors
        static let background = Color.black
        static let surface = Color.black.opacity(0.8)
        static let surfaceSecondary = Color.black.opacity(0.6)
        static let surfaceTertiary = Color.black.opacity(0.4)
        
        // Overlay colors
        static let overlay = Color.black.opacity(0.7)
        static let overlayLight = Color.black.opacity(0.3)
        
        // Grid and overlay colors
        static let grid = Color.white.opacity(0.6)
        static let level = Color.yellow.opacity(0.8)
        static let histogram = Color.blue.opacity(0.7)
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
        static let title = Font.system(size: 22, weight: .semibold, design: .default)
        static let headline = Font.system(size: 18, weight: .semibold, design: .default)
        
        // Body text
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 16, weight: .medium, design: .default)
        static let bodySemibold = Font.system(size: 16, weight: .semibold, design: .default)
        
        // Small text
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let captionSemibold = Font.system(size: 12, weight: .semibold, design: .default)
        
        // Monospace (for technical values)
        static let monospace = Font.system(size: 14, weight: .medium, design: .monospaced)
        static let monospaceSmall = Font.system(size: 12, weight: .medium, design: .monospaced)
        static let monospaceLarge = Font.system(size: 16, weight: .semibold, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Animations
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}

// MARK: - Shadow Extension
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func applyShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isActive: Bool
    let size: ButtonSize
    
    enum ButtonSize {
        case small, medium, large
        
        var frame: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 56
            case .large: return 72
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.frame, height: size.frame)
            .background(
                Circle()
                    .fill(isActive ? DesignSystem.Colors.accent : DesignSystem.Colors.surfaceSecondary)
                    .overlay(
                        Circle()
                            .stroke(
                                isActive ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiary,
                                lineWidth: isActive ? 2 : 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isActive ? DesignSystem.Colors.accent.opacity(0.2) : DesignSystem.Colors.surfaceTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(
                                isActive ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiary,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Card Styles
struct CardStyle: ViewModifier {
    let variant: CardVariant
    
    enum CardVariant {
        case primary, secondary, overlay
        
        var background: Color {
            switch self {
            case .primary: return DesignSystem.Colors.surface
            case .secondary: return DesignSystem.Colors.surfaceSecondary
            case .overlay: return DesignSystem.Colors.overlay
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .primary: return DesignSystem.CornerRadius.large
            case .secondary: return DesignSystem.CornerRadius.medium
            case .overlay: return DesignSystem.CornerRadius.medium
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(variant.background)
            .cornerRadius(variant.cornerRadius)
            .applyShadow(DesignSystem.Shadows.medium)
    }
}

extension View {
    func cardStyle(_ variant: CardStyle.CardVariant = .primary) -> some View {
        self.modifier(CardStyle(variant: variant))
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: Status
    let size: CGFloat
    
    enum Status {
        case active, inactive, warning, error
        
        var color: Color {
            switch self {
            case .active: return DesignSystem.Colors.success
            case .inactive: return DesignSystem.Colors.tertiary
            case .warning: return DesignSystem.Colors.warning
            case .error: return DesignSystem.Colors.error
            }
        }
    }
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(DesignSystem.Colors.background, lineWidth: 2)
            )
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    init(progress: Double, lineWidth: CGFloat = 4, color: Color = DesignSystem.Colors.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, lineWidth: lineWidth)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animations.smooth, value: progress)
        }
    }
}

// MARK: - Glass Effect
struct GlassEffect: ViewModifier {
    let intensity: Double
    
    init(intensity: Double = 0.1) {
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(.ultraThinMaterial)
                    .opacity(intensity)
            )
    }
}

extension View {
    func glassEffect(intensity: Double = 0.1) -> some View {
        self.modifier(GlassEffect(intensity: intensity))
    }
}

