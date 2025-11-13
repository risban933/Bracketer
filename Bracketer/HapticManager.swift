import UIKit
import CoreHaptics

/// Comprehensive haptic feedback system for professional camera controls
/// Provides tactile feedback that enhances the physical camera experience
final class HapticManager {
    static let shared = HapticManager()

    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    private init() {
        setupHapticEngine()
    }

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            supportsHaptics = false
            return
        }

        supportsHaptics = true
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation failed: \(error)")
        }

        // Handle engine reset
        hapticEngine?.resetHandler = { [weak self] in
            do {
                try self?.hapticEngine?.start()
            } catch {
                print("Haptic engine restart failed: \(error)")
            }
        }

        // Handle engine stop
        hapticEngine?.stoppedHandler = { reason in
            print("Haptic engine stopped: \(reason)")
        }
    }

    // MARK: - Camera Control Feedback Patterns

    /// Focus lock confirmation - sharp, definitive click
    func focusLocked() {
        playPattern(.focusLocked)
    }

    /// Reaching ISO limit - warning buzz
    func isoLimitReached() {
        playPattern(.limitReached)
    }

    /// Shutter speed limit reached - warning buzz
    func shutterLimitReached() {
        playPattern(.limitReached)
    }

    /// Lens/camera switching - smooth transition
    func lensSwitched() {
        playPattern(.lensSwitched)
    }

    /// Zoom level change - subtle click at each preset
    func zoomPresetSelected() {
        playPattern(.zoomPresetSelected)
    }

    /// Grid type cycled - light confirmation
    func gridTypeChanged() {
        playPattern(.settingChanged)
    }

    /// Control panel opened/closed - smooth transition
    func panelToggled() {
        playPattern(.panelToggle)
    }

    /// Exposure compensation adjusted - fine control feedback
    func exposureAdjusted() {
        playPattern(.fineAdjustment)
    }

    /// Shutter button pressed - camera-like feedback
    func shutterPressed() {
        playPattern(.shutterPressed)
    }

    /// Capture started - burst feedback for bracket capture
    func captureStarted() {
        playPattern(.captureStarted)
    }

    /// Individual bracket shot taken - light click
    func bracketShotCaptured() {
        playPattern(.bracketShot)
    }

    /// Capture sequence completed - success feedback
    func captureCompleted() {
        playPattern(.captureCompleted)
    }

    /// Error occurred - error pattern
    func errorOccurred() {
        playPattern(.error)
    }

    // MARK: - Core Haptic Implementation

    private enum HapticPattern {
        case focusLocked
        case limitReached
        case lensSwitched
        case zoomPresetSelected
        case settingChanged
        case panelToggle
        case fineAdjustment
        case shutterPressed
        case captureStarted
        case bracketShot
        case captureCompleted
        case error
    }

    private func playPattern(_ pattern: HapticPattern) {
        if !supportsHaptics {
            // Fallback to basic vibration for older devices
            playBasicFeedback(for: pattern)
            return
        }

        guard let engine = hapticEngine else { return }

        do {
            let events = createEvents(for: pattern)
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback failed: \(error)")
            // Fallback to basic feedback
            playBasicFeedback(for: pattern)
        }
    }

    private func createEvents(for pattern: HapticPattern) -> [CHHapticEvent] {
        switch pattern {
        case .focusLocked:
            // Sharp, definitive focus lock
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                            ],
                            relativeTime: 0,
                            duration: 0.1)
            ]

        case .limitReached:
            // Warning buzz for limits
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                            ],
                            relativeTime: 0,
                            duration: 0.15),
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                            ],
                            relativeTime: 0.2,
                            duration: 0.15)
            ]

        case .lensSwitched:
            // Smooth lens transition
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                            ],
                            relativeTime: 0,
                            duration: 0.2)
            ]

        case .zoomPresetSelected:
            // Subtle click for presets
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                            ],
                            relativeTime: 0)
            ]

        case .settingChanged:
            // Light confirmation
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                            ],
                            relativeTime: 0)
            ]

        case .panelToggle:
            // Smooth panel transition
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                            ],
                            relativeTime: 0,
                            duration: 0.15)
            ]

        case .fineAdjustment:
            // Very subtle for fine controls
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                            ],
                            relativeTime: 0)
            ]

        case .shutterPressed:
            // Camera-like shutter feedback
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                            ],
                            relativeTime: 0,
                            duration: 0.08)
            ]

        case .captureStarted:
            // Multi-shot burst start
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                            ],
                            relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                            ],
                            relativeTime: 0.1)
            ]

        case .bracketShot:
            // Individual bracket shot
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                            ],
                            relativeTime: 0)
            ]

        case .captureCompleted:
            // Success completion
            return [
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                            ],
                            relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                            ],
                            relativeTime: 0.1),
                CHHapticEvent(eventType: .hapticTransient,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                            ],
                            relativeTime: 0.2)
            ]

        case .error:
            // Error pattern - distinctive and attention-grabbing
            return [
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                            ],
                            relativeTime: 0,
                            duration: 0.1),
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                            ],
                            relativeTime: 0.15,
                            duration: 0.1),
                CHHapticEvent(eventType: .hapticContinuous,
                            parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                            ],
                            relativeTime: 0.3,
                            duration: 0.1)
            ]
        }
    }

    private func playBasicFeedback(for pattern: HapticPattern) {
        // Fallback for devices without advanced haptics
        let generator = UINotificationFeedbackGenerator()

        switch pattern {
        case .focusLocked, .zoomPresetSelected, .shutterPressed:
            generator.notificationOccurred(.success)
        case .limitReached, .error:
            generator.notificationOccurred(.error)
        case .lensSwitched, .panelToggle, .captureCompleted:
            generator.notificationOccurred(.warning)
        default:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    deinit {
        hapticEngine?.resetHandler = nil
        hapticEngine?.stoppedHandler = nil
        hapticEngine?.stop()
    }
}
