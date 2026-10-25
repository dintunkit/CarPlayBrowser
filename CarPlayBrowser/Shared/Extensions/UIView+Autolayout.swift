//
//  UIView+Autolayout.swift
//  CarPlayBrowser
//
//  Pure Swift AutoLayout convenience extensions for UIKit.
//

import UIKit

public extension UIView {

    /// Disables autoresizing mask translation and activates the given constraints.
    @discardableResult
    func activateConstraints(_ constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Constrains the view to all four edges of its superview with optional insets.
    @discardableResult
    func pinToEdges(of superview: UIView, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        if superview != self.superview {
            superview.addSubview(self)
        }
        let constraints = [
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right)
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Constrains the view to the safe area layout guide of its superview with optional insets.
    @discardableResult
    func pinToSafeArea(of superview: UIView, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        if superview != self.superview {
            superview.addSubview(self)
        }
        let guide = superview.safeAreaLayoutGuide
        let constraints = [
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right)
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Centers the view inside another view with optional horizontal and vertical offsets.
    @discardableResult
    func centerIn(view: UIView, xOffset: CGFloat = 0, yOffset: CGFloat = 0) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        if view != self.superview && self.superview == nil {
            view.addSubview(self)
        }
        let constraints = [
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: xOffset),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: yOffset)
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Sets explicit width and/or height constraints.
    @discardableResult
    func setDimensions(width: CGFloat? = nil, height: CGFloat? = nil) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if let width = width {
            constraints.append(widthAnchor.constraint(equalToConstant: width))
        }
        if let height = height {
            constraints.append(heightAnchor.constraint(equalToConstant: height))
        }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
