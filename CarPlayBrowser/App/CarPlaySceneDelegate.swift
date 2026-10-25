//
//  CarPlaySceneDelegate.swift
//  CarPlayBrowser
//
//  Apple CarPlay application scene delegate managing external automotive display lifecycle,
//  CPInterfaceController navigation, and CPWindow view presentation hierarchy.
//

import UIKit
import CarPlay

open class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    // MARK: - Static Accessor
    public static weak var shared: CarPlaySceneDelegate?

    // MARK: - Properties
    public var interfaceController: CPInterfaceController?
    public var carWindow: CPWindow?
    public private(set) var isConnected: Bool = false

    /// Hook for CarPlay menu coordinator or external presentation modules
    public var onConnectHandler: ((CPInterfaceController, CPWindow?) -> Void)?
    public var onDisconnectHandler: ((CPInterfaceController, CPWindow?) -> Void)?
    public var onMenuTargetSelected: ((CarPlayMenuTarget) -> Void)?

    // MARK: - Initialization
    public override init() {
        super.init()
        CarPlaySceneDelegate.shared = self
    }

    // MARK: - CPTemplateApplicationSceneDelegate (Window-Supported Variant)
    // Called when CarPlay connects with external window support (e.g. Navigation/Screen displays)
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController, to window: CPWindow
    ) {
        self.interfaceController = interfaceController
        self.carWindow = window
        self.isConnected = true

        // Attach window manager
        CarPlayWindowManager.shared.attach(window: window, interfaceController: interfaceController)

        NotificationCenter.default.post(
            name: Constants.Notifications.carPlayDidConnect,
            object: self,
            userInfo: [Constants.UserInfoKeys.isConnected: true]
        )

        // Delegate to handler if registered (e.g. custom coordinator)
        if let handler = onConnectHandler {
            handler(interfaceController, window)
        } else {
            setupDefaultInterface(interfaceController: interfaceController, window: window)
        }
    }

    // MARK: - CPTemplateApplicationSceneDelegate (Template Fallback Variant)
    // Called when CarPlay connects in standard template mode
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        self.isConnected = true

        // Check if carWindow is exposed via KVC on the scene
        if let window = templateApplicationScene.value(forKey: "carWindow") as? CPWindow {
            self.carWindow = window
        }

        CarPlayWindowManager.shared.attach(window: self.carWindow, interfaceController: interfaceController)

        NotificationCenter.default.post(
            name: Constants.Notifications.carPlayDidConnect,
            object: self,
            userInfo: [Constants.UserInfoKeys.isConnected: true]
        )

        if let handler = onConnectHandler {
            handler(interfaceController, self.carWindow)
        } else {
            setupDefaultInterface(interfaceController: interfaceController, window: self.carWindow)
        }
    }

    // MARK: - Disconnection Lifecycle
    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        let oldController = self.interfaceController
        let oldWindow = self.carWindow

        self.interfaceController = nil
        self.carWindow = nil
        self.isConnected = false

        CarPlayWindowManager.shared.detach()
        CarPlayMenuCoordinator.shared.resetSelection()

        onDisconnectHandler?(interfaceController, window)

        NotificationCenter.default.post(
            name: Constants.Notifications.carPlayDidDisconnect,
            object: self,
            userInfo: [Constants.UserInfoKeys.isConnected: false]
        )
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.carWindow = nil
        self.isConnected = false

        CarPlayWindowManager.shared.detach()
        CarPlayMenuCoordinator.shared.resetSelection()

        onDisconnectHandler?(interfaceController, nil)

        NotificationCenter.default.post(
            name: Constants.Notifications.carPlayDidDisconnect,
            object: self,
            userInfo: [Constants.UserInfoKeys.isConnected: false]
        )
    }

    // MARK: - Window View Presentation Management

    /// Mounts a custom view controller (e.g. CarPlayWebViewController) onto the automotive CPWindow.
    public func presentOnCarWindow(_ viewController: UIViewController) {
        guard let window = carWindow else {
            print("[CarPlaySceneDelegate] Warning: Cannot present view controller; carWindow is nil.")
            return
        }
        CarPlayWindowManager.shared.present(viewController, on: window)
    }

    /// Dismisses the custom view controller from CPWindow, restoring template visibility.
    public func dismissFromCarWindow() {
        CarPlayWindowManager.shared.dismiss()
    }

    // MARK: - Default Interface Setup

    private func setupDefaultInterface(interfaceController: CPInterfaceController, window: CPWindow?) {
        // Wire up CarPlayMenuCoordinator root menu template
        CarPlayMenuCoordinator.shared.onSelectTarget = { [weak self] target in
            self?.handleMenuTargetSelected(target)
        }
        CarPlayMenuCoordinator.shared.setupRootMenu(with: interfaceController)
    }

    private func handleMenuTargetSelected(_ target: CarPlayMenuTarget) {
        if let customHandler = onMenuTargetSelected {
            customHandler(target)
            return
        }

        let webVC = CarPlayWebViewController(target: target)
        webVC.onDismiss = { [weak self] in
            self?.dismissFromCarWindow()
            CarPlayMenuCoordinator.shared.resetSelection()
        }
        presentOnCarWindow(webVC)
    }
}
