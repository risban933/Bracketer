import SwiftUI
import Combine

/// Manages device orientation for rotating UI elements while keeping app locked to portrait
/// Follows Apple Camera app pattern: preview stays fixed, controls rotate
class OrientationManager: ObservableObject {
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    @Published var rotationAngle: Angle = .degrees(0)

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Start monitoring device orientation
        startMonitoring()
    }

    func startMonitoring() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .filter { orientation in
                // Only respond to valid orientations
                orientation.isPortrait || orientation.isLandscape
            }
            .sink { [weak self] orientation in
                self?.handleOrientationChange(orientation)
            }
            .store(in: &cancellables)

        // Set initial orientation
        let initialOrientation = UIDevice.current.orientation
        if initialOrientation.isValidInterfaceOrientation {
            currentOrientation = initialOrientation
            updateRotationAngle()
        }
    }

    private func handleOrientationChange(_ orientation: UIDeviceOrientation) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentOrientation = orientation
            updateRotationAngle()
        }
    }

    private func updateRotationAngle() {
        switch currentOrientation {
        case .portrait, .unknown:
            rotationAngle = .degrees(0)
        case .portraitUpsideDown:
            rotationAngle = .degrees(180)
        case .landscapeLeft:
            rotationAngle = .degrees(90)
        case .landscapeRight:
            rotationAngle = .degrees(-90)
        default:
            rotationAngle = .degrees(0)
        }
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

// MARK: - View Extension for Rotating Controls

extension View {
    /// Rotates the view based on the current device orientation around a customizable anchor point.
    func rotateWithDevice(_ orientationManager: OrientationManager, anchor: UnitPoint = .center) -> some View {
        self.rotationEffect(orientationManager.rotationAngle, anchor: anchor)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: orientationManager.rotationAngle)
    }

    /// Convenience for always keeping content upright (alias for rotateWithDevice).
    func alwaysUpright(_ orientationManager: OrientationManager, anchor: UnitPoint = .center) -> some View {
        rotateWithDevice(orientationManager, anchor: anchor)
    }
}

// MARK: - Orientation-Aware Button Style

struct OrientationAwareButtonStyle: ViewModifier {
    @ObservedObject var orientationManager: OrientationManager

    func body(content: Content) -> some View {
        content
            .rotationEffect(orientationManager.rotationAngle)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: orientationManager.rotationAngle)
    }
}

extension View {
    func orientationAware(_ orientationManager: OrientationManager) -> some View {
        self.modifier(OrientationAwareButtonStyle(orientationManager: orientationManager))
    }
}
