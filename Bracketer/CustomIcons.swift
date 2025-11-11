import SwiftUI

/// Custom icon system for professional camera controls
/// Provides distinctive, minimalist icons that enhance the tactile experience
enum CameraIcon {
    case grid, level, histogram, focus, dial, raw, flash, exposure

    func image(isActive: Bool = false) -> some View {
        ZStack {
            switch self {
            case .grid:
                GridIcon()
            case .level:
                LevelIcon()
            case .histogram:
                HistogramIcon()
            case .focus:
                FocusIcon()
            case .dial:
                DialIcon()
            case .raw:
                RawIcon()
            case .flash:
                FlashIcon()
            case .exposure:
                ExposureIcon()
            }
        }
        .foregroundColor(isActive ? .yellow : .white)
    }
}

// MARK: - Custom Icon Shapes

struct GridIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let lineWidth: CGFloat = size * 0.08

        // Create a 3x3 grid pattern
        let spacing = size / 4

        // Vertical lines
        for i in 1...2 {
            let x = spacing * CGFloat(i)
            path.addRect(CGRect(x: x - lineWidth/2, y: 0, width: lineWidth, height: size))
        }

        // Horizontal lines
        for i in 1...2 {
            let y = spacing * CGFloat(i)
            path.addRect(CGRect(x: 0, y: y - lineWidth/2, width: size, height: lineWidth))
        }

        return path
    }
}

struct LevelIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: size/2, y: size/2)
        let radius = size * 0.35
        let indicatorSize = size * 0.15

        // Outer circle
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2))

        // Inner circle
        path.addEllipse(in: CGRect(x: center.x - radius * 0.6, y: center.y - radius * 0.6,
                                  width: radius * 1.2, height: radius * 1.2))

        // Level indicator line
        path.addRect(CGRect(x: center.x - radius * 0.8, y: center.y - indicatorSize/2,
                           width: radius * 1.6, height: indicatorSize))

        // Center crosshairs
        path.addRect(CGRect(x: center.x - indicatorSize/2, y: center.y - radius * 0.3,
                           width: indicatorSize, height: radius * 0.6))
        path.addRect(CGRect(x: center.x - radius * 0.3, y: center.y - indicatorSize/2,
                           width: radius * 0.6, height: indicatorSize))

        return path
    }
}

struct HistogramIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let barWidth = size * 0.15
        let spacing = size * 0.2

        // Create histogram bars of varying heights
        let heights: [CGFloat] = [0.8, 0.4, 0.9, 0.3, 0.6]

        for (index, height) in heights.enumerated() {
            let x = spacing * CGFloat(index)
            let barHeight = size * height
            let y = size - barHeight

            path.addRect(CGRect(x: x, y: y, width: barWidth, height: barHeight))
        }

        return path
    }
}

struct FocusIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: size/2, y: size/2)

        // Outer circle (focus ring)
        let outerRadius = size * 0.4
        path.addEllipse(in: CGRect(x: center.x - outerRadius, y: center.y - outerRadius,
                                  width: outerRadius * 2, height: outerRadius * 2))

        // Inner circle (focus point)
        let innerRadius = size * 0.15
        path.addEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius,
                                  width: innerRadius * 2, height: innerRadius * 2))

        // Focus peaking dots around the ring
        let dotRadius = size * 0.03
        let dotDistance = size * 0.35

        for angle in stride(from: 0, to: 360, by: 60) {
            let radians = Double(angle) * .pi / 180
            let x = center.x + cos(radians) * dotDistance
            let y = center.y + sin(radians) * dotDistance

            path.addEllipse(in: CGRect(x: x - dotRadius, y: y - dotRadius,
                                      width: dotRadius * 2, height: dotRadius * 2))
        }

        return path
    }
}

struct DialIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: size/2, y: size/2)
        let radius = size * 0.4

        // Main dial circle
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2))

        // Dial markings (like camera aperture ring)
        let markingCount = 12
        let markingLength = size * 0.08
        let markingDistance = radius * 0.85

        for i in 0..<markingCount {
            let angle = (CGFloat(i) / CGFloat(markingCount)) * 2 * .pi
            let startX = center.x + cos(angle) * (markingDistance - markingLength/2)
            let startY = center.y + sin(angle) * (markingDistance - markingLength/2)
            let endX = center.x + cos(angle) * (markingDistance + markingLength/2)
            let endY = center.y + sin(angle) * (markingDistance + markingLength/2)

            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
        }

        // Center indicator (like f-stop marker)
        let indicatorSize = size * 0.1
        path.addRect(CGRect(x: center.x - indicatorSize/2, y: center.y - radius * 0.3,
                           width: indicatorSize, height: radius * 0.6))

        return path
    }
}

struct RawIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)

        // R
        path.move(to: CGPoint(x: size * 0.1, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.1, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.5))
        path.addLine(to: CGPoint(x: size * 0.1, y: size * 0.5))

        // R arc
        path.move(to: CGPoint(x: size * 0.3, y: size * 0.35))
        path.addQuadCurve(to: CGPoint(x: size * 0.1, y: size * 0.35),
                         control: CGPoint(x: size * 0.2, y: size * 0.25))

        // A
        path.move(to: CGPoint(x: size * 0.4, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.45, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.55, y: size * 0.8))

        // A crossbar
        path.move(to: CGPoint(x: size * 0.42, y: size * 0.5))
        path.addLine(to: CGPoint(x: size * 0.53, y: size * 0.5))

        // W
        path.move(to: CGPoint(x: size * 0.65, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.68, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.71, y: size * 0.5))
        path.addLine(to: CGPoint(x: size * 0.74, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.77, y: size * 0.2))

        return path
    }
}

struct FlashIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)

        // Lightning bolt shape
        path.move(to: CGPoint(x: size * 0.4, y: size * 0.2))
        path.addLine(to: CGPoint(x: size * 0.3, y: size * 0.4))
        path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.4))
        path.addLine(to: CGPoint(x: size * 0.35, y: size * 0.6))
        path.addLine(to: CGPoint(x: size * 0.6, y: size * 0.6))
        path.addLine(to: CGPoint(x: size * 0.7, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.8))
        path.addLine(to: CGPoint(x: size * 0.4, y: size * 0.2))

        return path
    }
}

struct ExposureIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let center = CGPoint(x: size/2, y: size/2)

        // Aperture blades (simplified)
        let bladeCount = 6
        let outerRadius = size * 0.4
        let innerRadius = size * 0.15

        for i in 0..<bladeCount {
            let angle = (CGFloat(i) / CGFloat(bladeCount)) * 2 * .pi
            let nextAngle = (CGFloat(i + 1) / CGFloat(bladeCount)) * 2 * .pi

            path.move(to: CGPoint(x: center.x + cos(angle) * innerRadius,
                                 y: center.y + sin(angle) * innerRadius))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * outerRadius,
                                   y: center.y + sin(angle) * outerRadius))
            path.addLine(to: CGPoint(x: center.x + cos(nextAngle) * outerRadius,
                                   y: center.y + sin(nextAngle) * outerRadius))
            path.addLine(to: CGPoint(x: center.x + cos(nextAngle) * innerRadius,
                                   y: center.y + sin(nextAngle) * innerRadius))
            path.closeSubpath()
        }

        // Center circle
        path.addEllipse(in: CGRect(x: center.x - innerRadius, y: center.y - innerRadius,
                                  width: innerRadius * 2, height: innerRadius * 2))

        return path
    }
}

// MARK: - Convenience Extensions

extension View {
    func cameraIcon(_ icon: CameraIcon, isActive: Bool = false) -> some View {
        icon.image(isActive: isActive)
            .aspectRatio(1, contentMode: .fit)
    }
}
