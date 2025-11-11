import Foundation
import SwiftUI
import AVFoundation
import CoreMedia
import Photos
import CoreLocation
import UIKit
import UserNotifications
import CoreHaptics

private enum Constants {
    static let defaultEVStep: Float = 1.0
    static let preferredTimescale: CMTimeScale = 1_000_000
    static let sessionQueueLabel = "bracketer.session.queue"
    static let aeSettleMaxWait: TimeInterval = 2.0
    static let aeSettlePollInterval: TimeInterval = 0.02
    static let aeOffsetThreshold: Float = 0.10
}

enum CameraKind: CaseIterable, Identifiable {
    case ultraWide, wide, telephoto, twoX, eightX
    var id: String { label }
    var label: String {
        switch self {
        case .ultraWide: return "0.5×"
        case .wide: return "1×"
        case .twoX: return "2×"
        case .telephoto: return "4×"
        case .eightX: return "8×"
        }
    }
    var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .ultraWide: return .builtInUltraWideCamera
        case .wide, .twoX: return .builtInWideAngleCamera
        case .telephoto, .eightX: return .builtInTelephotoCamera
        }
    }
}

struct CamError: Identifiable {
    let id = UUID()
    let message: String
    let isRecoverable: Bool
    init(message: String, isRecoverable: Bool = true) {
        self.message = message
        self.isRecoverable = isRecoverable
    }
}

final class CameraController: NSObject, ObservableObject, @unchecked Sendable {
    @Published var lastError: CamError?
    @Published var isProRAWEnabled: Bool = false
    @Published var selectedCamera: CameraKind = .wide
    @Published var currentUIOrientation: UIInterfaceOrientation = .portrait
    @Published var isInitializing: Bool = false
    @Published var isCapturing: Bool = false
    @Published var captureProgress: Int = 0
    @Published var currentISO: Float = 100.0
    @Published var currentShutterSpeedText: String = "1/60"
    @Published var lastBracketAssets: [PHAsset] = []
    @Published var showImageViewer = false

    @Published var teleUses12MP: Bool = false

    // Bracketing configuration
    private var plannedEVs: [Float] = []

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: Constants.sessionQueueLabel)
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private weak var previewLayer: AVCaptureVideoPreviewLayer?

    private var baseWBGains = AVCaptureDevice.WhiteBalanceGains(redGain: 1, greenGain: 1, blueGain: 1)
    private var baseISO: Float = 100.0
    private var baseShutterSpeed: CMTime = CMTime(value: 1, timescale: 100)
    private var baseFocusPosition: Float = 0.0

    private var sequenceInFlight: Bool = false
    private var sequenceEVStep: Float = Constants.defaultEVStep
    private var sequenceStep: Int = 0
    private var sequenceTimestamp: Int?
    private var bracketAssetIds: [String] = []
    private var rawPixelFormat: OSType?
    private var maxPhotoDims: CMVideoDimensions?

    private let locationProvider = LocationProvider()
    private var orientationObserver: NSObjectProtocol?
    private var exposureUpdateTimer: Timer?

    override init() {
        super.init()
        setupOrientationObserver()
    }

    deinit {
        cleanupOrientationObserver()
        exposureUpdateTimer?.invalidate()
    }

    private func setupOrientationObserver() {
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleOrientationChange()
        }
    }

    private func cleanupOrientationObserver() {
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
            orientationObserver = nil
        }
    }

    func attachPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        sessionQueue.async {
            self.previewLayer = layer
            layer.videoGravity = .resizeAspectFill
            // Do not rotate the preview layer; keep it visually fixed.
            // self.applyRotation(to: layer.connection) // removed
            self.applyRotation(to: self.photoOutput.connection(with: .video))
        }
    }

    func start() async {
        main { self.isInitializing = true }
        do {
            try await requestPermissions()
        } catch {
            main {
                self.lastError = CamError(message: "Permissions: \(error.localizedDescription)", isRecoverable: false)
                self.isInitializing = false
            }
            return
        }

        await configureSession(initialKind: selectedCamera)
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
        locationProvider.start()

        main {
            self.updateUIOrientationFromScene()
            self.isInitializing = false
            self.exposureUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateExposureUI()
            }
        }
    }

    private func requestPermissions() async throws {
        let camOK = await AVCaptureDevice.requestAccess(for: .video)
        guard camOK else {
            throw NSError(domain: "Bracketer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Camera access denied"])
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw NSError(domain: "Bracketer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
        }
        locationProvider.requestWhenInUse()
    }

    private func configureSession(initialKind: CameraKind) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.setInput(kind: initialKind)
                self.selectBestPhotoFormat()
                self.configureProRAW()
                self.configureMaxPhotoDimensions()

                self.session.commitConfiguration()
                cont.resume()
            }
        }
        sessionQueue.async {
            // Removed rotation to previewLayer.connection
            // self.applyRotation(to: self.previewLayer?.connection)
            self.applyRotation(to: self.photoOutput.connection(with: .video))
            self.applyZoomForSelectedCamera()
        }
    }

    private func configureMaxPhotoDimensions() {
        let desire48 = CMVideoDimensions(width: 8064, height: 6048)
        let desire12 = CMVideoDimensions(width: 4032, height: 3024)

        if #available(iOS 16.0, *) {
            if let dev = self.device {
                let supported = dev.activeFormat.supportedMaxPhotoDimensions
                let targetDims: CMVideoDimensions
                switch self.selectedCamera {
                case .twoX, .eightX:
                    targetDims = (self.teleUses12MP ? desire12 : desire48)
                default:
                    targetDims = desire48
                }

                if supported.contains(where: { $0.width == targetDims.width && $0.height == targetDims.height }) {
                    self.photoOutput.maxPhotoDimensions = targetDims
                    self.maxPhotoDims = targetDims
                } else if let best = supported.max(by: { ($0.width * $0.height) < ($1.width * $1.height) }) {
                    self.photoOutput.maxPhotoDimensions = best
                    self.maxPhotoDims = best
                }
            }
        }
        self.photoOutput.maxPhotoQualityPrioritization = .quality
    }

    func switchCamera(to kind: CameraKind) {
        guard selectedCamera != kind else { return }
        // Provide haptic feedback for lens switching
        main { HapticManager.shared.lensSwitched() }
        sessionQueue.async {
            self.session.beginConfiguration()
            if let existing = self.input {
                self.session.removeInput(existing)
                self.input = nil
            }
            self.setInput(kind: kind)
            self.selectBestPhotoFormat()
            self.configureProRAW()
            self.configureMaxPhotoDimensions()
            self.session.commitConfiguration()

            // Removed rotation to previewLayer.connection
            // self.applyRotation(to: self.previewLayer?.connection)
            self.applyRotation(to: self.photoOutput.connection(with: .video))
            self.applyZoomForSelectedCamera()
            self.main { self.selectedCamera = kind }
        }
    }

    private func setInput(kind: CameraKind) {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [kind.deviceType],
            mediaType: .video,
            position: .back
        )
        guard let dev = discovery.devices.first else {
            self.postError("Camera not available.")
            return
        }
        self.device = dev
        do {
            let inp = try AVCaptureDeviceInput(device: dev)
            if self.session.canAddInput(inp) {
                self.session.addInput(inp)
                self.input = inp
            }
        } catch {
            self.postError("Camera input error: \(error.localizedDescription)")
        }
    }

    private func selectBestPhotoFormat() {
        guard let dev = self.device else { return }
        if #available(iOS 16.0, *) {
            do {
                try dev.lockForConfiguration()
                defer { dev.unlockForConfiguration() }

                let desire48 = (width: Int32(8064), height: Int32(6048))
                let desire12 = (width: Int32(4032), height: Int32(3024))
                let target = ((self.selectedCamera == .twoX || self.selectedCamera == .eightX) && self.teleUses12MP) ? desire12 : desire48

                // Prefer formats that support the target size and RAW if available
                let preferredFormats = dev.formats.sorted { a, b in
                    let aDims = a.supportedMaxPhotoDimensions
                    let bDims = b.supportedMaxPhotoDimensions
                    let aHasTarget = aDims.contains { $0.width == target.width && $0.height == target.height }
                    let bHasTarget = bDims.contains { $0.width == target.width && $0.height == target.height }
                    if aHasTarget != bHasTarget { return aHasTarget && !bHasTarget }
                    // Fall back to larger total pixel count
                    let aMax = aDims.max(by: { ($0.width * $0.height) < ($1.width * $1.height) })
                    let bMax = bDims.max(by: { ($0.width * $0.height) < ($1.width * $1.height) })
                    let aPixels = Int64((aMax?.width ?? 0) * (aMax?.height ?? 0))
                    let bPixels = Int64((bMax?.width ?? 0) * (bMax?.height ?? 0))
                    return aPixels > bPixels
                }

                for fmt in preferredFormats {
                    dev.activeFormat = fmt
                    // If ProRAW is desired, ensure RAW is available
                    if self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
                        continue
                    }
                    // If we reached here, we found a suitable format
                    break
                }
            } catch {
                self.postError("Format selection failed: \(error.localizedDescription)")
            }
        }
    }

    private func configureProRAW() {
        if self.photoOutput.isAppleProRAWSupported {
            self.photoOutput.isAppleProRAWEnabled = true
            self.main { self.isProRAWEnabled = true }
        } else {
            self.photoOutput.isAppleProRAWEnabled = false
            self.main { self.isProRAWEnabled = false }
        }
        Logger.photo("ProRAW supported: \(self.photoOutput.isAppleProRAWSupported), enabled: \(self.photoOutput.isAppleProRAWEnabled)")
    }

    private func handleOrientationChange() {
        main { self.updateUIOrientationFromScene() }
        sessionQueue.async {
            // Removed rotation to previewLayer.connection
            // self.applyRotation(to: self.previewLayer?.connection)
            self.applyRotation(to: self.photoOutput.connection(with: .video))
        }
    }

    private func updateUIOrientationFromScene() {
        let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation ?? .portrait
        self.currentUIOrientation = orientation
    }

    private func rotationAngle(for io: UIInterfaceOrientation) -> CGFloat {
        switch io {
        case .portrait: return 90
        case .landscapeRight: return 0
        case .landscapeLeft: return 180
        case .portraitUpsideDown: return 270
        default: return 90
        }
    }

    private func applyRotation(to connection: AVCaptureConnection?) {
        guard let conn = connection else { return }
        let angle = rotationAngle(for: currentUIOrientation)
        if conn.isVideoRotationAngleSupported(angle) {
            conn.videoRotationAngle = angle
        }
        if conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = false
        }
    }

    private func applyZoomForSelectedCamera() {
        guard let dev = self.device else { return }
        do {
            try dev.lockForConfiguration()
            switch self.selectedCamera {
            case .twoX:
                dev.videoZoomFactor = min(max(2.0, dev.minAvailableVideoZoomFactor), dev.maxAvailableVideoZoomFactor)
            case .eightX:
                // Base telephoto is 4x; apply an extra 2x digital zoom to reach 8x
                dev.videoZoomFactor = min(max(2.0, dev.minAvailableVideoZoomFactor), dev.maxAvailableVideoZoomFactor)
            default:
                dev.videoZoomFactor = 1.0
            }
            dev.unlockForConfiguration()
        } catch {
            self.postError("Zoom configuration failed: \(error.localizedDescription)")
        }
    }

    func toggleProRAW() {
        sessionQueue.async {
            guard self.photoOutput.isAppleProRAWSupported else { return }
            self.photoOutput.isAppleProRAWEnabled.toggle()
            self.main { self.isProRAWEnabled = self.photoOutput.isAppleProRAWEnabled }
            Logger.photo("ProRAW supported: \(self.photoOutput.isAppleProRAWSupported), enabled: \(self.photoOutput.isAppleProRAWEnabled)")
        }
    }

    func captureLockdownBracket(evStep: Float = Constants.defaultEVStep, shotCount: Int = 3) {
        guard !isCapturing && !sequenceInFlight else { return }
        sessionQueue.async {
            guard let dev = self.device else {
                self.postError("Camera device not available")
                return
            }

            // Enforce fixed 4-shot bracket plan ignoring arguments
            self.sequenceEVStep = 1.0
            self.plannedEVs = [0, 0, +1, -1]

            self.sequenceInFlight = true
            self.sequenceStep = 0
            self.sequenceTimestamp = Int(Date().timeIntervalSince1970)
            self.rawPixelFormat = self.chooseRawPixelFormat()
            guard self.rawPixelFormat != nil else {
                self.sequenceInFlight = false
                self.postError("No RAW format available.")
                return
            }

            // Prepare device for auto to measure baseline (no capture)
            do {
                try dev.lockForConfiguration()
                if dev.isExposureModeSupported(.continuousAutoExposure) {
                    dev.exposureMode = .continuousAutoExposure
                }
                if dev.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    dev.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                if dev.isFocusModeSupported(.continuousAutoFocus) {
                    dev.focusMode = .continuousAutoFocus
                }
                dev.setExposureTargetBias(0, completionHandler: nil)
                dev.unlockForConfiguration()
            } catch {
                self.postError("Auto baseline failed: \(error.localizedDescription)")
                self.finishSequence()
                return
            }

            self.settleAutoExposure { [weak self] in
                guard let self = self else { return }
                self.applyRotation(to: self.photoOutput.connection(with: .video))
                self.main {
                    self.isCapturing = true
                    self.captureProgress = 0
                    HapticManager.shared.captureStarted()
                }
                // Read baseline without capturing
                self.extractBaselineFromDevice()
                // Proceed to first shot (0 EV)
                self.proceedToNextShot()
            }
        }
    }

    private func settleAutoExposure(timeout: TimeInterval = Constants.aeSettleMaxWait, poll: TimeInterval = Constants.aeSettlePollInterval, threshold: Float = Constants.aeOffsetThreshold, completion: @escaping () -> Void) {
        let start = CACurrentMediaTime()
        func check() {
            if let off = self.device?.exposureTargetOffset, abs(off) <= threshold {
                completion()
                return
            }
            if CACurrentMediaTime() - start >= timeout {
                completion() // timeout, proceed with best effort
                return
            }
            self.sessionQueue.asyncAfter(deadline: .now() + poll) {
                check()
            }
        }
        self.sessionQueue.async { check() }
    }

    private func buildBracketPlan(evStep: Float, shotCount: Int) -> [Float] {
        // Always include baseline 0 EV
        if shotCount >= 5 {
            return [0, +evStep, -evStep, +(2*evStep), -(2*evStep)]
        } else {
            return [0, +evStep, -evStep]
        }
    }

    private func extractBaselineFromDevice() {
        guard let dev = self.device else { return }
        self.baseWBGains = dev.deviceWhiteBalanceGains
        self.baseISO = dev.iso
        self.baseShutterSpeed = dev.exposureDuration
        self.baseFocusPosition = dev.lensPosition
    }

    private func captureManualAutoAtZeroEV() {
        guard let dev = self.device, let rawFmt = self.rawPixelFormat else { return }
        // Perform a short AE settle with a small positive bias to obtain a distinct shutter time while keeping ISO fixed at baseISO for capture
        do {
            try dev.lockForConfiguration()
            if dev.isExposureModeSupported(.continuousAutoExposure) {
                dev.exposureMode = .continuousAutoExposure
            }
            // Small target bias to differentiate from baseline AE
            dev.setExposureTargetBias(0.3, completionHandler: nil)
            dev.unlockForConfiguration()
        } catch {
            self.postError("Manual auto setup failed: \(error.localizedDescription)")
            self.finishSequence()
            return
        }

        self.settleAutoExposure { [weak self] in
            guard let self = self, let dev = self.device else { return }
            let s1 = dev.exposureDuration // read AE-computed shutter
            // Lock and capture using baseISO and AE-computed shutter
            do {
                try dev.lockForConfiguration()
                if dev.isExposureModeSupported(.custom) {
                    dev.exposureMode = .custom
                    dev.setExposureModeCustom(duration: s1, iso: self.baseISO) { _ in
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                            let settings = AVCapturePhotoSettings(rawPixelFormatType: rawFmt)
                            if #available(iOS 16.0, *), let dims = self.maxPhotoDims {
                                settings.maxPhotoDimensions = dims
                            }
                            settings.flashMode = .off
                            self.photoOutput.capturePhoto(with: settings, delegate: self)
                        }
                    }
                }
                if dev.isWhiteBalanceModeSupported(.locked) {
                    let clamped = self.clampWBGains(self.baseWBGains, for: dev)
                    dev.setWhiteBalanceModeLocked(with: clamped, completionHandler: nil)
                }
                if dev.isFocusModeSupported(.locked) {
                    dev.setFocusModeLocked(lensPosition: self.baseFocusPosition, completionHandler: nil)
                }
                // Reset bias for subsequent shots
                dev.setExposureTargetBias(0.0, completionHandler: nil)
                dev.unlockForConfiguration()
            } catch {
                self.postError("Manual auto capture failed: \(error.localizedDescription)")
                self.finishSequence()
                return
            }
        }
    }

    private func captureWithLockedSettings() {
        guard let dev = self.device, let rawFmt = self.rawPixelFormat else { return }

        do {
            try dev.lockForConfiguration()
            if dev.isExposureModeSupported(.custom) {
                dev.exposureMode = .custom
                dev.setExposureModeCustom(duration: baseShutterSpeed, iso: baseISO) { _ in
                    // exposure applied
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                        let settings = AVCapturePhotoSettings(rawPixelFormatType: rawFmt)
                        if #available(iOS 16.0, *), let dims = self.maxPhotoDims {
                            settings.maxPhotoDimensions = dims
                        }
                        settings.flashMode = .off
                        self.photoOutput.capturePhoto(with: settings, delegate: self)
                    }
                }
            }
            if dev.isWhiteBalanceModeSupported(.locked) {
                let clamped = self.clampWBGains(self.baseWBGains, for: dev)
                dev.setWhiteBalanceModeLocked(with: clamped, completionHandler: nil)
            }
            if dev.isFocusModeSupported(.locked) {
                dev.setFocusModeLocked(lensPosition: baseFocusPosition, completionHandler: nil)
            }
            dev.unlockForConfiguration()
        } catch {
            self.postError("Manual lock failed: \(error.localizedDescription)")
            self.finishSequence()
            return
        }
    }

    private func captureWithEVAdjustment(evOffset: Float) {
        guard let dev = self.device, let rawFmt = self.rawPixelFormat else { return }

        do {
            try dev.lockForConfiguration()

            let minDuration = CMTimeGetSeconds(dev.activeFormat.minExposureDuration)
            let maxDuration = CMTimeGetSeconds(dev.activeFormat.maxExposureDuration)

            let currentDuration = CMTimeGetSeconds(baseShutterSpeed)
            let exposureMultiplier = pow(2.0, Double(evOffset))
            let targetDuration = currentDuration * exposureMultiplier
            let clampedDuration = min(max(targetDuration, minDuration), maxDuration)

            let newShutterSpeed = CMTime(seconds: clampedDuration, preferredTimescale: Constants.preferredTimescale)

            if dev.isExposureModeSupported(.custom) {
                dev.exposureMode = .custom
                dev.setExposureModeCustom(duration: newShutterSpeed, iso: self.baseISO) { _ in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                        let settings = AVCapturePhotoSettings(rawPixelFormatType: rawFmt)
                        if #available(iOS 16.0, *), let dims = self.maxPhotoDims {
                            settings.maxPhotoDimensions = dims
                        }
                        settings.flashMode = .off
                        self.photoOutput.capturePhoto(with: settings, delegate: self)
                    }
                }
            }

            if dev.isWhiteBalanceModeSupported(.locked) {
                let clamped = self.clampWBGains(self.baseWBGains, for: dev)
                dev.setWhiteBalanceModeLocked(with: clamped, completionHandler: nil)
            }

            if dev.isFocusModeSupported(.locked) {
                dev.setFocusModeLocked(lensPosition: baseFocusPosition, completionHandler: nil)
            }

            dev.unlockForConfiguration()
        } catch {
            self.postError("EV adjustment failed: \(error.localizedDescription)")
            self.finishSequence()
            return
        }
    }

    private func extractBaselineMetadata() {
        guard let dev = self.device else { return }
        self.baseWBGains = dev.deviceWhiteBalanceGains
        self.baseISO = dev.iso
        self.baseShutterSpeed = dev.exposureDuration
        self.baseFocusPosition = dev.lensPosition
    }

    private func proceedToNextShot() {
        guard sequenceStep < plannedEVs.count else {
            self.main {
                self.captureProgress = 4
                HapticManager.shared.captureCompleted()
            }
            self.finishSequence()
            return
        }

        let ev = plannedEVs[sequenceStep]
        // Update UI progress (0: baseline, 1..)
        self.main {
            switch self.sequenceStep {
            case 0: self.captureProgress = 1; Logger.camera("Bracket: Baseline shot (0 EV)")
            case 1: self.captureProgress = 2; HapticManager.shared.bracketShotCaptured(); Logger.camera("Bracket: Manual auto (0 EV)")
            case 2: self.captureProgress = 3; HapticManager.shared.bracketShotCaptured(); Logger.camera("Bracket: +1EV shot")
            case 3: self.captureProgress = 4; HapticManager.shared.bracketShotCaptured(); Logger.camera("Bracket: -1EV shot")
            default: break
            }
        }

        if ev == 0 {
            if self.sequenceStep == 0 {
                self.captureWithLockedSettings()
            } else {
                self.captureManualAutoAtZeroEV()
            }
        } else {
            self.captureWithEVAdjustment(evOffset: ev)
        }
    }

    private func finishSequence() {
        if let dev = self.device {
            do {
                try dev.lockForConfiguration()
                if dev.isExposureModeSupported(.continuousAutoExposure) {
                    dev.exposureMode = .continuousAutoExposure
                }
                if dev.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    dev.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                if dev.isFocusModeSupported(.continuousAutoFocus) {
                    dev.focusMode = .continuousAutoFocus
                }
                dev.setExposureTargetBias(0, completionHandler: nil)
                dev.unlockForConfiguration()
            } catch {}
        }

        self.plannedEVs.removeAll()

        // Fetch the bracketed assets for the image viewer
        fetchBracketAssets()

        self.sequenceInFlight = false
        self.rawPixelFormat = nil
        self.sequenceTimestamp = nil

        main {
            self.isCapturing = false
            self.captureProgress = 0
        }
    }

    private func fetchBracketAssets() {
        let ids = self.bracketAssetIds
        guard !ids.isEmpty else { return }

        let fetchOptions = PHFetchOptions()
        let assetsResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: fetchOptions)

        // Build a map for quick lookup
        var map: [String: PHAsset] = [:]
        assetsResult.enumerateObjects { (asset, _, _) in
            map[asset.localIdentifier] = asset
        }

        var ordered: [PHAsset] = []
        for id in ids {
            if let a = map[id] { ordered.append(a) }
        }

        main {
            self.lastBracketAssets = ordered
            self.showImageViewer = true
        }

        self.bracketAssetIds.removeAll()
    }

    private func clampWBGains(_ g: AVCaptureDevice.WhiteBalanceGains, for dev: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let clamp: (Float) -> Float = { max(1.0, min(dev.maxWhiteBalanceGain, $0)) }
        return .init(redGain: clamp(g.redGain), greenGain: clamp(g.greenGain), blueGain: clamp(g.blueGain))
    }

    private func chooseRawPixelFormat() -> OSType? {
        let raw = photoOutput.availableRawPhotoPixelFormatTypes
        if photoOutput.isAppleProRAWEnabled {
            if let t = raw.first(where: { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) }) { return t }
        }
        if let t = raw.first(where: { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }) { return t }
        return raw.first
    }

    private func postError(_ message: String) {
        main { self.lastError = CamError(message: message) }
    }

    @inline(__always) private func main(_ body: @escaping () -> Void) {
        if Thread.isMainThread { body() } else { DispatchQueue.main.async(execute: body) }
    }
    
    private func updateExposureUI() {
        guard let dev = self.device else { return }
        let iso = dev.iso
        let duration = CMTimeGetSeconds(dev.exposureDuration)
        let shutterText = formatShutterSpeed(duration)
        
        main {
            self.currentISO = iso
            self.currentShutterSpeedText = shutterText
        }
    }
    
    private func formatShutterSpeed(_ duration: Double) -> String {
        if duration >= 1.0 {
            return String(format: "%.1fs", duration)
        } else {
            let fraction = 1.0 / duration
            if fraction < 10 {
                return String(format: "1/%.1f", fraction)
            } else {
                return String(format: "1/%.0f", fraction)
            }
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            postError("Capture error: \(error.localizedDescription)")
            return
        }
        guard let data = photo.fileDataRepresentation() else { return }
        let loc = locationProvider.latestLocation

        if sequenceStep == 0 {
            if let exif = photo.metadata["{Exif}"] as? [String: Any],
               let isoArray = exif["ISOSpeedRatings"] as? [NSNumber],
               let iso = isoArray.first?.floatValue,
               let expTime = exif["ExposureTime"] as? Double {
                sessionQueue.async {
                    self.baseISO = iso
                    self.baseShutterSpeed = CMTime(seconds: expTime, preferredTimescale: Constants.preferredTimescale)
                }
            }
        }

        if photo.isRawPhoto {
            let bracketLabel: String?
            if self.sequenceStep < self.plannedEVs.count {
                let ev = self.plannedEVs[self.sequenceStep]
                if ev == 0 {
                    bracketLabel = "0EV"
                } else {
                    bracketLabel = ev > 0 ? "+\(Int(ev))EV" : "\(Int(ev))EV"
                }
            } else {
                bracketLabel = nil
            }

            let assetId = PhotoSaver.saveRAW(data: data,
                                           suggestedFilename: "Bracket-\(self.sequenceTimestamp ?? Int(Date().timeIntervalSince1970)).dng",
                                           location: loc,
                                           bracketLabel: bracketLabel)
            if let assetId = assetId {
                self.bracketAssetIds.append(assetId)
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error {
            postError("Finish error: \(error.localizedDescription)")
        }
        sessionQueue.async {
            self.proceedToNextShot()
        }
    }
}

enum PhotoSaver {
    static func saveRAW(data: Data, suggestedFilename: String, location: CLLocation?, bracketLabel: String? = nil) -> String? {
        let timestamp: String
        if let range = suggestedFilename.range(of: #"\d+"#, options: .regularExpression),
           let extracted = Int(suggestedFilename[range]) {
            timestamp = String(extracted)
        } else {
            timestamp = String(Int(Date().timeIntervalSince1970))
        }

        let filename = bracketLabel != nil ? "Bracket-\(bracketLabel!)-\(timestamp).dng" : "Bracket-\(timestamp).dng"

        var assetIdentifier: String?

        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            req.location = location
            req.creationDate = Date()
            let opts = PHAssetResourceCreationOptions()
            opts.originalFilename = filename
            req.addResource(with: .photo, data: data, options: opts)
            assetIdentifier = req.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler: { success, error in
            if !success {
                print("Failed to save photo: \(error?.localizedDescription ?? "Unknown error")")
            }
        })

        return assetIdentifier
    }
}

final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var latestLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestWhenInUse() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func start() { manager.startUpdatingLocation() }
    func stop() { manager.stopUpdatingLocation() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocation = locations.last
    }
}
