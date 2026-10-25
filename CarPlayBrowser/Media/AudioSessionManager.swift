//
//  AudioSessionManager.swift
//  CarPlayBrowser
//
//  Manages AVAudioSession lifecycle, interruption handling, route change detection,
//  and background audio persistence for in-car media playback.
//

import Foundation
import AVFoundation

public final class AudioSessionManager {

    public static let shared = AudioSessionManager()

    public private(set) var isSessionActive: Bool = false
    public var onPlaybackInterrupted: ((Bool) -> Void)?

    private init() {
        setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup & Activation

    /// Configures the shared audio session for in-car video audio playback.
    /// Uses .playback category and .moviePlayback mode with AirPlay and Bluetooth A2DP.
    @discardableResult
    public func activateAudioSession() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            isSessionActive = true
            return true
        } catch {
            print("[AudioSessionManager] Failed to activate audio session: \(error.localizedDescription)")
            isSessionActive = false
            return false
        }
    }

    /// Deactivates the audio session when playback stops or CarPlay disconnects.
    public func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            print("[AudioSessionManager] Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Observers

    private func setupObservers() {
        let center = NotificationCenter.default

        // Audio Interruption (Phone calls, Siri, Navigation voice guidance)
        center.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        // Audio Route Change (Head unit disconnection, vehicle power off)
        center.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Pause playback when call or navigation audio arrives
            onPlaybackInterrupted?(true)
            YouTubeMediaBridge.shared.pause()

        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Resume playback when interruption finishes
                    onPlaybackInterrupted?(false)
                    YouTubeMediaBridge.shared.play()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            // CarPlay disconnected or vehicle turned off -> auto pause
            YouTubeMediaBridge.shared.pause()
        }
    }
}
