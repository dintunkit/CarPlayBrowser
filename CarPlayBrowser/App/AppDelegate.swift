//
//  AppDelegate.swift
//  CarPlayBrowser
//
//  Main application delegate managing multi-scene routing and early audio initialization.
//

import UIKit
import AVFoundation

@main
public class AppDelegate: UIResponder, UIApplicationDelegate {

    public static var shared: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    public var didInitializeAudioSession: Bool = false
    public var didInitializeRemoteCommands: Bool = false

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize early audio session and remote commands
        setupEarlyAudioSession()
        setupEarlyRemoteCommands()
        return true
    }

    // MARK: - Audio & Remote Command Initialization

    /// Configures the AVAudioSession for persistent background media playback.
    /// Uses .playback category and .moviePlayback mode to support inline HTML5 web videos.
    @discardableResult
    public func setupEarlyAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay])
            try session.setActive(true)
            didInitializeAudioSession = true
            return true
        } catch {
            print("[AppDelegate] Error configuring early audio session: \(error.localizedDescription)")
            didInitializeAudioSession = false
            return false
        }
    }

    /// Broadcasts remote command setup request across the application modules.
    public func setupEarlyRemoteCommands() {
        didInitializeRemoteCommands = true
        NotificationCenter.default.post(
            name: Constants.Notifications.setupRemoteCommands,
            object: self
        )
    }

    // MARK: - UISceneSession Lifecycle & Multi-Scene Routing

    public func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Route iPhone Window Scene
        if connectingSceneSession.role == .windowApplication {
            return UISceneConfiguration(
                name: Constants.SceneConfigurations.phone,
                sessionRole: connectingSceneSession.role
            )
        }

        // Route Apple CarPlay Template Application Scene (CPTemplateApplicationSceneSessionRoleApplication)
        if connectingSceneSession.role.rawValue == Constants.SceneSessionRoles.carPlayTemplate {
            return UISceneConfiguration(
                name: Constants.SceneConfigurations.carPlay,
                sessionRole: connectingSceneSession.role
            )
        }

        // Fallback to default phone configuration
        return UISceneConfiguration(
            name: Constants.SceneConfigurations.phone,
            sessionRole: connectingSceneSession.role
        )
    }

    public func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Release resources tied to discarded scene sessions if necessary
    }
}
