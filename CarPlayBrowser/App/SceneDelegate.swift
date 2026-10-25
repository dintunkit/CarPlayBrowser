//
//  SceneDelegate.swift
//  CarPlayBrowser
//
//  iPhone primary window scene delegate managing phone UI lifecycle.
//

import UIKit

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    public var window: UIWindow?

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let mainViewController = PhoneMainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)

        // Configure navigation bar appearance
        navigationController.navigationBar.prefersLargeTitles = true

        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }

    public func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is released by the system
    }

    public func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart any tasks that were paused while the scene was inactive
    }

    public func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene moves from active to inactive state
    }

    public func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground
    }

    public func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background
    }
}
