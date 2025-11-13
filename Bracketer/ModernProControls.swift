import SwiftUI

// MARK: - Modern Pro Controls Panel
/// Apple Camera app inspired pro controls with iOS 26 Liquid Glass design
/// Implements tinted glass effects for professional photography controls

@available(iOS 26.0, *)
struct ModernProControls: View {
    let camera: CameraController
    @Binding var showProControls: Bool
    @Binding var selectedEVStep: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    @Binding var bracketShotCount: Int

    // Manual controls
    @State private var manualISO: Float = 100
    @State private var manualShutterSpeed: Float = 0.01
    @State private var whiteBalance: Float = 5500
    @State private var manualFocus: Float = 0.5

    // Section expand/collapse state - only Bracketing expanded by default
    @State private var isExposureExpanded: Bool = false
    @State private var isFocusExpanded: Bool = false
    @State private var isBracketingExpanded: Bool = true

    // Drag gesture state for dismiss
    @State private var dragOffset: CGFloat = 0

    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }

                // Pro controls panel - bottom sheet
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(.white.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // Header
                    HStack {
                        Text("Pro Controls")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Button {
                            dismissSheet()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                    // Control sections
                    ScrollView {
                        VStack(spacing: 24) {
                            // Exposure controls with yellow tint
                            ModernExposureControls(
                                manualISO: $manualISO,
                                manualShutterSpeed: $manualShutterSpeed,
                                whiteBalance: $whiteBalance,
                                isExpanded: $isExposureExpanded
                            )

                            // Focus controls with green tint
                            ModernFocusControls(
                                manualFocus: $manualFocus,
                                focusPeakingEnabled: $focusPeakingEnabled,
                                focusPeakingColor: $focusPeakingColor,
                                focusPeakingIntensity: $focusPeakingIntensity,
                                focusPeakingColors: focusPeakingColors,
                                isExpanded: $isFocusExpanded
                            )

                            // Bracketing controls with orange tint
                            ModernBracketingControls(
                                selectedEVStep: $selectedEVStep,
                                currentEVCompensation: $currentEVCompensation,
                                evCompensationLocked: $evCompensationLocked,
                                bracketShotCount: $bracketShotCount,
                                isExpanded: $isBracketingExpanded
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
                }
                .frame(maxHeight: geometry.size.height * 0.75)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .overlayGlass(style: .panel, interactive: true)
                )
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging down
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            // Dismiss if dragged more than 100pt
                            if value.translation.height > 100 {
                                dismissSheet()
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func dismissSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showProControls = false
        }
    }
}

// MARK: - Modern Exposure Controls

@available(iOS 26.0, *)
struct ModernExposureControls: View {
    @Binding var manualISO: Float
    @Binding var manualShutterSpeed: Float
    @Binding var whiteBalance: Float
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Section header - tappable to expand/collapse
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.exposureAdjusted()
            } label: {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.yellow)
                    Text("Exposure")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            // Collapsible content
            if isExpanded {
                VStack(spacing: 20) {
                    // ISO Control
                    ModernSliderControl(
                        title: "ISO",
                        value: $manualISO,
                        range: 25...25600,
                        step: 25,
                        format: { "\(Int($0))" },
                        color: .yellow
                    )

                    // Shutter Speed Control
                    ModernSliderControl(
                        title: "Shutter",
                        value: $manualShutterSpeed,
                        range: 0.0005...30,
                        step: 0.001,
                        format: formatShutterSpeed,
                        color: .cyan
                    )

                    // White Balance Control
                    ModernSliderControl(
                        title: "White Balance",
                        value: $whiteBalance,
                        range: 2500...10000,
                        step: 100,
                        format: { "\(Int($0))K" },
                        color: .orange
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .liquidGlass(intensity: .regular, tint: .yellow.opacity(0.1), interactive: false)
        )
    }

    private func formatShutterSpeed(_ duration: Float) -> String {
        if duration >= 1.0 {
            return String(format: "%.1fs", duration)
        } else {
            let fraction = 1.0 / duration
            if fraction < 10 {
                return String(format: "1/%.1f", fraction)
            } else {
                return String(format: "1/%.0f", fraction)
            }
        }
    }
}

// MARK: - Modern Focus Controls

@available(iOS 26.0, *)
struct ModernFocusControls: View {
    @Binding var manualFocus: Float
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    let focusPeakingColors: [Color]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Section header - tappable to expand/collapse
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.exposureAdjusted()
            } label: {
                HStack {
                    Image(systemName: "scope")
                        .foregroundColor(.green)
                    Text("Focus")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            // Collapsible content
            if isExpanded {
                VStack(spacing: 20) {
                    // Manual Focus Control
                    ModernSliderControl(
                        title: "Focus",
                        value: $manualFocus,
                        range: 0...1,
                        step: 0.01,
                        format: { "\(Int($0 * 100))%" },
                        color: .green
                    )

                    // Focus Peaking Toggle
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.green)
                        Text("Focus Peaking")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $focusPeakingEnabled)
                            .labelsHidden()
                            .tint(.green)
                    }

                    // Focus Peaking Controls
                    if focusPeakingEnabled {
                        VStack(spacing: 12) {
                            // Color selection
                            HStack {
                                Text("Color")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }

                            HStack(spacing: 12) {
                                ForEach(focusPeakingColors, id: \.self) { color in
                                    Button {
                                        focusPeakingColor = color
                                        HapticManager.shared.exposureAdjusted()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(color.opacity(0.3))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(color, lineWidth: focusPeakingColor == color ? 3 : 1)
                                                )
                                                .liquidGlass(
                                                    intensity: .subtle,
                                                    tint: focusPeakingColor == color ? color.opacity(0.5) : nil,
                                                    interactive: true
                                                )

                                            if focusPeakingColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Intensity control
                            ModernSliderControl(
                                title: "Intensity",
                                value: $focusPeakingIntensity,
                                range: 0.1...1.0,
                                step: 0.1,
                                format: { "\(Int($0 * 100))%" },
                                color: .green
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .liquidGlass(intensity: .regular, tint: .green.opacity(0.1), interactive: false)
        )
    }
}

// MARK: - Modern Bracketing Controls

@available(iOS 26.0, *)
struct ModernBracketingControls: View {
    @Binding var selectedEVStep: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool
    @Binding var bracketShotCount: Int
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Section header - tappable to expand/collapse
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.exposureAdjusted()
            } label: {
                HStack {
                    Image(systemName: "rectangle.stack")
                        .foregroundColor(.orange)
                    Text("Bracketing")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            // Collapsible content
            if isExpanded {
                VStack(spacing: 20) {
                    // EV Compensation with inline glass effect
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                evCompensationLocked.toggle()
                            }
                            HapticManager.shared.exposureAdjusted()
                        } label: {
                            Image(systemName: evCompensationLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(evCompensationLocked ? .red : .white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .liquidGlass(
                                            intensity: .prominent,
                                            tint: evCompensationLocked ? .red.opacity(0.5) : nil,
                                            interactive: true
                                        )
                                )
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 4) {
                            HStack {
                                Text("EV Compensation")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(formatEV(currentEVCompensation))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.orange)
                                    .monospacedDigit()
                            }

                            Slider(value: $currentEVCompensation, in: -4.0...4.0, step: 0.1)
                                .accentColor(.orange)
                                .disabled(evCompensationLocked)
                        }
                    }

                    // Bracketing sequence visualization
                    ModernBracketingSequence(evStep: selectedEVStep, shotCount: bracketShotCount)

                    // EV Step selection
                    HStack(spacing: 12) {
                        ForEach([1, 2, 3], id: \.self) { value in
                            Button {
                                selectedEVStep = Float(value)
                                HapticManager.shared.exposureAdjusted()
                            } label: {
                                Text("±\(value)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedEVStep == Float(value) ? .black : .white)
                                    .frame(minWidth: 60)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .liquidGlass(
                                                intensity: selectedEVStep == Float(value) ? .prominent : .regular,
                                                tint: selectedEVStep == Float(value) ? .orange : nil,
                                                interactive: true
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Shot count selection
                    HStack(spacing: 12) {
                        ForEach([3, 5, 7], id: \.self) { count in
                            Button {
                                bracketShotCount = count
                                HapticManager.shared.exposureAdjusted()
                            } label: {
                                Text("\(count) shots")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(bracketShotCount == count ? .black : .white)
                                    .frame(minWidth: 70)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .liquidGlass(
                                                intensity: bracketShotCount == count ? .prominent : .regular,
                                                tint: bracketShotCount == count ? .orange.opacity(0.5) : nil,
                                                interactive: true
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .liquidGlass(intensity: .regular, tint: .orange.opacity(0.1), interactive: false)
        )
    }

    private func formatEV(_ value: Float) -> String {
        if value == 0 {
            return "±0"
        }
        return String(format: "%+.1f", value)
    }
}

// MARK: - Modern Slider Control

@available(iOS 26.0, *)
struct ModernSliderControl: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let format: (Float) -> String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(format(value))
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }

            Slider(value: $value, in: range, step: step) { editing in
                if !editing {
                    HapticManager.shared.exposureAdjusted()
                }
            }
            .accentColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .liquidGlass(intensity: .subtle, tint: color.opacity(0.1), interactive: false)
        )
    }
}

// MARK: - Modern Bracketing Sequence

@available(iOS 26.0, *)
struct ModernBracketingSequence: View {
    let evStep: Float
    let shotCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(generateBracketSequence(), id: \.self) { ev in
                VStack(spacing: 2) {
                    Text(formatEV(ev))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ev == 0 ? .black : .white)
                    Text("EV")
                        .font(.system(size: 9))
                        .foregroundColor(ev == 0 ? .black.opacity(0.7) : .white.opacity(0.7))
                }
                .frame(width: 40, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .liquidGlass(
                            intensity: ev == 0 ? .prominent : .subtle,
                            tint: ev == 0 ? .orange : .white.opacity(0.1),
                            interactive: false
                        )
                )
            }
        }
        .padding(.vertical, 8)
    }

    private func generateBracketSequence() -> [Float] {
        switch shotCount {
        case 3:
            return [-evStep, 0, +evStep]
        case 5:
            return [-2*evStep, -evStep, 0, +evStep, +2*evStep]
        case 7:
            return [-3*evStep, -2*evStep, -evStep, 0, +evStep, +2*evStep, +3*evStep]
        default:
            return [-evStep, 0, +evStep]
        }
    }

    private func formatEV(_ value: Float) -> String {
        if value == 0 {
            return "0"
        } else if value > 0 {
            return "+\(Int(value))"
        } else {
            return "\(Int(value))"
        }
    }
}
