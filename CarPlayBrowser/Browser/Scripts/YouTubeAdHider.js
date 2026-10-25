//
//  YouTubeAdHider.js
//  CarPlayBrowser
//
//  Standalone JavaScript bundle for YouTube ad hiding and skipping on CarPlay.
//

(function() {
    'use strict';

    // 1. Inject CSS for ad suppression
    const styleId = 'carplay-adblock-injected-style';
    if (!document.getElementById(styleId)) {
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
    }

    // 2. Video ad fast-forward engine
    let lastSkipAttempt = 0;

    function detectAndBypassVideoAds() {
        const isAdShowing = document.querySelector('.ad-showing, .ad-interrupting, .ytp-ad-player-overlay');
        const video = document.querySelector('video.html5-main-video') || document.querySelector('video');

        if (isAdShowing && video) {
            const now = Date.now();
            if (!video.muted) {
                video.muted = true;
            }
            video.playbackRate = 16.0;

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

    setInterval(detectAndBypassVideoAds, 250);

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
