//
//  CarPlayMenuTarget.swift
//  CarPlayBrowser
//
//  Menu navigation destinations for Apple CarPlay root CPGridTemplate.
//  Encapsulates target URLs, automotive responsive title variants, SF Symbols,
//  and automotive color badges.
//

import Foundation
import UIKit

public enum CarPlayMenuTarget: String, CaseIterable, Identifiable {
    case youtube = "youtube"
    case googleSearch = "googleSearch"

    public var id: String {
        return rawValue
    }

    /// Primary display title for standard automotive screens
    public var title: String {
        switch self {
        case .youtube:
            return "YouTube"
        case .googleSearch:
            return "Google Search"
        }
    }

    /// Target destination URL for in-car browser loading
    public var url: URL {
        switch self {
        case .youtube:
            return Constants.URLs.youtube
        case .googleSearch:
            return Constants.URLs.googleSearch
        }
    }

    /// Destination URL string
    public var urlString: String {
        switch self {
        case .youtube:
            return Constants.URLs.youtubeString
        case .googleSearch:
            return Constants.URLs.googleSearchString
        }
    }

    /// Multi-length responsive title variants adapting to vehicle screen dimensions.
    /// Ordered from longest (for wide/panoramic screens) to most compact.
    public var defaultTitleVariants: [String] {
        switch self {
        case .youtube:
            return ["YouTube Video", "YouTube", "YT"]
        case .googleSearch:
            return ["Google Search", "Google", "Search"]
        }
    }

    /// Apple SF Symbol icon name conforming to CarPlay system design
    public var sfSymbolName: String {
        switch self {
        case .youtube:
            return "play.rectangle.fill"
        case .googleSearch:
            return "magnifyingglass"
        }
    }

    /// Brand accent color providing high-contrast automotive visibility (> 4.5:1 ratio)
    public var badgeColor: UIColor {
        switch self {
        case .youtube:
            // High-contrast YouTube Red (#FF0000)
            return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case .googleSearch:
            // High-contrast Google Blue (#4285F4)
            return UIColor(red: 66.0 / 255.0, green: 133.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
        }
    }

    /// Unicode glyph symbol utilized by programmatic raster fallback renderer
    public var fallbackGlyph: String {
        switch self {
        case .youtube:
            return "▶"
        case .googleSearch:
            return "🔍"
        }
    }

    /// Resilient initializer with automatic fallback to default search target
    public init(fallbackFromString string: String) {
        self = CarPlayMenuTarget(rawValue: string) ?? .googleSearch
    }
}
