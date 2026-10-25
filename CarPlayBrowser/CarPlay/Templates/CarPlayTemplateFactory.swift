//
//  CarPlayTemplateFactory.swift
//  CarPlayBrowser
//
//  Factory producing Apple CarPlay CPGridTemplate and CPGridButton instances.
//  Ensures automotive HIG compliance, multi-length responsive title variants,
//  touch target minimums (>= 48pt), and tap debouncing.
//

import Foundation
import CarPlay
import UIKit

public final class CarPlayTemplateFactory {

    /// Standard root menu title
    public static let defaultTitle = Constants.App.name // "CarPlay Browser"

    /// Maximum buttons permitted by Apple CarPlay HIG for grid templates
    public static let maxCarPlayGridButtons: Int = 8

    /// Default selection debounce interval to prevent double-tap race conditions
    public static let defaultDebounceInterval: TimeInterval = 0.5

    // MARK: - Root Grid Template Construction

    /// Builds the primary CarPlay root CPGridTemplate with exactly 2 items: "YouTube" and "Google Search".
    ///
    /// - Parameters:
    ///   - title: Template header title (defaults to "CarPlay Browser")
    ///   - selectionHandler: Callback triggered when a menu target is selected
    /// - Returns: Fully configured CPGridTemplate instance
    public static func createRootGridTemplate(
        title: String = defaultTitle,
        selectionHandler: @escaping (CarPlayMenuTarget) -> Void
    ) -> CPGridTemplate {
        let youtubeButton = createGridButton(for: .youtube, selectionHandler: selectionHandler)
        let googleButton = createGridButton(for: .googleSearch, selectionHandler: selectionHandler)

        var buttons = [youtubeButton, googleButton]
        if buttons.count > maxCarPlayGridButtons {
            buttons = Array(buttons.prefix(maxCarPlayGridButtons))
        }

        return CPGridTemplate(title: title, gridButtons: buttons)
    }

    /// Builds a custom CPGridTemplate from a list of menu targets with safety clamping.
    public static func createGridTemplate(
        targets: [CarPlayMenuTarget],
        title: String = defaultTitle,
        debounceInterval: TimeInterval = defaultDebounceInterval,
        selectionHandler: @escaping (CarPlayMenuTarget) -> Void
    ) -> CPGridTemplate {
        let clampedTargets = targets.count > maxCarPlayGridButtons ? Array(targets.prefix(maxCarPlayGridButtons)) : targets
        let buttons = clampedTargets.map { target in
            createGridButton(for: target, debounceInterval: debounceInterval, selectionHandler: selectionHandler)
        }
        return CPGridTemplate(title: title, gridButtons: buttons)
    }

    // MARK: - Grid Button Construction

    /// Constructs an automotive-optimized CPGridButton with multi-length responsive title variants,
    /// dynamic icon, and debounced action dispatching.
    ///
    /// - Parameters:
    ///   - target: Destination target enum (.youtube or .googleSearch)
    ///   - debounceInterval: Time interval within which subsequent taps are ignored (default: 0.5s)
    ///   - customVariants: Optional override for title variants
    ///   - selectionHandler: Callback triggered upon validated tap
    /// - Returns: Instantiated CPGridButton
    public static func createGridButton(
        for target: CarPlayMenuTarget,
        debounceInterval: TimeInterval = defaultDebounceInterval,
        customVariants: [String]? = nil,
        selectionHandler: @escaping (CarPlayMenuTarget) -> Void
    ) -> CPGridButton {
        let rawVariants = customVariants ?? target.defaultTitleVariants
        let sanitizedVariants = sanitizeTitleVariants(rawVariants, fallbackTitle: target.title)
        let icon = UIImage.makeCarPlayIcon(for: target)

        var lastTapUptime: TimeInterval = 0

        let button = CPGridButton(titleVariants: sanitizedVariants, image: icon) { _ in
            let now = ProcessInfo.processInfo.systemUptime
            guard (now - lastTapUptime) >= debounceInterval else {
                return
            }
            lastTapUptime = now
            selectionHandler(target)
        }

        return button
    }

    // MARK: - Safety and Formatting Helpers

    /// Sanitizes title variants to prevent empty arrays and extreme character overflow.
    /// Clamps overly long strings to prevent head unit visual clipping.
    public static func sanitizeTitleVariants(_ variants: [String], fallbackTitle: String) -> [String] {
        guard !variants.isEmpty else {
            return [fallbackTitle]
        }
        let sanitized = variants.compactMap { variant -> String? in
            let trimmed = variant.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return nil
            }
            if trimmed.count > 35 {
                return String(trimmed.prefix(32)) + "..."
            }
            return trimmed
        }
        return sanitized.isEmpty ? [fallbackTitle] : sanitized
    }
}
