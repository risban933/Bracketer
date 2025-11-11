import SwiftUI

// MARK: - Modern Pro Controls Panel
/// Apple Camera app inspired pro controls with Halide professional features
/// Implements iOS 18+ design patterns for professional photography

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
    
    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]
    
    var body: some View {
        ZStack {
            // Background overlay
            ModernDesignSystem.Colors.cameraOverlay
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(ModernDesignSystem.Animations.spring) {
                        showProControls = false
                    }
                }
            
            // Pro controls panel
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Header
                HStack {
                    Text("Pro Controls")
                        .font(ModernDesignSystem.Typography.title2)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(ModernDesignSystem.Animations.spring) {
                            showProControls = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                
                // Control sections
                ScrollView {
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        // Exposure controls
                        ModernExposureControls(
                            manualISO: $manualISO,
                            manualShutterSpeed: $manualShutterSpeed,
                            whiteBalance: $whiteBalance
                        )
                        
                        // Focus controls
                        ModernFocusControls(
                            manualFocus: $manualFocus,
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            focusPeakingColors: focusPeakingColors
                        )
                        
                        // Bracketing controls
                        ModernBracketingControls(
                            selectedEVStep: $selectedEVStep,
                            currentEVCompensation: $currentEVCompensation,
                            evCompensationLocked: $evCompensationLocked,
                            bracketShotCount: $bracketShotCount
                        )
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                }
            }
            .padding(.vertical, ModernDesignSystem.Spacing.xl)
            .frame(maxWidth: 400)
            .modernCardStyle(.overlay)
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Modern Exposure Controls
struct ModernExposureControls: View {
    @Binding var manualISO: Float
    @Binding var manualShutterSpeed: Float
    @Binding var whiteBalance: Float
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                Text("Exposure")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // ISO Control
            ModernSliderControl(
                title: "ISO",
                value: $manualISO,
                range: 25...25600,
                step: 25,
                format: { "\(Int($0))" },
                color: ModernDesignSystem.Colors.cameraControlActive
            )
            
            // Shutter Speed Control
            ModernSliderControl(
                title: "Shutter",
                value: $manualShutterSpeed,
                range: 0.0005...30,
                step: 0.001,
                format: formatShutterSpeed,
                color: ModernDesignSystem.Colors.professional
            )
            
            // White Balance Control
            ModernSliderControl(
                title: "White Balance",
                value: $whiteBalance,
                range: 2500...10000,
                step: 100,
                format: { "\(Int($0))K" },
                color: ModernDesignSystem.Colors.warning
            )
        }
            .modernCardStyle(.glass)
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
struct ModernFocusControls: View {
    @Binding var manualFocus: Float
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    let focusPeakingColors: [Color]
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "scope")
                    .foregroundColor(ModernDesignSystem.Colors.success)
                Text("Focus")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // Manual Focus Control
            ModernSliderControl(
                title: "Focus",
                value: $manualFocus,
                range: 0...1,
                step: 0.01,
                format: { "\(Int($0 * 100))%" },
                color: ModernDesignSystem.Colors.success
            )
            
            // Focus Peaking Toggle
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(ModernDesignSystem.Colors.success)
                Text("Focus Peaking")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
                Toggle("", isOn: $focusPeakingEnabled)
                    .labelsHidden()
                    .tint(ModernDesignSystem.Colors.success)
            }
            
            // Focus Peaking Controls
            if focusPeakingEnabled {
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    // Color selection
                    HStack {
                        Text("Color")
                            .font(ModernDesignSystem.Typography.caption)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                        Spacer()
                    }
                    
                    HStack(spacing: ModernDesignSystem.Spacing.md) {
                        ForEach(focusPeakingColors, id: \.self) { color in
                            Button {
                                focusPeakingColor = color
                            } label: {
                                Circle()
                                    .fill(color.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(color, lineWidth: focusPeakingColor == color ? 2 : 1)
                                    )
                                    .overlay(
                                        Group {
                                            if focusPeakingColor == color {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                                            }
                                        }
                                    )
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
                        color: ModernDesignSystem.Colors.success
                    )
                }
            }
        }
            .modernCardStyle(.glass)
    }
}

// MARK: - Modern Bracketing Controls
struct ModernBracketingControls: View {
    @Binding var selectedEVStep: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool
    @Binding var bracketShotCount: Int
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "rectangle.stack")
                    .foregroundColor(ModernDesignSystem.Colors.warning)
                Text("Bracketing")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // EV Compensation
            ModernEVControl(
                currentEV: $currentEVCompensation,
                isLocked: $evCompensationLocked
            )
            
            // Bracketing sequence visualization
            ModernBracketingSequence(evStep: selectedEVStep)
            
            // EV Step selection
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                ForEach([1, 2, 3], id: \.self) { value in
                    Button {
                        selectedEVStep = Float(value)
                    } label: {
                        Text("±\(value)")
                            .font(ModernDesignSystem.Typography.bodyBold)
                            .foregroundColor(selectedEVStep == Float(value) ? ModernDesignSystem.Colors.cameraBackground : ModernDesignSystem.Colors.cameraControl)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(selectedEVStep == Float(value) ? ModernDesignSystem.Colors.warning : ModernDesignSystem.Colors.glassBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Shot count selection
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                ForEach([3, 5], id: \.self) { count in
                    Button {
                        bracketShotCount = count
                    } label: {
                        Text("\(count) shots")
                            .font(ModernDesignSystem.Typography.bodyBold)
                            .foregroundColor(bracketShotCount == count ? ModernDesignSystem.Colors.cameraBackground : ModernDesignSystem.Colors.cameraControl)
                            .frame(width: 80, height: 36)
                            .background(
                                Capsule()
                                    .fill(bracketShotCount == count ? ModernDesignSystem.Colors.professional : ModernDesignSystem.Colors.glassBackground)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
            .modernCardStyle(.glass)
    }
}

// MARK: - Modern Slider Control
struct ModernSliderControl: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let format: (Float) -> String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.sm) {
            HStack {
                Text(title)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
                Text(format(value))
                    .font(ModernDesignSystem.Typography.monospace)
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(color)
        }
    }
}

// MARK: - Modern Bracketing Sequence
struct ModernBracketingSequence: View {
    let evStep: Float
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            // Underexposed shot
            VStack(spacing: 2) {
                Text("-\(Int(evStep))")
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Text("EV")
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(ModernDesignSystem.Colors.glassBackground)
            )
            
            // Baseline shot
            VStack(spacing: 2) {
                Text("0")
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.cameraBackground)
                Text("EV")
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.cameraBackground)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(ModernDesignSystem.Colors.warning)
            )
            
            // Overexposed shot
            VStack(spacing: 2) {
                Text("+\(Int(evStep))")
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Text("EV")
                    .font(ModernDesignSystem.Typography.caption2)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(ModernDesignSystem.Colors.glassBackground)
            )
        }
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
    }
}

// MARK: - Modern EV Control
struct ModernEVControl: View {
    @Binding var currentEV: Float
    @Binding var isLocked: Bool
    
    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.sm) {
            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 14))
                .foregroundColor(isLocked ? ModernDesignSystem.Colors.error : ModernDesignSystem.Colors.cameraControl)
            
            Text(formatEV(currentEV))
                .font(ModernDesignSystem.Typography.monospace)
                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                .frame(minWidth: 40)
            
            Spacer()
            
            // Fine control slider
            Slider(value: $currentEV, in: -4.0...4.0, step: 0.1)
                .accentColor(ModernDesignSystem.Colors.warning)
                .frame(width: 120)
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(
            Capsule()
                .fill(ModernDesignSystem.Colors.glassBackground)
                .overlay(
                    Capsule()
                        .stroke(ModernDesignSystem.Colors.glassBorder, lineWidth: 1)
                )
        )
        .onTapGesture(count: 2) {
            isLocked.toggle()
            HapticManager.shared.gridTypeChanged()
        }
    }
    
    private func formatEV(_ value: Float) -> String {
        if value == 0 {
            return "0"
        }
        return String(format: "%+.1f", value)
    }
}
