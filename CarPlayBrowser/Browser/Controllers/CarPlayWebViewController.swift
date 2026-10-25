//
//  CarPlayWebViewController.swift
//  CarPlayBrowser
//
//  Automotive-optimized WKWebView controller rendered on Apple CarPlay CPWindow.
//  Hosts the touch navigation toolbar, handles desktop user-agent switching,
//  WebKit navigation lifecycle, and in-car failure recovery.
//

import UIKit
import WebKit

public class CarPlayWebViewController: UIViewController, WKNavigationDelegate, InCarNavigationToolbarDelegate {

    // MARK: - Properties
    public let target: CarPlayMenuTarget?
    public let initialURL: URL
    public private(set) var isDesktopMode: Bool = false
    public var onDismiss: (() -> Void)?

    public private(set) var webView: WKWebView!
    public private(set) var toolbar: InCarNavigationToolbar!
    public private(set) var errorHUDView: UIView?

    private var observers: [NSKeyValueObservation] = []
    private var isConfiguringWebView: Bool = false

    // MARK: - Initializers

    /// Primary initializer using CarPlayMenuTarget destination
    public init(target: CarPlayMenuTarget) {
        self.target = target
        self.initialURL = target.url
        super.init(nibName: nil, bundle: nil)
    }

    /// Flexible initializer using a direct URL and optional title
    public init(url: URL, initialTitle: String? = nil) {
        self.target = nil
        self.initialURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupToolbar()
        setupWebView()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupObservers()
    }

    deinit {
        cleanupObservers()
        webView?.stopLoading()
        webView?.navigationDelegate = nil
    }

    // MARK: - View Setup

    private func setupToolbar() {
        toolbar = InCarNavigationToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.delegate = self
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: Constants.UI.toolbarHeight)
        ])

        // Set initial title from target or host
        let initialTitle = target?.title ?? initialURL.host ?? "Browser"
        toolbar.updateTitle(initialTitle)
    }

    private func setupWebView() {
        isConfiguringWebView = true

        // Compile or fetch cached ad-blocking rules
        AdBlockRuleManager.shared.getOrCompileRuleList { [weak self] ruleList in
            guard let self = self else { return }

            let configuration = InCarWebViewConfigurationFactory.makeConfiguration(
                contentRuleList: ruleList,
                attachUserScripts: true
            )

            DispatchQueue.main.async {
                self.initializeWebView(with: configuration)
            }
        }
    }

    private func initializeWebView(with configuration: WKWebViewConfiguration) {
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = self

        // Apply desktop mode if initially requested
        CarPlayUserAgentManager.apply(isDesktop: self.isDesktopMode, to: webView)

        view.insertSubview(webView, belowSubview: toolbar)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupKVOObservers()
        isConfiguringWebView = false

        // Bind media bridge to receive and dispatch playback events
        YouTubeMediaBridge.shared.bind(webView: webView)

        // Load the initial destination URL
        load(url: initialURL)
    }

    // MARK: - KVO Observers

    private func setupKVOObservers() {
        guard let webView = webView else { return }
        cleanupObservers()

        observers = [
            webView.observe(\.canGoBack, options: [.new]) { [weak self] wv, _ in
                self?.toolbar?.updateNavigationState(canGoBack: wv.canGoBack, canGoForward: wv.canGoForward)
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] wv, _ in
                self?.toolbar?.updateNavigationState(canGoBack: wv.canGoBack, canGoForward: wv.canGoForward)
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] wv, _ in
                self?.toolbar?.updateLoadingState(isLoading: wv.isLoading)
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
                self?.toolbar?.updateProgress(Float(wv.estimatedProgress))
            },
            webView.observe(\.title, options: [.new]) { [weak self] wv, _ in
                let title = wv.title?.isEmpty == false ? wv.title : (wv.url?.host ?? self?.target?.title)
                self?.toolbar?.updateTitle(title)
                self?.notifyActiveURLChanged()
            },
            webView.observe(\.url, options: [.new]) { [weak self] wv, _ in
                self?.notifyActiveURLChanged()
            }
        ]
    }

    private func cleanupObservers() {
        observers.removeAll()
    }

    private func notifyActiveURLChanged() {
        guard let activeURL = webView?.url ?? Optional(initialURL) else { return }
        let currentTitle = webView?.title ?? target?.title ?? activeURL.host ?? ""

        NotificationCenter.default.post(
            name: Constants.Notifications.activeURLDidChange,
            object: self,
            userInfo: [
                Constants.UserInfoKeys.currentURL: activeURL,
                Constants.UserInfoKeys.currentTitle: currentTitle
            ]
        )
    }

    // MARK: - Navigation Control

    public func load(url: URL) {
        hideErrorHUD()
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    public func goBack() {
        if webView?.canGoBack == true {
            webView?.goBack()
        }
    }

    public func goForward() {
        if webView?.canGoForward == true {
            webView?.goForward()
        }
    }

    public func reload() {
        hideErrorHUD()
        webView?.reload()
    }

    public func stopLoading() {
        webView?.stopLoading()
    }

    public func setDesktopMode(_ enabled: Bool) {
        guard self.isDesktopMode != enabled else { return }
        self.isDesktopMode = enabled

        if let webView = self.webView {
            CarPlayUserAgentManager.apply(isDesktop: enabled, to: webView)
            toolbar?.updateDesktopMode(enabled)
            reload()
        }
    }

    public func dismiss() {
        cleanupObservers()
        stopLoading()

        if let customDismiss = onDismiss {
            customDismiss()
        } else {
            CarPlayWindowManager.shared.dismiss()
        }
    }

    // MARK: - InCarNavigationToolbarDelegate

    public func toolbarDidTapBack() {
        goBack()
    }

    public func toolbarDidTapForward() {
        goForward()
    }

    public func toolbarDidTapReload() {
        if webView?.isLoading == true {
            stopLoading()
        } else {
            reload()
        }
    }

    public func toolbarDidToggleDesktop(isDesktop: Bool) {
        setDesktopMode(isDesktop)
    }

    public func toolbarDidTapClose() {
        dismiss()
    }

    // MARK: - WKNavigationDelegate & Error Handling

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideErrorHUD()
        YouTubeMediaBridge.shared.injectMediaObserverScript(into: webView)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }

    private func handleNavigationError(_ error: Error) {
        // Ignore user cancellation errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }

        showErrorHUD(message: error.localizedDescription)
    }

    // MARK: - Automotive Error HUD

    private func showErrorHUD(message: String) {
        guard errorHUDView == nil else { return }

        let hud = UIView()
        hud.translatesAutoresizingMaskIntoConstraints = false
        hud.backgroundColor = UIColor(white: 0.12, alpha: 0.95)
        hud.layer.cornerRadius = Constants.UI.cornerRadius
        hud.layer.borderColor = UIColor.systemGray.cgColor
        hud.layer.borderWidth = 1.0

        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iconView.tintColor = .systemYellow
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Connection Failed"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        messageLabel.textColor = .lightGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        retryButton.tintColor = .white
        retryButton.backgroundColor = .systemBlue
        retryButton.layer.cornerRadius = 8.0
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minTouchTargetSize)
        ])

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel, retryButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        hud.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: hud.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: hud.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: hud.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: hud.trailingAnchor, constant: -20)
        ])

        view.addSubview(hud)
        NSLayoutConstraint.activate([
            hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hud.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hud.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])

        self.errorHUDView = hud
    }

    private func hideErrorHUD() {
        errorHUDView?.removeFromSuperview()
        errorHUDView = nil
    }

    @objc private func retryTapped() {
        hideErrorHUD()
        if let currentURL = webView?.url {
            load(url: currentURL)
        } else {
            load(url: initialURL)
        }
    }
}
