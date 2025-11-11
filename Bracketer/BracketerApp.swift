// BracketerApp.swift
// Main entry point for the Bracketer app.

import SwiftUI

@main
struct BracketerApp: App {
    @StateObject private var orientationManager = OrientationManager()

    init() {
        // Lock app to portrait orientation (like Apple Camera app)
        // UI elements will rotate, but the app stays portrait
        AppDelegate.orientationLock = .portrait
    }

    var body: some Scene {
        WindowGroup {
            ModernContentView()
                .environmentObject(orientationManager)
                .onAppear {
                    // Ensure orientation lock is applied
                    AppDelegate.orientationLock = .portrait
                }
        }
    }
}

// MARK: - App Delegate for Orientation Locking

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
