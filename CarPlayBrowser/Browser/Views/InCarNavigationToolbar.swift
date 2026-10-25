//
//  InCarNavigationToolbar.swift
//  CarPlayBrowser
//
//  Automotive-grade touch navigation toolbar for CarPlay web browsing.
//  Conforms to Apple HIG with touch targets >= 48x48 pt, anti-glare dark styling,
//  dynamic SSL status indicator, and progress tracking.
//

import UIKit

// MARK: - Delegate Protocol
public protocol InCarNavigationToolbarDelegate: AnyObject {
    func toolbarDidTapBack()
    func toolbarDidTapForward()
    func toolbarDidTapReload()
    func toolbarDidToggleDesktop(isDesktop: Bool)
    func toolbarDidTapClose()
}

public class InCarNavigationToolbar: UIView {

    // MARK: - Delegate & Callbacks
    public weak var delegate: InCarNavigationToolbarDelegate?

    public var onBackTapped: (() -> Void)?
    public var onForwardTapped: (() -> Void)?
    public var onReloadTapped: (() -> Void)?
    public var onDesktopToggleTapped: (() -> Void)?
    public var onCloseTapped: (() -> Void)?

    // MARK: - UI Components (Touch targets >= 48x48 pt)
    public let backButton = UIButton(type: .system)
    public let forwardButton = UIButton(type: .system)
    public let reloadButton = UIButton(type: .system)
    public let desktopButton = UIButton(type: .system)
    public let closeButton = UIButton(type: .system)

    public let titleLabel = UILabel()
    public let lockIcon = UIImageView()
    public let progressView = UIProgressView(progressViewStyle: .bar)

    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let titleContainerStack = UIStackView()
    private let leadingButtonsStack = UIStackView()
    private let trailingButtonsStack = UIStackView()
    private let contentStackView = UIStackView()

    // MARK: - State Properties
    public private(set) var isDesktopActive: Bool = false
    public private(set) var isLoading: Bool = false

    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - View Setup
    private func setupViews() {
        backgroundColor = UIColor(white: 0.10, alpha: 0.95)
        clipsToBounds = true

        // Translucent anti-glare dark blur
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurEffectView)
        sendSubviewToBack(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Configure Buttons with >= 48x48 pt touch target constraints
        configureButton(
            backButton,
            systemName: "chevron.backward",
            action: #selector(backAction),
            accessibilityLabel: "Back"
        )
        configureButton(
            forwardButton,
            systemName: "chevron.forward",
            action: #selector(forwardAction),
            accessibilityLabel: "Forward"
        )
        configureButton(
            reloadButton,
            systemName: "arrow.clockwise",
            action: #selector(reloadAction),
            accessibilityLabel: "Reload"
        )
        configureButton(
            desktopButton,
            systemName: "desktopcomputer",
            action: #selector(desktopAction),
            accessibilityLabel: "Desktop Mode"
        )
        configureButton(
            closeButton,
            systemName: "xmark.circle.fill",
            action: #selector(closeAction),
            accessibilityLabel: "Close"
        )

        // Button colors & initial states
        backButton.isEnabled = false
        backButton.alpha = 0.35
        forwardButton.isEnabled = false
        forwardButton.alpha = 0.35

        desktopButton.tintColor = .lightGray
        reloadButton.tintColor = .white
        closeButton.tintColor = .systemRed

        // Title & SSL Lock Icon
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .systemGreen
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lockIcon.widthAnchor.constraint(equalToConstant: 14),
            lockIcon.heightAnchor.constraint(equalToConstant: 14)
        ])

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textAlignment = .center
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        titleContainerStack.axis = .horizontal
        titleContainerStack.spacing = 6
        titleContainerStack.alignment = .center
        titleContainerStack.distribution = .fill
        titleContainerStack.addArrangedSubview(lockIcon)
        titleContainerStack.addArrangedSubview(titleLabel)

        // Stack Groups
        leadingButtonsStack.axis = .horizontal
        leadingButtonsStack.spacing = Constants.UI.buttonSpacing
        leadingButtonsStack.alignment = .center
        leadingButtonsStack.addArrangedSubview(backButton)
        leadingButtonsStack.addArrangedSubview(forwardButton)

        trailingButtonsStack.axis = .horizontal
        trailingButtonsStack.spacing = Constants.UI.buttonSpacing
        trailingButtonsStack.alignment = .center
        trailingButtonsStack.addArrangedSubview(desktopButton)
        trailingButtonsStack.addArrangedSubview(reloadButton)
        trailingButtonsStack.addArrangedSubview(closeButton)

        // Content Horizontal Stack
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.distribution = .equalSpacing
        contentStackView.spacing = 8
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(leadingButtonsStack)
        contentStackView.addArrangedSubview(titleContainerStack)
        contentStackView.addArrangedSubview(trailingButtonsStack)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        // 3pt Progress Bar at bottom edge
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .clear
        progressView.progress = 0.0
        progressView.alpha = 0.0
        addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3.0)
        ])
    }

    private func configureButton(
        _ button: UIButton,
        systemName: String,
        action: Selector,
        accessibilityLabel: String
    ) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)

        // Strict in-car touch target enforcement (>= 48x48 pt)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minTouchTargetSize),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minTouchTargetSize)
        ])
    }

    // MARK: - Actions

    @objc private func backAction() {
        onBackTapped?()
        delegate?.toolbarDidTapBack()
    }

    @objc private func forwardAction() {
        onForwardTapped?()
        delegate?.toolbarDidTapForward()
    }

    @objc private func reloadAction() {
        onReloadTapped?()
        delegate?.toolbarDidTapReload()
    }

    @objc private func desktopAction() {
        let newState = !isDesktopActive
        updateDesktopMode(newState)
        onDesktopToggleTapped?()
        delegate?.toolbarDidToggleDesktop(isDesktop: newState)
    }

    @objc private func closeAction() {
        onCloseTapped?()
        delegate?.toolbarDidTapClose()
    }

    // MARK: - State Updaters

    public func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        backButton.isEnabled = canGoBack
        backButton.alpha = canGoBack ? 1.0 : 0.35

        forwardButton.isEnabled = canGoForward
        forwardButton.alpha = canGoForward ? 1.0 : 0.35
    }

    public func updateLoadingState(isLoading: Bool) {
        self.isLoading = isLoading
        let glyphName = isLoading ? "xmark" : "arrow.clockwise"
        reloadButton.setImage(UIImage(systemName: glyphName), for: .normal)
        reloadButton.accessibilityLabel = isLoading ? "Stop" : "Reload"

        if isLoading {
            progressView.alpha = 1.0
        } else {
            UIView.animate(withDuration: 0.3) {
                self.progressView.alpha = 0.0
            } completion: { _ in
                self.progressView.progress = 0.0
            }
        }
    }

    public func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
        if progress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                self.progressView.alpha = 0.0
            } completion: { _ in
                self.progressView.progress = 0.0
            }
        } else {
            progressView.alpha = 1.0
        }
    }

    public func updateTitle(_ title: String?) {
        titleLabel.text = title
    }

    public func updateDesktopMode(_ isDesktop: Bool) {
        self.isDesktopActive = isDesktop
        desktopButton.tintColor = isDesktop ? .systemBlue : .lightGray
    }

    /// Full synchronized state update
    public func updateNavigationState(
        canGoBack: Bool,
        canGoForward: Bool,
        isLoading: Bool,
        isDesktop: Bool,
        title: String?
    ) {
        updateNavigationState(canGoBack: canGoBack, canGoForward: canGoForward)
        updateLoadingState(isLoading: isLoading)
        updateDesktopMode(isDesktop)
        updateTitle(title)
    }
}

public typealias CarPlayTouchToolbar = InCarNavigationToolbar
