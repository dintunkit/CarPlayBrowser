//
//  InCarWebViewConfiguration.swift
//  CarPlayBrowser
//
//  Factory producing hardened WKWebViewConfiguration instances optimized
//  for Apple CarPlay in-vehicle touch displays, inline media playback,
//  and content filtering.
//

import Foundation
import WebKit

public enum InCarWebViewConfigurationFactory {

    /// Constructs a hardened WKWebViewConfiguration configured for automotive touch displays.
    ///
    /// - Parameters:
    ///   - contentRuleList: Optional compiled WKContentRuleList to attach for network-level ad blocking.
    ///   - attachUserScripts: Flag indicating whether to attach YouTube CSS hiding and JS skipping scripts (default: true).
    /// - Returns: A fully prepared WKWebViewConfiguration instance.
    public static func makeConfiguration(
        contentRuleList: WKContentRuleList? = nil,
        attachUserScripts: Bool = true
    ) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()

        // 1. In-Vehicle Media Playback Settings
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true

        // 2. Persistent Storage for Sessions & Cookies
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // 3. Security and Window Management Preferences
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }

        // 4. User Content Controller for Ad-Blocking & User Scripts
        let userContentController = WKUserContentController()

        // Attach compiled native rule list if provided
        if let ruleList = contentRuleList {
            userContentController.add(ruleList)
        }

        // Attach DOM ad hiding and auto-skip user scripts
        if attachUserScripts {
            for script in YouTubeAdFilterScripts.allUserScripts() {
                userContentController.addUserScript(script)
            }
        }

        // Attach Media Bridge script message handler
        userContentController.add(YouTubeMediaBridge.shared, name: YouTubeMediaBridge.messageHandlerName)

        configuration.userContentController = userContentController
        return configuration
    }
}
