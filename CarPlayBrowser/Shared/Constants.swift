//
//  Constants.swift
//  CarPlayBrowser
//
//  Shared application constants, URLs, User-Agent strings, UI metrics, and notification names.
//

import Foundation
import CoreGraphics

public enum Constants {

    // MARK: - App Identity
    public enum App {
        public static let name = "CarPlay Browser"
        public static let bundleIdentifier = "com.carplaybrowser.app"
        public static let version = "1.0"
        public static let build = "1"
    }

    // MARK: - Default Web URLs
    public enum URLs {
        public static let youtubeString = "https://www.youtube.com"
        public static let googleSearchString = "https://www.google.com"

        public static var youtube: URL {
            return URL(string: youtubeString)!
        }

        public static var googleSearch: URL {
            return URL(string: googleSearchString)!
        }
    }

    // MARK: - User Agents
    public enum UserAgent {
        /// Standard Mobile Safari User-Agent for touch-optimized mobile sites
        public static let mobileSafari = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        /// macOS Safari User-Agent for full desktop view and bypass of mobile site restrictions
        public static let desktopMacSafari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    }

    // MARK: - Scene Configuration Names
    public enum SceneConfigurations {
        public static let phone = "PhoneConfiguration"
        public static let carPlay = "CarPlayConfiguration"
    }

    // MARK: - Scene Session Roles
    public enum SceneSessionRoles {
        public static let phone = "UIWindowSceneSessionRoleApplication"
        public static let carPlayTemplate = "CPTemplateApplicationSceneSessionRoleApplication"
    }

    // MARK: - Automotive UI Metrics
    public enum UI {
        /// Minimum touch hit target per Apple Human Interface Guidelines for CarPlay (>= 48pt)
        public static let minTouchTargetSize: CGFloat = 48.0

        /// Grid button icon target dimensions
        public static let gridButtonIconSize: CGFloat = 60.0

        /// Height of in-car navigation toolbar
        public static let toolbarHeight: CGFloat = 54.0

        /// Standard automotive corner radius for cards and buttons
        public static let cornerRadius: CGFloat = 10.0

        /// Standard padding for in-car layouts
        public static let defaultPadding: CGFloat = 16.0

        /// Spacing between toolbar buttons
        public static let buttonSpacing: CGFloat = 12.0
    }

    // MARK: - Notification Names for State Synchronization
    public enum Notifications {
        /// Dispatched when CarPlay session connects to the head unit
        public static let carPlayDidConnect = Notification.Name("com.carplaybrowser.carPlayDidConnect")

        /// Dispatched when CarPlay session disconnects
        public static let carPlayDidDisconnect = Notification.Name("com.carplaybrowser.carPlayDidDisconnect")

        /// Dispatched when web video playback state changes (play, pause, time update)
        public static let playbackStateDidChange = Notification.Name("com.carplaybrowser.playbackStateDidChange")

        /// Dispatched when the active browser URL changes
        public static let activeURLDidChange = Notification.Name("com.carplaybrowser.activeURLDidChange")

        /// Triggered during app launch to wire up remote command handlers
        public static let setupRemoteCommands = Notification.Name("com.carplaybrowser.setupRemoteCommands")
    }

    // MARK: - UserInfo Keys
    public enum UserInfoKeys {
        public static let isConnected = "isConnected"
        public static let currentURL = "currentURL"
        public static let currentTitle = "currentTitle"
        public static let isPlaying = "isPlaying"
        public static let duration = "duration"
        public static let currentTime = "currentTime"
        public static let channelName = "channelName"
        public static let playbackRate = "playbackRate"
    }
}
