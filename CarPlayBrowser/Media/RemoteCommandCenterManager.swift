//
//  RemoteCommandCenterManager.swift
//  CarPlayBrowser
//
//  Handles hardware steering wheel controls and lock-screen media actions
//  via MPRemoteCommandCenter, delegating commands to YouTubeMediaBridge.
//

import Foundation
import MediaPlayer

public final class RemoteCommandCenterManager {

    public static let shared = RemoteCommandCenterManager()

    public private(set) var isConfigured: Bool = false

    private init() {
        setupNotificationListener()
    }

    private func setupNotificationListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSetupNotification),
            name: Constants.Notifications.setupRemoteCommands,
            object: nil
        )
    }

    @objc private func handleSetupNotification() {
        setupCommands()
    }

    /// Configures steering wheel buttons and in-vehicle remote commands.
    public func setupCommands() {
        guard !isConfigured else { return }

        let center = MPRemoteCommandCenter.shared()

        // 1. Play Command
        center.playCommand.isEnabled = true
        center.playCommand.addTarget { _ in
            YouTubeMediaBridge.shared.play()
            return .success
        }

        // 2. Pause Command
        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { _ in
            YouTubeMediaBridge.shared.pause()
            return .success
        }

        // 3. Toggle Play/Pause (Steering Wheel Mute/Play button)
        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { _ in
            YouTubeMediaBridge.shared.togglePlayPause()
            return .success
        }

        // 4. Skip Forward (+10 seconds)
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [10]
        center.skipForwardCommand.addTarget { _ in
            YouTubeMediaBridge.shared.seek(by: 10)
            return .success
        }

        // 5. Skip Backward (-10 seconds)
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [10]
        center.skipBackwardCommand.addTarget { _ in
            YouTubeMediaBridge.shared.seek(by: -10)
            return .success
        }

        // 6. Next Track
        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { _ in
            YouTubeMediaBridge.shared.nextTrack()
            return .success
        }

        // 7. Previous Track
        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { _ in
            YouTubeMediaBridge.shared.previousTrack()
            return .success
        }

        // 8. Seek Position (Scrubber bar on head unit)
        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            YouTubeMediaBridge.shared.seek(to: positionEvent.positionTime)
            return .success
        }

        isConfigured = true
    }

    /// Disables remote commands
    public func disableCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = false
        center.pauseCommand.isEnabled = false
        center.togglePlayPauseCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
        isConfigured = false
    }
}
