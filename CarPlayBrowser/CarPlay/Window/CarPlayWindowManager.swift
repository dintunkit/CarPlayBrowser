//
//  CarPlayWindowManager.swift
//  CarPlayBrowser
//
//  Automotive window presentation manager hosting custom view controllers
//  (e.g. CarPlayWebViewController) on CPWindow and orchestrating clean dismissal
//  transitions back to CPGridTemplate with thread-safe presentation locking.
//

import UIKit
import CarPlay

public final class CarPlayWindowManager {

    // MARK: - Singleton
    public static let shared = CarPlayWindowManager()

    // MARK: - Properties
    public weak var carWindow: CPWindow?
    public weak var interfaceController: CPInterfaceController?

    /// Active view controller presented on the automotive display
    public private(set) var currentViewController: UIViewController?

    /// Presentation state flag
    public private(set) var isPresenting: Bool = false

    /// Synchronization lock to prevent double-tap re-entrancy and presentation race conditions
    private let lock = NSLock()

    /// Notification hook triggered when presentation state transitions
    public var onPresentationStateChanged: ((Bool) -> Void)?

    /// Hook executed upon successful dismissal back to grid template
    public var onDismissCompleted: (() -> Void)?

    // MARK: - Initialization
    private init() {}

    // MARK: - Lifecycle & Attachment

    /// Binds the active CarPlay window and interface controller instances.
    public func attach(window: CPWindow?, interfaceController: CPInterfaceController?) {
        lock.lock()
        defer { lock.unlock() }

        self.carWindow = window
        self.interfaceController = interfaceController
    }

    /// Detaches and resets presentation state when CarPlay session terminates.
    public func detach() {
        dismiss(animated: false)

        lock.lock()
        defer { lock.unlock() }

        self.carWindow = nil
        self.interfaceController = nil
    }

    // MARK: - Presentation Management

    /// Mounts and displays a custom view controller onto the automotive CPWindow.
    /// Thread-safe guard eliminates duplicate presentations from rapid physical touches.
    ///
    /// - Parameters:
    ///   - viewController: UIViewController to present (e.g. CarPlayWebViewController)
    ///   - window: Optional target CPWindow override (defaults to attached carWindow)
    ///   - animated: Visual transition flag
    ///   - completion: Callback executed upon completion
    public func present(
        _ viewController: UIViewController,
        on window: CPWindow? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        lock.lock()
        guard !isPresenting else {
            lock.unlock()
            print("[CarPlayWindowManager] Presentation ignored: view controller is already being presented.")
            return
        }

        let targetWindow = window ?? self.carWindow
        guard let win = targetWindow else {
            lock.unlock()
            print("[CarPlayWindowManager] Warning: Cannot present; CPWindow is nil.")
            completion?()
            return
        }

        self.isPresenting = true
        self.currentViewController = viewController
        lock.unlock()

        let presentAction = { [weak self] in
            win.rootViewController = viewController
            win.isHidden = false
            win.makeKeyAndVisible()

            self?.onPresentationStateChanged?(true)
            completion?()
        }

        if Thread.isMainThread {
            presentAction()
        } else {
            DispatchQueue.main.async(execute: presentAction)
        }
    }

    /// Dismisses the custom view controller from CPWindow, restoring template visibility.
    /// Safely clears rootViewController without interrupting ongoing background audio sessions.
    ///
    /// - Parameters:
    ///   - animated: Visual transition flag
    ///   - completion: Callback executed after cleanup
    public func dismiss(
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        lock.lock()
        guard isPresenting || currentViewController != nil else {
            lock.unlock()
            completion?()
            return
        }

        let targetWindow = self.carWindow
        self.isPresenting = false
        self.currentViewController = nil
        lock.unlock()

        let dismissAction = { [weak self] in
            if let win = targetWindow {
                win.rootViewController = nil
                win.isHidden = true
            }

            self?.onPresentationStateChanged?(false)
            self?.onDismissCompleted?()
            completion?()
        }

        if Thread.isMainThread {
            dismissAction()
        } else {
            DispatchQueue.main.async(execute: dismissAction)
        }
    }

    /// Thread-safe query for active presentation state
    public func isCurrentlyPresenting() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isPresenting
    }
}
