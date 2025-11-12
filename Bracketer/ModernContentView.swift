import SwiftUI
import Photos

// MARK: - Modern iOS Camera Interface
/// Apple Camera app inspired interface with Halide professional features
/// Implements iOS 18+ design patterns and modern camera controls

struct ModernContentView: View {
    @StateObject private var camera = CameraController()
    @EnvironmentObject var orientationManager: OrientationManager

    // UI State
    @State private var showProControls = false
    @State private var showSettings = false
    @State private var showGrid = true
    @State private var showLevel = true
    @State private var focusPeakingEnabled = false
    @State private var focusPeakingColor = Color.red
    @State private var focusPeakingIntensity: Float = 0.5
    @State private var isCompatibleDevice = true
    
    // Bracketing
    @State private var selectedEVStep: Float = 1.0
    @State private var currentEVCompensation: Float = 0.0
    @State private var evCompensationLocked = false
    @State private var bracketShotCount: Int = 3
    
    // Shooting modes
    @State private var currentShootingMode: ShootingMode = .auto
    @State private var gridType: GridType = .ruleOfThirds

    // Camera controls (iOS 26+)
    @State private var selectedZoom: CameraZoomLevel = .wide
    @State private var flashMode: FlashMode = .off
    @State private var timerMode: TimerMode = .off

    // Focus peaking colors
    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !isCompatibleDevice {
                    Color.black.opacity(0.9).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 28, weight: .bold)).foregroundColor(.yellow)
                        Text("Incompatible Device")
                            .font(ModernDesignSystem.Typography.title2)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                        Text("This app requires iOS 26 or later.")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    }
                    .padding(ModernDesignSystem.Spacing.xl)
                    .modernCardStyle(.overlay)
                }
                
                // Camera preview with overlays
                ModernCameraPreview(
                    camera: camera,
                    showGrid: showGrid,
                    gridType: gridType,
                    showLevel: showLevel,
                    focusPeakingEnabled: focusPeakingEnabled,
                    focusPeakingColor: focusPeakingColor,
                    focusPeakingIntensity: focusPeakingIntensity
                )
                
                // Top status bar (Apple Camera style) - pinned to top edge
                VStack {
                    if #available(iOS 26.0, *) {
                        ModernTopBarEnhanced(
                            camera: camera,
                            currentShootingMode: currentShootingMode,
                            selectedEVStep: selectedEVStep,
                            flashMode: $flashMode,
                            timerMode: $timerMode,
                            isGridActive: showGrid,
                            isLevelActive: showLevel,
                            onModeChange: cycleShootingMode,
                            onGridToggle: toggleGrid,
                            onLevelToggle: toggleLevel
                        )
                        .alwaysUpright(orientationManager)
                    } else {
                        ModernTopBar(
                            camera: camera,
                            currentShootingMode: currentShootingMode,
                            selectedEVStep: selectedEVStep,
                            isGridActive: showGrid,
                            isLevelActive: showLevel,
                            onModeChange: cycleShootingMode,
                            onGridToggle: toggleGrid,
                            onLevelToggle: toggleLevel
                        )
                        .alwaysUpright(orientationManager)
                    }
                    Spacer()
                }

                // Bottom controls (Apple Camera style) - buttons rotate with device
                VStack {
                    Spacer()

                    if #available(iOS 26.0, *) {
                        ModernBottomControlsEnhanced(
                            camera: camera,
                            showProControls: $showProControls,
                            showSettings: $showSettings,
                            selectedEVStep: $selectedEVStep,
                            currentEVCompensation: $currentEVCompensation,
                            evCompensationLocked: $evCompensationLocked,
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            bracketShotCount: $bracketShotCount,
                            selectedZoom: $selectedZoom,
                            flashMode: $flashMode,
                            timerMode: $timerMode,
                            isGridActive: showGrid,
                            isLevelActive: showLevel,
                            onGridToggle: toggleGrid,
                            onLevelToggle: toggleLevel
                        )
                    } else {
                        ModernBottomControls(
                            camera: camera,
                            showProControls: $showProControls,
                            showSettings: $showSettings,
                            selectedEVStep: $selectedEVStep,
                            currentEVCompensation: $currentEVCompensation,
                            evCompensationLocked: $evCompensationLocked,
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            bracketShotCount: $bracketShotCount,
                            flashMode: $flashMode,
                            timerMode: $timerMode,
                            isGridActive: showGrid,
                            isLevelActive: showLevel,
                            onGridToggle: toggleGrid,
                            onLevelToggle: toggleLevel
                        )
                    }
                }
                .alwaysUpright(orientationManager)
                
                // Pro Controls Overlay - rotates with device
                if showProControls {
                    if #available(iOS 26.0, *) {
                        ModernProControls(
                            camera: camera,
                            showProControls: $showProControls,
                            selectedEVStep: $selectedEVStep,
                            currentEVCompensation: $currentEVCompensation,
                            evCompensationLocked: $evCompensationLocked,
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            bracketShotCount: $bracketShotCount
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .alwaysUpright(orientationManager)
                    }
                }

                // Settings Overlay - slides up from bottom (iOS style bottom sheet)
                if showSettings {
                    ModernSettingsPanel(
                        camera: camera,
                        showSettings: $showSettings,
                        showGrid: $showGrid,
                        gridType: $gridType,
                        showLevel: $showLevel,
                        focusPeakingEnabled: $focusPeakingEnabled,
                        focusPeakingColor: $focusPeakingColor,
                        focusPeakingIntensity: $focusPeakingIntensity
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .alwaysUpright(orientationManager)
                }
                
                // Loading and progress overlays
                if camera.isInitializing {
                    ModernLoadingOverlay()
                }
                
                if camera.isCapturing {
                    ModernCaptureProgress(
                        progress: camera.captureProgress,
                        evStep: selectedEVStep
                    )
                }
            }
        }
        .ignoresSafeArea()
        .task {
            if isCompatibleDevice {
                await camera.start()
            }
        }
        .onAppear {
            isCompatibleDevice = ModernDeviceGate.isSupported
        }
        .alert(item: $camera.lastError) { error in
            Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Control Functions
    private func cycleShootingMode() {
        let allModes = ShootingMode.allCases
        let currentIndex = allModes.firstIndex(of: currentShootingMode) ?? 0
        let nextIndex = (currentIndex + 1) % allModes.count
        currentShootingMode = allModes[nextIndex]
        HapticManager.shared.gridTypeChanged()
    }
    
    private func toggleGrid() {
        showGrid.toggle()
        HapticManager.shared.gridTypeChanged()
    }
    
    private func toggleLevel() {
        showLevel.toggle()
        HapticManager.shared.gridTypeChanged()
    }
}

// MARK: - Modern Camera Preview
struct ModernCameraPreview: View {
    let camera: CameraController
    let showGrid: Bool
    let gridType: GridType
    let showLevel: Bool
    let focusPeakingEnabled: Bool
    let focusPeakingColor: Color
    let focusPeakingIntensity: Float

    var body: some View {
        ZStack {
            // Camera preview layer
            PreviewContainer(
                session: camera.session,
                onLayerReady: { _ in
                    // Preview ready callback
                },
                orientation: camera.currentUIOrientation,
                gridType: gridType,
                showGrid: showGrid,
                levelAngle: showLevel ? 0 : 0,
                showHistogram: false,
                focusPeakingEnabled: focusPeakingEnabled,
                focusPeakingColor: focusPeakingColor,
                focusPeakingIntensity: focusPeakingIntensity
            )
        }
    }
}

// MARK: - Modern Top Bar (Apple Camera Style - Status Only)
struct ModernTopBar: View {
    let camera: CameraController
    let currentShootingMode: ShootingMode
    let selectedEVStep: Float
    let isGridActive: Bool
    let isLevelActive: Bool
    let onModeChange: () -> Void
    let onGridToggle: () -> Void
    let onLevelToggle: () -> Void

    var body: some View {
        HStack {
            // Left side - Status indicators only
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                if camera.isProRAWEnabled {
                    Text("ProRAW")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .opacity(0.8)
                        )
                }
            }

            Spacer()

            // Center - Mode indicator and bracketing (tappable for mode change)
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                ModernShootingModeIndicator(mode: currentShootingMode, onTap: onModeChange)
                ModernBracketingIndicator(evStep: selectedEVStep)
            }

            Spacer()

            // Right side - Keep minimal for balance
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                // Reserved for status indicators (battery, storage warnings, etc.)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial.opacity(0.95))
    }
}

// MARK: - Modern Bottom Controls (Apple Camera Style)
struct ModernBottomControls: View {
    let camera: CameraController
    @Binding var showProControls: Bool
    @Binding var showSettings: Bool
    @Binding var selectedEVStep: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    @Binding var bracketShotCount: Int
    @Binding var flashMode: FlashMode
    @Binding var timerMode: TimerMode
    @Binding var isGridActive: Bool
    @Binding var isLevelActive: Bool
    let onGridToggle: () -> Void
    let onLevelToggle: () -> Void

    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.md) {
            // Secondary controls row (moved from top bar)
            HStack(spacing: 16) {
                ModernFlashButton(flashMode: $flashMode)
                ModernTimerButton(timerMode: $timerMode)
                ModernToggleButton(
                    icon: "square.grid.3x3",
                    isActive: isGridActive,
                    onTap: onGridToggle
                )
                ModernToggleButton(
                    icon: "level",
                    isActive: isLevelActive,
                    onTap: onLevelToggle
                )
                ModernProControlButton(showProControls: $showProControls)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)

            // Main control row
            HStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Photo library
                ModernPhotoLibraryButton()

                // Shutter button (larger for better prominence)
                ModernShutterButton(
                    isCapturing: camera.isCapturing,
                    progress: camera.captureProgress
                ) {
                    camera.captureLockdownBracket(evStep: selectedEVStep, shotCount: bracketShotCount)
                }

                // Settings
                ModernSettingsButton(showSettings: $showSettings)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.bottom, ModernDesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Modern Components

struct ModernFlashButton: View {
    @Binding var flashMode: FlashMode

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                flashMode = flashMode.next()
            }
            HapticManager.shared.exposureAdjusted()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(flashMode != .off ? .yellow.opacity(0.6) : .white.opacity(0.2), lineWidth: flashMode != .off ? 2 : 1)
                    )

                Image(systemName: flashMode.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(flashMode != .off ? .yellow : .white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ModernTimerButton: View {
    @Binding var timerMode: TimerMode

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                timerMode = timerMode.next()
            }
            HapticManager.shared.exposureAdjusted()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(timerMode != .off ? .orange.opacity(0.6) : .white.opacity(0.2), lineWidth: timerMode != .off ? 2 : 1)
                    )

                if timerMode == .off {
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Text("\(timerMode.seconds)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ModernShootingModeIndicator: View {
    let mode: ShootingMode
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ModernDesignSystem.Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(ModernDesignSystem.Typography.caption)
                Text(mode.rawValue)
                    .font(ModernDesignSystem.Typography.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .overlay(
                        Capsule()
                            .stroke(mode.color.opacity(0.6), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernBracketingIndicator: View {
    let evStep: Float

    var body: some View {
        HStack(spacing: ModernDesignSystem.Spacing.xs) {
            Image(systemName: "rectangle.stack")
                .font(ModernDesignSystem.Typography.caption)
            Text("±\(Int(evStep))")
                .font(ModernDesignSystem.Typography.monospaceSmall)
        }
        .foregroundColor(.white)
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
                .overlay(
                    Capsule()
                        .stroke(.yellow.opacity(0.6), lineWidth: 2)
                )
        )
    }
}

struct ModernToggleButton: View {
    let icon: String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isActive ? .yellow.opacity(0.6) : .white.opacity(0.2), lineWidth: isActive ? 2 : 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isActive ? .yellow : .white)
            }
        }
        .buttonStyle(.plain)
    }
}


struct ModernProControlButton: View {
    @Binding var showProControls: Bool

    var body: some View {
        Button {
            withAnimation(ModernDesignSystem.Animations.spring) {
                showProControls.toggle()
            }
            HapticManager.shared.panelToggled()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(showProControls ? .purple.opacity(0.6) : .white.opacity(0.2), lineWidth: showProControls ? 2 : 1)
                    )

                Image(systemName: "dial.min")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(showProControls ? .purple : .white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ModernPhotoLibraryButton: View {
    var body: some View {
        Button {
            // Photo library
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ModernShutterButton: View {
    let isCapturing: Bool
    let progress: Int
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.shutterPressed()
            action()
        } label: {
            ZStack {
                // Outer ring with glass effect (increased size)
                Circle()
                    .stroke(.white, lineWidth: 5)
                    .frame(width: 88, height: 88)

                // Inner button with liquid glass (increased size)
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.9)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .fill(isCapturing ? .red.opacity(0.3) : .white.opacity(0.2))
                    )
                    .scaleEffect(isCapturing ? 0.9 : 1.0)
                    .animation(ModernDesignSystem.Animations.spring, value: isCapturing)

                // Progress ring (increased size)
                if isCapturing {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress) / 4.0)
                        .stroke(
                            AngularGradient(
                                colors: [.yellow, .orange, .yellow],
                                center: .center
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .disabled(isCapturing)
        .scaleEffect(isCapturing ? 0.95 : 1.0)
        .animation(ModernDesignSystem.Animations.spring, value: isCapturing)
    }
}

struct ModernSettingsButton: View {
    @Binding var showSettings: Bool

    var body: some View {
        Button {
            withAnimation(ModernDesignSystem.Animations.spring) {
                showSettings.toggle()
            }
            HapticManager.shared.panelToggled()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(showSettings ? .blue.opacity(0.6) : .white.opacity(0.2), lineWidth: showSettings ? 2 : 1)
                    )

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(showSettings ? .blue : .white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Loading Overlay
struct ModernLoadingOverlay: View {
    var body: some View {
        ZStack {
            ModernDesignSystem.Colors.cameraOverlay.ignoresSafeArea()
            
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: ModernDesignSystem.Colors.cameraControlActive))
                
                Text("Initializing Camera")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
            }
            .padding(ModernDesignSystem.Spacing.xl)
            .modernCardStyle(.overlay)
        }
    }
}

// MARK: - Modern Capture Progress
struct ModernCaptureProgress: View {
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
            ModernDesignSystem.Colors.cameraOverlay.ignoresSafeArea()
            
            VStack(spacing: ModernDesignSystem.Spacing.lg) {
                ProgressView(value: Double(progress), total: 4.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: ModernDesignSystem.Colors.cameraControlActive))
                    .frame(width: 200)
                
                VStack(spacing: ModernDesignSystem.Spacing.xs) {
                    Text(progressText)
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    Text(progressSubtext)
                        .font(ModernDesignSystem.Typography.caption)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                }
                
                Text("Keep device steady")
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
            }
            .padding(ModernDesignSystem.Spacing.xl)
            .modernCardStyle(.overlay)
        }
    }
}

private enum ModernDeviceGate {
    static var isSupported: Bool {
        // Require iOS 26.0 or later
        guard #available(iOS 26.0, *) else { return false }

        // Accept all devices that support iOS 26 (simulators and physical devices)
        let id = ModernDeviceGate.hardwareIdentifier()
        // Allow simulators for testing
        return id == "x86_64" || id == "arm64" || id.hasPrefix("iPhone")
    }

    private static func hardwareIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineMirror = Mirror(reflecting: sysinfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - Enhanced Top Bar with iOS 26 Components

@available(iOS 26.0, *)
struct ModernTopBarEnhanced: View {
    let camera: CameraController
    let currentShootingMode: ShootingMode
    let selectedEVStep: Float
    @Binding var flashMode: FlashMode
    @Binding var timerMode: TimerMode
    let isGridActive: Bool
    let isLevelActive: Bool
    let onModeChange: () -> Void
    let onGridToggle: () -> Void
    let onLevelToggle: () -> Void

    var body: some View {
        HStack {
            // Left side - Status indicators only
            HStack(spacing: 8) {
                if camera.isProRAWEnabled {
                    Text("ProRAW")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .liquidGlass(intensity: .subtle, tint: .yellow.opacity(0.2))
                        )
                }
            }

            Spacer()

            // Center - Mode indicator and bracketing (tappable for mode change)
            HStack(spacing: 8) {
                ModernShootingModeIndicator(mode: currentShootingMode, onTap: onModeChange)
                ModernBracketingIndicator(evStep: selectedEVStep)
            }

            Spacer()

            // Right side - Keep minimal for balance
            HStack(spacing: 8) {
                // Reserved for status indicators (battery, storage warnings, etc.)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial.opacity(0.95))
    }
}

// MARK: - Enhanced Bottom Controls with iOS 26 Components

@available(iOS 26.0, *)
struct ModernBottomControlsEnhanced: View {
    let camera: CameraController
    @Binding var showProControls: Bool
    @Binding var showSettings: Bool
    @Binding var selectedEVStep: Float
    @Binding var currentEVCompensation: Float
    @Binding var evCompensationLocked: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    @Binding var bracketShotCount: Int
    @Binding var selectedZoom: CameraZoomLevel
    @Binding var flashMode: FlashMode
    @Binding var timerMode: TimerMode
    @Binding var isGridActive: Bool
    @Binding var isLevelActive: Bool
    let onGridToggle: () -> Void
    let onLevelToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Secondary controls row (moved from top bar) - all in thumb reach
            HStack(spacing: 16) {
                FlashModeControl(flashMode: $flashMode)
                TimerModeControl(timerMode: $timerMode)
                ModernToggleButton(
                    icon: "square.grid.3x3",
                    isActive: isGridActive,
                    onTap: onGridToggle
                )
                ModernToggleButton(
                    icon: "level",
                    isActive: isLevelActive,
                    onTap: onLevelToggle
                )
                ModernProControlButton(showProControls: $showProControls)
            }
            .padding(.horizontal, 20)

            // Main control row with enhanced shutter button
            HStack(spacing: 40) {
                // Photo library
                ModernPhotoLibraryButton()

                // Enhanced shutter button (larger size)
                EnhancedShutterButton(
                    isCapturing: camera.isCapturing,
                    progress: Double(camera.captureProgress) / Double(max(1, bracketShotCount))
                ) {
                    camera.captureLockdownBracket(evStep: selectedEVStep, shotCount: bracketShotCount)
                }

                // Settings
                ModernSettingsButton(showSettings: $showSettings)
            }
            .padding(.horizontal, 20)

            // Zoom selector at very bottom
            CameraZoomControl(
                selectedZoom: $selectedZoom,
                availableZoomLevels: CameraZoomLevel.iPhone17ProMaxLevels
            )
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    ModernContentView()
        .environmentObject(OrientationManager())
}
