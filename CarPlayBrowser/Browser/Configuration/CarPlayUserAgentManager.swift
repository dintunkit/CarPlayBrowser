//
//  CarPlayUserAgentManager.swift
//  CarPlayBrowser
//
//  Automotive User-Agent manager handling transitions between macOS Desktop Safari
//  and Mobile Safari representations on in-car touch displays.
//

import Foundation
import WebKit

public struct CarPlayUserAgentManager {

    // MARK: - Standard User-Agent Strings

    /// Exact macOS Safari Desktop User-Agent string
    public static let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    /// Mobile Safari User-Agent string
    public static let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

    // MARK: - Resolution Helpers

    /// Resolves the custom user agent string for the specified mode.
    /// In desktop mode returns the macOS Safari UA; in mobile mode returns nil
    /// (to allow default WebKit mobile UA) or an explicit mobile UA if requested.
    ///
    /// - Parameters:
    ///   - isDesktop: Boolean flag indicating desktop mode.
    ///   - explicitMobile: If true, returns mobileUserAgent instead of nil for mobile mode.
    /// - Returns: The resolved User-Agent string or nil.
    public static func userAgent(for isDesktop: Bool, explicitMobile: Bool = false) -> String? {
        if isDesktop {
            return desktopUserAgent
        } else {
            return explicitMobile ? mobileUserAgent : nil
        }
    }

    /// Resolves the WKContentMode corresponding to the desktop toggle state.
    @available(iOS 13.0, *)
    public static func preferredContentMode(for isDesktop: Bool) -> WKWebpagePreferences.ContentMode {
        return isDesktop ? .desktop : .mobile
    }

    /// Applies the specified desktop/mobile configuration to a WKWebView instance.
    public static func apply(isDesktop: Bool, to webView: WKWebView) {
        webView.customUserAgent = userAgent(for: isDesktop)

        if #available(iOS 13.0, *) {
            webView.configuration.defaultWebpagePreferences.preferredContentMode = preferredContentMode(for: isDesktop)
        }
    }
}
