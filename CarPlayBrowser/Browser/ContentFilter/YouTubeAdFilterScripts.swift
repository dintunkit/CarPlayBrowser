//
//  YouTubeAdFilterScripts.swift
//  CarPlayBrowser
//
//  WebKit user script providers for in-car YouTube ad filtering:
//  1. CSS style injection (.atDocumentStart) suppressing visual ad containers before rendering.
//  2. JavaScript auto-skipping engine (.atDocumentEnd) fast-forwarding in-stream ads to completion.
//

import Foundation
import WebKit

public struct YouTubeAdFilterScripts {

    // MARK: - Script Sources

    /// CSS injection script executed at .atDocumentStart to suppress ad overlays and banners immediately
    public static let cssHidingScriptSource: String = """
    (function() {
        'use strict';
        const styleId = 'carplay-adblock-injected-style';
        if (document.getElementById(styleId)) return;

        const css = `
            .ytp-ad-overlay-container,
            .ytp-ad-overlay-slot,
            .ytp-ad-message-container,
            .ytp-ad-text,
            .ytp-ad-player-overlay,
            .ytp-ad-player-overlay-layout,
            ytd-ad-slot-renderer,
            ytd-in-feed-ad-layout-renderer,
            ytd-banner-promo-renderer,
            ytd-promoted-sparkles-web-renderer,
            ytd-display-ad-renderer,
            ytm-promoted-sparkles-web-renderer,
            ytm-companion-ad-renderer,
            #player-ads,
            .sparkles-light-cta,
            #masthead-ad,
            .video-ads,
            .ytp-ad-module {
                display: none !important;
                visibility: hidden !important;
                opacity: 0 !important;
                pointer-events: none !important;
                height: 0 !important;
                max-height: 0 !important;
            }
        `;

        const style = document.createElement('style');
        style.id = styleId;
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
    })();
    """

    /// JavaScript video ad fast-forward & auto-skip engine executed at .atDocumentEnd
    public static let videoAdSkipperScriptSource: String = """
    (function() {
        'use strict';

        let lastSkipAttempt = 0;

        function detectAndBypassVideoAds() {
            // 1. Detect active in-stream ad states
            const isAdShowing = document.querySelector('.ad-showing, .ad-interrupting, .ytp-ad-player-overlay');
            const video = document.querySelector('video.html5-main-video') || document.querySelector('video');

            if (isAdShowing && video) {
                const now = Date.now();

                // Mute ad audio to avoid distracting the driver
                if (!video.muted) {
                    video.muted = true;
                }

                // Accelerate video playback speed to 16.0x
                video.playbackRate = 16.0;

                // Fast-forward to end of ad duration (throttled to avoid event flood)
                if (now - lastSkipAttempt > 250) {
                    lastSkipAttempt = now;
                    if (!isNaN(video.duration) && isFinite(video.duration) && video.duration > 0) {
                        video.currentTime = video.duration - 0.05;
                    } else {
                        video.currentTime = 99999;
                    }
                    video.dispatchEvent(new Event('timeupdate', { bubbles: true }));
                }
            }

            // 2. Click native YouTube skip ad buttons as soon as available
            const skipButtonSelectors = [
                '.ytp-ad-skip-button',
                '.ytp-ad-skip-button-modern',
                '.ytp-skip-ad-button',
                '.ytp-ad-skip-button-slot button',
                'button.ytp-ad-skip-button-modern',
                'button[aria-label^="Skip ad"]',
                'button[aria-label*="skip" i]'
            ];

            for (let i = 0; i < skipButtonSelectors.length; i++) {
                const btn = document.querySelector(skipButtonSelectors[i]);
                if (btn && btn.offsetParent !== null) {
                    btn.click();
                    break;
                }
            }
        }

        // Run watchdog cycle every 250ms
        setInterval(detectAndBypassVideoAds, 250);

        // Reactive MutationObserver for DOM state changes
        const observer = new MutationObserver(function() {
            detectAndBypassVideoAds();
        });

        const attachObserver = () => {
            const target = document.querySelector('#movie_player') || document.body;
            if (target) {
                observer.observe(target, { childList: true, subtree: true, attributes: true });
            }
        };

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', attachObserver);
        } else {
            attachObserver();
        }
    })();
    """

    // MARK: - WKUserScript Factory Methods

    /// Creates the CSS hiding user script injected at document start
    public static func makeCSSHidingUserScript() -> WKUserScript {
        return WKUserScript(
            source: cssHidingScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    }

    /// Creates the video ad skipping user script injected at document end
    public static func makeVideoAdSkipperUserScript() -> WKUserScript {
        return WKUserScript(
            source: videoAdSkipperScriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }

    /// Returns both user scripts configured for injection into WKWebView
    public static func allUserScripts() -> [WKUserScript] {
        return [
            makeCSSHidingUserScript(),
            makeVideoAdSkipperUserScript()
        ]
    }
}
