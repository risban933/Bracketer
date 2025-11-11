import SwiftUI
import Photos

enum GridType {
    case ruleOfThirds, goldenRatio, goldenSpiral, centerCrosshair
}

enum ShootingMode: String, CaseIterable {
    case auto = "Auto"
    case portrait = "Portrait"
    case macro = "Macro"
    case longExposure = "Long Exp"

    var icon: String {
        switch self {
        case .auto: return "camera"
        case .portrait: return "person"
        case .macro: return "magnifyingglass"
        case .longExposure: return "timer"
        }
    }

    var color: Color {
        switch self {
        case .auto: return .blue
        case .portrait: return .purple
        case .macro: return .green
        case .longExposure: return .orange
        }
    }
}

struct ContentView: View {
    @StateObject private var camera = CameraController()
    @StateObject private var motion = MotionLevelManager()
    @State private var showProControlPanel = false
    @State private var selectedEVStep: Float = 1.0
    @State private var showGrid = true
    @State private var gridType: GridType = .ruleOfThirds
    @State private var showLevel = true
    @State private var showHistogram = false
    @State private var focusPeakingEnabled = false
    @State private var focusPeakingColor = Color.red
    @State private var focusPeakingIntensity: Float = 0.5
    @State private var currentEVCompensation: Float = 0.0
    @State private var evCompensationLocked = false
    @State private var currentShootingMode: ShootingMode = .auto

    // Focus peaking color options
    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width

            ZStack {
                Color.black.ignoresSafeArea()

                ZStack {
                    PreviewContainer(
                        session: camera.session,
                        onLayerReady: camera.attachPreviewLayer,
                        orientation: camera.currentUIOrientation,
                        gridType: gridType,
                        showGrid: showGrid,
                        levelAngle: showLevel ? motion.levelAngleDegrees(for: camera.currentUIOrientation) : 0,
                        showHistogram: showHistogram,
                        focusPeakingEnabled: focusPeakingEnabled,
                        focusPeakingColor: focusPeakingColor,
                        focusPeakingIntensity: focusPeakingIntensity
                    )

                    // Pro Control Panel Overlay
                    if showProControlPanel {
                        ProControlPanel(
                            camera: camera,
                            showPanel: $showProControlPanel,
                            selectedEVStep: $selectedEVStep,
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            currentEVCompensation: $currentEVCompensation,
                            evCompensationLocked: $evCompensationLocked
                        )
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }

                if isPortrait {
                    PortraitLayout(
                        camera: camera,
                        showProControlPanel: $showProControlPanel,
                        selectedEVStep: $selectedEVStep,
                        showGrid: $showGrid,
                        showLevel: $showLevel,
                        showHistogram: $showHistogram,
                        focusPeakingEnabled: $focusPeakingEnabled,
                        currentShootingMode: $currentShootingMode,
                        onModeCycle: cycleShootingMode,
                        gridType: $gridType,
                        onGridCycle: onGridCycle,
                        currentEVCompensation: $currentEVCompensation,
                        evCompensationLocked: $evCompensationLocked
                    )
                } else {
                    LandscapeLayout(
                        camera: camera,
                        showProControlPanel: $showProControlPanel,
                        selectedEVStep: $selectedEVStep,
                        showGrid: $showGrid,
                        showLevel: $showLevel,
                        showHistogram: $showHistogram,
                        focusPeakingEnabled: $focusPeakingEnabled,
                        currentShootingMode: $currentShootingMode,
                        onModeCycle: cycleShootingMode,
                        gridType: $gridType,
                        onGridCycle: onGridCycle,
                        currentEVCompensation: $currentEVCompensation,
                        evCompensationLocked: $evCompensationLocked
                    )
                }

                if camera.isInitializing {
                    LoadingOverlay()
                }

                if camera.isCapturing {
                    CaptureProgressOverlay(progress: camera.captureProgress, evStep: selectedEVStep)
                }

                if camera.showImageViewer, !camera.lastBracketAssets.isEmpty {
                    ImageViewer(bracketAssets: camera.lastBracketAssets) {
                        camera.showImageViewer = false
                        camera.lastBracketAssets.removeAll()
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
        }
        .task {
            await camera.start()
            motion.start()
        }
        .onDisappear {
            motion.stop()
        }
        .alert(item: $camera.lastError) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    private func onGridCycle() {
        switch gridType {
        case .ruleOfThirds:
            gridType = .goldenRatio
        case .goldenRatio:
            gridType = .goldenSpiral
        case .goldenSpiral:
            gridType = .centerCrosshair
        case .centerCrosshair:
            gridType = .ruleOfThirds
        }
        HapticManager.shared.gridTypeChanged()
    }

    private func cycleShootingMode() {
        let allModes = ShootingMode.allCases
        let currentIndex = allModes.firstIndex(of: currentShootingMode) ?? 0
        let nextIndex = (currentIndex + 1) % allModes.count
        currentShootingMode = allModes[nextIndex]
        HapticManager.shared.gridTypeChanged()
    }
}

struct PortraitLayout: View {
    @ObservedObject var camera: CameraController
    @Binding var showProControlPanel: Bool
    @Binding var selectedEVStep: Float
    @Binding var showGrid: Bool
    @Binding var showLevel: Bool
    @Binding var showHistogram: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var currentShootingMode: ShootingMode
    let onModeCycle: () -> Void
    @Binding var gridType: GridType
    let onGridCycle: () -> Void
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool

    var body: some View {
        ZStack {
            // Minimalist top status bar
            VStack {
                HStack {
                    Spacer()
                    ExposureStatusView(iso: camera.currentISO, shutterSpeed: camera.currentShutterSpeedText)
                    Spacer()
                    BracketingIndicator(evStep: selectedEVStep)
                    Spacer()
                    ShootingModeIndicator(mode: currentShootingMode) {
                        onModeCycle()
                    }
                    Spacer()
                }
                .padding(.top, 60)
                Spacer()
            }

            // Left side controls
            VStack {
                Spacer()
                HStack {
                    VStack(spacing: 24) {
                        // Pro Control Panel button
                        Button {
                            HapticManager.shared.panelToggled()
                            withAnimation(DesignSystem.Animations.spring) {
                                showProControlPanel.toggle()
                            }
                        } label: {
                            CameraIcon.dial.image(isActive: showProControlPanel)
                                .frame(width: 28, height: 28)
                                .foregroundColor(showProControlPanel ? DesignSystem.Colors.accent : DesignSystem.Colors.primary)
                        }
                        .buttonStyle(PrimaryButtonStyle(isActive: showProControlPanel, size: .medium))

                        // Focus Peaking toggle
                        Button {
                            focusPeakingEnabled.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            CameraIcon.focus.image(isActive: focusPeakingEnabled)
                                .frame(width: 24, height: 24)
                                .foregroundColor(focusPeakingEnabled ? DesignSystem.Colors.accent : DesignSystem.Colors.primary)
                        }
                        .buttonStyle(PrimaryButtonStyle(isActive: focusPeakingEnabled, size: .medium))

                        // Histogram toggle
                        Button {
                            showHistogram.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            CameraIcon.histogram.image(isActive: showHistogram)
                                .frame(width: 24, height: 24)
                                .foregroundColor(showHistogram ? DesignSystem.Colors.accent : DesignSystem.Colors.primary)
                        }
                        .buttonStyle(PrimaryButtonStyle(isActive: showHistogram, size: .medium))
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                Spacer()
            }

            // Right side controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 24) {
                        // Grid overlay toggle
                        Button {
                            showGrid.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.grid.image(isActive: showGrid)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .onLongPressGesture {
                            onGridCycle()
                        }

                        // Level indicator toggle
                        Button {
                            showLevel.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.level.image(isActive: showLevel)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()
                VStack(spacing: 32) {
                    // Hybrid zoom control
                    HybridZoomControl(selectedZoom: $camera.selectedCamera) { kind in
                        camera.switchCamera(to: kind)
                    }

                    HStack(spacing: 60) {
                        // EV Compensation
                        EVControlView(
                            currentEV: $currentEVCompensation,
                            isLocked: $evCompensationLocked,
                            showFineControls: false,
                            onValueChanged: nil
                        )

                        // Shutter button
                        ShutterButton(isCapturing: camera.isCapturing, progress: camera.captureProgress) {
                            camera.lastBracketAssets.removeAll()
                            camera.showImageViewer = false
                            camera.captureLockdownBracket(evStep: selectedEVStep)
                        }

                        // RAW/ProRAW toggle
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(camera.isProRAWEnabled ? DesignSystem.Colors.accent.opacity(0.2) : DesignSystem.Colors.surfaceSecondary)
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Circle()
                                            .stroke(camera.isProRAWEnabled ? DesignSystem.Colors.accent : DesignSystem.Colors.tertiary, lineWidth: 2)
                                    )
                                VStack(spacing: 2) {
                                    CameraIcon.raw.image(isActive: camera.isProRAWEnabled)
                                        .frame(width: 18, height: 18)
                                    Text(camera.isProRAWEnabled ? "PRW" : "RAW")
                                        .font(DesignSystem.Typography.captionSemibold)
                                    Text(camera.isProRAWEnabled ? "48MP" : "12MP")
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundColor(camera.isProRAWEnabled ? DesignSystem.Colors.accent : DesignSystem.Colors.primary)
                            }
                        }
                        .onTapGesture {
                            HapticManager.shared.gridTypeChanged()
                            camera.toggleProRAW()
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

}

struct ExposureStatusView: View {
    let iso: Float
    let shutterSpeed: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("ISO \(Int(iso))")
                .font(DesignSystem.Typography.monospaceSmall)
                .foregroundColor(DesignSystem.Colors.primary)
            Text("•")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondary)
            Text(shutterSpeed)
                .font(DesignSystem.Typography.monospaceSmall)
                .foregroundColor(DesignSystem.Colors.primary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Colors.tertiary, lineWidth: 1)
                )
        )
        .applyShadow(DesignSystem.Shadows.small)
    }
}

struct EVControlView: View {
    @Binding var currentEV: Float
    @Binding var isLocked: Bool
    let showFineControls: Bool
    let onValueChanged: ((Float) -> Void)?

    private let evRange: ClosedRange<Float> = -4.0...4.0
    private let evStep: Float = 0.1

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(isLocked ? DesignSystem.Colors.error : DesignSystem.Colors.accentTertiary)
                    .font(DesignSystem.Typography.captionMedium)
                Text("EV Compensation")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
                Spacer()
                Text(formatEV(currentEV))
                    .font(DesignSystem.Typography.monospace)
                    .foregroundColor(DesignSystem.Colors.accentTertiary)
            }

            if showFineControls {
                // Fine control slider
                Slider(value: $currentEV, in: evRange, step: evStep) { editing in
                    if !editing && !isLocked {
                        onValueChanged?(currentEV)
                        HapticManager.shared.exposureAdjusted()
                    }
                }
                .accentColor(DesignSystem.Colors.accentTertiary)
                .disabled(isLocked)

                // Quick preset buttons
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach([-2, -1, 0, 1, 2], id: \.self) { value in
                        Button {
                            if !isLocked {
                                currentEV = Float(value)
                                onValueChanged?(currentEV)
                                HapticManager.shared.exposureAdjusted()
                            }
                        } label: {
                            Text(value == 0 ? "0" : "\(value > 0 ? "+" : "")\(value)")
                                .font(DesignSystem.Typography.captionSemibold)
                                .foregroundColor(currentEV == Float(value) ? DesignSystem.Colors.background : DesignSystem.Colors.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(currentEV == Float(value) ? DesignSystem.Colors.accentTertiary : DesignSystem.Colors.surfaceTertiary)
                                )
                        }
                        .disabled(isLocked)
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Compact display for main interface
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.tertiary, lineWidth: 1)
                        )

                    VStack(spacing: 2) {
                        Text(formatEV(currentEV))
                            .font(DesignSystem.Typography.monospace)
                        Text("EV")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)

                    // Lock indicator
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.error)
                            .offset(y: -20)
                    }
                }
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            isLocked.toggle()
                            HapticManager.shared.gridTypeChanged()
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if !isLocked {
                                let delta = Float(value.translation.width / 100)
                                currentEV = min(max(currentEV + delta, evRange.lowerBound), evRange.upperBound)
                                onValueChanged?(currentEV)
                            }
                        }
                        .onEnded { _ in
                            if !isLocked {
                                HapticManager.shared.exposureAdjusted()
                            }
                        }
                )
            }
        }
    }

    private func formatEV(_ value: Float) -> String {
        if value == 0 {
            return "0.0"
        }
        return String(format: "%+.1f", value)
    }
}

struct BracketingIndicator: View {
    let evStep: Float
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "rectangle.stack")
                .font(DesignSystem.Typography.captionMedium)
            Text("±\(Int(evStep))")
                .font(DesignSystem.Typography.monospaceSmall)
        }
        .foregroundColor(DesignSystem.Colors.primary)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.warning.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(DesignSystem.Colors.warning.opacity(0.4), lineWidth: 1.5)
                )
        )
        .applyShadow(DesignSystem.Shadows.small)
    }
}

struct BracketingSequenceView: View {
    let evStep: Float
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Underexposed shot
            VStack(spacing: 2) {
                Text("-\(Int(evStep))")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("EV")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondary)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignSystem.Colors.surfaceTertiary)
            )
            
            // Baseline shot
            VStack(spacing: 2) {
                Text("0")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.background)
                Text("EV")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.background)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignSystem.Colors.warning)
            )
            
            // Overexposed shot
            VStack(spacing: 2) {
                Text("+\(Int(evStep))")
                    .font(DesignSystem.Typography.captionSemibold)
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("EV")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondary)
            }
            .frame(width: 40, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignSystem.Colors.surfaceTertiary)
            )
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

struct ShootingModeIndicator: View {
    let mode: ShootingMode
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(DesignSystem.Typography.captionMedium)
                Text(mode.rawValue)
                    .font(DesignSystem.Typography.captionMedium)
            }
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(mode.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(mode.color.opacity(0.4), lineWidth: 1.5)
                    )
            )
            .applyShadow(DesignSystem.Shadows.small)
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(DesignSystem.Animations.quick, value: mode)
    }
}

struct ProControlPanel: View {
    let camera: CameraController
    @Binding var showPanel: Bool
    @Binding var selectedEVStep: Float
    @State private var manualISO: Float = 100
    @State private var manualShutterSpeed: Float = 0.01 // 1/100s
    @State private var whiteBalance: Float = 5500 // Kelvin
    @State private var manualFocus: Float = 0.5
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool

    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]

    var body: some View {
        ZStack {
            DesignSystem.Colors.overlay
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(DesignSystem.Animations.spring) {
                        showPanel = false
                    }
                }

            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                HStack {
                    Text("Pro Controls")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.primary)
                    Spacer()
                    Button {
                        withAnimation(DesignSystem.Animations.spring) {
                            showPanel = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.secondary)
                    }
                }
                .padding(.horizontal, 24)

                // Control Grid
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // ISO Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            CameraIcon.exposure.image(isActive: false)
                                .frame(width: 16, height: 16)
                                .foregroundColor(DesignSystem.Colors.accent)
                            Text("ISO")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Text("\(Int(manualISO))")
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                        Slider(value: $manualISO, in: 25...25600, step: 25)
                            .accentColor(DesignSystem.Colors.accent)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)

                    // Shutter Speed Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(DesignSystem.Colors.accentSecondary)
                            Text("Shutter")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Text(formatShutterSpeed(manualShutterSpeed))
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(DesignSystem.Colors.accentSecondary)
                        }
                        Slider(value: $manualShutterSpeed, in: 0.0005...30, step: 0.001)
                            .accentColor(DesignSystem.Colors.accentSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)

                    // White Balance Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "thermometer")
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("White Balance")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Text("\(Int(whiteBalance))K")
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                        Slider(value: $whiteBalance, in: 2500...10000, step: 100)
                            .accentColor(DesignSystem.Colors.warning)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)

                    // Manual Focus Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "scope")
                                .foregroundColor(DesignSystem.Colors.success)
                            Text("Focus")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Text("\(Int(manualFocus * 100))%")
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                        Slider(value: $manualFocus, in: 0...1, step: 0.01)
                            .accentColor(DesignSystem.Colors.success)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)

                    // EV Compensation Control
                    EVControlView(
                        currentEV: $currentEVCompensation,
                        isLocked: $evCompensationLocked,
                        showFineControls: true,
                        onValueChanged: nil
                    )

                    // EV Bracket Step Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "rectangle.stack")
                                .foregroundColor(DesignSystem.Colors.warning)
                            Text("Bracket EV Steps")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Text("±\(Int(selectedEVStep))")
                                .font(DesignSystem.Typography.monospace)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                        
                        // Bracketing sequence visualization
                        BracketingSequenceView(evStep: selectedEVStep)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ForEach([1, 2, 3], id: \.self) { value in
                                Button {
                                    selectedEVStep = Float(value)
                                } label: {
                                    Text("±\(value)")
                                        .font(DesignSystem.Typography.bodySemibold)
                                        .foregroundColor(selectedEVStep == Float(value) ? DesignSystem.Colors.warning : DesignSystem.Colors.primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(selectedEVStep == Float(value) ? DesignSystem.Colors.warning : DesignSystem.Colors.surfaceTertiary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)

                    // Focus Peaking Control
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(DesignSystem.Colors.success)
                            Text("Focus Peaking")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                            Toggle("", isOn: $focusPeakingEnabled)
                                .labelsHidden()
                                .tint(DesignSystem.Colors.success)
                        }

                        if focusPeakingEnabled {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                // Color selection
                                HStack {
                                    Text("Color")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondary)
                                    Spacer()
                                }

                                HStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(focusPeakingColors, id: \.self) { color in
                                        Button {
                                            focusPeakingColor = color
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(color.opacity(0.3))
                                                    .frame(width: 32, height: 32)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(color, lineWidth: focusPeakingColor == color ? 2 : 1)
                                                            .frame(width: 32, height: 32)
                                                    )
                                                if focusPeakingColor == color {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(DesignSystem.Colors.primary)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                // Intensity control
                                VStack(spacing: DesignSystem.Spacing.xs) {
                                    HStack {
                                        Text("Intensity")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondary)
                                        Spacer()
                                        Text("\(Int(focusPeakingIntensity * 100))%")
                                            .font(DesignSystem.Typography.monospaceSmall)
                                            .foregroundColor(DesignSystem.Colors.success)
                                    }
                                    Slider(value: $focusPeakingIntensity, in: 0.1...1.0, step: 0.1)
                                        .accentColor(DesignSystem.Colors.success)
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .cardStyle(.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .padding(.vertical, DesignSystem.Spacing.xl)
            .frame(maxWidth: 320)
            .cardStyle(.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
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

struct LandscapeLayout: View {
    @ObservedObject var camera: CameraController
    @Binding var showProControlPanel: Bool
    @Binding var selectedEVStep: Float
    @Binding var showGrid: Bool
    @Binding var showLevel: Bool
    @Binding var showHistogram: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var currentShootingMode: ShootingMode
    let onModeCycle: () -> Void
    @Binding var gridType: GridType
    let onGridCycle: () -> Void
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool

    var body: some View {
        ZStack {
            // Top status bar
            VStack {
                HStack {
                    Spacer()
                    ExposureStatusView(iso: camera.currentISO, shutterSpeed: camera.currentShutterSpeedText)
                    Spacer()
                    ShootingModeIndicator(mode: currentShootingMode, onTap: onModeCycle)
                    Spacer()
                }
                .padding(.top, 20)
                Spacer()
            }

            // Left side controls
            VStack {
                Spacer()
                HStack {
                    VStack(spacing: 24) {
                        // Pro Control Panel button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showProControlPanel.toggle()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "dial.min")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        // Focus Peaking toggle
                        Button {
                            focusPeakingEnabled.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.focus.image(isActive: focusPeakingEnabled)
                                    .frame(width: 24, height: 24)
                            }
                        }

                        // Histogram toggle
                        Button {
                            showHistogram.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.histogram.image(isActive: showHistogram)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
                Spacer()
            }

            // Right side controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 24) {
                        // Grid overlay toggle
                        Button {
                            showGrid.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.grid.image(isActive: showGrid)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .onLongPressGesture {
                            onGridCycle()
                        }

                        // Level indicator toggle
                        Button {
                            showLevel.toggle()
                            HapticManager.shared.gridTypeChanged()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 56, height: 56)
                                CameraIcon.level.image(isActive: showLevel)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }

            // Center controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 32) {
                        // Hybrid zoom control (landscape)
                        HybridZoomControl(selectedZoom: $camera.selectedCamera) { kind in
                            camera.switchCamera(to: kind)
                        }

                        HStack(spacing: 60) {
                            // EV Compensation
                            EVControlView(
                                currentEV: $currentEVCompensation,
                                isLocked: $evCompensationLocked,
                                showFineControls: false,
                                onValueChanged: nil
                            )

                            // Shutter button
                            ShutterButton(isCapturing: camera.isCapturing, progress: camera.captureProgress) {
                                camera.lastBracketAssets.removeAll()
                                camera.showImageViewer = false
                                camera.captureLockdownBracket(evStep: selectedEVStep)
                            }

                            // RAW/ProRAW toggle
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 64, height: 64)
                                    VStack(spacing: 2) {
                                        Image(systemName: camera.isProRAWEnabled ? "r.square.fill" : "r.square")
                                            .font(.system(size: 20))
                                        Text(camera.isProRAWEnabled ? "PRW" : "RAW")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(camera.isProRAWEnabled ? .yellow : .white)
                                }
                            }
                            .onTapGesture {
                                camera.toggleProRAW()
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct SettingsPanel: View {
    let camera: CameraController
    @Binding var showSettings: Bool
    @Binding var selectedEVStep: Float
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bracket Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings.toggle()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("EV Step")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    ForEach([1, 2, 3], id: \.self) { value in
                        Button {
                            selectedEVStep = Float(value)
                        } label: {
                            Text("±\(value)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedEVStep == Float(value) ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedEVStep == Float(value) ? Color.white : Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Capture Format")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                VStack(spacing: 8) {
                    // ProRAW Option
                    Button {
                        if !camera.isProRAWEnabled {
                            camera.toggleProRAW()
                        }
                    } label: {
                        HStack {
                            CameraIcon.raw.image(isActive: camera.isProRAWEnabled)
                                .frame(width: 20, height: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ProRAW")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("48MP • Apple ProRAW")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            if camera.isProRAWEnabled {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .padding(8)
                        .background(camera.isProRAWEnabled ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Standard RAW Option
                    Button {
                        if camera.isProRAWEnabled {
                            camera.toggleProRAW()
                        }
                    } label: {
                        HStack {
                            CameraIcon.raw.image(isActive: !camera.isProRAWEnabled)
                                .frame(width: 20, height: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RAW")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("12MP • Bayer RAW")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            if !camera.isProRAWEnabled {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .padding(8)
                        .background(!camera.isProRAWEnabled ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

struct ShutterButton: View {
    let isCapturing: Bool
    let progress: Int
    let action: () -> Void
    
    var body: some View {
        Button {
            HapticManager.shared.shutterPressed()
            action()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(DesignSystem.Colors.primary, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .opacity(0.8)
                
                // Inner button
                Circle()
                    .fill(isCapturing ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isCapturing ? 0.9 : 1.0)
                    .animation(DesignSystem.Animations.spring, value: isCapturing)
                
                // Progress ring
                if isCapturing {
                    ProgressRing(
                        progress: CGFloat(progress) / 4.0,
                        lineWidth: 4,
                        color: DesignSystem.Colors.accent
                    )
                    .frame(width: 88, height: 88)
                }
                
                // Center dot for non-capturing state
                if !isCapturing {
                    Circle()
                        .fill(DesignSystem.Colors.background)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .disabled(isCapturing)
        .scaleEffect(isCapturing ? 0.95 : 1.0)
        .animation(DesignSystem.Animations.spring, value: isCapturing)
    }
}

struct ZoomSelector: View {
    let selected: CameraKind
    var isVertical: Bool = false
    let onSelect: (CameraKind) -> Void
    
    private let lenses: [CameraKind] = [.ultraWide, .wide, .twoX, .telephoto, .eightX]
    
    var body: some View {
        Group {
            if isVertical {
                VStack(spacing: 8) {
                    ForEach(lenses, id: \.self) { lens in
                        ZoomButton(lens: lens, isSelected: selected == lens, onSelect: onSelect)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)
            } else {
                HStack(spacing: 20) {
                    ForEach(lenses, id: \.self) { lens in
                        ZoomButton(lens: lens, isSelected: selected == lens, onSelect: onSelect)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.4))
                .cornerRadius(20)
            }
        }
    }
}

struct ZoomButton: View {
    let lens: CameraKind
    let isSelected: Bool
    let onSelect: (CameraKind) -> Void
    
    var body: some View {
        Button {
            onSelect(lens)
        } label: {
            Text(lens.label)
                .font(.system(size: isSelected ? 18 : 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .yellow : .white)
                .frame(width: 44, height: 44)
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.overlay.ignoresSafeArea()
            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.accent))
                Text("Initializing Camera")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.xl)
            .cardStyle(.primary)
        }
    }
}

struct CaptureProgressOverlay: View {
    let progress: Int
    let evStep: Float
    
    private var progressText: String {
        switch progress {
        case 0: return "Preparing bracket..."
        case 1: return "Baseline (0 EV)"
        case 2: return "Overexposed (+\(Int(evStep)) EV)"
        case 3: return "Underexposed (-\(Int(evStep)) EV)"
        case 4: return "Processing..."
        default: return "Processing..."
        }
    }
    
    private var progressSubtext: String {
        switch progress {
        case 0: return "Setting up exposure bracketing"
        case 1: return "Auto exposure reference"
        case 2: return "Longer shutter speed"
        case 3: return "Shorter shutter speed"
        case 4: return "Saving bracketed sequence"
        default: return "Finalizing capture"
        }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.overlayLight.ignoresSafeArea()
            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView(value: Double(progress), total: 4.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.accent))
                    .frame(width: 200)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(progressText)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(progressSubtext)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondary)
                }
                
                Text("Keep device steady")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiary)
            }
            .padding(DesignSystem.Spacing.lg)
            .cardStyle(.primary)
        }
    }
}

#Preview {
    ContentView()
}
