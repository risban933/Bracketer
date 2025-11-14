import SwiftUI
import AVFoundation

/// Interactive Depth Map Viewer for Portrait mode photos
/// Provides 3D visualization of depth data with focal plane analysis
struct DepthMapViewer: View {
    let image: UIImage?
    let depthData: AVDepthData?
    @State private var rotation: Angle = .zero
    @State private var scale: CGFloat = 1.0
    @State private var showWireframe = false
    @State private var focalPlane: Float = 0.5
    @State private var depthRange: ClosedRange<Float> = 0.0...1.0

    // Simulated depth data for demonstration
    private let simulatedDepthMap: [[Float]] = {
        var depthMap = [[Float]]()
        for y in 0..<50 {
            var row = [Float]()
            for x in 0..<50 {
                // Create a simulated depth map with foreground and background
                let centerX: Float = 25.0
                let centerY: Float = 25.0
                let distance = sqrt(pow(Float(x) - centerX, 2) + pow(Float(y) - centerY, 2))
                let depth = min(1.0, distance / 20.0) // Closer = lower depth value
                row.append(depth)
            }
            depthMap.append(row)
        }
        return depthMap
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Depth Map Analysis")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        // Dismiss action would be handled by parent
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(10)
                            .background(
                                Circle()
                                    .liquidGlass(intensity: .regular, tint: .white.opacity(0.15), interactive: true)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // 3D Depth Visualization
                ZStack {
                    if showWireframe {
                        WireframeDepthView(depthMap: simulatedDepthMap, rotation: rotation, scale: scale)
                    } else {
                        SurfaceDepthView(depthMap: simulatedDepthMap, rotation: rotation, scale: scale)
                    }

                    // Focal plane indicator
                    FocalPlaneOverlay(focalPlane: focalPlane, depthRange: depthRange)
                }
                .frame(height: 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .gesture(
                    RotationGesture()
                        .onChanged { angle in
                            rotation = angle
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                )

                // Controls
                VStack(spacing: 16) {
                    // View mode toggle
                    HStack {
                        Text("Visualization")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("Mode", selection: $showWireframe) {
                            Text("Surface").tag(false)
                            Text("Wireframe").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }

                    // Focal plane slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focal Plane: \(String(format: "%.2f", focalPlane))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        Slider(value: $focalPlane, in: 0...1, step: 0.01)
                            .accentColor(.blue)
                    }

                    // Depth range adjustment
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Depth Range")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)

                        HStack {
                            Text("Near")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Slider(value: .init(
                                get: { depthRange.lowerBound },
                                set: { depthRange = $0...depthRange.upperBound }
                            ), in: 0...1)
                            .accentColor(.green)
                            Text("Far")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Depth statistics
                    HStack(spacing: 20) {
                        DepthStatView(label: "Min Depth", value: String(format: "%.2f", depthRange.lowerBound))
                        DepthStatView(label: "Max Depth", value: String(format: "%.2f", depthRange.upperBound))
                        DepthStatView(label: "Range", value: String(format: "%.2f", depthRange.upperBound - depthRange.lowerBound))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

// MARK: - Depth Visualization Views

struct SurfaceDepthView: View {
    let depthMap: [[Float]]
    let rotation: Angle
    let scale: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<depthMap.count, id: \.self) { y in
                    ForEach(0..<depthMap[y].count, id: \.self) { x in
                        let depth = depthMap[y][x]
                        let normalizedDepth = (depth - 0.0) / (1.0 - 0.0) // Normalize to 0-1

                        Rectangle()
                            .fill(depthColor(for: normalizedDepth))
                            .frame(width: geo.size.width / CGFloat(depthMap[y].count),
                                   height: geo.size.height / CGFloat(depthMap.count))
                            .offset(x: CGFloat(x) * geo.size.width / CGFloat(depthMap[y].count) - geo.size.width/2,
                                    y: CGFloat(y) * geo.size.height / CGFloat(depthMap.count) - geo.size.height/2)
                            .zIndex(Double(normalizedDepth) * 100)
                    }
                }
            }
            .rotation3DEffect(rotation, axis: (x: 0, y: 1, z: 0))
            .scaleEffect(scale)
        }
    }

    private func depthColor(for depth: Float) -> Color {
        // Color mapping: near = red, far = blue
        let red = depth
        let blue = 1.0 - depth
        let green = 0.0
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
}

struct WireframeDepthView: View {
    let depthMap: [[Float]]
    let rotation: Angle
    let scale: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Horizontal lines
                ForEach(0..<depthMap.count, id: \.self) { y in
                    Path { path in
                        for x in 0..<depthMap[y].count {
                            let depth = depthMap[y][x]
                            let xPos = CGFloat(x) * geo.size.width / CGFloat(depthMap[y].count)
                            let yPos = CGFloat(y) * geo.size.height / CGFloat(depthMap.count)
                            let zOffset = Double(depth) * 20 // Exaggerate depth for visibility

                            if x == 0 {
                                path.move(to: CGPoint(x: xPos, y: yPos - zOffset))
                            } else {
                                path.addLine(to: CGPoint(x: xPos, y: yPos - zOffset))
                            }
                        }
                    }
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                }

                // Vertical lines
                ForEach(0..<depthMap[0].count, id: \.self) { x in
                    Path { path in
                        for y in 0..<depthMap.count {
                            let depth = depthMap[y][x]
                            let xPos = CGFloat(x) * geo.size.width / CGFloat(depthMap[y].count)
                            let yPos = CGFloat(y) * geo.size.height / CGFloat(depthMap.count)
                            let zOffset = Double(depth) * 20

                            if y == 0 {
                                path.move(to: CGPoint(x: xPos, y: yPos - zOffset))
                            } else {
                                path.addLine(to: CGPoint(x: xPos, y: yPos - zOffset))
                            }
                        }
                    }
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                }
            }
            .rotation3DEffect(rotation, axis: (x: 0, y: 1, z: 0))
            .scaleEffect(scale)
        }
    }
}

struct FocalPlaneOverlay: View {
    let focalPlane: Float
    let depthRange: ClosedRange<Float>

    var body: some View {
        GeometryReader { geo in
            // Focal plane indicator
            Rectangle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: geo.size.width, height: 2)
                .offset(y: geo.size.height * (1.0 - CGFloat(focalPlane)))

            // Depth range indicators
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .frame(width: geo.size.width, height: geo.size.height * CGFloat(depthRange.upperBound - depthRange.lowerBound))
                .offset(y: geo.size.height * (1.0 - CGFloat(depthRange.upperBound)))
        }
    }
}

struct DepthStatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Preview

struct DepthMapViewer_Previews: PreviewProvider {
    static var previews: some View {
        DepthMapViewer(image: nil, depthData: nil)
    }
}
