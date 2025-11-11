import SwiftUI

/// Virtual zoom dial providing smooth, continuous zoom control with haptic feedback at preset stops
/// Mimics the tactile feel of a physical camera zoom ring
struct VirtualZoomDial: View {
    @Binding var selectedZoom: CameraKind
    let onZoomChange: (CameraKind) -> Void

    // Zoom dial properties
    private let zoomLevels: [CameraKind] = [.ultraWide, .wide, .twoX, .telephoto, .eightX]
    private let dialRadius: CGFloat = 80
    private let indicatorSize: CGFloat = 8

    // Animation and interaction state
    @State private var rotation: Angle = .zero
    @State private var isDragging = false
    @State private var lastHapticZoom: CameraKind?

    // Calculate current zoom level based on rotation
    private var currentZoomIndex: Int {
        let normalizedRotation = (rotation.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let totalLevels = zoomLevels.count
        let stepSize = 360.0 / Double(totalLevels)
        let index = Int((normalizedRotation + stepSize/2) / stepSize) % totalLevels
        return index
    }

    private var currentZoomLevel: CameraKind {
        zoomLevels[currentZoomIndex]
    }

    var body: some View {
        ZStack {
            // Outer dial ring
            Circle()
                .stroke(ModernDesignSystem.Colors.cameraControlSecondary, lineWidth: 2)
                .frame(width: dialRadius * 2, height: dialRadius * 2)

            // Zoom level markers
            ForEach(0..<zoomLevels.count, id: \.self) { index in
                let angle = Angle(degrees: Double(index) * (360.0 / Double(zoomLevels.count)))
                let isSelected = currentZoomLevel == zoomLevels[index]

                // Marker line
                Rectangle()
                    .fill(isSelected ? ModernDesignSystem.Colors.cameraControlActive : ModernDesignSystem.Colors.cameraControlSecondary)
                    .frame(width: isSelected ? 3 : 2, height: isSelected ? 25 : 20)
                    .offset(y: -dialRadius + 15)
                    .rotationEffect(angle)

                // Zoom level label
                Text(zoomLevels[index].label)
                    .font(ModernDesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? ModernDesignSystem.Colors.cameraControlActive : ModernDesignSystem.Colors.cameraControlSecondary)
                    .offset(y: -dialRadius + 35)
                    .rotationEffect(angle)
            }

            // Center indicator
            Circle()
                .fill(ModernDesignSystem.Colors.glassBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(ModernDesignSystem.Colors.cameraControlSecondary, lineWidth: 1)
                )

            // Current zoom display
            Text(currentZoomLevel.label)
                .font(ModernDesignSystem.Typography.monospace)
                .foregroundColor(ModernDesignSystem.Colors.cameraControl)
                .frame(width: 40, height: 40)
                .background(ModernDesignSystem.Colors.cameraBackground.opacity(0.8))
                .clipShape(Circle())

            // Rotation indicator (small triangle pointing to current zoom)
            Triangle()
                .fill(ModernDesignSystem.Colors.cameraControlActive)
                .frame(width: indicatorSize, height: indicatorSize)
                .offset(y: -dialRadius + 10)
                .rotationEffect(Angle(degrees: Double(currentZoomIndex) * (360.0 / Double(zoomLevels.count))))
        }
        .frame(width: dialRadius * 2 + 40, height: dialRadius * 2 + 40)
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    isDragging = true
                    rotation = angle

                    // Provide haptic feedback when crossing zoom level boundaries
                    let newZoom = currentZoomLevel
                    if newZoom != lastHapticZoom {
                        HapticManager.shared.zoomPresetSelected()
                        lastHapticZoom = newZoom
                    }
                }
                .onEnded { _ in
                    isDragging = false

                    // Snap to nearest zoom level
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        let targetIndex = currentZoomIndex
                        let targetAngle = Angle(degrees: Double(targetIndex) * (360.0 / Double(zoomLevels.count)))
                        rotation = targetAngle
                    }

                    // Update selected zoom
                    let newZoom = currentZoomLevel
                    if newZoom != selectedZoom {
                        selectedZoom = newZoom
                        onZoomChange(newZoom)
                        HapticManager.shared.lensSwitched()
                    }
                }
        )
        .onAppear {
            // Initialize rotation to match current zoom
            if let currentIndex = zoomLevels.firstIndex(of: selectedZoom) {
                rotation = Angle(degrees: Double(currentIndex) * (360.0 / Double(zoomLevels.count)))
            }
        }
        .onChange(of: selectedZoom) { oldValue, newZoom in
            if let index = zoomLevels.firstIndex(of: newZoom) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    rotation = Angle(degrees: Double(index) * (360.0 / Double(zoomLevels.count)))
                }
            }
        }
    }
}

/// Triangle shape for zoom indicator
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Alternative compact zoom dial for smaller spaces
struct CompactZoomDial: View {
    @Binding var selectedZoom: CameraKind
    let onZoomChange: (CameraKind) -> Void

    private let zoomLevels: [CameraKind] = [.ultraWide, .wide, .twoX, .telephoto, .eightX]

    var body: some View {
        HStack(spacing: 8) {
            // Zoom out button
            Button {
                cycleZoom(direction: -1)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }

            // Current zoom display
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 50, height: 50)

                Text(selectedZoom.label)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            // Zoom in button
            Button {
                cycleZoom(direction: 1)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
    }

    private func cycleZoom(direction: Int) {
        guard let currentIndex = zoomLevels.firstIndex(of: selectedZoom) else { return }

        let newIndex = (currentIndex + direction + zoomLevels.count) % zoomLevels.count
        let newZoom = zoomLevels[newIndex]

        selectedZoom = newZoom
        onZoomChange(newZoom)
        HapticManager.shared.zoomPresetSelected()
    }
}

/// Hybrid zoom control that combines both smooth and stepped zoom
struct HybridZoomControl: View {
    @Binding var selectedZoom: CameraKind
    let onZoomChange: (CameraKind) -> Void

    @State private var showVirtualDial = false

    var body: some View {
        ZStack {
            // Default zoom selector (compact)
            if !showVirtualDial {
                CompactZoomDial(selectedZoom: $selectedZoom, onZoomChange: onZoomChange)
            }

            // Virtual zoom dial (when activated)
            if showVirtualDial {
                VirtualZoomDial(selectedZoom: $selectedZoom, onZoomChange: onZoomChange)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation(.spring()) {
                        showVirtualDial.toggle()
                        if !showVirtualDial {
                            HapticManager.shared.gridTypeChanged()
                        }
                    }
                }
        )
    }
}
