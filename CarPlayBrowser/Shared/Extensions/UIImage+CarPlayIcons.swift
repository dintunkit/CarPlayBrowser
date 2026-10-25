//
//  UIImage+CarPlayIcons.swift
//  CarPlayBrowser
//
//  High-contrast, automotive-optimized dynamic icon generator for CarPlay CPGridButton items.
//  Uses UIGraphicsImageRenderer with Apple SF Symbols support and crisp programmatic fallback.
//

import UIKit

public extension UIImage {

    /// Generates an automotive-optimized high-contrast icon for CarPlay grid buttons.
    /// Supports Apple SF Symbols with automatic programmatic rounded-rect glyph fallback.
    ///
    /// - Parameters:
    ///   - systemName: SF Symbol identifier (e.g. "play.rectangle.fill", "magnifyingglass")
    ///   - fallbackSymbol: Unicode string glyph fallback (e.g. "▶", "🔍")
    ///   - backgroundColor: Brand badge background color
    ///   - size: Target dimensions (clamped to automotive safety minimum >= 44pt)
    /// - Returns: Rendered high-contrast UIImage
    static func makeCarPlayIcon(
        systemName: String,
        fallbackSymbol: String,
        backgroundColor: UIColor,
        size: CGSize = CGSize(width: Constants.UI.gridButtonIconSize, height: Constants.UI.gridButtonIconSize)
    ) -> UIImage {
        // Enforce automotive bounds: non-negative and minimum 44pt touch/readability size
        let nonNegativeWidth = max(0.0, size.width)
        let nonNegativeHeight = max(0.0, size.height)
        let effectiveWidth = nonNegativeWidth > 0 ? max(Constants.UI.minTouchTargetSize, nonNegativeWidth) : Constants.UI.minTouchTargetSize
        let effectiveHeight = nonNegativeHeight > 0 ? max(Constants.UI.minTouchTargetSize, nonNegativeHeight) : Constants.UI.minTouchTargetSize
        let renderSize = CGSize(width: effectiveWidth, height: effectiveHeight)

        let cornerRadius: CGFloat = 14.0 * (effectiveWidth / Constants.UI.gridButtonIconSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale > 0 ? UIScreen.main.scale : 2.0

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        // Attempt SF Symbol resolution
        let symbolPointSize: CGFloat = min(effectiveWidth, effectiveHeight) * 0.48
        var symbolConfig = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
        if #available(iOS 15.0, *) {
            symbolConfig = symbolConfig.applying(UIImage.SymbolConfiguration(hierarchicalColor: .white))
        }

        if let sfImage = UIImage(systemName: systemName, withConfiguration: symbolConfig) {
            return renderer.image { _ in
                // Render high-contrast rounded-rect background
                let bounds = CGRect(origin: .zero, size: renderSize)
                let bgPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
                backgroundColor.setFill()
                bgPath.fill()

                // Render centered white SF Symbol
                let symbolAspect = sfImage.size.width / max(1.0, sfImage.size.height)
                let maxGlyphDim = min(effectiveWidth, effectiveHeight) * 0.60
                let glyphWidth: CGFloat
                let glyphHeight: CGFloat
                if symbolAspect > 1.0 {
                    glyphWidth = maxGlyphDim
                    glyphHeight = maxGlyphDim / symbolAspect
                } else {
                    glyphHeight = maxGlyphDim
                    glyphWidth = maxGlyphDim * symbolAspect
                }

                let glyphRect = CGRect(
                    x: (renderSize.width - glyphWidth) / 2.0,
                    y: (renderSize.height - glyphHeight) / 2.0,
                    width: glyphWidth,
                    height: glyphHeight
                )
                sfImage.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: glyphRect)
            }
        }

        // Programmatic Fallback: Rounded rect with high-contrast text glyph
        return renderProgrammaticFallback(
            symbolText: fallbackSymbol,
            backgroundColor: backgroundColor,
            renderSize: renderSize,
            cornerRadius: cornerRadius
        )
    }

    /// Renders a programmatic fallback icon using UIKit CoreGraphics drawing.
    static func renderProgrammaticFallback(
        symbolText: String,
        backgroundColor: UIColor,
        renderSize: CGSize,
        cornerRadius: CGFloat = 14.0
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        return renderer.image { _ in
            let bounds = CGRect(origin: .zero, size: renderSize)
            let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
            backgroundColor.setFill()
            path.fill()

            let fontSize: CGFloat = max(20.0, min(renderSize.width, renderSize.height) * 0.43)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white
            ]
            let attrString = NSAttributedString(string: symbolText, attributes: attributes)
            let textSize = attrString.size()
            let textRect = CGRect(
                x: (renderSize.width - textSize.width) / 2.0,
                y: (renderSize.height - textSize.height) / 2.0,
                width: textSize.width,
                height: textSize.height
            )
            attrString.draw(in: textRect)
        }
    }

    /// Convenience generator for a specific CarPlayMenuTarget
    static func makeCarPlayIcon(
        for target: CarPlayMenuTarget,
        size: CGSize = CGSize(width: Constants.UI.gridButtonIconSize, height: Constants.UI.gridButtonIconSize)
    ) -> UIImage {
        return makeCarPlayIcon(
            systemName: target.sfSymbolName,
            fallbackSymbol: target.fallbackGlyph,
            backgroundColor: target.badgeColor,
            size: size
        )
    }

    /// Evaluates the contrast ratio between foreground and background colors according to WCAG AA guidelines
    static func calculateContrastRatio(foreground: UIColor, background: UIColor) -> Double {
        var fgR: CGFloat = 0, fgG: CGFloat = 0, fgB: CGFloat = 0, fgA: CGFloat = 0
        var bgR: CGFloat = 0, bgG: CGFloat = 0, bgB: CGFloat = 0, bgA: CGFloat = 0
        foreground.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        background.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)

        func linearize(_ c: CGFloat) -> CGFloat {
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        let l1 = 0.2126 * linearize(fgR) + 0.7152 * linearize(fgG) + 0.0722 * linearize(fgB)
        let l2 = 0.2126 * linearize(bgR) + 0.7152 * linearize(bgG) + 0.0722 * linearize(bgB)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return Double((lighter + 0.05) / (darker + 0.05))
    }
}
