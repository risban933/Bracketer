import SwiftUI
import AVFoundation

/// Liquid Glass design implementation for iOS 26+ camera interface
/// Provides dynamic translucency, blur effects, and reactive materials
extension ModernDesignSystem {
    
    // MARK: - Liquid Glass Materials
    struct LiquidGlass {
        
        /// Primary liquid glass material with dynamic opacity
        static func primary(intensity: Double = 0.8) -> some View {
            ZStack {
                // Base glass layer
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(intensity * 0.6)
                
                // Color reflection layer
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .clear,
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
                
                // Edge highlights
                Rectangle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .clear,
                                .white.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        }
        
        /// Secondary liquid glass for subtle elements
        static func secondary(intensity: Double = 0.4) -> some View {
            ZStack {
                Rectangle()
                    .fill(.thinMaterial)
                    .opacity(intensity)
                
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .blendMode(.softLight)
            }
        }
        
        /// Interactive liquid glass that responds to touch
        static func interactive(isPressed: Bool, intensity: Double = 0.7) -> some View {
            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                    .opacity(isPressed ? intensity * 1.2 : intensity)
                
                // Ripple effect on press
                if isPressed {
                    Rectangle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .scaleEffect(isPressed ? 1.5 : 1.0)
                        .animation(.easeOut(duration: 0.3), value: isPressed)
                }
                
                Rectangle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
        }
    }
    
    // MARK: - Liquid Glass Modifiers
    struct LiquidGlassModifier: ViewModifier {
        let style: LiquidGlassStyle
        let intensity: Double
        let cornerRadius: CGFloat
        
        enum LiquidGlassStyle {
            case primary, secondary, interactive, overlay
        }
        
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(overlayGradient)
                                .blendMode(.overlay)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(borderGradient, lineWidth: 1)
                        )
                )
        }
        
        private var backgroundMaterial: some ShapeStyle {
            switch style {
            case .primary: return .regularMaterial
            case .secondary: return .thinMaterial
            case .interactive: return .thickMaterial
            case .overlay: return .ultraThinMaterial
            }
        }
        
        private var overlayGradient: some ShapeStyle {
            LinearGradient(
                colors: [
                    .white.opacity(intensity * 0.3),
                    .clear,
                    .white.opacity(intensity * 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        private var borderGradient: some ShapeStyle {
            LinearGradient(
                colors: [
                    .white.opacity(intensity * 0.6),
                    .white.opacity(intensity * 0.2),
                    .white.opacity(intensity * 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Reactive Liquid Glass
    struct ReactiveLiquidGlass: ViewModifier {
        @State private var hoverLocation: CGPoint = .zero
        @State private var isHovering = false
        let cornerRadius: CGFloat
        
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                        .overlay(
                            // Dynamic highlight that follows interaction
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            .white.opacity(0.4),
                                            .white.opacity(0.1),
                                            .clear
                                        ],
                                        center: UnitPoint(
                                            x: hoverLocation.x / 200,
                                            y: hoverLocation.y / 200
                                        ),
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .position(hoverLocation)
                                .opacity(isHovering ? 1 : 0)
                                .animation(.easeOut(duration: 0.3), value: isHovering)
                                .blendMode(.overlay)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.4),
                                            .white.opacity(0.1),
                                            .white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hoverLocation = value.location
                            isHovering = true
                        }
                        .onEnded { _ in
                            isHovering = false
                        }
                )
        }
    }
}

// MARK: - View Extensions for Liquid Glass
extension View {
    
    /// Apply liquid glass effect with customization
    func liquidGlass(
        style: ModernDesignSystem.LiquidGlassModifier.LiquidGlassStyle = .primary,
        intensity: Double = 0.7,
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium
    ) -> some View {
        self.modifier(
            ModernDesignSystem.LiquidGlassModifier(
                style: style,
                intensity: intensity,
                cornerRadius: cornerRadius
            )
        )
    }
    
    /// Apply reactive liquid glass that responds to touch
    func reactiveLiquidGlass(
        cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.medium
    ) -> some View {
        self.modifier(
            ModernDesignSystem.ReactiveLiquidGlass(cornerRadius: cornerRadius)
        )
    }
}

// MARK: - Enhanced EV Control with Liquid Glass
struct LiquidGlassEVControl: View {
    @Binding var currentEV: Float
    @Binding var isLocked: Bool
    
    private let evRange: ClosedRange<Float> = -3.0...3.0
    private let stepSize: Float = 0.3
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.md) {
            // EV lock button
            Button {
                withAnimation(ModernDesignSystem.Animations.spring) {
                    isLocked.toggle()
                }
                HapticManager.shared.exposureAdjusted()
            } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isLocked ? ModernDesignSystem.Colors.warning : ModernDesignSystem.Colors.cameraControl)
            }
            .liquidGlass(style: .secondary, intensity: isLocked ? 0.8 : 0.4)
            .frame(width: 40, height: 40)
            
            // EV compensation slider
            VStack(spacing: ModernDesignSystem.Spacing.xs) {
                HStack {
                    Text("EV")
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    
                    Spacer()
                    
                    Text(formatEV(currentEV))
                        .font(ModernDesignSystem.Typography.monospaceSmall)
                        .foregroundColor(currentEV == 0 ? ModernDesignSystem.Colors.cameraControl : ModernDesignSystem.Colors.warning)
                        .monospacedDigit()
                }
                
                // Custom EV slider with liquid glass track
                LiquidGlassEVSlider(
                    value: $currentEV,
                    range: evRange,
                    step: stepSize,
                    isLocked: isLocked
                )
                .frame(height: 30)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .liquidGlass(style: .primary, intensity: 0.6)
        }
    }
    
    private func formatEV(_ value: Float) -> String {
        if value == 0 {
            return "±0"
        } else if value > 0 {
            return "+\(String(format: "%.1f", value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

struct LiquidGlassEVSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let isLocked: Bool
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 4)
                    .fill(ModernDesignSystem.LiquidGlass.secondary(intensity: 0.3))
                    .frame(height: 8)
                
                // Center line (0 EV)
                Rectangle()
                    .fill(ModernDesignSystem.Colors.cameraControl.opacity(0.5))
                    .frame(width: 2, height: 12)
                    .position(x: geometry.size.width / 2, y: 15)
                
                // EV value indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        value == 0 ? 
                        ModernDesignSystem.Colors.cameraControl :
                        ModernDesignSystem.Colors.warning
                    )
                    .frame(width: 12, height: 12)
                    .position(x: sliderPosition(in: geometry), y: 15)
                    .scaleEffect(isDragging ? 1.3 : 1.0)
                    .animation(ModernDesignSystem.Animations.spring, value: isDragging)
                
                // Interactive overlay
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gestureValue in
                                if !isLocked {
                                    isDragging = true
                                    let newValue = valueFromPosition(gestureValue.location.x, in: geometry)
                                    let steppedValue = round(newValue / step) * step
                                    value = max(range.lowerBound, min(range.upperBound, steppedValue))
                                    HapticManager.shared.exposureAdjusted()
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
        }
    }
    
    private func sliderPosition(in geometry: GeometryProxy) -> CGFloat {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return geometry.size.width * CGFloat(normalizedValue)
    }
    
    private func valueFromPosition(_ position: CGFloat, in geometry: GeometryProxy) -> Float {
        let normalizedPosition = position / geometry.size.width
        return range.lowerBound + Float(normalizedPosition) * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Liquid Glass Progress Indicators
struct LiquidGlassProgressView: View {
    let progress: Double
    let title: String
    let subtitle: String?
    
    init(progress: Double, title: String, subtitle: String? = nil) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Progress ring with liquid glass background
            ZStack {
                Circle()
                    .stroke(ModernDesignSystem.Colors.cameraControlSecondary, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                ModernDesignSystem.Colors.cameraControlActive,
                                ModernDesignSystem.Colors.cameraControlActive.opacity(0.6),
                                ModernDesignSystem.Colors.cameraControlActive
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(ModernDesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    .monospacedDigit()
            }
            
            VStack(spacing: ModernDesignSystem.Spacing.xs) {
                Text(title)
                    .font(ModernDesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                }
            }
        }
        .padding(ModernDesignSystem.Spacing.xl)
        .liquidGlass(style: .overlay, intensity: 0.8)
    }
}

#Preview("EV Control") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            LiquidGlassEVControl(
                currentEV: .constant(0.0),
                isLocked: .constant(false)
            )
            
            LiquidGlassEVControl(
                currentEV: .constant(1.3),
                isLocked: .constant(true)
            )
        }
        .padding()
    }
}

#Preview("Liquid Glass Progress") {
    ZStack {
        Color.black.ignoresSafeArea()
        LiquidGlassProgressView(
            progress: 0.65,
            title: "Processing Bracket",
            subtitle: "Shot 2 of 4"
        )
    }
}
