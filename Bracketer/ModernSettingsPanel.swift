import SwiftUI

// MARK: - Modern Settings Panel
/// Apple Camera app inspired settings with iOS 18+ design patterns
/// Professional camera settings with modern interface

struct ModernSettingsPanel: View {
    @ObservedObject var camera: CameraController
    @Binding var showSettings: Bool
    @Binding var showGrid: Bool
    @Binding var gridType: GridType
    @Binding var showLevel: Bool
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    
    private let focusPeakingColors: [Color] = [.red, .blue, .yellow, .green, .orange, .purple, .white]
    
    var body: some View {
        ZStack {
            // Enhanced background overlay with glass effect
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            .onTapGesture {
                withAnimation(ModernDesignSystem.Animations.spring) {
                    showSettings = false
                }
            }

            // Settings panel
            VStack(spacing: ModernDesignSystem.Spacing.xl) {
                // Header
                HStack {
                    Text("Settings")
                        .font(ModernDesignSystem.Typography.title2)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(ModernDesignSystem.Animations.spring) {
                            showSettings = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    }
                }
                .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                
                // Settings sections
                ScrollView {
                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        // Viewfinder settings
                        ModernViewfinderSettings(
                            showGrid: $showGrid,
                            gridType: $gridType,
                            showLevel: $showLevel
                        )
                        
                        // Focus settings
                        ModernFocusSettings(
                            focusPeakingEnabled: $focusPeakingEnabled,
                            focusPeakingColor: $focusPeakingColor,
                            focusPeakingIntensity: $focusPeakingIntensity,
                            focusPeakingColors: focusPeakingColors
                        )
                        
                        // Camera settings
                        ModernCameraSettings(
                            teleUses12MP: $camera.teleUses12MP,
                            selectedCamera: camera.selectedCamera
                        )
                        
                        // About section
                        ModernAboutSection()
                    }
                    .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                }
            }
            .padding(.vertical, ModernDesignSystem.Spacing.xl)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.large)
                    .fill(.ultraThinMaterial)
                    .opacity(0.95)
                    .overlay(
                        RoundedRectangle(cornerRadius: ModernDesignSystem.CornerRadius.large)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Modern Viewfinder Settings
struct ModernViewfinderSettings: View {
    @Binding var showGrid: Bool
    @Binding var gridType: GridType
    @Binding var showLevel: Bool
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(ModernDesignSystem.Colors.professional)
                Text("Viewfinder")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // Grid settings (3x3 only)
            HStack {
                Image(systemName: "square.grid.3x3")
                    .foregroundColor(ModernDesignSystem.Colors.professional)
                Text("Grid Overlay (3×3)")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
                Toggle("", isOn: $showGrid)
                    .labelsHidden()
                    .tint(ModernDesignSystem.Colors.professional)
            }
            
            // Level indicator
            HStack {
                Image(systemName: "level")
                    .foregroundColor(ModernDesignSystem.Colors.warning)
                Text("Level Indicator")
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
                Toggle("", isOn: $showLevel)
                    .labelsHidden()
                    .tint(ModernDesignSystem.Colors.warning)
            }
        }
        .modernCardStyle(.glass)
    }
    
    private func gridTypeLabel(_ type: GridType) -> String {
        switch type {
        case .ruleOfThirds: return "3×3"
        case .goldenRatio: return "Golden"
        case .goldenSpiral: return "Spiral"
        case .centerCrosshair: return "Cross"
        }
    }
}

// MARK: - Modern Focus Settings
struct ModernFocusSettings: View {
    @Binding var focusPeakingEnabled: Bool
    @Binding var focusPeakingColor: Color
    @Binding var focusPeakingIntensity: Float
    let focusPeakingColors: [Color]
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(ModernDesignSystem.Colors.success)
                Text("Focus")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // Focus Peaking toggle
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
            
            // Focus Peaking controls
            if focusPeakingEnabled {
                VStack(spacing: ModernDesignSystem.Spacing.md) {
                    // Color selection
                    VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                        Text("Peaking Color")
                            .font(ModernDesignSystem.Typography.caption)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                        
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
                    }
                    
                    // Intensity control
                    VStack(spacing: ModernDesignSystem.Spacing.sm) {
                        HStack {
                            Text("Intensity")
                                .font(ModernDesignSystem.Typography.body)
                                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                            Spacer()
                            Text("\(Int(focusPeakingIntensity * 100))%")
                                .font(ModernDesignSystem.Typography.monospace)
                                .foregroundColor(ModernDesignSystem.Colors.success)
                        }
                        
                        Slider(value: $focusPeakingIntensity, in: 0.1...1.0, step: 0.1)
                            .accentColor(ModernDesignSystem.Colors.success)
                    }
                }
            }
        }
        .modernCardStyle(.glass)
    }
}

// MARK: - Modern Camera Settings
struct ModernCameraSettings: View {
    @Binding var teleUses12MP: Bool
    let selectedCamera: CameraKind
    
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "camera")
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                Text("Camera")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            // Camera settings
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                ModernSettingRow(
                    icon: "photo",
                    title: "Photo Format",
                    value: "RAW + HEIF",
                    action: {}
                )
                
                ModernSettingRow(
                    icon: "timer",
                    title: "Timer",
                    value: "Off",
                    action: {}
                )
                
                ModernSettingRow(
                    icon: "bolt.slash",
                    title: "Flash",
                    value: "Auto",
                    action: {}
                )
                
                ModernSettingRow(
                    icon: "location",
                    title: "Location",
                    value: "On",
                    action: {}
                )
                
                // Tele resolution (2x/8x)
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.sm) {
                    HStack {
                        Image(systemName: "camera.aperture")
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                        Text("Tele Resolution (2×/8×)")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                        Spacer()
                        Picker("Tele Resolution", selection: $teleUses12MP) {
                            Text("48MP").tag(false)
                            Text("12MP").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .disabled(!(selectedCamera == .twoX || selectedCamera == .eightX))
                    }
                    Text("Use 12MP on 2×/8× for speed and noise; 48MP for maximum detail.")
                        .font(ModernDesignSystem.Typography.caption2)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                }
            }
        }
        .modernCardStyle(.glass)
    }
}

// MARK: - Modern About Section
struct ModernAboutSection: View {
    var body: some View {
        VStack(spacing: ModernDesignSystem.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                Text("About")
                    .font(ModernDesignSystem.Typography.bodyBold)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                Spacer()
            }
            
            VStack(spacing: ModernDesignSystem.Spacing.md) {
                ModernSettingRow(
                    icon: "app.badge",
                    title: "Version",
                    value: "1.0.0",
                    action: {}
                )
            }
        }
        .modernCardStyle(.glass)
    }
}

// MARK: - Modern Setting Row
struct ModernSettingRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                
                Spacer()
                
                Text(value)
                    .font(ModernDesignSystem.Typography.body)
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
            }
            .padding(.vertical, ModernDesignSystem.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}
