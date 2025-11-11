// BracketerApp.swift
// Main entry point for the Bracketer app.

import SwiftUI

@main
struct BracketerApp: App {
    @StateObject private var orientationManager = OrientationManager()

    init() {
        // Support all orientations - camera preview will auto-rotate
        AppDelegate.orientationLock = .all
    }

    var body: some Scene {
        WindowGroup {
            ModernContentView()
                .environmentObject(orientationManager)
                .onAppear {
                    // Support all orientations for camera
                    AppDelegate.orientationLock = .all
                }
        }
    }
}

// MARK: - App Delegate for Orientation Support

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
