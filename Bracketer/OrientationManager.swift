import SwiftUI
import Combine
import UIKit

/// # OrientationManager
/// Single source of truth for device orientation management throughout the app
///
/// ## Architecture
/// This class consolidates all orientation tracking that was previously scattered across:
/// - CameraController (for photo output rotation)
/// - PreviewContainer (for preview layer rotation)
/// - ModernContentView (for geometry-based landscape detection)
///
/// ## Strategy
/// - **Preview Layer**: NOT rotated - stays fixed to device screen orientation
/// - **Photo Output**: Rotated via AVFoundation's videoRotationAngle based on current orientation
/// - **UI Controls**: Rotated to stay upright using SwiftUI rotation effects
///
/// ## Orientation Locking
/// During bracketed photo capture, orientation is locked to ensure all photos in a sequence
/// have consistent EXIF orientation metadata. This prevents HDR merging issues.
///
/// ## Thread Safety
/// - All @Published properties are on @MainActor
/// - Orientation changes are observed via Combine on main thread
/// - CameraController observes changes and applies rotation on session queue
///
/// ## Usage
/// ```swift
/// @StateObject private var orientationManager = OrientationManager()
/// // ...
/// .environmentObject(orientationManager)
/// ```
///
/// Thread-safe implementation with serial queue
@MainActor
final class OrientationManager: ObservableObject {
    // MARK: - Published Properties

    /// Current interface orientation from UIWindowScene
    @Published private(set) var currentOrientation: UIInterfaceOrientation = .portrait

    /// Rotation angle for UI elements (in degrees)
    @Published private(set) var rotationAngle: Angle = .degrees(0)

    /// Whether orientation is locked (e.g., during photo capture)
    @Published private(set) var isOrientationLocked: Bool = false

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var lockedOrientation: UIInterfaceOrientation?
    private let queue = DispatchQueue(label: "com.bracketer.orientation", qos: .userInitiated)

    // MARK: - Computed Properties

    /// Returns true if current orientation is landscape
    var isLandscape: Bool {
        currentOrientation.isLandscape
    }

    /// Returns true if current orientation is portrait
    var isPortrait: Bool {
        currentOrientation == .portrait || currentOrientation == .portraitUpsideDown
    }

    /// Video rotation angle for AVFoundation (in degrees)
    /// Coordinate system: 0° = landscape right, 90° = portrait, 180° = landscape left, 270° = upside down
    var videoRotationAngle: CGFloat {
        videoRotationAngleValue(for: currentOrientation)
    }

    // MARK: - Initialization

    init() {
        // Set initial orientation from window scene
        updateOrientationFromScene()

        // Start monitoring orientation changes
        startMonitoring()
    }

    // MARK: - Orientation Monitoring

    private func startMonitoring() {
        // Monitor device orientation changes
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in
                // Always read from window scene for accurate interface orientation
                (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation
            }
            .filter { [weak self] orientation in
                guard let self = self else { return false }

                // If orientation is locked, ignore changes
                if self.isOrientationLocked {
                    return false
                }

                // Only respond to valid orientations
                return orientation != .unknown
            }
            .removeDuplicates()
            .sink { [weak self] orientation in
                self?.handleOrientationChange(orientation)
            }
            .store(in: &cancellables)
    }

    private func handleOrientationChange(_ orientation: UIInterfaceOrientation) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.currentOrientation = orientation
            self.updateRotationAngle()
        }

        Logger.ui("Orientation changed to: \(orientation.debugDescription)")
    }

    private func updateOrientationFromScene() {
        let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation ?? .portrait
        self.currentOrientation = orientation
        updateRotationAngle()
    }

    private func updateRotationAngle() {
        // UI rotation angle for controls (to keep them upright)
        switch currentOrientation {
        case .portrait:
            rotationAngle = .degrees(0)
        case .portraitUpsideDown:
            rotationAngle = .degrees(180)
        case .landscapeLeft:
            rotationAngle = .degrees(90)
        case .landscapeRight:
            rotationAngle = .degrees(-90)
        case .unknown:
            rotationAngle = .degrees(0)
        @unknown default:
            rotationAngle = .degrees(0)
        }
    }

    // MARK: - Orientation Locking

    /// Lock orientation to current value (e.g., during bracketed capture)
    func lockOrientation() {
        guard !isOrientationLocked else { return }

        lockedOrientation = currentOrientation
        isOrientationLocked = true

        Logger.ui("Orientation locked to: \(currentOrientation.debugDescription)")
    }

    /// Unlock orientation and resume monitoring
    func unlockOrientation() {
        guard isOrientationLocked else { return }

        isOrientationLocked = false
        lockedOrientation = nil

        // Update to current orientation
        updateOrientationFromScene()

        Logger.ui("Orientation unlocked")
    }

    /// Get the locked orientation if currently locked, otherwise current orientation
    var effectiveOrientation: UIInterfaceOrientation {
        isOrientationLocked ? (lockedOrientation ?? currentOrientation) : currentOrientation
    }

    // MARK: - Video Rotation Calculation

    /// Calculate video rotation angle for AVFoundation
    /// AVFoundation coordinate system: 0° = landscape right, 90° = portrait, 180° = landscape left, 270° = upside down
    private func videoRotationAngleValue(for orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:
            return 90
        case .landscapeRight:
            return 0
        case .landscapeLeft:
            return 180
        case .portraitUpsideDown:
            return 270
        case .unknown:
            return 90  // Default to portrait
        @unknown default:
            return 90
        }
    }

    /// Get video rotation angle for a specific orientation
    func videoRotationAngle(for orientation: UIInterfaceOrientation) -> CGFloat {
        videoRotationAngleValue(for: orientation)
    }

    // MARK: - Cleanup

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        cancellables.removeAll()
    }
}

// MARK: - View Extensions

extension View {
    /// Rotates the view to stay upright based on device orientation
    func rotateWithDevice(_ orientationManager: OrientationManager, anchor: UnitPoint = .center) -> some View {
        self.rotationEffect(orientationManager.rotationAngle, anchor: anchor)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: orientationManager.rotationAngle)
    }

    /// Convenience for keeping content upright (alias for rotateWithDevice)
    func alwaysUpright(_ orientationManager: OrientationManager, anchor: UnitPoint = .center) -> some View {
        rotateWithDevice(orientationManager, anchor: anchor)
    }
}

// MARK: - UIInterfaceOrientation Extensions

extension UIInterfaceOrientation {
    var debugDescription: String {
        switch self {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Portrait Upside Down"
        case .landscapeLeft: return "Landscape Left"
        case .landscapeRight: return "Landscape Right"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
