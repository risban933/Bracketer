# CLAUDE.md - Bracketer iOS Camera App

**Last Updated:** 2025-11-13
**Project Type:** Native iOS Application (SwiftUI)
**Target Platform:** iPhone 17 Pro Max, iOS 26.0+

This document provides comprehensive guidance for AI assistants working with the Bracketer codebase.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Tech Stack & Dependencies](#tech-stack--dependencies)
4. [Architecture & Design Patterns](#architecture--design-patterns)
5. [Key Components](#key-components)
6. [Development Workflow](#development-workflow)
7. [Coding Conventions](#coding-conventions)
8. [Testing](#testing)
9. [Known Issues & Bug Tracking](#known-issues--bug-tracking)
10. [Device Requirements](#device-requirements)
11. [Important Notes for AI Assistants](#important-notes-for-ai-assistants)

---

## Project Overview

**Bracketer** is a professional camera application for iOS that specializes in **bracketed photography**. It provides advanced manual camera controls, ProRAW capture, and computational photography features designed for professional photographers.

### Core Features
- **Bracketed Photography**: Capture multiple exposures with configurable EV steps
- **ProRAW Support**: 48MP sensor RAW capture with full metadata
- **Manual Camera Controls**: ISO, shutter speed, exposure compensation, focus
- **Real-time Level Indicator**: CoreMotion-based device leveling
- **Focus Peaking**: Visual focus confirmation with customizable colors
- **Advanced Haptics**: CoreHaptics-based tactile feedback
- **EXIF Viewer**: Comprehensive metadata display for captured images
- **Depth Map Visualization**: Portrait mode depth data viewing
- **Multiple Camera Lenses**: Ultra-wide, wide, 2x, telephoto support

### Target Device
- **Exclusive to iPhone 17 Pro Max** (identifier: "iPhone17,1")
- **iOS 26.0+** required for advanced camera APIs
- Simulator support enabled for development

---

## Project Structure

```
Bracketer/
├── Bracketer/                          # Main application source
│   ├── BracketerApp.swift             # App entry point (@main)
│   ├── ModernContentView.swift        # Main UI (1,052 lines)
│   ├── CameraController.swift         # Camera logic & AVFoundation (750 lines)
│   ├── PreviewContainer.swift         # Camera preview (790 lines)
│   ├── ModernProControls.swift        # Pro controls UI (608 lines)
│   ├── ModernSettingsPanel.swift      # Settings panel (424 lines)
│   ├── ModernDesignSystem.swift       # Design system tokens (304 lines)
│   ├── CameraZoomControl.swift        # Zoom controls (420 lines)
│   ├── HapticManager.swift            # Haptics (351 lines)
│   ├── MotionManager.swift            # Motion sensing & level (286 lines)
│   ├── ImageViewer.swift              # Image viewing (349 lines)
│   ├── EXIFViewer.swift               # EXIF display (490 lines)
│   ├── DepthMapViewer.swift           # Depth visualization (281 lines)
│   ├── LiquidGlassDesign.swift        # UI effects (490 lines)
│   ├── ContextualControls.swift       # Context menus (324 lines)
│   ├── DeviceGating.swift             # Device compatibility (261 lines)
│   ├── OrientationManager.swift       # Orientation handling (99 lines)
│   ├── ModeSwitcherPanel.swift        # Mode switching (219 lines)
│   ├── VirtualZoomDial.swift          # Zoom dial UI (234 lines)
│   ├── CustomIcons.swift              # Custom icons (279 lines)
│   ├── Overlays.swift                 # Overlay views (118 lines)
│   ├── Logger.swift                   # Logging utility (131 lines)
│   └── Assets.xcassets/               # App assets
│       ├── AppIcon.appiconset/
│       ├── AccentColor.colorset/
│       └── Contents.json
├── BracketerTests/                     # Unit tests
│   └── BracketerTests.swift           # Test scaffolding
├── BracketerUITests/                   # UI tests
│   ├── BracketerUITests.swift
│   └── BracketerUITestsLaunchTests.swift
├── Bracketer.xcodeproj/               # Xcode project
│   └── project.pbxproj                # Project configuration
├── BUG_REPORT.md                      # Detailed bug analysis
├── FIXES_APPLIED.md                   # Applied bug fixes documentation
└── CLAUDE.md                          # This file

**Total:** ~8,300 lines of Swift code across 25 files
```

---

## Tech Stack & Dependencies

### Core Technologies
- **Swift 5.0** - Primary programming language
- **SwiftUI** - Modern declarative UI framework (iOS 18+ design patterns)
- **Xcode** - Development environment (project format version 77)

### Apple Frameworks (No External Dependencies)
- **AVFoundation** - Camera control, video preview, media capture
- **CoreMotion** - Device motion tracking and level detection
- **Photos/PhotoKit** - Photo library management and RAW image saving
- **CoreHaptics** - Advanced haptic feedback system
- **CoreLocation** - GPS geotagging for photos
- **UIKit** - Supporting UI components and device interaction
- **os.log** - Structured logging system
- **Combine** - Reactive programming for state management
- **UserNotifications** - Notification handling

### Build Configuration
- **Bundle ID**: `com.rishabh.Bracketer`
- **Development Team**: UZD4BS94DT
- **iOS Deployment Target**: iOS 26.0 (Debug/Release base: iOS 18.5)
- **Supported Platforms**: iPhone only (no iPad/Mac Catalyst)
- **Swift Version**: 5.0
- **Code Signing**: Automatic

**Important**: This project has **NO external dependencies** - no CocoaPods, Swift Package Manager, or Carthage. Everything is pure Swift and Apple frameworks.

---

## Architecture & Design Patterns

### SwiftUI MVVM Architecture

**Views** (SwiftUI declarative)
- `ModernContentView.swift` - Main camera interface
- `ModernProControls.swift` - Professional camera controls
- `PreviewContainer.swift` - Camera preview (UIViewRepresentable)

**ViewModels** (ObservableObject with @Published properties)
- `CameraController` - Camera session management
- `MotionManager` (MotionLevelManager) - Device motion tracking
- `HapticManager` - Haptic feedback coordination
- `OrientationManager` - Device orientation handling

**Models** (Enums & Structs)
- `ShootingMode` - Photo modes (manual, auto, bracket)
- `GridType` - Overlay grid types
- `CameraKind` - Lens selection (ultra-wide, wide, telephoto)

### State Management Patterns

```swift
// Published properties for reactive updates
@Published var currentISO: Float = 100
@Published var currentShutterSpeed: Double = 1/125

// StateObject for lifecycle management
@StateObject private var camera = CameraController()
@StateObject private var motionManager = MotionLevelManager()

// EnvironmentObject for shared state
@EnvironmentObject var orientationManager: OrientationManager
```

### Coordinator Pattern

UIViewRepresentable views use Coordinators for UIKit integration:

```swift
struct PreviewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator {
        // Manages NotificationCenter observers
        // Handles UIKit-SwiftUI bridge
        // Lifecycle management
    }
}
```

### Singleton Pattern

Used for shared services:
- `DeviceGating.shared` - Device compatibility checking
- `HapticManager.shared` - Haptic feedback coordination

### Thread Safety Pattern

```swift
// Serial dispatch queue for camera operations
private let sessionQueue = DispatchQueue(label: "com.bracketer.camera")

// Main queue for UI updates
DispatchQueue.main.async {
    self.updateUIState()
}

// @MainActor for UI-bound types
@MainActor
final class CameraController: ObservableObject { }
```

---

## Key Components

### 1. CameraController.swift (750 lines)
**Purpose**: Central camera session management using AVFoundation

**Key Responsibilities**:
- AVCaptureSession configuration and lifecycle
- Lens selection and switching (ultra-wide, wide, telephoto)
- Manual exposure, ISO, shutter speed control
- Focus control and focus peaking
- Bracketed photo capture with EV steps
- ProRAW image processing
- Auto-exposure settling
- Preview layer management

**Critical Methods**:
- `start()` - Initialize camera session
- `captureRawBracket(evStep:)` - Capture bracketed photos
- `switchCamera(to:)` - Change camera lens
- `settleAutoExposure(completion:)` - Wait for exposure to settle
- `saveRAW(pixelBuffer:metadata:evStep:)` - Save ProRAW images

**Thread Safety**: Uses `sessionQueue` for all camera operations

### 2. ModernContentView.swift (1,052 lines)
**Purpose**: Main UI composition and state orchestration

**Key Features**:
- Camera preview display
- Pro controls integration
- Settings panel
- Image viewer
- Mode switching (manual/auto/bracket)
- Toast notifications
- Gesture handling

**State Management**:
- Manages 30+ @State properties
- Coordinates multiple @StateObject controllers
- Handles view lifecycle

### 3. PreviewContainer.swift (790 lines)
**Purpose**: AVCaptureVideoPreviewLayer SwiftUI wrapper

**Features**:
- UIViewRepresentable implementation
- Orientation handling via NotificationCenter
- Grid overlays (Rule of Thirds, Golden Spiral, etc.)
- Focus peaking visualization
- Level indicator
- Coordinator pattern for lifecycle management

**Recent Fix**: NotificationCenter observer leak fixed in FIXES_APPLIED.md

### 4. MotionManager.swift (286 lines)
**Purpose**: CoreMotion integration for device leveling

**Features**:
- Real-time device attitude tracking
- Reference attitude for relative measurements
- Pitch, roll, yaw calculations
- Level angle computation

**Critical Fix**: State corruption bug fixed - now creates copy before mutating CMAttitude

### 5. Logger.swift (131 lines)
**Purpose**: Comprehensive structured logging system

**Categories**:
- Camera (camera operations)
- Motion (device motion)
- Photo (image capture/save)
- Location (GPS tagging)
- UI (user interface events)

**Levels**: debug 🔍, info ℹ️, warning ⚠️, error ❌, critical 🚨

**Usage**:
```swift
Logger.camera("Session started")
Logger.photo("Saving image with EV +2.0")
Logger.error("Failed to configure device", category: .camera)
```

### 6. DeviceGating.swift (261 lines)
**Purpose**: Enforce device compatibility requirements

**Features**:
- Device model detection via uname()
- iOS version checking
- Simulator detection
- Informative compatibility messages

**Requirements**:
- iPhone 17 Pro Max (identifier: "iPhone17,1")
- iOS 26.0+
- Allows simulators in debug builds

### 7. HapticManager.swift (351 lines)
**Purpose**: Advanced haptic feedback system

**Features**:
- CoreHaptics engine management
- Custom haptic patterns
- Event-based haptics (button tap, mode change, capture, etc.)
- Engine lifecycle management

**Pattern Examples**:
- Shutter click: Sharp impact
- Mode change: Soft impact with light feedback
- Grid type change: Medium impact
- Error: Heavy impact with decay

### 8. ModernDesignSystem.swift (304 lines)
**Purpose**: Centralized design tokens and styling

**Provides**:
- Typography system
- Spacing constants
- Color definitions
- Shadow styles
- Animation curves
- Glass morphism effects
- iOS-native button styles

---

## Development Workflow

### Building & Running

**Xcode Setup**:
1. Open `Bracketer.xcodeproj` in Xcode
2. Select iPhone 17 Pro Max simulator (or real device)
3. Build and run (Cmd+R)

**Build Configurations**:
- **Debug**: Full debugging, no optimization, DEBUG=1 flag
- **Release**: Whole module optimization, stripped binaries

### Git Workflow

**Current Branch**: `claude/claude-md-mhy0gmiucgw2vzde-01LdKvTHiFPGpxWrmEFztXCX`

**Recent Branches**:
- `claude/pro-controls-redesign-01B7Dt5tYsuDnnX9BgSBJBLc` - Pro Controls redesign
- `claude/fix-unreachable-code-devicegating-011QurZ497UFVcNS1G6p5TNB` - DeviceGating fixes

**Commit Guidelines**:
- Use descriptive commit messages
- Reference bug numbers when fixing issues
- Include context in commit body

### Debugging

**Console Logging**:
```swift
// Structured logging with os.log
Logger.camera("Session started", level: .info)
Logger.error("Capture failed: \(error)")
```

**Xcode Instruments**:
- Memory Graph Debugger - Check for retain cycles
- Leaks - Monitor memory leaks
- Time Profiler - Performance analysis

**Common Issues**:
- NotificationCenter observer leaks (FIXED)
- Timer accumulation (FIXED)
- State mutation bugs (FIXED)
- Async photo save issues (FIXED)

---

## Coding Conventions

### Naming Conventions

**Files**: PascalCase
- ✅ `CameraController.swift`
- ✅ `ModernContentView.swift`

**Types**: PascalCase
- ✅ `class CameraController`
- ✅ `struct ShootingMode`
- ✅ `enum GridType`

**Properties/Methods**: lowerCamelCase
- ✅ `currentISO`
- ✅ `func captureRawBracket(evStep:)`

**Constants**: lowerCamelCase or UPPER_SNAKE_CASE for globals
- ✅ `let maxExposureDuration`

### Code Organization

**MARK Comments**: Organize code into logical sections
```swift
// MARK: - Camera Session Management
// MARK: - Exposure Controls
// MARK: - Photo Capture
// MARK: - Private Helpers
```

**Access Control**:
- Default to `private` or `fileprivate`
- Use `public` only when necessary
- `final` class unless inheritance needed

**Extensions**:
```swift
// Protocol conformance in extensions
extension CameraController: AVCapturePhotoCaptureDelegate {
    // ...
}
```

### Swift Best Practices

**1. Memory Management**:
```swift
// Use weak self to prevent retain cycles
sessionQueue.async { [weak self] in
    guard let self = self else { return }
    // ...
}

// Timer invalidation in deinit
deinit {
    exposureUpdateTimer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

**2. Error Handling**:
```swift
// DO NOT use empty catch blocks
do {
    try device.lockForConfiguration()
} catch {
    Logger.error("Configuration failed: \(error)")
}
```

**3. State Mutation**:
```swift
// Create copies before mutating reference types
guard let current = currentAttitude?.copy() as? CMAttitude else { return }
current.multiply(byInverseOf: reference)  // Safe - operating on copy
```

**4. Async Task Cancellation**:
```swift
// Use DispatchWorkItem for cancellable tasks
private var toastHideTask: DispatchWorkItem?

toastHideTask?.cancel()
let task = DispatchWorkItem {
    // Animation code
}
toastHideTask = task
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: task)
```

**5. Thread Safety**:
```swift
// UI updates on main queue
DispatchQueue.main.async {
    self.updateExposureUI()
}

// Camera operations on session queue
sessionQueue.async {
    self.session.startRunning()
}
```

### SwiftUI Conventions

**Property Wrappers**:
- `@State` - View-local mutable state
- `@StateObject` - Observable object lifecycle tied to view
- `@ObservedObject` - Observable object owned elsewhere
- `@EnvironmentObject` - Shared environment state
- `@Published` - Observable object property changes

**View Composition**:
```swift
var body: some View {
    ZStack {
        cameraPreviewLayer
        overlayViews
        controlPanel
    }
}

private var cameraPreviewLayer: some View {
    // Extracted view
}
```

---

## Testing

### Test Infrastructure

**Unit Tests** (`BracketerTests/`)
- Framework: Swift Testing (modern approach with `@Test` attribute)
- Location: `/home/user/Bracketer/BracketerTests/BracketerTests.swift`
- Status: Scaffolding only - ready for implementation
- Import: `@testable import Bracketer`

**UI Tests** (`BracketerUITests/`)
- Framework: XCTest + XCUITest
- Features:
  - Launch performance measurement (`XCTApplicationLaunchMetric`)
  - Setup/teardown infrastructure
  - `@MainActor` annotations
- Status: Basic scaffolding in place

### Testing Recommendations

**Critical Functionality**:
1. Bracket capture - verify images saved and appear in viewer
2. Memory leaks - rotate device rapidly, check memory usage
3. Level indicator - test accuracy after multiple calls
4. Timer cleanup - verify no accumulation on restart

**UI Behavior**:
5. Mode switching - rapid mode changes, verify toast animations
6. Orientation changes - rotate device during camera use
7. Preview lifecycle - navigate away and back to camera

**Edge Cases**:
8. Long exposure settling - test in extreme lighting
9. Rapid bracket captures - multiple quick captures
10. Resource cleanup - force quit and restart

---

## Known Issues & Bug Tracking

### Bug Documentation Files

**BUG_REPORT.md** (Comprehensive analysis)
- 14 bugs identified (as of 2025-11-12)
- Severity levels: Critical, High, Medium, Low
- Detailed descriptions with code examples
- Impact analysis and fix recommendations

**FIXES_APPLIED.md** (Applied fixes)
- 8 bugs fixed (4 critical, 1 high, 2 medium, 1 low)
- Detailed before/after code comparisons
- Testing recommendations
- 6 remaining low-priority issues

### Critical Bugs FIXED

1. ✅ **PhotoSaver async issue** - DispatchSemaphore added for synchronous asset ID return
2. ✅ **NotificationCenter memory leak** - Coordinator pattern implemented with proper cleanup
3. ✅ **MotionManager state corruption** - CMAttitude copy created before mutation
4. ✅ **Timer resource leak** - Timer invalidation before creating new instance
5. ✅ **Weak self in recursive closure** - Proper guard statements added
6. ✅ **Duplicate import** - Removed duplicate SwiftUI import
7. ✅ **Uncancelled async tasks** - DispatchWorkItem used for cancellable operations
8. ✅ **Silent error handling** - Logger calls added to catch blocks

### Remaining Issues

**Medium-High** (#5): Force cast in PreviewView - Safe due to layerClass override but could add safety comment

**Medium** (#7): Haptic engine handling - Likely correct, needs verification

**Low-Medium** (#10): Date() in view body - Animation bug requiring Timer publisher

**Low** (#11): Thread safety - sessionQueue access pattern (unlikely in practice)

**Very Low** (#12): Combine cancellation - Auto-handled but explicit cleanup recommended

**Very Low** (#14): Golden spiral math - Cosmetic issue, not mathematically accurate

---

## Device Requirements

### Hardware Requirements

**Exclusive Device**: iPhone 17 Pro Max
- **Model Identifier**: "iPhone17,1"
- **Reason**: 48MP sensor, ProRAW capabilities, advanced camera system

**Development Exception**: Simulators allowed (`#if targetEnvironment(simulator)`)

### Software Requirements

**iOS Version**: 26.0+
- Required for latest camera APIs
- Computational photography features
- Advanced AVFoundation capabilities

**Permissions Required**:
- `NSCameraUsageDescription`: "I need the camera to capture bracketed photos."
- `NSPhotoLibraryAddUsageDescription`: "I need to save the photos to your library."
- `NSLocationWhenInUseUsageDescription`: "I need to geotag your photos"

### Compatibility Gating

`DeviceGating.swift` enforces requirements:
- Checks device model via `uname()`
- Compares iOS version strings
- Displays informative error messages
- Allows development in simulator

---

## Important Notes for AI Assistants

### Critical Guidelines

**1. Thread Safety is Paramount**
- Camera operations MUST run on `sessionQueue`
- UI updates MUST run on main queue
- Always use `[weak self]` in async closures
- Check for nil after weak capture: `guard let self = self else { return }`

**2. Memory Management**
- Invalidate timers in deinit
- Remove NotificationCenter observers
- Cancel async tasks when view disappears
- Use Coordinator pattern for UIViewRepresentable lifecycle

**3. State Mutation**
- NEVER mutate @Published reference types in-place
- Create copies before mutation (e.g., CMAttitude)
- Use value types (structs) when possible

**4. Error Handling**
- NO empty catch blocks: `} catch { }`
- Always log errors with Logger
- Provide context in error messages

**5. Logging**
- Use structured logging via Logger.swift
- Choose appropriate category (camera, motion, photo, location, ui)
- Include relevant context in messages
- Use appropriate log levels

### Common Patterns to Follow

**Camera Configuration**:
```swift
sessionQueue.async { [weak self] in
    guard let self = self else { return }
    do {
        try self.device?.lockForConfiguration()
        // Configuration code
        self.device?.unlockForConfiguration()
    } catch {
        Logger.camera("Configuration failed: \(error)")
    }
}
```

**UI State Updates**:
```swift
DispatchQueue.main.async {
    self.isCapturing = false
    self.captureProgress = 1.0
}
```

**Cancellable Delayed Tasks**:
```swift
private var delayedTask: DispatchWorkItem?

func scheduleTask() {
    delayedTask?.cancel()
    let task = DispatchWorkItem {
        // Task code
    }
    delayedTask = task
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
}
```

### What NOT to Do

❌ Empty catch blocks
❌ Mutating @Published reference types
❌ Force unwrapping without safety checks
❌ Uncancellable delayed tasks
❌ Missing observer cleanup
❌ Missing timer invalidation
❌ Synchronous photo saves without semaphore
❌ UI updates on background queue
❌ Camera operations on main queue

### When Making Changes

**Before Modifying Code**:
1. Read the relevant file(s) completely
2. Understand the threading model
3. Check for memory management concerns
4. Review related bugs in BUG_REPORT.md and FIXES_APPLIED.md

**After Making Changes**:
1. Verify thread safety (main queue vs sessionQueue)
2. Check for memory leaks (observers, timers, retain cycles)
3. Add appropriate logging
4. Update relevant documentation
5. Test critical functionality

**For New Features**:
1. Follow existing patterns (MVVM, Coordinator, Singleton)
2. Use ModernDesignSystem for UI styling
3. Add structured logging
4. Consider memory management from the start
5. Write thread-safe code

### Code Review Checklist

- [ ] Thread safety verified (correct queue usage)
- [ ] Memory leaks prevented (observers removed, timers invalidated)
- [ ] Error handling implemented (no empty catches)
- [ ] Logging added for debugging
- [ ] State mutation handled correctly (copies created)
- [ ] Async tasks are cancellable
- [ ] Weak self used in closures
- [ ] Nil checks after weak capture
- [ ] SwiftUI best practices followed
- [ ] Consistent with existing code style

---

## Additional Resources

### Documentation Files
- **BUG_REPORT.md** - Comprehensive bug analysis with 14 identified issues
- **FIXES_APPLIED.md** - Documentation of 8 fixed bugs with code examples
- **CLAUDE.md** - This file

### Apple Documentation
- [AVFoundation Programming Guide](https://developer.apple.com/documentation/avfoundation)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [CoreMotion Framework](https://developer.apple.com/documentation/coremotion)
- [PhotoKit Framework](https://developer.apple.com/documentation/photokit)
- [CoreHaptics Framework](https://developer.apple.com/documentation/corehaptics)

### Project Statistics
- **Total Lines of Code**: ~8,300
- **Number of Swift Files**: 25
- **Largest File**: ModernContentView.swift (1,052 lines)
- **External Dependencies**: 0 (Pure Swift + Apple frameworks)
- **Bugs Fixed**: 8/14 (All critical issues resolved)
- **Test Coverage**: Infrastructure ready, implementation pending

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-13 | 1.0 | Initial CLAUDE.md creation |
| 2025-11-12 | - | 8 critical/high-priority bugs fixed |
| 2025-11-12 | - | Pro Controls redesign completed |

---

**End of CLAUDE.md**

For questions or clarifications about this codebase, refer to the comprehensive bug tracking in BUG_REPORT.md and FIXES_APPLIED.md, or examine the inline documentation in the source files.
