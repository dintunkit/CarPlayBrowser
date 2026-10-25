//
//  CarPlayMenuCoordinator.swift
//  CarPlayBrowser
//
//  Singleton coordinator managing Apple CarPlay root menu template hierarchy,
//  destination target routing, debounced selection locks, and scene callbacks.
//

import Foundation
import CarPlay
import UIKit

public final class CarPlayMenuCoordinator {

    // MARK: - Singleton
    public static let shared = CarPlayMenuCoordinator()

    // MARK: - Properties
    public private(set) var rootGridTemplate: CPGridTemplate?
    public weak var interfaceController: CPInterfaceController?

    /// Currently active or last selected menu destination
    public private(set) var activeTarget: CarPlayMenuTarget?

    /// Callback delegated when a menu item is tapped
    public var onSelectTarget: ((CarPlayMenuTarget) -> Void)?

    /// Optional browser URL handler
    public var onOpenBrowser: ((URL, String) -> Void)?

    /// Debounce lock interval preventing rapid multi-tap re-entrancy
    public var debounceInterval: TimeInterval = CarPlayTemplateFactory.defaultDebounceInterval

    /// Internal transition lock state
    private var isTransitionLocked: Bool = false
    private let lockQueue = DispatchQueue(label: "com.carplaybrowser.menuCoordinatorLock")

    // MARK: - Initialization
    private init() {}

    // MARK: - Root Menu Setup

    /// Configures and sets the root menu template on the CarPlay interface controller.
    ///
    /// - Parameters:
    ///   - interfaceController: The active CarPlay CPInterfaceController
    ///   - animated: Whether the template presentation should be animated
    ///   - completion: Completion closure invoked with status
    public func setupRootMenu(
        with interfaceController: CPInterfaceController,
        animated: Bool = false,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        self.interfaceController = interfaceController
        let template = createRootMenuTemplate()
        interfaceController.setRootTemplate(template, animated: animated, completion: completion)
    }

    /// Creates and caches the root CPGridTemplate with configured debounced selection routing.
    ///
    /// - Parameter selectionHandler: Optional custom override handler
    /// - Returns: Fully wired CPGridTemplate
    @discardableResult
    public func createRootMenuTemplate(
        selectionHandler: ((CarPlayMenuTarget) -> Void)? = nil
    ) -> CPGridTemplate {
        let template = CarPlayTemplateFactory.createRootGridTemplate { [weak self] target in
            self?.handleTargetSelection(target, customHandler: selectionHandler)
        }
        self.rootGridTemplate = template
        return template
    }

    // MARK: - Selection Handling & Debouncing

    /// Handles destination selection with automotive transition lock and notification dispatching.
    public func handleTargetSelection(
        _ target: CarPlayMenuTarget,
        customHandler: ((CarPlayMenuTarget) -> Void)? = nil
    ) {
        var shouldProceed = false
        lockQueue.sync {
            if !self.isTransitionLocked {
                self.isTransitionLocked = true
                shouldProceed = true
            }
        }

        guard shouldProceed else {
            print("[CarPlayMenuCoordinator] Ignored rapid tap for target '\(target.rawValue)' during debounce lock.")
            return
        }

        self.activeTarget = target

        // Dispatch notifications and callbacks on main thread
        let dispatchAction = { [weak self] in
            guard let self = self else { return }

            NotificationCenter.default.post(
                name: Constants.Notifications.activeURLDidChange,
                object: self,
                userInfo: [
                    Constants.UserInfoKeys.currentURL: target.url,
                    Constants.UserInfoKeys.currentTitle: target.title
                ]
            )

            customHandler?(target)
            self.onSelectTarget?(target)
            self.onOpenBrowser?(target.url, target.title)
        }

        if Thread.isMainThread {
            dispatchAction()
        } else {
            DispatchQueue.main.async(execute: dispatchAction)
        }

        // Release transition lock after debounce interval
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval) { [weak self] in
            self?.lockQueue.sync {
                self?.isTransitionLocked = false
            }
        }
    }

    /// Resets the active destination and releases any lingering debounce lock.
    public func resetSelection() {
        lockQueue.sync {
            self.isTransitionLocked = false
        }
        self.activeTarget = nil
    }

    /// Queries whether the coordinator is currently locked in transition.
    public func isLocked() -> Bool {
        return lockQueue.sync { self.isTransitionLocked }
    }
}
