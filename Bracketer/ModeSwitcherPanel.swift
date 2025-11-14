import SwiftUI

// MARK: - Mode Switcher Panel
/// Quick mode switcher that appears when tapping mode indicator
/// Shows all available modes with descriptions

struct ModeSwitcherPanel: View {
    @Binding var currentMode: ShootingMode
    @Binding var showModeSwitcher: Bool

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showModeSwitcher = false
                    }
                }

            // Mode switcher card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Shooting Mode")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showModeSwitcher = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(10)
                            .background(
                                Circle()
                                    .liquidGlass(intensity: .regular, tint: .white.opacity(0.12), interactive: true)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Mode options
                VStack(spacing: 0) {
                    ForEach(ShootingMode.allCases, id: \.self) { mode in
                        ModeOptionRow(
                            mode: mode,
                            isSelected: currentMode == mode,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    currentMode = mode
                                    showModeSwitcher = false
                                }
                                HapticManager.shared.gridTypeChanged()
                            }
                        )

                        if mode != ShootingMode.allCases.last {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 60)
                        }
                    }
                }
            }
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .overlayGlass(style: .panel, interactive: true)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
    }
}

// MARK: - Mode Option Row
struct ModeOptionRow: View {
    let mode: ShootingMode
    let isSelected: Bool
    let action: () -> Void

    private var modeDescription: String {
        switch mode {
        case .auto:
            return "Automatic settings with quick controls"
        case .manual:
            return "Full manual control with ISO & shutter"
        case .portrait:
            return "Optimized for portrait photography"
        case .night:
            return "Long exposure for low light scenes"
        }
    }

    private var modeFeatures: String {
        switch mode {
        case .auto:
            return "Flash • Timer • Grid • Level"
        case .manual:
            return "ISO • Shutter • White Balance"
        case .portrait:
            return "Auto settings • Portrait mode"
        case .night:
            return "Timer • Stabilization • No flash"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Mode icon
                ZStack {
                    Circle()
                        .liquidGlass(
                            intensity: isSelected ? .prominent : .subtle,
                            tint: isSelected ? mode.color.opacity(0.4) : .white.opacity(0.08),
                            interactive: true
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: mode.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? mode.color : .white.opacity(0.7))
                }

                // Mode info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.rawValue)
                            .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(.white)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(mode.color)
                        }
                    }

                    Text(modeDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)

                    Text(modeFeatures)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(mode.color.opacity(0.8))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .liquidGlass(
                        intensity: isSelected ? .regular : .subtle,
                        tint: isSelected ? mode.color.opacity(0.25) : .white.opacity(0.05),
                        interactive: true
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Change Toast
struct ModeChangeToast: View {
    let mode: ShootingMode

    private var contextHint: String {
        switch mode {
        case .auto:
            return "All controls available"
        case .manual:
            return "ISO & Shutter speed displayed"
        case .portrait:
            return "Portrait optimized settings"
        case .night:
            return "Long exposure mode active"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(mode.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(contextHint)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(mode.color.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
