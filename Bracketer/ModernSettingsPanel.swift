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
        GeometryReader { geometry in
            ZStack {
                // Enhanced background overlay with glass effect
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(ModernDesignSystem.Animations.spring) {
                            showSettings = false
                        }
                    }

                // Settings panel as bottom sheet
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: ModernDesignSystem.Spacing.lg) {
                        // Drag handle (iOS style)
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(ModernDesignSystem.Colors.cameraControlSecondary)
                            .frame(width: 36, height: 5)
                            .padding(.top, 8)

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
                                HapticManager.shared.panelToggled()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                            }
                        }
                        .padding(.horizontal, ModernDesignSystem.Spacing.lg)
                        .padding(.top, ModernDesignSystem.Spacing.sm)

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
                            .padding(.bottom, ModernDesignSystem.Spacing.xl)
                        }
                    }
                    .frame(maxHeight: geometry.size.height * 0.7)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(0.98)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: -10)
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}

// MARK: - Modern Viewfinder Settings
struct ModernViewfinderSettings: View {
    @Binding var showGrid: Bool
    @Binding var gridType: GridType
    @Binding var showLevel: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            // Section header with enhanced styling
            HStack(spacing: 8) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.professional)
                Text("VIEWFINDER")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    .tracking(0.5)
            }
            .padding(.bottom, 4)

            VStack(spacing: 0) {
                // Grid settings (3x3 only)
                HStack {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 18))
                        .foregroundColor(ModernDesignSystem.Colors.professional)
                        .frame(width: 24)
                    Text("Grid Overlay")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    Spacer()
                    Toggle("", isOn: $showGrid)
                        .labelsHidden()
                        .tint(ModernDesignSystem.Colors.professional)
                }
                .padding(.vertical, 12)

                Divider()
                    .background(ModernDesignSystem.Colors.cameraControlSecondary.opacity(0.2))

                // Level indicator
                HStack {
                    Image(systemName: "level")
                        .font(.system(size: 18))
                        .foregroundColor(ModernDesignSystem.Colors.warning)
                        .frame(width: 24)
                    Text("Level Indicator")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    Spacer()
                    Toggle("", isOn: $showLevel)
                        .labelsHidden()
                        .tint(ModernDesignSystem.Colors.warning)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(16)
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
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.md) {
            // Section header with enhanced styling
            HStack(spacing: 8) {
                Image(systemName: "camera")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                Text("CAMERA")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                    .tracking(0.5)
            }
            .padding(.bottom, 4)

            VStack(spacing: 0) {
                // Photo Format
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                        .frame(width: 24)
                    Text("Photo Format")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    Spacer()
                    Text("ProRAW")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                }
                .padding(.vertical, 12)

                Divider()
                    .background(ModernDesignSystem.Colors.cameraControlSecondary.opacity(0.2))

                // Location Services
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                        .frame(width: 24)
                    Text("Location Services")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                    Spacer()
                    Text("On")
                        .font(ModernDesignSystem.Typography.body)
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                }
                .padding(.vertical, 12)

                Divider()
                    .background(ModernDesignSystem.Colors.cameraControlSecondary.opacity(0.2))

                // Tele resolution (2x/8x)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 18))
                            .foregroundColor(ModernDesignSystem.Colors.cameraControlActive)
                            .frame(width: 24)
                        Text("Telephoto Resolution")
                            .font(ModernDesignSystem.Typography.body)
                            .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                        Spacer()
                    }

                    Picker("Tele Resolution", selection: $teleUses12MP) {
                        Text("48MP").tag(false)
                        Text("12MP").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!(selectedCamera == .twoX || selectedCamera == .eightX))

                    Text("12MP: Better in low light. 48MP: Maximum detail.")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesignSystem.Colors.cameraControlSecondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 12)
            }
        }
        .padding(16)
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
