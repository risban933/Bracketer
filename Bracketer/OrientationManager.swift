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
    /// Rotates the view to match device orientation (for buttons and controls)
    /// Use this on UI elements that should rotate while the app stays portrait
    func rotateWithDevice(_ orientationManager: OrientationManager) -> some View {
        self.rotationEffect(orientationManager.rotationAngle)
    }

    /// Rotates the view to always face upward regardless of device orientation
    /// Perfect for buttons, labels, and icons in camera apps
    func alwaysUpright(_ orientationManager: OrientationManager) -> some View {
        self.rotationEffect(orientationManager.rotationAngle)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: orientationManager.rotationAngle)
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
