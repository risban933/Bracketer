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
    @State private var showHistogram = false
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
                        Text("This app requires iPhone 17 Pro Max on iOS 26 or later.")
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
                    showHistogram: showHistogram,
                    focusPeakingEnabled: focusPeakingEnabled,
                    focusPeakingColor: focusPeakingColor,
                    focusPeakingIntensity: focusPeakingIntensity
                )
                
                // Top status bar (Apple Camera style) - buttons rotate with device
                ModernTopBar(
                    camera: camera,
                    currentShootingMode: currentShootingMode,
                    selectedEVStep: selectedEVStep,
                    isGridActive: showGrid,
                    isLevelActive: showLevel,
                    isHistogramActive: showHistogram,
                    onModeChange: cycleShootingMode,
                    onGridToggle: toggleGrid,
                    onLevelToggle: toggleLevel,
                    onHistogramToggle: toggleHistogram
                )
                .alwaysUpright(orientationManager)

                // Bottom controls (Apple Camera style) - buttons rotate with device
                VStack {
                    Spacer()

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
                        bracketShotCount: $bracketShotCount
                    )
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

                // Settings Overlay - rotates with device
                if showSettings {
                    ModernSettingsPanel(
                        camera: camera,
                        showSettings: $showSettings,
                        showGrid: $showGrid,
                        gridType: $gridType,
                        showLevel: $showLevel,
                        showHistogram: $showHistogram,
                        focusPeakingEnabled: $focusPeakingEnabled,
                        focusPeakingColor: $focusPeakingColor,
                        focusPeakingIntensity: $focusPeakingIntensity
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
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
    
    private func toggleHistogram() {
        showHistogram.toggle()
        HapticManager.shared.gridTypeChanged()
    }
}

// MARK: - Modern Camera Preview
struct ModernCameraPreview: View {
    let camera: CameraController
    let showGrid: Bool
    let gridType: GridType
    let showLevel: Bool
    let showHistogram: Bool
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
                showHistogram: showHistogram,
                focusPeakingEnabled: focusPeakingEnabled,
                focusPeakingColor: focusPeakingColor,
                focusPeakingIntensity: focusPeakingIntensity
            )
        }
    }
}

// MARK: - Modern Top Bar (Apple Camera Style)
struct ModernTopBar: View {
    let camera: CameraController
    let currentShootingMode: ShootingMode
    let selectedEVStep: Float
    let isGridActive: Bool
    let isLevelActive: Bool
    let isHistogramActive: Bool
    let onModeChange: () -> Void
    let onGridToggle: () -> Void
    let onLevelToggle: () -> Void
    let onHistogramToggle: () -> Void
    
    var body: some View {
        HStack {
            // Left side - Flash and timer
            HStack(spacing: ModernDesignSystem.Spacing.md) {
                ModernFlashButton()
                ModernTimerButton()
            }
            
            Spacer()
            
            // Center - Mode indicator and bracketing
            HStack(spacing: ModernDesignSystem.Spacing.sm) {
                ModernShootingModeIndicator(mode: currentShootingMode, onTap: onModeChange)
                ModernBracketingIndicator(evStep: selectedEVStep)
            }
            
            Spacer()
            
            // Right side - Grid, level, histogram
            HStack(spacing: ModernDesignSystem.Spacing.md) {
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
                ModernToggleButton(
                    icon: "chart.bar",
                    isActive: isHistogramActive,
                    onTap: onHistogramToggle
                )
            }
        }
        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        .padding(.top, ModernDesignSystem.Spacing.lg)
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
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // EV Compensation and Pro Controls
            HStack {
                EVControlView(
                    currentEV: $currentEVCompensation,
                    isLocked: $evCompensationLocked,
                    showFineControls: false,
                    onValueChanged: nil
                )
                
                Spacer()
                
                ModernProControlButton(showProControls: $showProControls)
            }
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            
            // Main control row
            HStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Photo library
                ModernPhotoLibraryButton()
                
                // Shutter button
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
    var body: some View {
        Button {
            // Flash toggle
        } label: {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
        }
        .buttonStyle(iOSButtonStyle(variant: .secondary, size: .medium))
    }
}

struct ModernTimerButton: View {
    var body: some View {
        Button {
            // Timer toggle
        } label: {
            Image(systemName: "timer")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
        }
        .buttonStyle(iOSButtonStyle(variant: .secondary, size: .medium))
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
            .foregroundColor(ModernDesignSystem.Colors.cameraControl)
            .padding(.horizontal, ModernDesignSystem.Spacing.md)
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(mode.color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(mode.color.opacity(0.4), lineWidth: 1)
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
        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
        .padding(.horizontal, ModernDesignSystem.Spacing.md)
        .padding(.vertical, ModernDesignSystem.Spacing.sm)
        .background(
            Capsule()
                .fill(ModernDesignSystem.Colors.warning.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(ModernDesignSystem.Colors.warning.opacity(0.4), lineWidth: 1)
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
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isActive ? ModernDesignSystem.Colors.cameraControlActive : ModernDesignSystem.Colors.cameraControl)
        }
        .buttonStyle(iOSButtonStyle(variant: .secondary, size: .medium))
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
            Image(systemName: "dial.min")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(showProControls ? ModernDesignSystem.Colors.cameraControlActive : ModernDesignSystem.Colors.cameraControl)
        }
        .buttonStyle(iOSButtonStyle(variant: showProControls ? .primary : .secondary, size: .medium))
    }
}

struct ModernPhotoLibraryButton: View {
    var body: some View {
        Button {
            // Photo library
        } label: {
            RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.small)
                .fill(ModernDesignSystem.Colors.cameraControlSecondary)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                )
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
                // Outer ring
                Circle()
                    .stroke(ModernDesignSystem.Colors.cameraControl, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Inner button
                Circle()
                    .fill(isCapturing ? ModernDesignSystem.Colors.error : ModernDesignSystem.Colors.cameraControl)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isCapturing ? 0.9 : 1.0)
                    .animation(ModernDesignSystem.Animations.spring, value: isCapturing)
                
                // Progress ring
                if isCapturing {
                    iOSProgressRing(
                        progress: CGFloat(progress) / 4.0,
                        lineWidth: 4,
                        color: ModernDesignSystem.Colors.cameraControlActive
                    )
                    .frame(width: 88, height: 88)
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
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
        }
        .buttonStyle(iOSButtonStyle(variant: .secondary, size: .medium))
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
        // OS gate first
        guard #available(iOS 26.0, *) else { return false }
        // Device model gate: require iPhone 17 family (best-effort heuristic)
        let id = ModernDeviceGate.hardwareIdentifier()
        // Accept identifiers that start with "iPhone17" and include Pro Max variants if applicable
        return id.hasPrefix("iPhone17")
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

#Preview {
    ModernContentView()
}
