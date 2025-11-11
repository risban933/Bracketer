import SwiftUI
import AVFoundation

/// iOS 26+ Liquid Glass design implementation using official Apple API
/// Provides dynamic translucency, tinting, and reactive materials
/// Requires iOS 26.0 or later

@available(iOS 26.0, *)
extension View {

    // MARK: - Liquid Glass Effect Modifiers

    /// Apply standard liquid glass effect
    func liquidGlass(
        intensity: GlassIntensity = .regular,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        self.modifier(LiquidGlassModifier(intensity: intensity, tint: tint, interactive: interactive))
    }

    /// Apply liquid glass effect with camera-specific styling
    func cameraGlass(
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        self.liquidGlass(intensity: .regular, tint: tint, interactive: interactive)
    }

    /// Apply liquid glass effect for overlay components (toolbars, panels)
    func overlayGlass(
        style: OverlayGlassStyle = .standard,
        interactive: Bool = false
    ) -> some View {
        self.modifier(OverlayGlassModifier(style: style, interactive: interactive))
    }
}

// MARK: - Glass Intensity Levels

@available(iOS 26.0, *)
enum GlassIntensity {
    case subtle
    case regular
    case prominent

    var material: Material {
        switch self {
        case .subtle: return .ultraThin
        case .regular: return .regular
        case .prominent: return .thick
        }
    }
}

// MARK: - Overlay Glass Styles

@available(iOS 26.0, *)
enum OverlayGlassStyle {
    case standard
    case toolbar
    case panel
    case control
    case warning
    case success
    case error

    var tintColor: Color? {
        switch self {
        case .standard, .toolbar, .panel, .control:
            return nil
        case .warning:
            return .orange
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    var intensity: GlassIntensity {
        switch self {
        case .standard, .toolbar:
            return .regular
        case .panel:
            return .prominent
        case .control:
            return .subtle
        case .warning, .success, .error:
            return .regular
        }
    }
}

// MARK: - Liquid Glass Modifier (iOS 26)

@available(iOS 26.0, *)
struct LiquidGlassModifier: ViewModifier {
    let intensity: GlassIntensity
    let tint: Color?
    let interactive: Bool

    func body(content: Content) -> some View {
        if let tint = tint {
            // iOS 26.1+ tinted glass effect
            if interactive {
                content
                    .glassEffect(intensity.material.tint(tint))
                    .interactive()
            } else {
                content
                    .glassEffect(intensity.material.tint(tint))
            }
        } else {
            // Standard glass effect
            if interactive {
                content
                    .glassEffect(intensity.material)
                    .interactive()
            } else {
                content
                    .glassEffect(intensity.material)
            }
        }
    }
}

// MARK: - Overlay Glass Modifier

@available(iOS 26.0, *)
struct OverlayGlassModifier: ViewModifier {
    let style: OverlayGlassStyle
    let interactive: Bool

    func body(content: Content) -> some View {
        content
            .liquidGlass(
                intensity: style.intensity,
                tint: style.tintColor,
                interactive: interactive
            )
    }
}

// MARK: - Glass Effect Container (for grouped elements)

@available(iOS 26.0, *)
struct LiquidGlassContainer<Content: View>: View {
    let tint: Color?
    let intensity: GlassIntensity
    let content: Content

    init(
        tint: Color? = nil,
        intensity: GlassIntensity = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.intensity = intensity
        self.content = content()
    }

    var body: some View {
        GlassEffectContainer {
            content
                .liquidGlass(intensity: intensity, tint: tint)
        }
    }
}

// MARK: - Liquid Glass Button Styles

@available(iOS 26.0, *)
struct LiquidGlassButtonStyle: ButtonStyle {
    let tint: Color?
    let isActive: Bool

    init(tint: Color? = nil, isActive: Bool = false) {
        self.tint = tint
        self.isActive = isActive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .liquidGlass(
                        intensity: isActive ? .prominent : .regular,
                        tint: isActive ? (tint ?? .accentColor) : tint,
                        interactive: true
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pre-iOS 26 Fallback Implementation

struct LegacyLiquidGlassModifier: ViewModifier {
    let intensity: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(intensity * 0.6)

                    // Tint layer (if provided)
                    if let tint = tint {
                        Rectangle()
                            .fill(tint.opacity(0.2))
                            .blendMode(.overlay)
                    }

                    // Highlight gradient
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
                }
            )
    }
}

// MARK: - Backward Compatibility Extensions

extension View {
    /// Apply liquid glass effect with fallback for pre-iOS 26
    func liquidGlassCompatible(
        intensity: CGFloat = 0.7,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            let glassIntensity: GlassIntensity = intensity < 0.4 ? .subtle : (intensity > 0.8 ? .prominent : .regular)
            return AnyView(self.liquidGlass(intensity: glassIntensity, tint: tint, interactive: interactive))
        } else {
            return AnyView(self.modifier(LegacyLiquidGlassModifier(intensity: intensity, tint: tint)))
        }
    }
}

// MARK: - Enhanced EV Control with Liquid Glass (iOS 26)

@available(iOS 26.0, *)
struct LiquidGlassEVControl: View {
    @Binding var currentEV: Float
    @Binding var isLocked: Bool

    private let evRange: ClosedRange<Float> = -3.0...3.0
    private let stepSize: Float = 0.3

    var body: some View {
        LiquidGlassContainer(tint: isLocked ? .orange : nil, intensity: .regular) {
            HStack(spacing: 12) {
                // EV lock button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLocked.toggle()
                    }
                    HapticManager.shared.exposureAdjusted()
                } label: {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isLocked ? .orange : .white)
                }
                .frame(width: 40, height: 40)
                .liquidGlass(tint: isLocked ? .orange : nil, interactive: true)

                // EV compensation slider
                VStack(spacing: 4) {
                    HStack {
                        Text("EV")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Text(formatEV(currentEV))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(currentEV == 0 ? .white : .orange)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .padding(8)
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

@available(iOS 26.0, *)
struct LiquidGlassEVSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let isLocked: Bool

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background with glass effect
                RoundedRectangle(cornerRadius: 4)
                    .liquidGlass(intensity: .subtle, tint: .white.opacity(0.1))
                    .frame(height: 8)

                // Center line (0 EV)
                Rectangle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 2, height: 12)
                    .position(x: geometry.size.width / 2, y: 15)

                // EV value indicator with glass effect
                Circle()
                    .liquidGlass(
                        intensity: .prominent,
                        tint: value == 0 ? nil : .orange,
                        interactive: true
                    )
                    .frame(width: 20, height: 20)
                    .position(x: sliderPosition(in: geometry), y: 15)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)

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

@available(iOS 26.0, *)
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
        VStack(spacing: 16) {
            // Progress ring with liquid glass background
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .cyan,
                                .blue,
                                .cyan
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
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .liquidGlass(intensity: .prominent, tint: .blue.opacity(0.3))
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
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

@available(iOS 26.0, *)
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
