//
//  NowPlayingInfoManager.swift
//  CarPlayBrowser
//
//  Synchronizes HTML5 media metadata (title, artist, elapsed time, duration, playback rate)
//  with iOS MPNowPlayingInfoCenter for lock-screen and in-vehicle instrument cluster display.
//

import Foundation
import MediaPlayer

public final class NowPlayingInfoManager {

    public static let shared = NowPlayingInfoManager()

    private init() {}

    /// Updates MPNowPlayingInfoCenter with current video metadata.
    public func updateNowPlaying(
        title: String,
        artist: String,
        currentTime: TimeInterval,
        duration: TimeInterval,
        isPlaying: Bool
    ) {
        var info = [String: Any]()

        info[MPMediaItemPropertyTitle] = title.isEmpty ? "CarPlay Browser" : title
        info[MPMediaItemPropertyArtist] = artist.isEmpty ? "YouTube" : artist
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(0, currentTime)
        
        if duration > 0 && duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Use default artwork if available
        if #available(iOS 14.0, *) {
            if let carPlayImage = UIImage(systemName: "play.rectangle.fill") {
                let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
                    return carPlayImage
                }
                info[MPMediaItemPropertyArtwork] = artwork
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Clears MPNowPlayingInfoCenter metadata when playback stops or session ends.
    public func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
