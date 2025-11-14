import SwiftUI
import CoreMotion
import UIKit

private enum Constants {
    static let motionUpdateInterval: TimeInterval = 1.0/60.0
    static let levelThresholdDegrees: Double = 1.0
    static let levelIndicatorWidth: CGFloat = 0.6
    static let levelIndicatorHeight: CGFloat = 2.0
}

struct LevelerOverlay: View {
    let angleDegrees: Double

    private var isLevel: Bool {
        abs(angleDegrees) < Constants.levelThresholdDegrees
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Outer bullseye ring
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)

                // Inner bullseye ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 80, height: 80)

                // Center crosshairs
                Path { path in
                    // Horizontal line
                    path.move(to: CGPoint(x: 50, y: 60))
                    path.addLine(to: CGPoint(x: 70, y: 60))
                    // Vertical line
                    path.move(to: CGPoint(x: 60, y: 50))
                    path.addLine(to: CGPoint(x: 60, y: 70))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 1)

                // Level indicator dot
                Circle()
                    .fill(isLevel ? Color.yellow : Color.white)
                    .frame(width: 8, height: 8)
                    .offset(x: sin(angleDegrees * .pi / 180) * 40,
                           y: -cos(angleDegrees * .pi / 180) * 40)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: angleDegrees)

                // Level indicator
                if !isLevel {
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 60, height: 2)
                        .rotationEffect(.degrees(angleDegrees))
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: angleDegrees)
                }
            }
            .position(x: geo.size.width / 2, y: 80)
            .opacity(isLevel ? 0.3 : 1.0) // Fade when level
        }
        .allowsHitTesting(false)
    }
}

// Note: MotionManager functionality is provided by MotionLevelManager in MotionManager.swift
// This ensures a single, consistent implementation for motion tracking across the app
