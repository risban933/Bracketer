// Logger.swift
// Logging utility for the Bracketer app.

import Foundation
import os.log
import UIKit

/// Comprehensive logging system for Bracketer app debugging
final class Logger {
    
    // MARK: - Log Categories
    
    private static let cameraLog = OSLog(subsystem: "com.bracketer.app", category: "Camera")
    private static let motionLog = OSLog(subsystem: "com.bracketer.app", category: "Motion")
    private static let photoLog = OSLog(subsystem: "com.bracketer.app", category: "Photo")
    private static let locationLog = OSLog(subsystem: "com.bracketer.app", category: "Location")
    private static let uiLog = OSLog(subsystem: "com.bracketer.app", category: "UI")
    
    // MARK: - Log Levels
    
    enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
        case critical = "🚨"
    }
    
    // MARK: - Public Methods
    
    static func debug(_ message: String, category: OSLog = cameraLog, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: OSLog = cameraLog, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: OSLog = cameraLog, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: OSLog = cameraLog, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, category: OSLog = cameraLog, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Camera-specific Logging
    
    static func camera(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: cameraLog, file: file, function: function, line: line)
    }
    
    static func motion(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: motionLog, file: file, function: function, line: line)
    }
    
    static func photo(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: photoLog, file: file, function: function, line: line)
    }
    
    static func location(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: locationLog, file: file, function: function, line: line)
    }
    
    static func ui(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: uiLog, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private static func log(_ message: String, level: Level, category: OSLog, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(level.rawValue) [\(fileName):\(line)] \(function): \(message)"
        
        switch level {
        case .debug:
            os_log(.debug, log: category, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: category, "%{public}@", logMessage)
        case .warning:
            os_log(.default, log: category, "%{public}@", logMessage)
        case .error:
            os_log(.error, log: category, "%{public}@", logMessage)
        case .critical:
            os_log(.fault, log: category, "%{public}@", logMessage)
        }
        
        #if DEBUG
        print(logMessage)
        #endif
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log camera session state changes
    static func cameraSession(_ state: String, additionalInfo: String? = nil) {
        let message = "Camera session: \(state)"
        if let info = additionalInfo {
            camera("\(message) - \(info)")
        } else {
            camera(message)
        }
    }
    
    /// Log camera switching events
    static func cameraSwitch(from: CameraKind, to: CameraKind) {
        camera("Switching camera from \(from.label) to \(to.label)")
    }
    
    /// Log photo capture events
    static func photoCapture(evStep: Float, isProRAW: Bool) {
        photo("Starting bracket capture: EV step \(evStep), ProRAW: \(isProRAW)")
    }
    
    /// Log motion updates
    static func motionUpdate(angle: Double, orientation: UIInterfaceOrientation) {
        motion("Motion update: angle \(String(format: "%.2f", angle))°, orientation: \(orientation)")
    }
    
    /// Log permission requests
    static func permissionRequest(_ permission: String, granted: Bool) {
        let status = granted ? "granted" : "denied"
        camera("Permission \(permission): \(status)")
    }
}
