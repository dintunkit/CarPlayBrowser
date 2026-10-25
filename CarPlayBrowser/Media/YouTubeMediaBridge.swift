//
//  YouTubeMediaBridge.swift
//  CarPlayBrowser
//
//  Two-way JavaScript bridge for inspecting and controlling HTML5 video playback
//  inside WKWebView, dispatching steering wheel commands and syncing Now Playing metadata.
//

import Foundation
import WebKit

public final class YouTubeMediaBridge: NSObject, WKScriptMessageHandler {

    public static let shared = YouTubeMediaBridge()
    public static let messageHandlerName = "carPlayMediaBridge"

    public weak var activeWebView: WKWebView?

    public private(set) var isPlaying: Bool = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    public private(set) var currentTitle: String = ""
    public private(set) var channelName: String = ""

    override private init() {
        super.init()
    }

    // MARK: - Binding

    /// Binds a WKWebView instance to this media bridge and injects DOM observers.
    public func bind(webView: WKWebView) {
        self.activeWebView = webView
        injectMediaObserverScript(into: webView)
    }

    /// Injects JavaScript observer into the active web page to detect HTML5 <video> state changes.
    public func injectMediaObserverScript(into webView: WKWebView) {
        let script = """
        (function() {
            if (window.__carPlayBridgeInjected) return;
            window.__carPlayBridgeInjected = true;

            function postBridgeMessage(payload) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(YouTubeMediaBridge.messageHandlerName)) {
                    window.webkit.messageHandlers.\(YouTubeMediaBridge.messageHandlerName).postMessage(payload);
                }
            }

            function attachListenersToVideo(v) {
                if (!v || v.__carPlayBound) return;
                v.__carPlayBound = true;

                v.addEventListener('play', function() {
                    postBridgeMessage({
                        event: 'play',
                        currentTime: v.currentTime || 0,
                        duration: v.duration || 0,
                        title: document.title || '',
                        channel: extractChannelName()
                    });
                });

                v.addEventListener('pause', function() {
                    postBridgeMessage({
                        event: 'pause',
                        currentTime: v.currentTime || 0,
                        duration: v.duration || 0
                    });
                });

                v.addEventListener('timeupdate', function() {
                    // Throttled time updates
                    if (!v.__lastTimeUpdate || (Date.now() - v.__lastTimeUpdate > 2000)) {
                        v.__lastTimeUpdate = Date.now();
                        postBridgeMessage({
                            event: 'timeupdate',
                            currentTime: v.currentTime || 0,
                            duration: v.duration || 0
                        });
                    }
                });

                v.addEventListener('ended', function() {
                    postBridgeMessage({ event: 'ended' });
                });
            }

            function extractChannelName() {
                var elem = document.querySelector('#owner-name, ytm-channel-name, .ytm-channel-name, #channel-name');
                return elem ? elem.innerText.trim() : 'YouTube';
            }

            // Periodic discovery in case dynamic navigation loads video later
            setInterval(function() {
                var video = document.querySelector('video');
                if (video) {
                    attachListenersToVideo(video);
                }
            }, 1000);
        })();
        """

        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    // MARK: - Remote Control Execution (Steering Wheel Actions)

    public func play() {
        executeJS("var v = document.querySelector('video'); if (v) v.play();")
    }

    public func pause() {
        executeJS("var v = document.querySelector('video'); if (v) v.pause();")
    }

    public func togglePlayPause() {
        executeJS("""
        var v = document.querySelector('video');
        if (v) {
            v.paused ? v.play() : v.pause();
        }
        """)
    }

    public func seek(by seconds: TimeInterval) {
        executeJS("var v = document.querySelector('video'); if (v) v.currentTime += \(seconds);")
    }

    public func seek(to position: TimeInterval) {
        executeJS("var v = document.querySelector('video'); if (v) v.currentTime = \(position);")
    }

    public func nextTrack() {
        executeJS("""
        var nextBtn = document.querySelector('.ytp-next-button, [aria-label*="Next"]');
        if (nextBtn) { nextBtn.click(); }
        """)
    }

    public func previousTrack() {
        executeJS("""
        var prevBtn = document.querySelector('.ytp-prev-button, [aria-label*="Previous"]');
        if (prevBtn) { prevBtn.click(); }
        """)
    }

    private func executeJS(_ code: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeWebView?.evaluateJavaScript(code, completionHandler: nil)
        }
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == YouTubeMediaBridge.messageHandlerName,
              let payload = message.body as? [String: Any] else { return }

        let event = payload["event"] as? String ?? ""
        if let time = payload["currentTime"] as? TimeInterval {
            self.currentTime = time
        }
        if let dur = payload["duration"] as? TimeInterval, dur.isFinite {
            self.duration = dur
        }
        if let title = payload["title"] as? String, !title.isEmpty {
            self.currentTitle = title
        }
        if let channel = payload["channel"] as? String, !channel.isEmpty {
            self.channelName = channel
        }

        switch event {
        case "play":
            self.isPlaying = true
            NowPlayingInfoManager.shared.updateNowPlaying(
                title: self.currentTitle,
                artist: self.channelName,
                currentTime: self.currentTime,
                duration: self.duration,
                isPlaying: true
            )
            postPlaybackNotification()

        case "pause":
            self.isPlaying = false
            NowPlayingInfoManager.shared.updateNowPlaying(
                title: self.currentTitle,
                artist: self.channelName,
                currentTime: self.currentTime,
                duration: self.duration,
                isPlaying: false
            )
            postPlaybackNotification()

        case "timeupdate":
            NowPlayingInfoManager.shared.updateNowPlaying(
                title: self.currentTitle,
                artist: self.channelName,
                currentTime: self.currentTime,
                duration: self.duration,
                isPlaying: self.isPlaying
            )

        case "ended":
            self.isPlaying = false
            postPlaybackNotification()

        default:
            break
        }
    }

    private func postPlaybackNotification() {
        NotificationCenter.default.post(
            name: Constants.Notifications.playbackStateDidChange,
            object: self,
            userInfo: [
                Constants.UserInfoKeys.isPlaying: self.isPlaying,
                Constants.UserInfoKeys.currentTitle: self.currentTitle,
                Constants.UserInfoKeys.currentTime: self.currentTime,
                Constants.UserInfoKeys.duration: self.duration,
                Constants.UserInfoKeys.channelName: self.channelName
            ]
        )
    }
}
